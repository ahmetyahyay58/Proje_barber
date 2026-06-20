import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/app_theme.dart';
import '../data/models/appointment.dart';
import '../data/stores/appointment_store.dart';

class AppointmentMiniWidget extends StatelessWidget {
  const AppointmentMiniWidget({
    super.key,
    this.onBookNow,
    this.onShowDetail,
  });

  final VoidCallback? onBookNow;
  final VoidCallback? onShowDetail;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: AppointmentStore.instance.appointments,
      builder: (context, appointments, _) {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        final next = _nextAppointment(appointments, uid);
        if (next != null) {
          return _ActiveAppointmentBadge(
            appointment: next,
            onTap: onShowDetail,
          );
        }
        final streak = _calcStreakMonths(appointments, uid);
        return _StreakBadge(streakMonths: streak);
      },
    );
  }

  Appointment? _nextAppointment(List<Appointment> all, String? uid) {
    if (uid == null) return null;
    final now = DateTime.now();
    final upcoming = all
        .where((a) => a.customerId == uid && a.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Geçmiş randevulardan aylık streak hesaplar.
  /// Her ay en fazla 1 sayılır; mevcut aydan geriye doğru ardışık sayar.
  int _calcStreakMonths(List<Appointment> all, String? uid) {
    if (uid == null) return 0;
    final now = DateTime.now();
    final visitedMonths = all
        .where((a) => a.customerId == uid && !a.dateTime.isAfter(now))
        .map((a) => a.dateTime.year * 12 + a.dateTime.month)
        .toSet();

    int streak = 0;
    var monthIdx = now.year * 12 + now.month;
    while (visitedMonths.contains(monthIdx)) {
      streak++;
      monthIdx--;
    }
    return streak;
  }
}

// ---------------------------------------------------------------------------
// Aktif randevu var
// ---------------------------------------------------------------------------

class _ActiveAppointmentBadge extends StatelessWidget {
  const _ActiveAppointmentBadge({required this.appointment, this.onTap});

  final Appointment appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _fmtDate(appointment.dateTime);
    final timeLabel = _fmtTime(appointment.dateTime);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_available_rounded,
                size: 13,
                color: AppTheme.accent,
              ),
              const SizedBox(width: 5),
              Text(
                '$dateLabel · $timeLabel',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (appointment.barberName.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              appointment.barberName.trim(),
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Streak rozeti
// ---------------------------------------------------------------------------

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streakMonths});

  final int streakMonths;

  @override
  Widget build(BuildContext context) {
    final level = _level(streakMonths);

    if (level == null) {
      // Henüz streak yok — ilerleme göster
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(
                '$streakMonths/3 ay',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Level 1\'e ulaş',
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(level.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              'Level ${level.num}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          level.title,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  _StreakLevel? _level(int months) {
    if (months >= 12) {
      return const _StreakLevel(num: 3, emoji: '👑', title: 'VIP Müşteri');
    }
    if (months >= 6) {
      return const _StreakLevel(num: 2, emoji: '⭐', title: 'Düzenli Müşteri');
    }
    if (months >= 3) {
      return const _StreakLevel(num: 1, emoji: '🌱', title: 'Sadık Müşteri');
    }
    return null;
  }
}

class _StreakLevel {
  const _StreakLevel({
    required this.num,
    required this.emoji,
    required this.title,
  });
  final int num;
  final String emoji;
  final String title;
}
