import 'package:flutter/foundation.dart';

import '../models/appointment.dart';

class AppointmentStore {
  AppointmentStore._();

  static final AppointmentStore instance = AppointmentStore._();

  final ValueNotifier<List<Appointment>> appointments =
      ValueNotifier<List<Appointment>>(<Appointment>[]);

  void addAppointment(Appointment appointment) {
    final list = List<Appointment>.from(appointments.value)..add(appointment);
    appointments.value = list;
  }

  void updateRating({
    required String id,
    required double rating,
    String? note,
  }) {
    final list = appointments.value.map((a) {
      if (a.id != id) return a;
      return a.copyWith(
        rating: rating,
        note: note ?? a.note,
      );
    }).toList();
    appointments.value = list;
  }
}

