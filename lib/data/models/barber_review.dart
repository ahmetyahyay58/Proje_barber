class BarberReview {
  const BarberReview({
    required this.id,
    required this.rating,
    required this.dateTime,
    this.note,
    this.customerName,
  });

  final String id;
  final double rating;
  final DateTime dateTime;
  final String? note;
  final String? customerName;
}
