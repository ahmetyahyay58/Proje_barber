-- Supabase SQL Editor'de calistirin: musteri yorumlarinin herkese acik okunmasi icin.
drop policy if exists "appointments_read_public_reviews" on public.appointments;
create policy "appointments_read_public_reviews"
on public.appointments for select to authenticated
using (rating is not null);
