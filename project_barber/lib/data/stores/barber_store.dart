import 'package:flutter/foundation.dart';

import '../fake/fake_barbers.dart';
import '../models/barber.dart';

class BarberStore {
  BarberStore._();

  static final BarberStore instance = BarberStore._();

  final ValueNotifier<List<Barber>> barbers = ValueNotifier<List<Barber>>(
    buildFakeBarbers(),
  );

  void addBarber(Barber barber) {
    final next = List<Barber>.from(barbers.value)..add(barber);
    barbers.value = next;
  }
}

