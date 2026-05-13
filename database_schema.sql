-- 1) Extensions
create extension if not exists "pgcrypto";
create extension if not exists "btree_gist";

-- 2) Enumlar
do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type app_role as enum ('customer', 'barber', 'admin');
  end if;

  if not exists (select 1 from pg_type where typname = 'appointment_status') then
    create type appointment_status as enum ('pending', 'confirmed', 'completed', 'cancelled');
  end if;
end $$;

-- 3) updated_at trigger function
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- 4) profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role app_role not null default 'customer',
  full_name text,
  phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Eski kurulumlar icin migration: profil fotografi kolonu.
alter table public.profiles
add column if not exists avatar_url text;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- 5) barbers
create table if not exists public.barbers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  city text not null,
  district text not null,
  address text not null,
  lat double precision,
  lng double precision,
  rating numeric(2,1) not null default 0 check (rating >= 0 and rating <= 5),
  min_price integer not null default 0,
  max_price integer not null default 0,
  avatar_url text,
  about text,
  gallery_urls text[] not null default '{}',
  masters text[] not null default '{}',
  days_off int[] not null default '{7}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_barbers_updated_at on public.barbers;
create trigger trg_barbers_updated_at
before update on public.barbers
for each row execute function public.set_updated_at();

create index if not exists idx_barbers_owner_id on public.barbers(owner_id);
create index if not exists idx_barbers_city_district on public.barbers(city, district);
create index if not exists idx_barbers_lat_lng on public.barbers(lat, lng);

-- 6) barber_services
create table if not exists public.barber_services (
  id uuid primary key default gen_random_uuid(),
  barber_id uuid not null references public.barbers(id) on delete cascade,
  name text not null,
  duration_minutes integer not null check (duration_minutes > 0),
  price integer not null check (price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_barber_services_updated_at on public.barber_services;
create trigger trg_barber_services_updated_at
before update on public.barber_services
for each row execute function public.set_updated_at();

create index if not exists idx_barber_services_barber_id on public.barber_services(barber_id);

-- 7) appointments
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references auth.users(id) on delete cascade, -- YENİ: nullable yapıldı (Hesabı olmayan müşteri eklenebilsin diye)
  customer_name_snapshot text, -- YENİ: Dışardan gelen, hesabı olmayan müşteri isimleri için (Manuel eklemelerde)
  barber_id uuid not null references public.barbers(id) on delete cascade,
  barber_name_snapshot text not null,
  start_at timestamptz not null,
  duration_minutes integer not null check (duration_minutes > 0),
  total_amount integer not null default 0,
  service_names text[] not null default '{}',
  master_name text,
  -- Overbooking önleme için: bitiş zamanı ve "usta" anahtarı.
  end_at timestamptz generated always as (start_at + make_interval(mins => duration_minutes)) stored,
  master_key text generated always as (coalesce(nullif(btrim(master_name), ''), '__ANY__')) stored,
  rating numeric(2,1) check (rating >= 0 and rating <= 5), -- YORUMLAR/Puan: (Randevu sonrası oylama buraya yapılacak)
  note text, -- YORUMLAR/Metin: (Randevu sonrası yazılı yorum)
  status appointment_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_appointments_updated_at on public.appointments;
create trigger trg_appointments_updated_at
before update on public.appointments
for each row execute function public.set_updated_at();

create index if not exists idx_appointments_customer_id on public.appointments(customer_id);
create index if not exists idx_appointments_barber_id on public.appointments(barber_id);
create index if not exists idx_appointments_start_at on public.appointments(start_at);
create index if not exists idx_appointments_barber_master_start on public.appointments(barber_id, master_key, start_at);

-- 7.0) Overbooking (çakışma) engelleme
-- Aynı berber + aynı usta için zaman aralıklarının üst üste binmesini engeller.
-- cancelled randevular kısıta dahil değildir.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'appointments_no_overlap_per_master'
  ) then
    alter table public.appointments
    add constraint appointments_no_overlap_per_master
    exclude using gist (
      barber_id with =,
      master_key with =,
      tstzrange(start_at, end_at, '[)') with &&
    )
    where (status <> 'cancelled');
  end if;
end $$;

alter table public.appointments
add column if not exists total_amount integer not null default 0;

-- 7.1) barber_expenses
create table if not exists public.barber_expenses (
  id uuid primary key default gen_random_uuid(),
  barber_id uuid not null references public.barbers(id) on delete cascade,
  title text not null,
  amount integer not null check (amount >= 0),
  incurred_on date not null default current_date,
  description text,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.barber_expenses
add column if not exists description text;

drop trigger if exists trg_barber_expenses_updated_at on public.barber_expenses;
create trigger trg_barber_expenses_updated_at
before update on public.barber_expenses
for each row execute function public.set_updated_at();

create index if not exists idx_barber_expenses_barber_id on public.barber_expenses(barber_id);


-- YENİ: DİNAMİK PUANLAMA (RATING) TRIGGER'I 🔥
-- Müşteri randevusuna puan verdiğinde, berberin genel rating'ini otomatik günceller.
create or replace function public.update_barber_rating()
returns trigger
language plpgsql
as $$
begin
  if (TG_OP = 'UPDATE' and old.rating is distinct from new.rating) or
     (TG_OP = 'INSERT' and new.rating is not null) then
    
    update public.barbers
    set rating = (
      select coalesce(round(avg(rating), 1), 0)
      from public.appointments
      where barber_id = new.barber_id and rating is not null
    )
    where id = new.barber_id;
    
  end if;
  return new;
end;
$$;

drop trigger if exists trg_appointments_rating_update on public.appointments;
create trigger trg_appointments_rating_update
after insert or update of rating on public.appointments
for each row execute function public.update_barber_rating();


-- 8) RLS
alter table public.profiles enable row level security;
alter table public.barbers enable row level security;
alter table public.barber_services enable row level security;
alter table public.appointments enable row level security;
alter table public.barber_expenses enable row level security;

-- 9) Policies (temiz & güçlendirilmiş)

-- profiles (YENİLENDİ: Artık herkes profillerin ismini ve telefonunu okuyabilir)
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_read_auth" on public.profiles;
create policy "profiles_read_auth"
on public.profiles for select to authenticated
using (true);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert to authenticated
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- barbers
drop policy if exists "barbers_read_anon" on public.barbers;
create policy "barbers_read_anon"
on public.barbers for select to anon
using (true);

drop policy if exists "barbers_read_auth" on public.barbers;
create policy "barbers_read_auth"
on public.barbers for select to authenticated
using (true);

drop policy if exists "barbers_owner_insert" on public.barbers;
create policy "barbers_owner_insert"
on public.barbers for insert to authenticated
with check (auth.uid() = owner_id);

drop policy if exists "barbers_owner_update" on public.barbers;
create policy "barbers_owner_update"
on public.barbers for update to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "barbers_owner_delete" on public.barbers;
create policy "barbers_owner_delete"
on public.barbers for delete to authenticated
using (auth.uid() = owner_id);

-- services
drop policy if exists "services_read_anon" on public.barber_services;
create policy "services_read_anon"
on public.barber_services for select to anon
using (true);

drop policy if exists "services_read_auth" on public.barber_services;
create policy "services_read_auth"
on public.barber_services for select to authenticated
using (true);

drop policy if exists "services_owner_write" on public.barber_services;
create policy "services_owner_write"
on public.barber_services for all to authenticated
using (
  exists (
    select 1 from public.barbers b
    where b.id = barber_id and b.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.barbers b
    where b.id = barber_id and b.owner_id = auth.uid()
  )
);

-- appointments (Okuma, Yazma, Güncelleme)
drop policy if exists "appointments_customer_read_own" on public.appointments;
drop policy if exists "appointments_read" on public.appointments;
create policy "appointments_read"
on public.appointments for select to authenticated
using (
  customer_id = auth.uid()
  or exists (
    select 1 from public.barbers b
    where b.id = barber_id and b.owner_id = auth.uid()
  )
);

-- YENİLENDİ: Berberler de kendi dükkanına kayıt ekleyebilsin
drop policy if exists "appointments_customer_insert_own" on public.appointments;
drop policy if exists "appointments_insert" on public.appointments;
create policy "appointments_insert"
on public.appointments for insert to authenticated
with check (
  customer_id = auth.uid() 
  or 
  exists (
    select 1 from public.barbers b
    where b.id = barber_id and b.owner_id = auth.uid()
  )
);

-- YENİLENDİ: Güncellemeyi (Puanlama dahil) yapabilecekler
drop policy if exists "appointments_customer_update_own" on public.appointments;
drop policy if exists "appointments_barber_update_own_shop" on public.appointments;
drop policy if exists "appointments_update" on public.appointments;
create policy "appointments_update"
on public.appointments for update to authenticated
using (
  customer_id = auth.uid()
  or exists (
    select 1 from public.barbers b
    where b.id = barber_id and b.owner_id = auth.uid()
  )
)
with check (
  customer_id = auth.uid()
  or exists (
    select 1 from public.barbers b
    where b.id = barber_id and b.owner_id = auth.uid()
  )
);

-- barber_expenses
drop policy if exists "barber_expenses_owner_all" on public.barber_expenses;
create policy "barber_expenses_owner_all"
on public.barber_expenses for all to authenticated
using (
  exists (
    select 1 from public.barbers b
    where b.id = barber_id and b.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.barbers b
    where b.id = barber_id and b.owner_id = auth.uid()
  )
);
