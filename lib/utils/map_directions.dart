import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/barber.dart';

Future<String?> _currentLocationParam() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return null;

  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm != LocationPermission.whileInUse &&
      perm != LocationPermission.always) {
    return null;
  }

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    ),
  );
  return '${pos.latitude},${pos.longitude}';
}

Future<bool> openDirectionsToBarber(Barber barber) async {
  final lat = barber.lat;
  final lng = barber.lng;
  if (lat == null || lng == null) return false;

  final origin = await _currentLocationParam();
  final destination = '$lat,$lng';
  final uri = origin == null
      ? Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
        )
      : Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving',
        );

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
