class Appointment {
  const Appointment({
    required this.id,
    required this.barberId,
    required this.barberName,
    required this.dateTime,
    required this.durationMinutes,
    this.totalAmount = 0,
    this.customerId,
    this.customerName,
    this.customerPhone,
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
  final int totalAmount;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  /// Seçilen hizmet adları.
  final List<String> serviceNames;
   /// Randevuyu alacak usta / berber adı (isteğe bağlı).
  final String? masterName;
  final double? rating;
  final String? note;

  Appointment copyWith({
    int? durationMinutes,
    int? totalAmount,
    String? customerId,
    String? customerName,
    String? customerPhone,
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
      totalAmount: totalAmount ?? this.totalAmount,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceNames: serviceNames ?? this.serviceNames,
      masterName: masterName ?? this.masterName,
      rating: rating ?? this.rating,
      note: note ?? this.note,
    );
  }
}
