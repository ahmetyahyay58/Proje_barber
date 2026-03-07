class Barber {
  const Barber({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.address,
    required this.rating,
    required this.minPrice,
    required this.maxPrice,
    this.avatarPath,
    this.galleryPaths = const <String>[],
  });

  final String id;
  final String name;
  final String city;
  final String district;
  final String address;
  final double rating;
  final int minPrice;
  final int maxPrice;
   /// Cihazdan seçilen profil fotoğrafı yolu (isteğe bağlı).
  final String? avatarPath;

  /// Berbere ait galeri fotoğrafları (isteğe bağlı).
  final List<String> galleryPaths;
}

