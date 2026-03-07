import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/models/barber.dart';
import '../../data/models/appointment.dart';
import '../../data/stores/appointment_store.dart';
import '../../data/stores/barber_store.dart';
import '../../data/stores/working_days_store.dart';

enum _BarberMenu {
  home('Ana Ekran', Icons.dashboard_outlined),
  appointments('Randevular', Icons.event_note_outlined),
  staff('Eleman Ekle/Çıkar', Icons.groups_outlined),
  prices('Fiyat Listesi', Icons.payments_outlined),
  daysOff('İzin Günleri', Icons.beach_access_outlined),
  settings('Genel Ayarlar', Icons.settings_outlined);

  const _BarberMenu(this.label, this.icon);
  final String label;
  final IconData icon;
}

class BarberShell extends StatefulWidget {
  const BarberShell({super.key});

  @override
  State<BarberShell> createState() => _BarberShellState();
}

class _BarberShellState extends State<BarberShell> {
  _BarberMenu _selected = _BarberMenu.home;

  void _select(_BarberMenu menu) {
    setState(() => _selected = menu);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_selected) {
      _BarberMenu.home => _BarberHome(
          onAddBarber: () => _showAddBarberDialog(context),
        ),
      _BarberMenu.appointments => const _BarberAppointmentsPage(),
      _BarberMenu.staff => const _BarberStaffPage(),
      _BarberMenu.prices => const _BarberPriceListPage(),
      _BarberMenu.daysOff => const _BarberDaysOffPage(),
      _BarberMenu.settings => const _BarberSettingsPage(),
    };

    return Scaffold(
      appBar: AppBar(title: Text(_selected.label)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const _DrawerHeader(title: 'Berber Paneli'),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final item in _BarberMenu.values)
                      ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.label),
                        selected: item == _selected,
                        onTap: () => _select(item),
                      ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Çıkış Yap'),
                      onTap: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.roleSelect,
                          (_) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: page,
    );
  }

  Future<void> _showAddBarberDialog(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'İstanbul');
    final districtCtrl = TextEditingController(text: 'Kadıköy');
    final addressCtrl = TextEditingController();
    final minPriceCtrl = TextEditingController(text: '250');
    final maxPriceCtrl = TextEditingController(text: '650');
    double rating = 4.5;
    String? avatarPath;
    final List<String> galleryPaths = <String>[];

    Future<void> close() async {
      nameCtrl.dispose();
      cityCtrl.dispose();
      districtCtrl.dispose();
      addressCtrl.dispose();
      minPriceCtrl.dispose();
      maxPriceCtrl.dispose();
      Navigator.of(context).pop();
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Future<void> pickAvatar() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowMultiple: false,
              );
              if (result != null && result.files.single.path != null) {
                setStateDialog(() {
                  avatarPath = result.files.single.path;
                });
              }
            }

            Future<void> pickGallery() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowMultiple: true,
              );
              if (result != null) {
                setStateDialog(() {
                  for (final f in result.files) {
                    if (f.path != null) {
                      galleryPaths.add(f.path!);
                    }
                  }
                });
              }
            }

            Widget buildAvatarPreview() {
              if (avatarPath == null) {
                return CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  foregroundColor: scheme.primary,
                  child: const Icon(Icons.camera_alt_outlined),
                );
              }
              final file = File(avatarPath!);
              if (!file.existsSync()) {
                return CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  foregroundColor: scheme.primary,
                  child: const Icon(Icons.camera_alt_outlined),
                );
              }
              return CircleAvatar(
                radius: 28,
                backgroundImage: FileImage(file),
              );
            }

            return AlertDialog(
              title: const Text('Yeni Berber Oluştur'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: pickAvatar,
                            child: buildAvatarPreview(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profil Fotoğrafı',
                                  style:
                                      Theme.of(ctx).textTheme.titleSmall,
                                ),
                                Text(
                                  'Logon ya da dükkânının fotoğrafı.',
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.outline,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: pickGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            galleryPaths.isEmpty
                                ? 'Genel fotoğraflar ekle'
                                : '(${galleryPaths.length}) fotoğraf seçildi',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Berber Adı',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.length < 3) return 'En az 3 karakter gir.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Şehir',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Şehir gir.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: districtCtrl,
                        decoration: const InputDecoration(
                          labelText: 'İlçe',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'İlçe gir.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Adres',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.length < 5) return 'Adres gir.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: minPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Fiyat (₺)',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: maxPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maksimum Fiyat (₺)',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Başlangıç puanı: ${rating.toStringAsFixed(1)}',
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                      ),
                      Slider(
                        min: 3,
                        max: 5,
                        divisions: 4,
                        label: rating.toStringAsFixed(1),
                        value: rating,
                        onChanged: (v) {
                          setStateDialog(() {
                            rating = v;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Oluşturduğun bu profil müşteri tarafındaki listede fotoğraflı ve premium görünecek.',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: scheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: close, child: const Text('İptal')),
                FilledButton(
                  onPressed: () {
                    final ok = formKey.currentState?.validate() ?? false;
                    if (!ok) return;
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    final minPrice =
                        int.tryParse(minPriceCtrl.text.trim()) ?? 250;
                    final maxPrice =
                        int.tryParse(maxPriceCtrl.text.trim()) ?? 650;
                    BarberStore.instance.addBarber(
                      Barber(
                        id: id,
                        name: nameCtrl.text.trim(),
                        city: cityCtrl.text.trim(),
                        district: districtCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        rating: rating,
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                        avatarPath: avatarPath,
                        galleryPaths: List<String>.from(galleryPaths),
                      ),
                    );
                    close();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Berber eklendi.')),
                    );
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: const Icon(Icons.content_cut),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarberHome extends StatelessWidget {
  const _BarberHome({required this.onAddBarber});

  final VoidCallback onAddBarber;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Yeni Berber Oluştur',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Şehir, ilçe, adres ve fiyat aralığıyla sıfırdan yeni bir berber profili oluştur.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onAddBarber,
                    icon: const Icon(Icons.add_business),
                    label: const Text('Yeni Berber Oluştur'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Özet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                title: 'Bugünkü Randevular',
                value: '5',
                icon: Icons.event_available_outlined,
                color: scheme.primaryContainer,
              ),
              _StatCard(
                title: 'Toplam Eleman',
                value: '3',
                icon: Icons.groups_outlined,
                color: scheme.secondaryContainer,
              ),
              _StatCard(
                title: 'İzin Günleri',
                value: 'Ayarla',
                icon: Icons.beach_access_outlined,
                color: scheme.tertiaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarberAppointmentsPage extends StatelessWidget {
  const _BarberAppointmentsPage();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: AppointmentStore.instance.appointments,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Henüz randevu yok.'),
            ),
          );
        }

        String formatDateTime(DateTime d) {
          final day = d.day.toString().padLeft(2, '0');
          final month = d.month.toString().padLeft(2, '0');
          final year = d.year.toString();
          final hour = d.hour.toString().padLeft(2, '0');
          final minute = d.minute.toString().padLeft(2, '0');
          return '$day.$month.$year • $hour:$minute';
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final a = list[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: Text(a.barberName),
                subtitle: Text(formatDateTime(a.dateTime)),
              ),
            );
          },
        );
      },
    );
  }
}

class _BarberStaffPage extends StatefulWidget {
  const _BarberStaffPage();

  @override
  State<_BarberStaffPage> createState() => _BarberStaffPageState();
}

class _BarberStaffPageState extends State<_BarberStaffPage> {
  final List<String> _staff = ['Ali', 'Mehmet', 'Ayşe'];

  Future<void> _addStaff() async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eleman Ekle'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Ad'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ctrl.dispose();
              Navigator.of(ctx).pop();
            },
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() => _staff.add(name));
              }
              ctrl.dispose();
              Navigator.of(ctx).pop();
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Elemanlar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              FilledButton.icon(
                onPressed: _addStaff,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _staff.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(_staff[i]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _staff.removeAt(i)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarberPriceListPage extends StatefulWidget {
  const _BarberPriceListPage();

  @override
  State<_BarberPriceListPage> createState() => _BarberPriceListPageState();
}

class _BarberPriceListPageState extends State<_BarberPriceListPage> {
  final Map<String, int> _prices = {
    'Saç Kesim': 350,
    'Sakal Tıraşı': 200,
    'Saç + Sakal': 500,
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Fiyat Listesi',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        for (final entry in _prices.entries)
          Card(
            child: ListTile(
              title: Text(entry.key),
              trailing: Text('${entry.value} ₺'),
              onTap: () async {
                final ctrl = TextEditingController(text: entry.value.toString());
                final result = await showDialog<int?>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('${entry.key} ücreti'),
                    content: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          ctrl.dispose();
                          Navigator.of(ctx).pop(null);
                        },
                        child: const Text('İptal'),
                      ),
                      FilledButton(
                        onPressed: () {
                          final n = int.tryParse(ctrl.text.trim());
                          ctrl.dispose();
                          Navigator.of(ctx).pop(n);
                        },
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                );
                if (result != null) {
                  setState(() => _prices[entry.key] = result);
                }
              },
            ),
          ),
      ],
    );
  }
}

class _BarberDaysOffPage extends StatefulWidget {
  const _BarberDaysOffPage();

  @override
  State<_BarberDaysOffPage> createState() => _BarberDaysOffPageState();
}

class _BarberDaysOffPageState extends State<_BarberDaysOffPage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: WorkingDaysStore.instance.daysOff,
      builder: (context, daysOff, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'İzin Günleri',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            for (var weekday = 1; weekday <= 7; weekday++)
              SwitchListTile(
                value: daysOff.contains(weekday),
                title: Text(WorkingDaysStore.weekdayNames[weekday] ?? ''),
                onChanged: (v) =>
                    WorkingDaysStore.instance.setDayOff(weekday, v),
              ),
          ],
        );
      },
    );
  }
}

class _BarberSettingsPage extends StatelessWidget {
  const _BarberSettingsPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Genel Ayarlar',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Profil / İletişim'),
            subtitle: Text('Demo sayfa'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Bildirim Ayarları'),
            subtitle: Text('Demo sayfa'),
          ),
        ),
      ],
    );
  }
}

