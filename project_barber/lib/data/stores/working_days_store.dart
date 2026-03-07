import 'package:flutter/foundation.dart';

class WorkingDaysStore {
  WorkingDaysStore._();

  static final WorkingDaysStore instance = WorkingDaysStore._();

  // 1 = Pazartesi ... 7 = Pazar
  final ValueNotifier<Set<int>> daysOff =
      ValueNotifier<Set<int>>(<int>{7}); // Varsayılan: Pazar izin.

  bool isDayOff(DateTime date) => daysOff.value.contains(date.weekday);

  void setDayOff(int weekday, bool isOff) {
    final next = Set<int>.from(daysOff.value);
    if (isOff) {
      next.add(weekday);
    } else {
      next.remove(weekday);
    }
    daysOff.value = next;
  }

  static const Map<int, String> weekdayNames = <int, String>{
    1: 'Pazartesi',
    2: 'Salı',
    3: 'Çarşamba',
    4: 'Perşembe',
    5: 'Cuma',
    6: 'Cumartesi',
    7: 'Pazar',
  };
}

