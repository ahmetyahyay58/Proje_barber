import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes.dart';
import '../../data/auth/session_service.dart';
import '../../data/storage/media_storage.dart';
import '../../data/models/barber.dart';
import '../../data/models/appointment.dart';
import '../../data/models/barber_expense.dart';
import '../../data/stores/appointment_store.dart';
import '../../data/stores/barber_expense_store.dart';
import '../../data/stores/barber_store.dart';
import '../../data/stores/working_days_store.dart';
import '../../app/app_theme.dart';
import '../../widgets/finance_pie_chart.dart';
import '../../widgets/modern_settings_ui.dart';
import '../../widgets/weather_widget.dart';
import 'location_picker_screen.dart';

enum _BarberMenu {
  appointments('Randevular', Icons.event_note_outlined),
  finance('Finans', Icons.bar_chart_outlined),
  home('Dükkanım', Icons.storefront_outlined),
  services('Hizmet Seçenekleri', Icons.tune_outlined),
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

  @override
  void initState() {
    super.initState();
    AppointmentStore.instance.refreshAppointments();
    BarberStore.instance.refreshBarbers();
    BarberExpenseStore.instance.refreshExpenses();
    BarberStore.instance.barbers.addListener(_syncDaysOff);
  }

  void _syncDaysOff() {
    final barber = BarberStore.instance.currentUserBarber;
    if (barber != null) {
      WorkingDaysStore.instance.loadFromBarber(barber.daysOff);
    }
  }

  @override
  void dispose() {
    BarberStore.instance.barbers.removeListener(_syncDaysOff);
    super.dispose();
  }

  void _select(_BarberMenu menu) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    if (_selected != menu) {
      setState(() => _selected = menu);
    }
    unawaited(_refreshForMenu(menu));
  }

  Future<void> _refreshForMenu(_BarberMenu menu) async {
    if (menu == _BarberMenu.finance) {
      await BarberStore.instance.refreshBarbers();
      await AppointmentStore.instance.refreshAppointments();
      await BarberExpenseStore.instance.refreshExpenses();
    } else if (menu == _BarberMenu.appointments) {
      await AppointmentStore.instance.refreshAppointments();
    } else if (menu == _BarberMenu.services) {
      await BarberStore.instance.refreshBarbers();
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
      _BarberMenu.home => _BarberHome(onNavigate: _select),
      _BarberMenu.finance => const _BarberFinancePage(),
      _BarberMenu.appointments => const _BarberAppointmentsPage(),
      _BarberMenu.services => const _BarberServicesPage(),
      _BarberMenu.settings => _BarberSettingsPage(onLogout: _logout),
    };

    final items = _BarberMenu.values;

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppTheme.surfaceBase,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_selected.label),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.accent.withValues(alpha: 0.1),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selected),
          child: page,
        ),
      ),
      bottomNavigationBar: _BarberBottomNav(
        items: items,
        selected: _selected,
        onSelect: _select,
      ),
      ),
    );
  }
}

class _BarberBottomNav extends StatelessWidget {
  const _BarberBottomNav({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<_BarberMenu> items;
  final _BarberMenu selected;
  final void Function(_BarberMenu) onSelect;

  @override
  Widget build(BuildContext context) {
    const accent = AppTheme.accent;

    return SafeArea(
      top: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
              border: Border(
                top: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: item == _BarberMenu.home
                        ? const SizedBox.shrink()
                        : _NavItem(
                            icon: item.icon,
                            label: item.label,
                            selected: selected == item,
                            accent: accent,
                            onTap: () => onSelect(item),
                          ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: item == _BarberMenu.home
                        ? _HomeNavItem(
                            selected: selected == item,
                            onTap: () => onSelect(item),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HomeNavItem extends StatelessWidget {
  const _HomeNavItem({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = AppTheme.accent;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? accent : AppTheme.surfaceRaised,
              border: Border.all(
                color: selected ? accent : AppTheme.borderLight,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: selected ? 0.35 : 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.storefront_rounded,
              size: 26,
              color: selected ? Colors.white : accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dükkanım',
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? accent
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}


ImageProvider? _imageProviderFromSource(String? source) {
  if (source == null || source.isEmpty) return null;
  if (source.startsWith('data:image')) {
    final comma = source.indexOf(',');
    if (comma < 0) return null;
    return MemoryImage(base64Decode(source.substring(comma + 1)));
  }
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return NetworkImage(source);
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

class _BarberHome extends StatelessWidget {
  const _BarberHome({required this.onNavigate});

  final void Function(_BarberMenu menu) onNavigate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const accent = AppTheme.accent;

    return ValueListenableBuilder<List<Barber>>(
      valueListenable: BarberStore.instance.barbers,
      builder: (context, _, __) {
        final barber = BarberStore.instance.currentUserBarber;
        return ValueListenableBuilder<List<Appointment>>(
          valueListenable: AppointmentStore.instance.appointments,
          builder: (context, appointments, ___) {
            final today = DateTime.now();
            final todayCount = barber == null
                ? 0
                : appointments.where((a) {
                    return a.barberId == barber.id &&
                        a.dateTime.year == today.year &&
                        a.dateTime.month == today.month &&
                        a.dateTime.day == today.day;
                  }).length;

            if (barber == null) {
              return const Center(child: Text('Dükkan kaydı bulunamadı.'));
            }

            final avatar = _imageProviderFromSource(barber.avatarPath);
            final ratedAppointments = appointments
                .where((a) => a.barberId == barber.id && a.rating != null)
                .toList();
            final effectiveRating = ratedAppointments.isEmpty
                ? barber.rating
                : ratedAppointments.fold<double>(
                        0, (sum, a) => sum + a.rating!) /
                    ratedAppointments.length;
            final priceRange = barber.minPrice > 0
                ? '₺${barber.minPrice} – ₺${barber.maxPrice}'
                : 'Fiyat belirlenmedi';
            final greeting = _greetingForHour(today.hour);

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingSm,
                AppTheme.spacingMd,
                AppTheme.spacingLg,
              ),
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                Text(
                  barber.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
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
                            Positioned(
                              right: 16,
                              top: 12,
                              child: Icon(
                                Icons.content_cut_rounded,
                                size: 72,
                                color: accent.withValues(alpha: 0.2),
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
                                      color: AppTheme.textPrimary.withValues(alpha: 0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 56,
                                  backgroundColor: scheme.primary,
                                  backgroundImage: avatar,
                                  child: avatar == null
                                      ? const Icon(
                                          Icons.storefront_rounded,
                                          size: 50,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${barber.city} / ${barber.district}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _ShopBadge(
                                    icon: Icons.star_rounded,
                                    label: effectiveRating.toStringAsFixed(1),
                                    color: accent,
                                  ),
                                  const SizedBox(width: 8),
                                  _ShopBadge(
                                    icon: Icons.payments_outlined,
                                    label: priceRange,
                                    color: scheme.primary,
                                  ),
                                ],
                              ),
                              if (barber.about != null &&
                                  barber.about!.trim().isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  barber.about!.trim(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.75),
                                        height: 1.5,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceDeep,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.accent.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const WeatherWidget(),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _ShopStatCard(
                        title: 'Bugün',
                        value: '$todayCount',
                        subtitle: 'randevu',
                        icon: Icons.event_available_rounded,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ShopStatCard(
                        title: 'Eleman',
                        value: '${barber.masters.length}',
                        subtitle: 'kişi',
                        icon: Icons.groups_rounded,
                        color: AppTheme.info,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ShopStatCard(
                        title: 'Hizmet',
                        value: '${barber.services.length}',
                        subtitle: 'adet',
                        icon: Icons.content_cut_rounded,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CurrentNextCustomerCard(
                  appointments: appointments,
                  barberId: barber.id,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hızlı Erişim',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _QuickActionTile(
                      label: 'Randevular',
                      icon: Icons.event_note_rounded,
                      color: accent,
                      onTap: () => onNavigate(_BarberMenu.appointments),
                    ),
                    _QuickActionTile(
                      label: 'Finans',
                      icon: Icons.pie_chart_rounded,
                      color: const Color(0xFF81C784),
                      onTap: () => onNavigate(_BarberMenu.finance),
                    ),
                    _QuickActionTile(
                      label: 'Hizmet Seçenekleri',
                      icon: Icons.tune_rounded,
                      color: const Color(0xFF64B5F6),
                      onTap: () => onNavigate(_BarberMenu.services),
                    ),
                    _QuickActionTile(
                      label: 'Ayarlar',
                      icon: Icons.settings_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                      onTap: () => onNavigate(_BarberMenu.settings),
                    ),
                  ],
                ),
                if (barber.address.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SettingsGroup(
                    children: [
                      SettingsTile(
                        icon: Icons.place_rounded,
                        title: 'Dükkan Adresi',
                        subtitle: barber.address,
                        iconColor: accent,
                        showChevron: false,
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _ShopBadge extends StatelessWidget {
  const _ShopBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _ShopStatCard extends StatelessWidget {
  const _ShopStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 96,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                '$title $subtitle',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentNextCustomerCard extends StatelessWidget {
  const _CurrentNextCustomerCard({
    required this.appointments,
    required this.barberId,
  });

  final List<Appointment> appointments;
  final String barberId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayAppts = appointments
        .where((a) {
          final d = a.dateTime;
          return a.barberId == barberId &&
              d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        })
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    Appointment? current;
    Appointment? next;

    for (final a in todayAppts) {
      final end = a.dateTime.add(Duration(minutes: a.durationMinutes));
      if (!a.dateTime.isAfter(now) && end.isAfter(now)) {
        current = a;
      } else if (a.dateTime.isAfter(now) && next == null) {
        next = a;
      }
    }

    final scheme = Theme.of(context).colorScheme;
    const accent = AppTheme.accent;

    Widget emptySlot({
      required String label,
      required Color labelColor,
      required IconData icon,
      required String emptyText,
    }) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: labelColor.withValues(alpha: 0.45), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: labelColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: labelColor.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  emptyText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.38),
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget customerTile({
      required String label,
      required Color labelColor,
      required IconData icon,
      required Appointment appt,
    }) {
      final name = (appt.customerName == null || appt.customerName!.trim().isEmpty)
          ? 'Misafir müşteri'
          : appt.customerName!;
      final phone = appt.customerPhone ?? '-';
      final hour = appt.dateTime.hour.toString().padLeft(2, '0');
      final min = appt.dateTime.minute.toString().padLeft(2, '0');
      final services = appt.serviceNames.isEmpty ? 'Hizmet bilgisi yok' : appt.serviceNames.join(', ');

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: labelColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: labelColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: labelColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$hour:$min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                Text(
                  services,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          current != null
              ? customerTile(
                  label: 'Şu anki müşteri',
                  labelColor: AppTheme.success,
                  icon: Icons.person_rounded,
                  appt: current,
                )
              : emptySlot(
                  label: 'Şu anki müşteri',
                  labelColor: AppTheme.success,
                  icon: Icons.person_rounded,
                  emptyText: 'Şu an randevunuz yok',
                ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: scheme.outline.withValues(alpha: 0.15),
            ),
          ),
          next != null
              ? customerTile(
                  label: 'Sıradaki müşteri',
                  labelColor: accent,
                  icon: Icons.person_outline_rounded,
                  appt: next,
                )
              : emptySlot(
                  label: 'Sıradaki müşteri',
                  labelColor: accent,
                  icon: Icons.person_outline_rounded,
                  emptyText: 'Yaklaşan randevunuz yok',
                ),
        ],
      ),
    );
  }
}

class _BarberFinancePage extends StatefulWidget {
  const _BarberFinancePage();

  @override
  State<_BarberFinancePage> createState() => _BarberFinancePageState();
}

class _BarberFinancePageState extends State<_BarberFinancePage> {
  String? _staffFilter;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  @override
  void initState() {
    super.initState();
    AppointmentStore.instance.refreshAppointments();
    BarberExpenseStore.instance.refreshExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: AppointmentStore.instance.appointments,
      builder: (context, appointments, _) {
        final barber = BarberStore.instance.currentUserBarber;
        if (barber == null) {
          return const Center(child: Text('Berber kaydi bulunamadi.'));
        }
        final own = appointments
            .where((a) => a.barberId == barber.id && a.dateTime.isAfter(monthAgo))
            .toList();
        final realized = own.where((a) => a.dateTime.isBefore(now)).toList();
        final servicePriceByName = <String, int>{
          for (final s in barber.services) s.name.trim().toLowerCase(): s.price,
        };
        int incomeOf(Appointment a) {
          if (a.totalAmount > 0) return a.totalAmount;
          if (a.serviceNames.isEmpty) return 0;
          return a.serviceNames.fold<int>(0, (sum, name) {
            final key = name.trim().toLowerCase();
            return sum + (servicePriceByName[key] ?? 0);
          });
        }
        final incomeByDay = <DateTime, int>{};
        for (final a in realized) {
          final day = _dateOnly(a.dateTime);
          incomeByDay[day] = (incomeByDay[day] ?? 0) + incomeOf(a);
        }
        final sortedDays = incomeByDay.keys.toList()..sort((a, b) => b.compareTo(a));
        final staffNames = <String>{
          ...barber.masters,
          ...realized
              .map((a) => (a.masterName ?? '').trim())
              .where((e) => e.isNotEmpty),
        }.toList()
          ..sort();
        final effectiveStaff = _staffFilter != null && staffNames.contains(_staffFilter)
            ? _staffFilter
            : null;
        final staffRows = realized
            .where((a) => effectiveStaff == null || (a.masterName ?? '').trim() == effectiveStaff)
            .toList();
        final staffIncomeByDay = <DateTime, int>{};
        for (final a in staffRows) {
          final day = _dateOnly(a.dateTime);
          staffIncomeByDay[day] = (staffIncomeByDay[day] ?? 0) + incomeOf(a);
        }
        final summaryIncomeMonth = realized.fold<int>(0, (s, a) => s + incomeOf(a));

        return ValueListenableBuilder<List<BarberExpense>>(
          valueListenable: BarberExpenseStore.instance.expenses,
          builder: (context, expenses, __) {
            final expenseMonth = expenses
                .where((e) => e.incurredOn.isAfter(monthAgo))
                .fold<int>(0, (s, e) => s + e.amount);

            final netMonth = summaryIncomeMonth - expenseMonth;
            final incomeGreen = AppTheme.success;
            final expenseRed = AppTheme.error;
            const accent = AppTheme.accent;

            final staffIncomeTotals = <String, int>{};
            for (final a in realized) {
              final name = (a.masterName ?? '').trim();
              if (name.isEmpty) continue;
              staffIncomeTotals[name] =
                  (staffIncomeTotals[name] ?? 0) + incomeOf(a);
            }
            final sortedStaffIncome = staffIncomeTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final staffChartColors = [
              accent,
              incomeGreen,
              AppTheme.info,
              AppTheme.bronze,
              AppTheme.latte,
              AppTheme.accentSoft,
            ];

            final expenseByTitle = <String, int>{};
            for (final e in expenses.where((e) => e.incurredOn.isAfter(monthAgo))) {
              expenseByTitle[e.title] = (expenseByTitle[e.title] ?? 0) + e.amount;
            }

            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Expanded(
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) => [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Finans Özeti',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Son 30 günlük gelir ve gider analizi',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.65),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Card(
                              color: netMonth >= 0
                                  ? incomeGreen.withValues(alpha: 0.15)
                                  : expenseRed.withValues(alpha: 0.15),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Icon(
                                      netMonth >= 0
                                          ? Icons.trending_up_rounded
                                          : Icons.trending_down_rounded,
                                      color: netMonth >= 0
                                          ? incomeGreen
                                          : expenseRed,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Aylık Net Durum',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            '₺${netMonth.abs()}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  color: netMonth >= 0
                                                      ? incomeGreen
                                                      : expenseRed,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      netMonth >= 0 ? 'Kâr' : 'Zarar',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: netMonth >= 0
                                                ? incomeGreen
                                                : expenseRed,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _FinanceStatCard(
                                    label: 'Aylık Gelir',
                                    value: summaryIncomeMonth,
                                    icon: Icons.trending_up_rounded,
                                    color: incomeGreen.withValues(alpha: 0.18),
                                    valueColor: incomeGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _FinanceStatCard(
                                    label: 'Aylık Gider',
                                    value: expenseMonth,
                                    icon: Icons.trending_down_rounded,
                                    color: expenseRed.withValues(alpha: 0.18),
                                    valueColor: expenseRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            child: FinancePieChartCard(
                              title: 'Gelir / Gider Dağılımı (Aylık)',
                              slices: [
                                FinanceChartSlice(
                                  label: 'Gelir',
                                  value: summaryIncomeMonth.toDouble(),
                                  color: incomeGreen,
                                ),
                                FinanceChartSlice(
                                  label: 'Gider',
                                  value: expenseMonth.toDouble(),
                                  color: expenseRed,
                                ),
                              ],
                              emptyMessage: 'Bu ay gelir veya gider kaydı yok.',
                            ),
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _FinanceTabBarDelegate(
                            TabBar(
                              labelColor: accent,
                              unselectedLabelColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              indicatorColor: accent,
                              indicatorWeight: 3,
                              tabs: const [
                                Tab(text: 'Gelir Detayı'),
                                Tab(text: 'Eleman Geliri'),
                                Tab(text: 'Giderler'),
                              ],
                            ),
                          ),
                        ),
                      ],
                      body: TabBarView(
                        children: [
                          ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Text(
                                'Aylık gelir detayı',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              for (final day in sortedDays)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            incomeGreen.withValues(alpha: 0.2),
                                        child: Icon(
                                          Icons.payments_outlined,
                                          color: incomeGreen,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(_formatDate(day)),
                                      trailing: Text(
                                        '₺${incomeByDay[day] ?? 0}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: incomeGreen,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (sortedDays.isEmpty)
                                const Card(
                                  child: ListTile(
                                    title: Text('Son 1 ayda gelir kaydı yok.'),
                                  ),
                                ),
                            ],
                          ),
                          ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              DropdownButtonFormField<String?>(
                                initialValue: effectiveStaff,
                                decoration: const InputDecoration(
                                  labelText: 'Eleman seç',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Tüm elemanlar'),
                                  ),
                                  for (final m in staffNames)
                                    DropdownMenuItem<String?>(
                                      value: m,
                                      child: Text(m),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _staffFilter = v),
                              ),
                              const SizedBox(height: 16),
                              FinancePieChartCard(
                                title: 'Eleman Gelir Dağılımı',
                                slices: [
                                  for (var i = 0;
                                      i < sortedStaffIncome.length;
                                      i++)
                                    FinanceChartSlice(
                                      label: sortedStaffIncome[i].key,
                                      value: sortedStaffIncome[i].value
                                          .toDouble(),
                                      color: staffChartColors[
                                          i % staffChartColors.length],
                                    ),
                                ],
                                emptyMessage: 'Eleman gelir kaydı yok.',
                              ),
                              const SizedBox(height: 16),
                              for (final day
                                  in (staffIncomeByDay.keys.toList()
                                    ..sort((a, b) => b.compareTo(a))))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            accent.withValues(alpha: 0.2),
                                        child: Icon(
                                          Icons.person_outline,
                                          color: accent,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(_formatDate(day)),
                                      subtitle:
                                          Text(effectiveStaff ?? 'Tüm elemanlar'),
                                      trailing: Text(
                                        '₺${staffIncomeByDay[day] ?? 0}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (staffIncomeByDay.isEmpty)
                                const Card(
                                  child: ListTile(
                                    title: Text('Bu filtrede gelir kaydı yok.'),
                                  ),
                                ),
                            ],
                          ),
                          _ExpenseTab(
                            expenses: expenses,
                            expenseByTitle: expenseByTitle,
                            expenseChartColors: staffChartColors,
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
      },
    );
  }
}

class _FinanceStatCard extends StatelessWidget {
  const _FinanceStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.valueColor,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 18, color: valueColor),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₺$value',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: valueColor,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceTabBarDelegate extends SliverPersistentHeaderDelegate {
  _FinanceTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _FinanceTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

class _ExpenseTab extends StatefulWidget {
  const _ExpenseTab({
    required this.expenses,
    required this.expenseByTitle,
    required this.expenseChartColors,
  });

  final List<BarberExpense> expenses;
  final Map<String, int> expenseByTitle;
  final List<Color> expenseChartColors;

  @override
  State<_ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<_ExpenseTab> {
  Future<void> _openAddExpense() async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? imageUrl;
    bool isUploading = false;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Gider Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Gider adi'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fiyat'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detayli aciklama (istege bagli)',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      initialDate: selectedDate,
                    );
                    if (picked == null) return;
                    setModal(() => selectedDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          try {
                            setModal(() => isUploading = true);
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                      withData: kIsWeb,
                    );
                    if (result == null) return;
                    final f = result.files.single;
                    Uint8List? bytes = f.bytes;
                    if ((bytes == null || bytes.isEmpty) && !kIsWeb && f.path != null) {
                      bytes = await File(f.path!).readAsBytes();
                    }
                    if (bytes == null || bytes.isEmpty) return;
                    final ownerId =
                        BarberStore.instance.currentUserBarber?.ownerId ??
                            Supabase.instance.client.auth.currentUser?.id;
                    if (ownerId == null) return;
                    final url = await MediaStorage.uploadImage(
                      folder: 'barber/expense',
                      ownerId: ownerId,
                      bytes: bytes,
                      extension: f.extension,
                    );
                    setModal(() => imageUrl = url);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gorsel yuklenemedi: $e')),
                            );
                          } finally {
                            if (mounted) {
                              setModal(() => isUploading = false);
                            }
                          }
                        },
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    isUploading
                        ? 'Yukleniyor...'
                        : (imageUrl == null
                            ? 'Gorsel ekle (istege bagli)'
                            : 'Gorsel eklendi'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      final amountText = amountCtrl.text
                          .replaceAll('₺', '')
                          .replaceAll(',', '')
                          .trim();
                      final amount = int.tryParse(amountText) ?? -1;
                      if (title.isEmpty) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gider adi zorunlu.')),
                        );
                        return;
                      }
                      if (amount < 0) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gecerli bir fiyat gir.')),
                        );
                        return;
                      }
                      try {
                        setModal(() => isSaving = true);
                        await BarberExpenseStore.instance.addExpense(
                          title: title,
                          amount: amount,
                          incurredOn: selectedDate,
                          description: descCtrl.text,
                          imageUrl: imageUrl,
                        );
                        if (!context.mounted) return;
                        Navigator.of(ctx).pop();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gider kaydedilemedi: $e')),
                        );
                      } finally {
                        if (mounted) {
                          setModal(() => isSaving = false);
                        }
                      }
                    },
              child: Text(isSaving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseRed = AppTheme.error;
    final sortedTitles = widget.expenseByTitle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Gider Kayıtları',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            FilledButton.icon(
              onPressed: _openAddExpense,
              icon: const Icon(Icons.add),
              label: const Text('Gider Ekle'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FinancePieChartCard(
          title: 'Gider Kategorileri',
          slices: [
            for (var i = 0; i < sortedTitles.length; i++)
              FinanceChartSlice(
                label: sortedTitles[i].key,
                value: sortedTitles[i].value.toDouble(),
                color: widget.expenseChartColors[i % widget.expenseChartColors.length],
              ),
          ],
          emptyMessage: 'Henüz gider kaydı yok.',
        ),
        const SizedBox(height: 16),
        for (final e in widget.expenses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
              leading: CircleAvatar(
                backgroundColor: expenseRed.withValues(alpha: 0.2),
                child: Icon(
                  Icons.receipt_outlined,
                  color: expenseRed,
                  size: 20,
                ),
              ),
              title: Text(e.title),
              subtitle: Text(
                '${e.incurredOn.day.toString().padLeft(2, '0')}.${e.incurredOn.month.toString().padLeft(2, '0')}.${e.incurredOn.year}',
              ),
              trailing: Text(
                '₺${e.amount}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: expenseRed,
                    ),
              ),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(e.title),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tutar: ₺${e.amount}'),
                          Text(
                            'Tarih: ${e.incurredOn.day.toString().padLeft(2, '0')}.${e.incurredOn.month.toString().padLeft(2, '0')}.${e.incurredOn.year}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (e.description ?? '').trim().isEmpty
                                ? 'Aciklama girilmemis.'
                                : e.description!,
                          ),
                          if (e.imageUrl != null && e.imageUrl!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                e.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Kapat'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ),
          ),
        if (widget.expenses.isEmpty)
          const Card(
            child: ListTile(title: Text('Henüz gider kaydı yok.')),
          ),
      ],
    );
  }
}

class _BarberAppointmentsPage extends StatefulWidget {
  const _BarberAppointmentsPage();

  @override
  State<_BarberAppointmentsPage> createState() => _BarberAppointmentsPageState();
}

class _BarberAppointmentsPageState extends State<_BarberAppointmentsPage> {
  DateTime? _selectedFutureDay;
  DateTime? _selectedPastDay;
  String? _selectedMasterFilter;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateTime(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year • $hour:$minute';
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: AppointmentStore.instance.appointments,
      builder: (context, list, _) {
        final currentBarber = BarberStore.instance.currentUserBarber;
        final ownAppointments = currentBarber == null
            ? const <Appointment>[]
            : list.where((a) => a.barberId == currentBarber.id).toList();
        final masters = <String>{
          ...(currentBarber?.masters ?? const <String>[]),
          ...ownAppointments
              .map((a) => a.masterName?.trim() ?? '')
              .where((m) => m.isNotEmpty),
        }.toList()
          ..sort();
        final now = DateTime.now();
        final today = _dateOnly(now);
        final futureLimit = today.add(const Duration(days: 30));
        final pastLimit = today.subtract(const Duration(days: 90));

        final futureBase = ownAppointments
            .where((a) =>
                !a.dateTime.isBefore(today) && !a.dateTime.isAfter(futureLimit))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

        final pastBase = ownAppointments
            .where((a) =>
                a.dateTime.isBefore(today) && !a.dateTime.isBefore(pastLimit))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        final futureByDate = _selectedFutureDay == null
            ? futureBase
            : futureBase
                .where((a) => _isSameDay(a.dateTime, _selectedFutureDay!))
                .toList();
        final pastByDate = _selectedPastDay == null
            ? pastBase
            : pastBase.where((a) => _isSameDay(a.dateTime, _selectedPastDay!)).toList();
        final futureItems = _selectedMasterFilter == null
            ? futureByDate
            : futureByDate
                .where((a) => (a.masterName ?? '').trim() == _selectedMasterFilter)
                .toList();
        final pastItems = _selectedMasterFilter == null
            ? pastByDate
            : pastByDate
                .where((a) => (a.masterName ?? '').trim() == _selectedMasterFilter)
                .toList();

        Widget buildList(List<Appointment> items, String emptyText) {
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
              final customerName =
                  (a.customerName == null || a.customerName!.trim().isEmpty)
                      ? 'Misafir müşteri'
                      : a.customerName!;
              final serviceText = a.serviceNames.isEmpty
                  ? 'Hizmet bilgisi yok'
                  : a.serviceNames.join(', ');
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(customerName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatDateTime(a.dateTime)),
                      Text('Telefon: ${a.customerPhone ?? '-'}'),
                      Text(serviceText),
                      if (a.masterName != null && a.masterName!.trim().isNotEmpty)
                        Text('Usta: ${a.masterName!}'),
                    ],
                  ),
                ),
              );
            },
          );
        }

        Future<void> pickFutureDate() async {
          final selected = await showDatePicker(
            context: context,
            firstDate: today,
            lastDate: futureLimit,
            initialDate: _selectedFutureDay ?? today,
          );
          if (selected == null) return;
          setState(() => _selectedFutureDay = selected);
        }

        Future<void> pickPastDate() async {
          final initial = _selectedPastDay ?? today.subtract(const Duration(days: 1));
          final selected = await showDatePicker(
            context: context,
            firstDate: pastLimit,
            lastDate: today.subtract(const Duration(days: 1)),
            initialDate: initial.isBefore(pastLimit) ? pastLimit : initial,
          );
          if (selected == null) return;
          setState(() => _selectedPastDay = selected);
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Gelecek'),
                  Tab(text: 'Geçmiş'),
                ],
              ),
              if (masters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _selectedMasterFilter,
                          decoration: const InputDecoration(
                            labelText: 'Eleman filtresi',
                            prefixIcon: Icon(Icons.person_search_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tum elemanlar'),
                            ),
                            for (final m in masters)
                              DropdownMenuItem<String?>(
                                value: m,
                                child: Text(m),
                              ),
                          ],
                          onChanged: (v) => setState(() => _selectedMasterFilter = v),
                        ),
                      ),
                      if (_selectedMasterFilter != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() => _selectedMasterFilter = null),
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: pickFutureDate,
                                  icon: const Icon(Icons.calendar_month_outlined),
                                  label: Text(
                                    _selectedFutureDay == null
                                        ? 'Tüm Günler (1 ay)'
                                        : _formatDate(_selectedFutureDay!),
                                  ),
                                ),
                              ),
                              if (_selectedFutureDay != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => setState(() => _selectedFutureDay = null),
                                  icon: const Icon(Icons.clear),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: buildList(
                            futureItems,
                            'Onumuzdeki 1 ay icinde randevu yok.',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: pickPastDate,
                                  icon: const Icon(Icons.calendar_month_outlined),
                                  label: Text(
                                    _selectedPastDay == null
                                        ? 'Tüm Günler (son 3 ay)'
                                        : _formatDate(_selectedPastDay!),
                                  ),
                                ),
                              ),
                              if (_selectedPastDay != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => setState(() => _selectedPastDay = null),
                                  icon: const Icon(Icons.clear),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: buildList(
                            pastItems,
                            'Son 3 ay icinde gecmis randevu yok.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarberServicesPage extends StatelessWidget {
  const _BarberServicesPage();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: AppTheme.accent,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            indicatorColor: AppTheme.accent,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Elemanlar'),
              Tab(text: 'Fiyat Listesi'),
              Tab(text: 'İzin Günleri'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _BarberStaffPage(),
                _BarberPriceListPage(),
                _BarberDaysOffPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarberStaffPage extends StatefulWidget {
  const _BarberStaffPage();

  @override
  State<_BarberStaffPage> createState() => _BarberStaffPageState();
}

class _BarberStaffPageState extends State<_BarberStaffPage> {
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
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                final current = BarberStore.instance.currentUserBarber;
                if (current != null) {
                  final next = List<String>.from(current.masters);
                  if (!next.contains(name)) {
                    next.add(name);
                    await BarberStore.instance.updateMasters(next);
                  }
                }
              }
              ctrl.dispose();
              if (!mounted) return;
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
    return ValueListenableBuilder<List<Barber>>(
      valueListenable: BarberStore.instance.barbers,
      builder: (context, _, __) {
        final staff = BarberStore.instance.currentUserBarber?.masters ?? const <String>[];
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
                  itemCount: staff.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(staff[i]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final current = BarberStore.instance.currentUserBarber;
                          if (current == null) return;
                          final next = List<String>.from(current.masters)..removeAt(i);
                          await BarberStore.instance.updateMasters(next);
                        },
                      ),
                    ),
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

class _BarberPriceListPage extends StatefulWidget {
  const _BarberPriceListPage();

  @override
  State<_BarberPriceListPage> createState() => _BarberPriceListPageState();
}

class _BarberPriceListPageState extends State<_BarberPriceListPage> {
  Future<void> _openServiceDialog({BarberService? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final durationCtrl = TextEditingController(
      text: editing?.durationMinutes.toString() ?? '30',
    );
    final priceCtrl = TextEditingController(text: editing?.price.toString() ?? '0');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editing == null ? 'Hizmet Ekle' : 'Hizmeti Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Hizmet Adı'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Süre (dk)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final duration = int.tryParse(durationCtrl.text.trim()) ?? 0;
              final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
              if (name.isEmpty || duration <= 0 || price < 0) return;
              await BarberStore.instance.upsertService(
                id: editing?.id,
                name: name,
                durationMinutes: duration,
                price: price,
              );
              if (!mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Barber>>(
      valueListenable: BarberStore.instance.barbers,
      builder: (context, _, __) {
        final services = BarberStore.instance.currentUserBarber?.services ?? const <BarberService>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fiyat Listesi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openServiceDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Hizmet Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (services.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('Henuz hizmet eklenmedi'),
                  subtitle: Text('Musteri tarafinda secilebilmesi icin hizmet ekleyin.'),
                ),
              ),
            for (final service in services)
              Card(
                child: ListTile(
                  title: Text(service.name),
                  subtitle: Text('${service.durationMinutes} dk'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${service.price} ₺'),
                      IconButton(
                        onPressed: () => _openServiceDialog(editing: service),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => BarberStore.instance.deleteService(service.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
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
                onChanged: (v) {
                  WorkingDaysStore.instance.setDayOff(weekday, v);
                  unawaited(BarberStore.instance.updateDaysOff(
                    WorkingDaysStore.instance.daysOff.value,
                  ));
                },
              ),
          ],
        );
      },
    );
  }
}

class _BarberSettingsPage extends StatefulWidget {
  const _BarberSettingsPage({required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<_BarberSettingsPage> createState() => _BarberSettingsPageState();
}

class _BarberSettingsPageState extends State<_BarberSettingsPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _aboutCtrl;
  late TextEditingController _instagramCtrl;
  late TextEditingController _tiktokCtrl;
  Barber? _barber;

  @override
  void initState() {
    super.initState();
    _barber = BarberStore.instance.currentUserBarber;
    _nameCtrl = TextEditingController(text: _barber?.name ?? '');
    _aboutCtrl = TextEditingController(text: _barber?.about ?? '');
    _instagramCtrl = TextEditingController(text: _barber?.instagramUrl ?? '');
    _tiktokCtrl = TextEditingController(text: _barber?.tiktokUrl ?? '');
    BarberStore.instance.barbers.addListener(_syncCurrentBarber);
    BarberStore.instance.refreshBarbers();
  }

  @override
  void dispose() {
    BarberStore.instance.barbers.removeListener(_syncCurrentBarber);
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    _instagramCtrl.dispose();
    _tiktokCtrl.dispose();
    super.dispose();
  }

  void _syncCurrentBarber() {
    final current = BarberStore.instance.currentUserBarber;
    if (!mounted) return;
    setState(() {
      _barber = current;
      if (current != null) {
        _nameCtrl.text = current.name;
        _aboutCtrl.text = current.about ?? '';
        _instagramCtrl.text = current.instagramUrl ?? '';
        _tiktokCtrl.text = current.tiktokUrl ?? '';
      }
    });
  }

  Future<void> _saveProfile() async {
    final barbers = BarberStore.instance.barbers.value;
    if (barbers.isEmpty || _barber == null) return;
    final current = _barber!;
    await BarberStore.instance.updateCurrentBarberProfile(
      name: _nameCtrl.text.trim().isEmpty ? current.name : _nameCtrl.text.trim(),
      about: _aboutCtrl.text.trim().isEmpty ? '' : _aboutCtrl.text.trim(),
      instagramUrl: _instagramCtrl.text.trim(),
      tiktokUrl: _tiktokCtrl.text.trim(),
    );
    final refreshed = BarberStore.instance.currentUserBarber;
    if (refreshed != null) {
      setState(() {
        _barber = refreshed;
      });
    }
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil güncellendi.')),
    );
  }

  Future<void> _pickLocation() async {
    if (_barber == null) return;
    final barber = _barber!;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: barber.lat,
          initialLng: barber.lng,
        ),
      ),
    );
    if (!mounted) return;
    if (updated == true) {
      setState(() => _barber = BarberStore.instance.currentUserBarber);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum kaydedildi.')),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null) return;
    final file = result.files.single;
    Uint8List? bytes = file.bytes;
    if ((bytes == null || bytes.isEmpty) && !kIsWeb && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty || _barber == null) return;
    final source = await MediaStorage.uploadImage(
      folder: 'barber/avatar',
      ownerId: _barber!.ownerId,
      bytes: bytes,
      extension: file.extension,
    );
    await BarberStore.instance.updateCurrentBarberProfile(avatarUrl: source);
    final refreshed = BarberStore.instance.currentUserBarber;
    if (refreshed != null) {
      setState(() {
        _barber = refreshed;
      });
    }
  }

  Future<void> _pickGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result == null) return;
    final newPaths = <String>[];
    if (_barber == null) return;
    for (final f in result.files) {
      Uint8List? bytes = f.bytes;
      if ((bytes == null || bytes.isEmpty) && !kIsWeb && f.path != null) {
        bytes = await File(f.path!).readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) continue;
      final url = await MediaStorage.uploadImage(
        folder: 'barber/gallery',
        ownerId: _barber!.ownerId,
        bytes: bytes,
        extension: f.extension,
      );
      newPaths.add(url);
    }
    if (newPaths.isEmpty) return;
    final current = _barber!;
    const maxGalleryPhotos = 10;
    final availableSlots = maxGalleryPhotos - current.galleryPaths.length;
    if (availableSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 10 galeri fotosu ekleyebilirsin.')),
      );
      return;
    }
    final limitedNewPaths = newPaths.take(availableSlots).toList();
    final merged = [...current.galleryPaths, ...limitedNewPaths];
    await BarberStore.instance.updateCurrentBarberProfile(galleryUrls: merged);
    final refreshed = BarberStore.instance.currentUserBarber;
    if (refreshed != null) {
      setState(() {
        _barber = refreshed;
      });
    }
    if (newPaths.length > limitedNewPaths.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sadece ilk 10 foto kaydedildi.')),
      );
    }
  }

  void _removeGalleryItem(int index) {
    if (_barber == null) return;
    final current = _barber!;
    if (index < 0 || index >= current.galleryPaths.length) return;
    final newGallery = List<String>.from(current.galleryPaths)..removeAt(index);
    BarberStore.instance.updateCurrentBarberProfile(galleryUrls: newGallery).then((_) {
      final refreshed = BarberStore.instance.currentUserBarber;
      if (!mounted) return;
      if (refreshed != null) {
        setState(() {
          _barber = refreshed;
        });
      }
    });
  }

  ImageProvider? _toImageProvider(String? source) {
    if (source == null || source.isEmpty) return null;
    if (source.startsWith('data:image')) {
      final comma = source.indexOf(',');
      if (comma < 0) return null;
      return MemoryImage(base64Decode(source.substring(comma + 1)));
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return NetworkImage(source);
    }
    if (kIsWeb) return null;
    final file = File(source);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  @override
  Widget build(BuildContext context) {
    if (_barber == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Profil düzenlemek için en az bir berber oluşturmalısın.'),
        ),
      );
    }

    final barber = _barber!;

    final locationSubtitle = barber.lat != null && barber.lng != null
        ? 'Kaydedildi • ${barber.lat!.toStringAsFixed(4)}, ${barber.lng!.toStringAsFixed(4)}'
        : 'Haritadan konum seç';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          SettingsProfileHeader(
            name: barber.name,
            subtitle: '${barber.city} / ${barber.district}',
            avatar: _toImageProvider(barber.avatarPath),
            onAvatarTap: _pickAvatar,
            hint: 'Fotoğrafa dokunarak değiştir',
          ),
          const SettingsSectionLabel('Konum'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.location_on_rounded,
                title: 'Dükkan Konumu',
                subtitle: locationSubtitle,
                iconColor: AppTheme.info,
                onTap: _pickLocation,
              ),
            ],
          ),
          const SettingsSectionLabel('Dükkan Bilgileri'),
          SettingsFieldGroup(
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dükkan Adı',
                  prefixIcon: Icon(Icons.storefront_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aboutCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Hakkımda',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.info_outline_rounded),
                ),
              ),
            ],
          ),
          const SettingsSectionLabel('Sosyal Medya'),
          SettingsFieldGroup(
            children: [
              TextField(
                controller: _instagramCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Instagram Linki',
                  hintText: 'https://instagram.com/hesabin',
                  prefixIcon: Icon(Icons.camera_alt_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tiktokCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'TikTok Linki',
                  hintText: 'https://tiktok.com/@hesabin',
                  prefixIcon: Icon(Icons.music_video_outlined),
                ),
              ),
            ],
          ),
          const SettingsSectionLabel('Galeri'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.photo_library_rounded,
                title: 'Galeri Fotoğrafları',
                subtitle: barber.galleryPaths.isEmpty
                    ? 'Henüz fotoğraf eklenmedi'
                    : '${barber.galleryPaths.length}/10 fotoğraf',
                iconColor: AppTheme.bronze,
                onTap: _pickGallery,
              ),
            ],
          ),
          if (barber.galleryPaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: barber.galleryPaths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final path = barber.galleryPaths[index];
                  final provider = _toImageProvider(path);
                  if (provider == null) return const SizedBox.shrink();
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image(
                          image: provider,
                          width: 130,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _removeGalleryItem(index),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          SettingsSaveBar(onPressed: _saveProfile),
          const SizedBox(height: 8),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Çıkış Yap',
                iconColor: AppTheme.error,
                onTap: widget.onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

