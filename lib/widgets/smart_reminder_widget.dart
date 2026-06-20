import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/app_theme.dart';

/// Müşteri profil kartı banner alanı için akıllı hatırlatıcı widget.
///
/// - Geçmişte randevu varsa: "Son Tıraş: X Gün Önce" gösterir.
///   20+ gün geçmişse uyarı tonuna geçer.
/// - Hiç randevu yoksa: streak ilerleme rozeti gösterir.
class SmartReminderWidget extends StatefulWidget {
  const SmartReminderWidget({super.key, this.onBookNow});

  final VoidCallback? onBookNow;

  @override
  State<SmartReminderWidget> createState() => _SmartReminderWidgetState();
}

class _SmartReminderWidgetState extends State<SmartReminderWidget> {
  late final Future<_ReminderData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchData();
  }

  Future<_ReminderData> _fetchData() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return const _ReminderData(daysSince: null, streakMonths: 0);

    // Son tamamlanmış randevu (gün farkı için)
    final lastRows = await Supabase.instance.client
        .from('appointments')
        .select('start_at')
        .eq('customer_id', uid)
        .neq('status', 'cancelled')
        .order('start_at', ascending: false)
        .limit(1);

    final list = (lastRows as List<dynamic>).cast<Map<String, dynamic>>();
    int? daysSince;
    if (list.isNotEmpty) {
      final raw = list.first['start_at']?.toString();
      final lastDate = raw != null ? DateTime.tryParse(raw)?.toLocal() : null;
      if (lastDate != null) {
        daysSince = DateTime.now().difference(lastDate).inDays;
      }
    }

    // Streak: kaç farklı ayda randevu var (ardışık, geriye doğru)
    final allRows = await Supabase.instance.client
        .from('appointments')
        .select('start_at')
        .eq('customer_id', uid)
        .neq('status', 'cancelled');

    final now = DateTime.now();
    final months = (allRows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((r) {
          final dt = DateTime.tryParse(r['start_at']?.toString() ?? '');
          if (dt == null || dt.isAfter(now)) return null;
          return dt.year * 12 + dt.month;
        })
        .whereType<int>()
        .toSet();

    int streak = 0;
    var idx = now.year * 12 + now.month;
    while (months.contains(idx)) {
      streak++;
      idx--;
    }

    return _ReminderData(daysSince: daysSince, streakMonths: streak);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReminderData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accent),
          );
        }

        final data = snapshot.data ?? const _ReminderData(daysSince: null, streakMonths: 0);

        if (data.daysSince != null) {
          return _LastCutBadge(days: data.daysSince!, onTap: widget.onBookNow);
        }

        return _StreakProgressBadge(streakMonths: data.streakMonths);
      },
    );
  }
}

class _ReminderData {
  const _ReminderData({required this.daysSince, required this.streakMonths});
  final int? daysSince;
  final int streakMonths;
}

// ---------------------------------------------------------------------------
// Son tıraş kaç gün önce
// ---------------------------------------------------------------------------

class _LastCutBadge extends StatelessWidget {
  const _LastCutBadge({required this.days, this.onTap});

  final int days;
  final VoidCallback? onTap;

  Color get _color {
    if (days >= 20) return const Color(0xFFD4843A);
    if (days >= 14) return AppTheme.accent;
    return AppTheme.success;
  }

  String get _dayLabel {
    if (days == 0) return 'Bugün';
    if (days == 1) return 'Dün';
    return '$days gün önce';
  }

  String get _hint {
    if (days >= 20) return 'Randevu zamanı geldi!';
    if (days >= 14) return 'Biraz daha geçiyor...';
    return 'Harika gidiyorsun 👍';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDeep,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: _color.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: _color.withValues(alpha: 0.10),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.content_cut_rounded, size: 13, color: _color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Son Tıraş',
                  style: TextStyle(
                    fontSize: 9,
                    color: _color.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _dayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _color,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _hint,
                  style: TextStyle(
                    fontSize: 8,
                    color: _color.withValues(alpha: 0.6),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak ilerleme / level rozeti
// ---------------------------------------------------------------------------

class _StreakProgressBadge extends StatelessWidget {
  const _StreakProgressBadge({required this.streakMonths});

  final int streakMonths;

  @override
  Widget build(BuildContext context) {
    final level = _level(streakMonths);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDeep,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
      ),
      child: level == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '$streakMonths/3 ay',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Level 1\'e ulaş',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                    height: 1.1,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(level.emoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${level.num}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  level.title,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }

  ({int num, String emoji, String title})? _level(int months) {
    if (months >= 12) return (num: 3, emoji: '👑', title: 'VIP Müşteri');
    if (months >= 6) return (num: 2, emoji: '⭐', title: 'Düzenli Müşteri');
    if (months >= 3) return (num: 1, emoji: '🌱', title: 'Sadık Müşteri');
    return null;
  }
}
