import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../data/auth/session_service.dart';
import '../../data/models/appointment.dart';
import '../../data/models/barber.dart';
import '../../data/storage/media_storage.dart';
import '../../data/stores/appointment_store.dart';
import '../../data/stores/barber_store.dart';
import '../../data/stores/customer_profile_store.dart';
import '../../data/models/barber_review.dart';
import '../../data/stores/working_days_store.dart';
import '../../app/app_theme.dart';
import '../../utils/map_directions.dart';
import '../../widgets/hover_lift.dart';
import '../../widgets/appointment_mini_widget.dart';
import '../../widgets/smart_reminder_widget.dart';
import '../../widgets/modern_settings_ui.dart';
import '../../widgets/modern_ui.dart' show PremiumAvatar, SelectionCapsule;
import '../../widgets/weather_widget.dart';

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

String _greetingForHour(int hour) {
  if (hour < 12) return 'Günaydın';
  if (hour < 18) return 'İyi günler';
  return 'İyi akşamlar';
}

Color _avatarColorForName(String name) {
  const palette = [
    AppTheme.accent,
    AppTheme.bronze,
    AppTheme.info,
    AppTheme.success,
    AppTheme.latte,
  ];
  final key = name.trim().isEmpty ? '?' : name.trim();
  return palette[key.hashCode.abs() % palette.length].withValues(alpha: 0.32);
}

String _initialFromName(String? name) {
  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

Widget _buildCustomerAvatar({
  required String? name,
  required ImageProvider? image,
  double radius = 24,
}) {
  final initial = _initialFromName(name);
  return CircleAvatar(
    radius: radius,
    backgroundColor: image == null ? _avatarColorForName(name ?? '') : null,
    backgroundImage: image,
    child: image == null
        ? Text(
            initial,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: radius * 0.72,
              color: AppTheme.textPrimary,
            ),
          )
        : null,
  );
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
  }

  Future<void> _logout() async {
    await SessionService.clearRole();
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.roleSelect,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_selected) {
      _CustomerMenu.home => const _CustomerFindBarberPage(),
      _CustomerMenu.appointments => const _CustomerAppointmentsPage(),
      _CustomerMenu.reviews => const _CustomerReviewsPage(),
      _CustomerMenu.settings => _CustomerSettingsPage(onLogout: _logout),
    };

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.surfaceBase,
      appBar: _selected != _CustomerMenu.home
          ? AppBar(
              title: Text(_selected.label),
              automaticallyImplyLeading: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppTheme.accent.withValues(alpha: 0.1),
                ),
              ),
            )
          : null,
      body: ClipRect(
        child: ColoredBox(
          color: AppTheme.surfaceBase,
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: page,
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selected: _selected,
        onSelect: _select,
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
  bool _nearby = false;
  Position? _userPosition;
  String _query = '';
  String? _selectedBarberId;

  @override
  void initState() {
    super.initState();
    BarberStore.instance.refreshBarbers();
  }

  Future<void> _toggleNearby() async {
    final next = !_nearby;
    if (!next) {
      setState(() {
        _nearby = false;
        _userPosition = null;
      });
      return;
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum servisi kapalı.')),
      );
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum izni verilmedi.')),
      );
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _nearby = true;
        _userPosition = pos;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konum alınamadı: $e')),
      );
    }
  }

  double? _distanceKm(Barber b) {
    final p = _userPosition;
    if (p == null || b.lat == null || b.lng == null) return null;
    final meters = Geolocator.distanceBetween(
      p.latitude,
      p.longitude,
      b.lat!,
      b.lng!,
    );
    return meters / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Barber>>(
      valueListenable: BarberStore.instance.barbers,
      builder: (context, barbers, _) {
        final ratingByBarberId = <String, double>{
          for (final barber in barbers) barber.id: barber.rating,
        };

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
          final q = _query.trim().toLowerCase();
          if (q.isNotEmpty) {
            final inName = b.name.toLowerCase().contains(q);
            final inCity = b.city.toLowerCase().contains(q);
            final inDistrict = b.district.toLowerCase().contains(q);
            if (!inName && !inCity && !inDistrict) return false;
          }

          return true;
        }).toList();

        final distanceById = <String, double?>{};
        if (_nearby && _userPosition != null) {
          for (final b in filtered) {
            distanceById[b.id] = _distanceKm(b);
          }
          filtered.sort((a, b) {
            final da = distanceById[a.id];
            final db = distanceById[b.id];
            if (da == null && db == null) {
              // 3B: konumu olmayanlar listede kalsın, ama en altta.
              return 0;
            }
            if (da == null) return 1;
            if (db == null) return -1;
            final byDistance = da.compareTo(db);
            if (byDistance != 0) return byDistance;
            // tie-breaker: puan
            return (ratingByBarberId[b.id] ?? b.rating)
                .compareTo(ratingByBarberId[a.id] ?? a.rating);
          });
        } else {
          if (_sortByRating) {
            filtered.sort(
              (a, b) => (ratingByBarberId[b.id] ?? b.rating)
                  .compareTo(ratingByBarberId[a.id] ?? a.rating),
            );
          } else {
            filtered.sort((a, b) {
              final aMin = a.services.isNotEmpty ? a.services.map((s) => s.price).reduce((x, y) => x < y ? x : y) : a.minPrice;
              final bMin = b.services.isNotEmpty ? b.services.map((s) => s.price).reduce((x, y) => x < y ? x : y) : b.minPrice;
              return aMin.compareTo(bMin);
            });
          }
        }

        final scheme = Theme.of(context).colorScheme;

        return ListView(
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            ValueListenableBuilder<CustomerProfileData?>(
              valueListenable: CustomerProfileStore.instance.profile,
              builder: (context, profile, _) {
                final image = _imageProviderFromSource(profile?.avatarUrl);
                final displayName = (profile?.fullName ?? '').trim().isEmpty
                    ? 'Misafir'
                    : profile!.fullName!.trim();
                final timeGreeting = _greetingForHour(DateTime.now().hour);
                final phone = (profile?.phone ?? '').trim();
                const accent = AppTheme.accent;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                timeGreeting,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                              Text(
                                'Hoş geldin, $displayName 👋',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.12),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  scheme.surfaceContainerHighest,
                                  accent.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Dekoratif daireler — arka plan dokusu
                                Positioned(
                                  right: -20,
                                  top: -20,
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent.withValues(alpha: 0.08),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 40,
                                  bottom: -30,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent.withValues(alpha: 0.06),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: -10,
                                  bottom: -25,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent.withValues(alpha: 0.05),
                                    ),
                                  ),
                                ),
                                // Makas ikonu — berber teması
                                Positioned(
                                  left: 18,
                                  top: 14,
                                  child: Icon(
                                    Icons.content_cut_rounded,
                                    size: 22,
                                    color: accent.withValues(alpha: 0.35),
                                  ),
                                ),
                                // Akıllı hatırlatıcı — sağ üst
                                Positioned(
                                  right: 14,
                                  top: 12,
                                  child: SmartReminderWidget(
                                    onBookNow: () {},
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -44),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: scheme.surface,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.textPrimary
                                              .withValues(alpha: 0.12),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _buildCustomerAvatar(
                                      name: profile?.fullName,
                                      image: image,
                                      radius: 52,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      phone,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: scheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  if ((profile?.locationLabel ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_on_rounded,
                                          size: 13,
                                          color: AppTheme.accent.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          profile!.locationLabel!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceDeep,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppTheme.accent
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: const WeatherWidget(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceDeep,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppTheme.accent
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: AppointmentMiniWidget(
                                            onBookNow: null,
                                            onShowDetail: null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${filtered.length} berber bulundu',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleNearby,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _nearby
                          ? AppTheme.accent.withValues(alpha: 0.2)
                          : scheme.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _nearby ? Icons.near_me : Icons.near_me_outlined,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Yakınımda',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SortToggleChip(
                        label: 'Puan',
                        icon: Icons.star_outline,
                        selected: _sortByRating,
                        onTap: () => setState(() => _sortByRating = true),
                      ),
                      _SortToggleChip(
                        label: 'Fiyat',
                        icon: Icons.swap_vert,
                        selected: !_sortByRating,
                        onTap: () => setState(() => _sortByRating = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...filtered.map(
              (b) => _BarberCard(
                barber: b,
                effectiveRating: ratingByBarberId[b.id] ?? b.rating,
                distanceKm: distanceById[b.id],
                isSelected: _selectedBarberId == b.id,
                onSelect: () => setState(() => _selectedBarberId = b.id),
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
  }
}

class _SortToggleChip extends StatelessWidget {
  const _SortToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: AppTheme.textPrimary),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({
    required this.barber,
    required this.effectiveRating,
    required this.onSelect,
    this.distanceKm,
    this.isSelected = false,
  });

  final Barber barber;
  final double effectiveRating;
  final double? distanceKm;
  final bool isSelected;
  final VoidCallback onSelect;

  ImageProvider? _avatarImage() {
    final path = barber.avatarPath;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (path.startsWith('data:image')) {
      final comma = path.indexOf(',');
      if (comma < 0) return null;
      return MemoryImage(base64Decode(path.substring(comma + 1)));
    }
    if (kIsWeb) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  void _openDirections(BuildContext context) async {
    if (barber.lat == null || barber.lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu berber henuz konum kaydetmemis.')),
      );
      return;
    }
    final opened = await openDirectionsToBarber(barber);
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harita uygulamasi acilamadi.')),
      );
    }
  }

  void _openBooking(BuildContext context) {
    onSelect();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surfaceRaised,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        initialChildSize: 0.78,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            0,
            AppTheme.spacingMd,
            AppTheme.spacingLg,
          ),
          child: ValueListenableBuilder<List<Barber>>(
            valueListenable: BarberStore.instance.barbers,
            builder: (_, barbers, __) {
              final fresh = barbers.firstWhere(
                (b) => b.id == barber.id,
                orElse: () => barber,
              );
              return _BookAppointmentSheet(
                barber: fresh,
                effectiveRating: effectiveRating,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: HoverLift(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openBooking(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: AppTheme.glassCard(selected: isSelected),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PremiumAvatar(
                        name: barber.name,
                        image: _avatarImage(),
                        radius: 30,
                        selected: isSelected,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              barber.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${barber.city} / ${barber.district}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (barber.lat != null && barber.lng != null)
                                  IconButton(
                                    onPressed: () => _openDirections(context),
                                    icon: const Icon(
                                      Icons.directions_rounded,
                                      size: 18,
                                    ),
                                    tooltip: 'Yol tarifi',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                  ),
                              ],
                            ),
                            if (distanceKm != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${distanceKm!.toStringAsFixed(1)} km uzaklıkta',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.info,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: AppTheme.accent,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  effectiveRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: barber.isOpenToday
                                  ? AppTheme.success.withValues(alpha: 0.15)
                                  : AppTheme.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: barber.isOpenToday
                                        ? AppTheme.success
                                        : AppTheme.error,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  barber.isOpenToday ? 'Açık' : 'Kapalı',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: barber.isOpenToday
                                        ? AppTheme.success
                                        : AppTheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (barber.services.isNotEmpty)
                                for (final s in barber.services.take(3))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceOverlay
                                            .withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: AppTheme.accent
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Text(
                                        s.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        barber.services.isNotEmpty
                            ? '₺${barber.services.map((s) => s.price).reduce((a, b) => a < b ? a : b)} – ₺${barber.services.map((s) => s.price).reduce((a, b) => a > b ? a : b)}'
                            : '₺${barber.minPrice} – ₺${barber.maxPrice}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.cream,
                            ),
                      ),
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 16,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Randevu almak için dokun',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppTheme.accent,
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
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
  List<BarberReview> _reviews = const <BarberReview>[];
  bool _reviewsLoading = true;

  final Set<String> _selectedServiceIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.barber.masters.isNotEmpty) {
      _selectedMaster = widget.barber.masters.first;
    }
    BarberStore.instance.refreshBarbers();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews =
        await AppointmentStore.instance.fetchBarberReviews(widget.barber.id);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _reviewsLoading = false;
    });
  }

  Future<void> _openDirections() async {
    if (widget.barber.lat == null || widget.barber.lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu berber henuz konum kaydetmemis.')),
      );
      return;
    }
    final opened = await openDirectionsToBarber(widget.barber);
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harita uygulamasi acilamadi.')),
      );
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
    if (rating >= 4) return AppTheme.success;
    if (rating >= 3) return AppTheme.accent;
    return AppTheme.error;
  }

  List<DateTime> _selectableDays({int maxCount = 14}) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final last = first.add(const Duration(days: 30));
    final days = <DateTime>[];
    var cursor = first;
    while (cursor.isBefore(last) && days.length < maxCount) {
      if (!WorkingDaysStore.instance.isDayOff(cursor)) {
        days.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  String _dayShortLabel(DateTime d) {
    return AppTheme.weekdayShort[d.weekday - 1];
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  ImageProvider? _barberAvatar() {
    final path = widget.barber.avatarPath;
    if (path == null || path.isEmpty) return null;
    return _imageProviderFromSource(path);
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
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppTheme.success,
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
      if (e is AppointmentSlotTakenException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu saat dilimi az önce doldu. Lütfen başka bir saat seç.'),
          ),
        );
        return;
      }
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
    final selectableDays = _selectableDays();
    final slots = _selectedDate == null
        ? const <TimeOfDay>[]
        : _generateSlots(_selectedDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: AppTheme.glassCard(),
          child: Row(
            children: [
              PremiumAvatar(
                name: widget.barber.name,
                image: _barberAvatar(),
                radius: 34,
                selected: true,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.barber.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.barber.city} / ${widget.barber.district}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.effectiveRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.barber.services.isNotEmpty
                              ? '₺${widget.barber.services.map((s) => s.price).reduce((a, b) => a < b ? a : b)} – ₺${widget.barber.services.map((s) => s.price).reduce((a, b) => a > b ? a : b)}'
                              : '₺${widget.barber.minPrice} – ₺${widget.barber.maxPrice}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.cream,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.barber.address.trim().isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            widget.barber.address,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (widget.barber.lat != null && widget.barber.lng != null) ...[
          const SizedBox(height: AppTheme.spacingSm),
          OutlinedButton.icon(
            onPressed: _openDirections,
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: const Text('Yol Tarifi Al'),
          ),
        ],
        if ((widget.barber.instagramUrl?.isNotEmpty ?? false) ||
            (widget.barber.tiktokUrl?.isNotEmpty ?? false)) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              if (widget.barber.instagramUrl?.isNotEmpty ?? false)
                _SocialButton(
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  faIcon: FontAwesomeIcons.instagram,
                  onTap: () => launchUrl(
                    Uri.parse(widget.barber.instagramUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              if ((widget.barber.instagramUrl?.isNotEmpty ?? false) &&
                  (widget.barber.tiktokUrl?.isNotEmpty ?? false))
                const SizedBox(width: 8),
              if (widget.barber.tiktokUrl?.isNotEmpty ?? false)
                _SocialButton(
                  label: 'TikTok',
                  color: const Color(0xFF010101),
                  faIcon: FontAwesomeIcons.tiktok,
                  onTap: () => launchUrl(
                    Uri.parse(widget.barber.tiktokUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppTheme.spacingMd),
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
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: AppTheme.glassCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gün Seçimi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              SizedBox(
                height: 76,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final day in selectableDays)
                      SelectionCapsule(
                        label: _dayShortLabel(day),
                        sublabel: '${day.day}.${day.month}',
                        selected: _isSameDay(_selectedDate, day),
                        onTap: () => setState(() {
                          _selectedDate = day;
                          _selectedSlot = null;
                        }),
                      ),
                    SelectionCapsule(
                      label: 'Takvim',
                      sublabel: 'Daha fazla',
                      selected: false,
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
              if (widget.barber.masters.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Usta Seçimi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final m in widget.barber.masters)
                        SelectionCapsule(
                          label: m,
                          selected: _selectedMaster == m,
                          onTap: () => setState(() {
                            _selectedMaster = m;
                            _selectedSlot = null;
                          }),
                        ),
                    ],
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                  child: Text(
                    'Bu berber için eleman tanımı yok.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (_selectedDate != null) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Saat Seçimi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                if (slots.isEmpty)
                  Text(
                    'Bu gün için uygun saat kalmadı.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final slot in slots)
                          SelectionCapsule(
                            label: _formatTime(slot),
                            selected: _selectedSlot == slot,
                            onTap: () => setState(() => _selectedSlot = slot),
                          ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'İzin günlerinde randevu alınamaz.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
        Card(
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
                if (_reviewsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_reviews.isEmpty)
                  Text(
                    'Henuz yorum bulunmuyor.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                  )
                else
                  ..._reviews.map((r) {
                    final starColor = _ratingColor(r.rating);
                    final comment = (r.note ?? '').trim();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
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
                                  r.rating.toStringAsFixed(1),
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
                        color: AppTheme.accent,
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
                    if (!ctx.mounted) return;
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
                            ? AppTheme.success
                            : a.rating! >= 3
                                ? AppTheme.accent
                                : AppTheme.error,
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
  const _CustomerSettingsPage({required this.onLogout});

  final VoidCallback onLogout;

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
        final displayName = profile?.fullName?.trim().isNotEmpty == true
            ? profile!.fullName!.trim()
            : 'Profilim';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              SettingsProfileHeader(
                name: displayName,
                subtitle: profile?.phone?.trim().isNotEmpty == true
                    ? profile!.phone!.trim()
                    : 'Telefon ekle',
                avatar: image,
                onAvatarTap: _pickAvatar,
                hint: 'Fotoğrafa dokunarak değiştir',
              ),
              const SettingsSectionLabel('Kişisel Bilgiler'),
              SettingsFieldGroup(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      prefixIcon: Icon(Icons.phone_rounded),
                      hintText: '05XX XXX XX XX',
                    ),
                  ),
                ],
              ),
              const SettingsSectionLabel('Hesap'),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: Icons.badge_rounded,
                    title: 'Profil Durumu',
                    subtitle: profile?.fullName?.trim().isNotEmpty == true
                        ? 'Profil bilgileri dolu'
                        : 'Profilini tamamla',
                    iconColor: AppTheme.success,
                    showChevron: false,
                  ),
                  SettingsTile(
                    icon: Icons.photo_camera_rounded,
                    title: 'Profil Fotoğrafı',
                    subtitle: image != null ? 'Fotoğraf yüklendi' : 'Fotoğraf ekle',
                    iconColor: AppTheme.info,
                    onTap: _pickAvatar,
                  ),
                ],
              ),
              SettingsSaveBar(
                onPressed: _saveProfile,
                isLoading: _isSaving,
                label: _isSaving ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet',
              ),
              const SettingsSectionLabel('Oturum'),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: Icons.logout_rounded,
                    title: 'Çıkış Yap',
                    iconColor: AppTheme.error,
                    onTap: widget.onLogout,
                    showChevron: false,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── Premium Bottom Nav ─────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selected, required this.onSelect});

  final _CustomerMenu selected;
  final void Function(_CustomerMenu) onSelect;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(14, 0, 14, 12 + bottomPad),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _CustomerMenu.values.map((item) {
          final isSelected = item == selected;
          return Expanded(
            child: _NavItem(
              icon: item.icon,
              label: item.label,
              selected: isSelected,
              onTap: () => onSelect(item),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 22,
                color: selected ? AppTheme.accent : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppTheme.accent : AppTheme.textMuted,
                height: 1.0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.color,
    required this.faIcon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData faIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.40)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(faIcon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

