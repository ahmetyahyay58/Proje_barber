import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes.dart';
import '../../data/models/appointment.dart';
import '../../data/models/barber.dart';
import '../../data/storage/media_storage.dart';
import '../../data/stores/appointment_store.dart';
import '../../data/stores/barber_store.dart';
import '../../data/stores/customer_profile_store.dart';
import '../../data/stores/working_days_store.dart';
import '../../widgets/berber_pro_logo.dart';
import '../../widgets/hover_lift.dart';

enum _CustomerMenu {
  home('Berber Pro', Icons.search),
  appointments('Randevularım', Icons.event_available_outlined),
  reviews('Değerlendirmeler', Icons.rate_review_outlined),
  settings('Ayarlar', Icons.settings_outlined);

  const _CustomerMenu(this.label, this.icon);
  final String label;
  final IconData icon;
}

ImageProvider? _imageProviderFromSource(String? source) {
  if (source == null || source.isEmpty) return null;
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return NetworkImage(source);
  }
  if (source.startsWith('data:image')) {
    final comma = source.indexOf(',');
    if (comma < 0) return null;
    return MemoryImage(base64Decode(source.substring(comma + 1)));
  }
  if (kIsWeb) return null;
  final file = File(source);
  if (!file.existsSync()) return null;
  return FileImage(file);
}

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  _CustomerMenu _selected = _CustomerMenu.home;

  @override
  void initState() {
    super.initState();
    CustomerProfileStore.instance.refreshProfile();
    BarberStore.instance.refreshBarbers();
  }

  void _select(_CustomerMenu menu) {
    setState(() => _selected = menu);
    if (menu == _CustomerMenu.home) {
      BarberStore.instance.refreshBarbers();
    }
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
                      HoverLift(
                        child: ListTile(
                          leading: Icon(item.icon),
                          title: Text(item.label),
                          selected: item == _selected,
                          onTap: () => _select(item),
                        ),
                      ),
                    const Divider(),
                    HoverLift(
                      child: ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Çıkış Yap'),
                        onTap: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.roleSelect,
                            (_) => false,
                          );
                        },
                      ),
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
    return ValueListenableBuilder<CustomerProfileData?>(
      valueListenable: CustomerProfileStore.instance.profile,
      builder: (context, profile, _) {
        final image = _imageProviderFromSource(profile?.avatarUrl);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: scheme.secondaryContainer,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.secondary,
                foregroundColor: scheme.onSecondary,
                backgroundImage: image,
                child: image == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (profile?.fullName ?? '').trim().isEmpty
                      ? title
                      : profile!.fullName!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSecondaryContainer,
                      ),
                ),
              ),
            ],
          ),
        );
      },
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
  String _query = '';

  _ServiceFilter _serviceFilter = _ServiceFilter.all;

  @override
  void initState() {
    super.initState();
    BarberStore.instance.refreshBarbers();
  }

  bool _matchesService(Barber b) {
    if (_serviceFilter == _ServiceFilter.all) return true;
    if (b.services.isEmpty) return true;
    final text = b.services.map((s) => s.name.toLowerCase()).join(' ');
    switch (_serviceFilter) {
      case _ServiceFilter.all:
        return true;
      case _ServiceFilter.hair:
        return text.contains('saç');
      case _ServiceFilter.beard:
        return text.contains('sakal');
      case _ServiceFilter.skin:
        return text.contains('cilt');
      case _ServiceFilter.color:
        return text.contains('boya') || text.contains('renk');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Barber>>(
      valueListenable: BarberStore.instance.barbers,
      builder: (context, barbers, _) {
        return ValueListenableBuilder<List<Appointment>>(
          valueListenable: AppointmentStore.instance.appointments,
          builder: (context, appointments, __) {
        final ratingByBarberId = <String, double>{};
        for (final barber in barbers) {
          final rated = appointments
              .where((a) => a.barberId == barber.id && a.rating != null)
              .toList();
          if (rated.isEmpty) {
            ratingByBarberId[barber.id] = barber.rating;
            continue;
          }
          final average =
              rated.fold<double>(0, (sum, a) => sum + a.rating!) / rated.length;
          ratingByBarberId[barber.id] = average;
        }

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
          if (!_matchesService(b)) return false;

          final q = _query.trim().toLowerCase();
          if (q.isNotEmpty) {
            final inName = b.name.toLowerCase().contains(q);
            final inCity = b.city.toLowerCase().contains(q);
            final inDistrict = b.district.toLowerCase().contains(q);
            if (!inName && !inCity && !inDistrict) return false;
          }

          return true;
        }).toList();

        if (_sortByRating) {
          filtered.sort(
            (a, b) => (ratingByBarberId[b.id] ?? b.rating)
                .compareTo(ratingByBarberId[a.id] ?? a.rating),
          );
        } else {
          filtered.sort((a, b) => a.minPrice.compareTo(b.minPrice));
        }

        final scheme = Theme.of(context).colorScheme;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const Center(
              child: BerberProLogo(width: 110),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.content_cut, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  'BERBER ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'PRO',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.amber,
                      ),
                ),
                const Spacer(),
                ValueListenableBuilder<CustomerProfileData?>(
                  valueListenable: CustomerProfileStore.instance.profile,
                  builder: (context, profile, _) {
                    final image = _imageProviderFromSource(profile?.avatarUrl);
                    return CircleAvatar(
                      radius: 17,
                      backgroundColor: scheme.surfaceContainerHighest,
                      backgroundImage: image,
                      child: image == null
                          ? const Icon(Icons.person_outline, size: 18)
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.workspace_premium_outlined,
                          size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'VIP',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Berber veya bölge ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipPill(
                    label: 'Tümü',
                    selected: _serviceFilter == _ServiceFilter.all,
                    onTap: () =>
                        setState(() => _serviceFilter = _ServiceFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipPill(
                    label: 'Saç Kesimi',
                    selected: _serviceFilter == _ServiceFilter.hair,
                    onTap: () =>
                        setState(() => _serviceFilter = _ServiceFilter.hair),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipPill(
                    label: 'Sakal',
                    selected: _serviceFilter == _ServiceFilter.beard,
                    onTap: () =>
                        setState(() => _serviceFilter = _ServiceFilter.beard),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipPill(
                    label: 'Cilt Bakımı',
                    selected: _serviceFilter == _ServiceFilter.skin,
                    onTap: () =>
                        setState(() => _serviceFilter = _ServiceFilter.skin),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipPill(
                    label: 'Boya',
                    selected: _serviceFilter == _ServiceFilter.color,
                    onTap: () =>
                        setState(() => _serviceFilter = _ServiceFilter.color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${filtered.length} berber bulundu',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: SegmentedButton<bool>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      selectedBackgroundColor: Colors.amber.withValues(
                        alpha: 0.2,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.star_outline),
                        label: Text('Puan'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.swap_vert),
                        label: Text('Fiyat'),
                      ),
                    ],
                    selected: {_sortByRating},
                    onSelectionChanged: (s) =>
                        setState(() => _sortByRating = s.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...filtered.map(
              (b) => _BarberCard(
                barber: b,
                effectiveRating: ratingByBarberId[b.id] ?? b.rating,
              ),
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: Text('Seçime uygun berber bulunamadı.')),
              ),
          ],
        );
          },
        );
      },
    );
  }
}

enum _ServiceFilter { all, hair, beard, skin, color }

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.amber
              : scheme.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : scheme.onSurface,
              ),
        ),
      ),
    );
  }
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({
    required this.barber,
    required this.effectiveRating,
  });

  final Barber barber;
  final double effectiveRating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return HoverLift(
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
                child: _BookAppointmentSheet(
                  barber: barber,
                  effectiveRating: effectiveRating,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        scheme.primary.withValues(alpha: 0.12),
                    child: _buildAvatar(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barber.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '${barber.city} / ${barber.district}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '"${barber.address}"',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          effectiveRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (barber.services.isNotEmpty)
                        for (final s in barber.services.take(2))
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  scheme.surface.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              s.name.split(' ').take(2).join(' '),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${barber.minPrice}-${barber.maxPrice} ₺',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (barber.avatarPath == null) {
      return const Icon(Icons.storefront);
    }
    final source = barber.avatarPath!;
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          source,
          fit: BoxFit.cover,
          width: 40,
          height: 40,
          errorBuilder: (_, __, ___) => const Icon(Icons.storefront),
        ),
      );
    }
    if (source.startsWith('data:image')) {
      final comma = source.indexOf(',');
      if (comma < 0) return const Icon(Icons.storefront);
      final bytes = base64Decode(source.substring(comma + 1));
      return ClipOval(
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 40,
          height: 40,
        ),
      );
    }
    if (kIsWeb) {
      return const Icon(Icons.storefront);
    }
    final file = File(source);
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
  const _BookAppointmentSheet({
    required this.barber,
    required this.effectiveRating,
  });

  final Barber barber;
  final double effectiveRating;

  @override
  State<_BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<_BookAppointmentSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedSlot;
  String? _selectedMaster;
  bool _isSubmitting = false;

  final Set<String> _selectedServiceIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.barber.masters.isNotEmpty) {
      _selectedMaster = widget.barber.masters.first;
    }
  }

  int get _totalDurationMinutes {
    if (widget.barber.services.isEmpty || _selectedServiceIds.isEmpty) {
      return 0;
    }
    return widget.barber.services
        .where((s) => _selectedServiceIds.contains(s.id))
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  int get _totalPrice {
    if (widget.barber.services.isEmpty || _selectedServiceIds.isEmpty) return 0;
    final services = widget.barber.services
        .where((s) => _selectedServiceIds.contains(s.id))
        .toList();
    return services.fold<int>(0, (sum, s) => sum + s.price);
  }

  List<String> get _selectedServiceNames {
    if (widget.barber.services.isEmpty || _selectedServiceIds.isEmpty) {
      return const <String>[];
    }
    final services = widget.barber.services
        .where((s) => _selectedServiceIds.contains(s.id))
        .toList();
    return services.map((s) => s.name).toList();
  }

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

  String _maskName(String? name) {
    final value = (name ?? '').trim();
    if (value.isEmpty) return 'mi*** mü***';
    final parts = value.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final masked = parts.map((part) {
      final lower = part.toLowerCase();
      final visible = lower.length >= 2 ? lower.substring(0, 2) : lower;
      return '$visible***';
    }).toList();
    return masked.join(' ');
  }

  Color _ratingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.amber;
    return Colors.redAccent;
  }

  ImageProvider? _imageProviderFromSource(String source) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return NetworkImage(source);
    }
    if (source.startsWith('data:image')) {
      final comma = source.indexOf(',');
      if (comma < 0) return null;
      return MemoryImage(base64Decode(source.substring(comma + 1)));
    }
    if (kIsWeb) return null;
    final file = File(source);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  List<TimeOfDay> _generateSlots(DateTime date) {
    final now = DateTime.now();
    final durationMinutes = _totalDurationMinutes;
    final existing = AppointmentStore.instance.appointments.value.where(
      (a) =>
          a.barberId == widget.barber.id &&
          a.dateTime.year == date.year &&
          a.dateTime.month == date.month &&
          a.dateTime.day == date.day,
    );

    bool isSameMaster(Appointment a) {
      // Elemanli berberlerde cakisma kontrolu eleman bazinda calisir.
      if (widget.barber.masters.isNotEmpty) {
        final selected = (_selectedMaster ?? '').trim();
        final booked = (a.masterName ?? '').trim();
        return selected.isNotEmpty && booked.isNotEmpty && selected == booked;
      }
      // Eleman tanimsiz berberlerde tek koltuk varsayimiyla global cakisma.
      return true;
    }

    bool overlaps(DateTime start, DateTime end, Appointment a) {
      final aDuration = a.durationMinutes <= 0 ? 30 : a.durationMinutes;
      final aEnd = a.dateTime.add(Duration(minutes: aDuration));
      return start.isBefore(aEnd) && end.isAfter(a.dateTime);
    }

    final slots = <TimeOfDay>[];
    for (var hour = 9; hour <= 21; hour++) {
      for (var minute in <int>[0, 30]) {
        final slot = TimeOfDay(hour: hour, minute: minute);
        final start = DateTime(
          date.year,
          date.month,
          date.day,
          slot.hour,
          slot.minute,
        );
        final end = start.add(Duration(minutes: durationMinutes));

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day &&
            start.isBefore(now)) {
          continue; // geçmiş saatleri gösterme
        }

        var isFree = true;
        for (final a in existing) {
          if (!isSameMaster(a)) continue;
          if (overlaps(start, end, a)) {
            isFree = false;
            break;
          }
        }
        if (!isFree) continue;

        slots.add(slot);
      }
    }
    return slots;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = firstDate.add(const Duration(days: 30));
    bool isSelectable(DateTime d) =>
        !WorkingDaysStore.instance.isDayOff(d);

    DateTime initial =
        _selectedDate ?? firstDate;
    if (initial.isBefore(firstDate) ||
        initial.isAfter(lastDate) ||
        !isSelectable(initial)) {
      initial = firstDate;
      while (!isSelectable(initial) && initial.isBefore(lastDate)) {
        initial = initial.add(const Duration(days: 1));
      }
    }

    DateTime temp = initial;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return SizedBox(
          height: 380,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tarih Seç',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('İptal'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CalendarDatePicker(
                  initialDate: initial,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  selectableDayPredicate: isSelectable,
                  onDateChanged: (d) {
                    temp = d;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = temp;
                        _selectedSlot = null;
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Onayla'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, String?>> _loadCustomerInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const {'name': null, 'phone': null};
    }
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('full_name,phone')
        .eq('id', user.id)
        .maybeSingle();
    final name = profile?['full_name']?.toString();
    final phone = profile?['phone']?.toString();
    return <String, String?>{
      'name': (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (user.email ?? 'Müşteri'),
      'phone': phone,
    };
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _selectedSlot == null || _isSubmitting) return;
    if (widget.barber.services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu berber icin hizmet tanimli degil.'),
        ),
      );
      return;
    }
    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lutfen en az bir hizmet sec.'),
        ),
      );
      return;
    }
    if (widget.barber.masters.isNotEmpty &&
        (_selectedMaster == null || _selectedMaster!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lutfen bir eleman sec.'),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
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
      final duration = _totalDurationMinutes;
      final services = _selectedServiceNames;
      final customerInfo = await _loadCustomerInfo();
      await AppointmentStore.instance.addAppointment(
        Appointment(
          id: id,
          barberId: widget.barber.id,
          barberName: widget.barber.name,
          durationMinutes: duration,
          totalAmount: _totalPrice,
          customerId: Supabase.instance.client.auth.currentUser?.id,
          customerName: customerInfo['name'],
          customerPhone: customerInfo['phone'],
          serviceNames: services,
          masterName: _selectedMaster,
          dateTime: dateTime,
        ),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final scheme = Theme.of(ctx).colorScheme;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade500,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tebrikler!',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Randevunuz başarıyla oluşturuldu.\nRandevu saatinizden önce sizi bilgilendireceğiz.',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: scheme.outline,
                        ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Tamam'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu olusturulamadi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                Text(widget.effectiveRating.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(width: 12),
            Text('${widget.barber.minPrice}-${widget.barber.maxPrice} ₺'),
          ],
        ),
        if (widget.barber.galleryPaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.barber.galleryPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final path = widget.barber.galleryPaths[index];
                final provider = _imageProviderFromSource(path);
                if (provider == null) {
                  return const SizedBox.shrink();
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: provider,
                    width: 120,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (widget.barber.services.isNotEmpty)
          Card(
            color: scheme.surface.withValues(alpha: 0.9),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hizmet Seçimi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final service in widget.barber.services)
                        FilterChip(
                          selected: _selectedServiceIds.contains(service.id),
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service.name),
                              Text(
                                '${service.durationMinutes} dk • ${service.price} ₺',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: scheme.outline),
                              ),
                            ],
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServiceIds.add(service.id);
                              } else {
                                _selectedServiceIds.remove(service.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Toplam sure: $_totalDurationMinutes dk',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_totalPrice > 0)
                        Text(
                          'Toplam ucret: $_totalPrice ₺',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            color: scheme.surface.withValues(alpha: 0.9),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Bu berberin fiyat listesinde henuz hizmet yok. Randevu olusturulamaz.',
              ),
            ),
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
                if (widget.barber.masters.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMaster ?? widget.barber.masters.first,
                        decoration: const InputDecoration(
                          labelText: 'Usta Seç',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: [
                          for (final m in widget.barber.masters)
                            DropdownMenuItem<String>(
                              value: m,
                              child: Text(m),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          _selectedMaster = v;
                          _selectedSlot = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                    ],
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Bu berber icin eleman tanimi yok.'),
                  ),
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
              _selectedDate != null &&
                      _selectedSlot != null &&
                      !_isSubmitting &&
                      widget.barber.services.isNotEmpty &&
                      _selectedServiceIds.isNotEmpty
                  ? _submit
                  : null,
          icon: const Icon(Icons.event_available_outlined),
          label: Text(_isSubmitting ? 'Olusturuluyor...' : 'Randevuyu Onayla'),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<List<Appointment>>(
          valueListenable: AppointmentStore.instance.appointments,
          builder: (context, appointments, _) {
            final reviews = appointments
                .where((a) => a.barberId == widget.barber.id && a.rating != null)
                .toList()
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

            return Card(
              color: scheme.surface.withValues(alpha: 0.9),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Musteri Yorumlari',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (reviews.isEmpty)
                      Text(
                        'Henuz yorum bulunmuyor.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.outline,
                            ),
                      )
                    else
                      ...reviews.take(20).map((r) {
                        final starColor = _ratingColor(r.rating!);
                        final comment = (r.note ?? '').trim();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _maskName(r.customerName),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Icon(Icons.star, size: 16, color: starColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      r.rating!.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: starColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(comment),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CustomerAppointmentsPage extends StatelessWidget {
  const _CustomerAppointmentsPage();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Yaklaşan'),
              Tab(text: 'Geçmiş'),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder<List<Appointment>>(
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

                final now = DateTime.now();
                final upcoming = list
                    .where((a) => !a.dateTime.isBefore(now))
                    .toList()
                  ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
                final past = list
                    .where((a) => a.dateTime.isBefore(now))
                    .toList()
                  ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

                Widget buildList(
                  List<Appointment> items,
                  String emptyText, {
                  required bool isUpcoming,
                }) {
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(emptyText),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final a = items[i];
                      final title = a.masterName != null &&
                              a.masterName!.isNotEmpty
                          ? '${a.barberName} • ${a.masterName}'
                          : a.barberName;
                      final servicesText = a.serviceNames.isNotEmpty
                          ? a.serviceNames.join(', ')
                          : null;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_note_outlined),
                          title: Text(title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(formatDateTime(a.dateTime)),
                              if (servicesText != null)
                                Text(
                                  servicesText,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                ),
                            ],
                          ),
                          trailing: isUpcoming
                              ? Builder(
                                  builder: (context) {
                                    final canCancel =
                                        a.dateTime.difference(now) >=
                                            const Duration(hours: 4);
                                    return TextButton(
                                      onPressed: canCancel
                                          ? () async {
                                              await AppointmentStore.instance
                                                  .cancelAppointment(a.id);
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Randevu iptal edildi.',
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                      child: Text(
                                        canCancel
                                            ? 'Iptal Et'
                                            : '<4 saat kala iptal yok',
                                      ),
                                    );
                                  },
                                )
                              : (a.rating != null
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, size: 16),
                                        const SizedBox(width: 2),
                                        Text(a.rating!.toStringAsFixed(1)),
                                      ],
                                    )
                                  : const SizedBox.shrink()),
                        ),
                      );
                    },
                  );
                }

                return TabBarView(
                  children: [
                    buildList(
                      upcoming,
                      'Yaklaşan randevun yok.',
                      isUpcoming: true,
                    ),
                    buildList(
                      past,
                      'Geçmiş randevun yok.',
                      isUpcoming: false,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerReviewsPage extends StatelessWidget {
  const _CustomerReviewsPage();

  String _maskName(String? name) {
    final value = (name ?? '').trim();
    if (value.isEmpty) return 'mi*** mü***';
    final parts = value.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'mi*** mü***';
    final masked = parts.map((part) {
      final lower = part.toLowerCase();
      final visible = lower.length >= 2 ? lower.substring(0, 2) : lower;
      return '$visible***';
    }).toList();
    return masked.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: AppointmentStore.instance.appointments,
      builder: (context, list, _) {
        final now = DateTime.now();
        final reviewable = list
            .where((a) => a.dateTime.isBefore(now))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        if (reviewable.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Randevu saati gecmis degerlendirebilecegin randevu yok.'),
            ),
          );
        }

        Future<void> openReviewDialog(Appointment a) async {
          if (!a.dateTime.isBefore(DateTime.now())) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Randevu saatinden once degerlendirme yapilamaz.'),
              ),
            );
            return;
          }
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
                  onPressed: () async {
                    await AppointmentStore.instance.updateRating(
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
          itemCount: reviewable.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final a = reviewable[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.rate_review_outlined),
                title: Text(a.barberName),
                subtitle: Text(
                  a.rating == null
                      ? 'Henüz değerlendirilmedi'
                      : 'Yorum sahibi: ${_maskName(a.customerName)} • Puan: ${a.rating!.toStringAsFixed(1)}'
                          '${a.note != null && a.note!.isNotEmpty ? ' • "${a.note!}"' : ''}',
                ),
                trailing: a.rating == null
                    ? const Icon(Icons.chevron_right)
                    : Icon(
                        Icons.star,
                        color: a.rating! >= 4
                            ? Colors.green
                            : a.rating! >= 3
                                ? Colors.amber
                                : Colors.redAccent,
                      ),
                onTap: () => openReviewDialog(a),
              ),
            );
          },
        );
      },
    );
  }
}

class _CustomerSettingsPage extends StatefulWidget {
  const _CustomerSettingsPage();

  @override
  State<_CustomerSettingsPage> createState() => _CustomerSettingsPageState();
}

class _CustomerSettingsPageState extends State<_CustomerSettingsPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _syncControllers(CustomerProfileStore.instance.profile.value);
    CustomerProfileStore.instance.profile.addListener(_onProfileChanged);
    CustomerProfileStore.instance.refreshProfile();
  }

  @override
  void dispose() {
    CustomerProfileStore.instance.profile.removeListener(_onProfileChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    _syncControllers(CustomerProfileStore.instance.profile.value);
  }

  void _syncControllers(CustomerProfileData? profile) {
    final nextName = profile?.fullName ?? '';
    final nextPhone = profile?.phone ?? '';
    if (_nameCtrl.text != nextName) _nameCtrl.text = nextName;
    if (_phoneCtrl.text != nextPhone) _phoneCtrl.text = nextPhone;
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null) return;
    final selected = result.files.single;
    Uint8List? bytes = selected.bytes;
    if ((bytes == null || bytes.isEmpty) && !kIsWeb && selected.path != null) {
      bytes = await File(selected.path!).readAsBytes();
    }
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || bytes == null || bytes.isEmpty) return;
    final avatarSource = await MediaStorage.uploadImage(
      folder: 'customer/avatar',
      ownerId: uid,
      bytes: bytes,
      extension: selected.extension,
    );
    await CustomerProfileStore.instance.updateProfile(
      fullName: _nameCtrl.text,
      phone: _phoneCtrl.text,
      avatarUrl: avatarSource,
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await CustomerProfileStore.instance.updateProfile(
        fullName: _nameCtrl.text,
        phone: _phoneCtrl.text,
        avatarUrl: CustomerProfileStore.instance.profile.value?.avatarUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil kaydedildi.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CustomerProfileData?>(
      valueListenable: CustomerProfileStore.instance.profile,
      builder: (context, profile, _) {
        final image = _imageProviderFromSource(profile?.avatarUrl);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                'Profil',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickAvatar,
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: image,
                              child: image == null
                                  ? const Icon(Icons.add_a_photo_outlined)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Profil fotografini degistirmek icin fotoya dokun.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

