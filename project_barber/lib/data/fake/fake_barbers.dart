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
      about: 'Kadıköy merkezde, klasik ve modern kesim hizmeti veren aile işletmesi.',
      masters: <String>['Ahmet Usta', 'Emre Usta'],
      services: <BarberService>[
        BarberService(
          id: 'b1_cut',
          name: 'Saç Kesimi',
          durationMinutes: 30,
          price: 350,
        ),
        BarberService(
          id: 'b1_beard',
          name: 'Sakal Tıraşı',
          durationMinutes: 20,
          price: 200,
        ),
        BarberService(
          id: 'b1_blow',
          name: 'Fön',
          durationMinutes: 15,
          price: 120,
        ),
      ],
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
      about: 'Şehir merkezinde modern tasarımlı erkek bakım salonu.',
      masters: <String>['Mert', 'Kaan'],
      services: <BarberService>[
        BarberService(
          id: 'b2_cut',
          name: 'Saç + Sakal Paket',
          durationMinutes: 45,
          price: 500,
        ),
        BarberService(
          id: 'b2_skin',
          name: 'Cilt Bakımı',
          durationMinutes: 40,
          price: 450,
        ),
      ],
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
      about: 'Yılların tecrübesiyle klasik berber deneyimi.',
      masters: <String>['Hüseyin Usta', 'Serkan'],
      services: <BarberService>[
        BarberService(
          id: 'b3_cut',
          name: 'Klasik Saç Kesimi',
          durationMinutes: 30,
          price: 300,
        ),
        BarberService(
          id: 'b3_shave',
          name: 'Jilet Sakal',
          durationMinutes: 25,
          price: 220,
        ),
      ],
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
      about: 'Deniz manzaralı modern berber salonu.',
      masters: <String>['Burak', 'Ege'],
      services: <BarberService>[
        BarberService(
          id: 'b4_cut',
          name: 'Fade Saç Kesimi',
          durationMinutes: 35,
          price: 380,
        ),
        BarberService(
          id: 'b4_color',
          name: 'Renk Uygulama',
          durationMinutes: 60,
          price: 650,
        ),
      ],
    ),
  ];
}

