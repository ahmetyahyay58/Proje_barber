class Appointment {
  const Appointment({
    required this.id,
    required this.barberId,
    required this.barberName,
    required this.dateTime,
    this.rating,
    this.note,
  });

  final String id;
  final String barberId;
  final String barberName;
  final DateTime dateTime;
  final double? rating;
  final String? note;

  Appointment copyWith({
    double? rating,
    String? note,
  }) {
    return Appointment(
      id: id,
      barberId: barberId,
      barberName: barberName,
      dateTime: dateTime,
      rating: rating ?? this.rating,
      note: note ?? this.note,
    );
  }
}

