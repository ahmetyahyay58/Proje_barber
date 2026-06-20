class BarberExpense {
  const BarberExpense({
    required this.id,
    required this.barberId,
    required this.title,
    required this.amount,
    required this.incurredOn,
    this.description,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String barberId;
  final String title;
  final int amount;
  final DateTime incurredOn;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;
}

