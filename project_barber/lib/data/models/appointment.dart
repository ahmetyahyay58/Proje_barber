class Appointment {
  const Appointment({
    required this.id,
    required this.barberId,
    required this.barberName,
    required this.dateTime,
    required this.durationMinutes,
    this.serviceNames = const <String>[],
    this.masterName,
    this.rating,
    this.note,
  });

  final String id;
  final String barberId;
  final String barberName;
  final DateTime dateTime;
  /// Toplam hizmet süresi (dakika).
  final int durationMinutes;
  /// Seçilen hizmet adları.
  final List<String> serviceNames;
   /// Randevuyu alacak usta / berber adı (isteğe bağlı).
  final String? masterName;
  final double? rating;
  final String? note;

  Appointment copyWith({
    int? durationMinutes,
    List<String>? serviceNames,
    double? rating,
    String? note,
    String? masterName,
  }) {
    return Appointment(
      id: id,
      barberId: barberId,
      barberName: barberName,
      dateTime: dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      serviceNames: serviceNames ?? this.serviceNames,
      masterName: masterName ?? this.masterName,
      rating: rating ?? this.rating,
      note: note ?? this.note,
    );
  }
}
