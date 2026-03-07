import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/models/appointment.dart';
import '../../data/models/barber.dart';
import '../../data/stores/appointment_store.dart';
import '../../data/stores/barber_store.dart';
import '../../data/stores/working_days_store.dart';

enum _CustomerMenu {
  home('Berber Bul', Icons.search),
  appointments('Randevularım', Icons.event_available_outlined),
  reviews('Değerlendirmeler', Icons.rate_review_outlined),
  settings('Ayarlar', Icons.settings_outlined);

  const _CustomerMenu(this.label, this.icon);
  final String label;
  final IconData icon;
}

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  _CustomerMenu _selected = _CustomerMenu.home;

  void _select(_CustomerMenu menu) {
    setState(() => _selected = menu);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_selected) {
      _CustomerMenu.home => const _CustomerFindBarberPage(),
      _CustomerMenu.appointments => const _CustomerAppointmentsPage(),
      _CustomerMenu.reviews => const _CustomerReviewsPage(),
      _CustomerMenu.settings => const _CustomerSettingsPage(),
    };

    return Scaffold(
      appBar: AppBar(title: Text(_selected.label)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const _DrawerHeader(title: 'Müşteri'),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final item in _CustomerMenu.values)
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
      color: scheme.secondaryContainer,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.secondary,
            foregroundColor: scheme.onSecondary,
            child: const Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSecondaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerFindBarberPage extends StatefulWidget {
  const _CustomerFindBarberPage();

  @override
  State<_CustomerFindBarberPage> createState() => _CustomerFindBarberPageState();
}

class _CustomerFindBarberPageState extends State<_CustomerFindBarberPage> {
  String? _city;
  String? _district;
  bool _sortByRating = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Barber>>(
      valueListenable: BarberStore.instance.barbers,
      builder: (context, barbers, _) {
        final cities = barbers.map((b) => b.city).toSet().toList()..sort();
        final effectiveCity = _city != null && cities.contains(_city) ? _city : null;
        final districtCandidates = barbers
            .where((b) => effectiveCity == null || b.city == effectiveCity)
            .map((b) => b.district)
            .toSet()
            .toList()
          ..sort();
        final effectiveDistrict = _district != null &&
                districtCandidates.contains(_district)
            ? _district
            : null;

        final filtered = barbers.where((b) {
          if (effectiveCity != null && b.city != effectiveCity) return false;
          if (effectiveDistrict != null && b.district != effectiveDistrict) {
            return false;
          }
          return true;
        }).toList();

        if (_sortByRating) {
          filtered.sort((a, b) => b.rating.compareTo(a.rating));
        } else {
          filtered.sort((a, b) => a.minPrice.compareTo(b.minPrice));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Şehir ve ilçe seçerek filtrele',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: effectiveCity,
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tümü'),
                      ),
                      ...cities.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c,
                          child: Text(c),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _city = v;
                        _district = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: effectiveDistrict,
                    decoration: const InputDecoration(
                      labelText: 'İlçe',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tümü'),
                      ),
                      ...districtCandidates.map(
                        (d) => DropdownMenuItem<String?>(
                          value: d,
                          child: Text(d),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _district = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sonuç: ${filtered.length} berber',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.star_outline),
                          label: Text('Puan'),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.payments_outlined),
                          label: Text('Fiyat'),
                        ),
                      ],
                      selected: {_sortByRating},
                      onSelectionChanged: (s) =>
                          setState(() => _sortByRating = s.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...filtered.map((b) => _BarberCard(barber: b)),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: Text('Seçime uygun berber bulunamadı.')),
              ),
          ],
        );
      },
    );
  }
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({required this.barber});

  final Barber barber;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(
                alpha: 0.12,
          ),
          child: _buildAvatar(),
        ),
        title: Text(
          barber.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Text(
          '${barber.city} / ${barber.district}\n${barber.address}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16),
                const SizedBox(width: 4),
                Text(barber.rating.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${barber.minPrice}-${barber.maxPrice} ₺'),
          ],
        ),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            useSafeArea: true,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (ctx) => DraggableScrollableSheet(
              expand: false,
              maxChildSize: 0.85,
              minChildSize: 0.4,
              initialChildSize: 0.6,
              builder: (_, controller) => SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                child: _BookAppointmentSheet(barber: barber),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar() {
    if (barber.avatarPath == null) {
      return const Icon(Icons.storefront);
    }
    final file = File(barber.avatarPath!);
    if (!file.existsSync()) {
      return const Icon(Icons.storefront);
    }
    return ClipOval(
      child: Image.file(
        file,
        fit: BoxFit.cover,
        width: 40,
        height: 40,
      ),
    );
  }
}

class _BookAppointmentSheet extends StatefulWidget {
  const _BookAppointmentSheet({required this.barber});

  final Barber barber;

  @override
  State<_BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<_BookAppointmentSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedSlot;

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day.$month.$year';
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<TimeOfDay> _generateSlots(DateTime date) {
    final now = DateTime.now();
    final existing = AppointmentStore.instance.appointments.value.where(
      (a) =>
          a.barberId == widget.barber.id &&
          a.dateTime.year == date.year &&
          a.dateTime.month == date.month &&
          a.dateTime.day == date.day,
    );
    final taken = existing
        .map(
          (a) => TimeOfDay(hour: a.dateTime.hour, minute: a.dateTime.minute),
        )
        .toSet();

    final slots = <TimeOfDay>[];
    for (var hour = 9; hour <= 21; hour++) {
      for (var minute in <int>[0, 30]) {
        final slot = TimeOfDay(hour: hour, minute: minute);
        final slotDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          slot.hour,
          slot.minute,
        );
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day &&
            slotDateTime.isBefore(now)) {
          continue; // geçmiş saatleri gösterme
        }
        if (taken.contains(slot)) continue; // bu saat dolu
        slots.add(slot);
      }
    }
    return slots;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = now;
    final last = now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: first,
      lastDate: last,
      selectableDayPredicate: (d) => !WorkingDaysStore.instance.isDayOff(d),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
    }
  }

  void _submit() {
    if (_selectedDate == null || _selectedSlot == null) return;
    final date = _selectedDate!;
    final time = _selectedSlot!;
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    AppointmentStore.instance.addAppointment(
      Appointment(
        id: id,
        barberId: widget.barber.id,
        barberName: widget.barber.name,
        dateTime: dateTime,
      ),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Randevun oluşturuldu.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.barber.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text('${widget.barber.city} / ${widget.barber.district}'),
        const SizedBox(height: 4),
        Text(widget.barber.address),
        const SizedBox(height: 12),
        Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 18),
                const SizedBox(width: 4),
                Text(widget.barber.rating.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(width: 12),
            Text('${widget.barber.minPrice}-${widget.barber.maxPrice} ₺'),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: scheme.surface.withValues(alpha: 0.9),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Randevu Tarih ve Saat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _selectedDate == null
                              ? 'Gün Seç'
                              : _formatDate(_selectedDate!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selectedDate != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in _generateSlots(_selectedDate!))
                        ChoiceChip(
                          label: Text(_formatTime(slot)),
                          selected: _selectedSlot == slot,
                          onSelected: (_) =>
                              setState(() => _selectedSlot = slot),
                        ),
                      if (_generateSlots(_selectedDate!).isEmpty)
                        Text(
                          'Bu gün için uygun saat kalmadı.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.outline,
                                  ),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  'İzin günlerinde randevu alınamaz. Berber panelinden izin günlerini ayarlayabilirsin.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed:
              _selectedDate != null && _selectedSlot != null ? _submit : null,
          icon: const Icon(Icons.event_available_outlined),
          label: const Text('Randevuyu Onayla'),
        ),
      ],
    );
  }
}

class _CustomerAppointmentsPage extends StatelessWidget {
  const _CustomerAppointmentsPage();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: AppointmentStore.instance.appointments,
      builder: (context, list, _) {
        String formatDateTime(DateTime d) {
          final day = d.day.toString().padLeft(2, '0');
          final month = d.month.toString().padLeft(2, '0');
          final year = d.year.toString();
          final hour = d.hour.toString().padLeft(2, '0');
          final minute = d.minute.toString().padLeft(2, '0');
          return '$day.$month.$year • $hour:$minute';
        }

        if (list.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Henüz randevun yok.'),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final a = list[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.event_note_outlined),
                title: Text(a.barberName),
                subtitle: Text(formatDateTime(a.dateTime)),
                trailing: a.rating != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16),
                          const SizedBox(width: 2),
                          Text(a.rating!.toStringAsFixed(1)),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}

class _CustomerReviewsPage extends StatelessWidget {
  const _CustomerReviewsPage();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: AppointmentStore.instance.appointments,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Değerlendirebileceğin randevu yok.'),
            ),
          );
        }

        Future<void> openReviewDialog(Appointment a) async {
          double rating = a.rating ?? 5;
          final noteCtrl = TextEditingController(text: a.note ?? '');
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('${a.barberName} için değerlendirme'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        onPressed: () {
                          rating = starValue.toDouble();
                          (ctx as Element).markNeedsBuild();
                        },
                        icon: Icon(
                          rating >= starValue
                              ? Icons.star
                              : Icons.star_border_outlined,
                        ),
                        color: Colors.amber,
                      );
                    }),
                  ),
                  TextField(
                    controller: noteCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Yorum (isteğe bağlı)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    noteCtrl.dispose();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    AppointmentStore.instance.updateRating(
                      id: a.id,
                      rating: rating,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );
                    noteCtrl.dispose();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final a = list[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.rate_review_outlined),
                title: Text(a.barberName),
                subtitle: Text(
                  a.rating == null
                      ? 'Henüz değerlendirilmedi'
                      : 'Puan: ${a.rating!.toStringAsFixed(1)}'
                          '${a.note != null && a.note!.isNotEmpty ? ' • "${a.note!}"' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openReviewDialog(a),
              ),
            );
          },
        );
      },
    );
  }
}

class _CustomerSettingsPage extends StatelessWidget {
  const _CustomerSettingsPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profil'),
            subtitle: Text('Demo sayfa'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Bildirimler'),
            subtitle: Text('Demo sayfa'),
          ),
        ),
      ],
    );
  }
}

