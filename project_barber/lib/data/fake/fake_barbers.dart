import '../models/barber.dart';

List<Barber> buildFakeBarbers() {
  return const [
    Barber(
      id: 'b1',
      name: 'Usta Berber Ahmet',
      city: 'İstanbul',
      district: 'Kadıköy',
      address: 'Rıhtım Cd. No:12',
      rating: 4.7,
      minPrice: 250,
      maxPrice: 600,
      galleryPaths: <String>[],
    ),
    Barber(
      id: 'b2',
      name: 'Salon 34',
      city: 'İstanbul',
      district: 'Beşiktaş',
      address: 'Çarşı Sk. No:8',
      rating: 4.5,
      minPrice: 300,
      maxPrice: 750,
      galleryPaths: <String>[],
    ),
    Barber(
      id: 'b3',
      name: 'Ankara Klasik',
      city: 'Ankara',
      district: 'Çankaya',
      address: 'Atakule Yakını',
      rating: 4.6,
      minPrice: 220,
      maxPrice: 550,
      galleryPaths: <String>[],
    ),
    Barber(
      id: 'b4',
      name: 'İzmir Makas',
      city: 'İzmir',
      district: 'Karşıyaka',
      address: 'Sahil Bulvarı',
      rating: 4.4,
      minPrice: 200,
      maxPrice: 500,
      galleryPaths: <String>[],
    ),
  ];
}

