class BarberService {
  const BarberService({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });

  final String id;
  final String name;
  final int durationMinutes;
  final int price;
}

class Barber {
  const Barber({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.city,
    required this.district,
    required this.address,
    this.lat,
    this.lng,
    required this.rating,
    required this.minPrice,
    required this.maxPrice,
    this.avatarPath,
    this.galleryPaths = const <String>[],
    this.about,
    this.masters = const <String>[],
    this.services = const <BarberService>[],
    this.daysOff = const <int>[],
  });

  final String id;
  final String ownerId;
  final String name;
  final String city;
  final String district;
  final String address;
  final double? lat;
  final double? lng;
  final double rating;
  final int minPrice;
  final int maxPrice;
   /// Cihazdan seçilen profil fotoğrafı yolu (isteğe bağlı).
  final String? avatarPath;

  /// Berbere ait galeri fotoğrafları (isteğe bağlı).
  final List<String> galleryPaths;
  /// Dükkan / usta hakkında açıklama metni.
  final String? about;

  /// Randevu alırken seçilebilecek ustalar.
  final List<String> masters;

  /// Verilen hizmetler ve süreleri.
  final List<BarberService> services;

  /// İzin günleri: 1=Pazartesi … 7=Pazar
  final List<int> daysOff;

  bool get isOpenToday => !daysOff.contains(DateTime.now().weekday);
}

