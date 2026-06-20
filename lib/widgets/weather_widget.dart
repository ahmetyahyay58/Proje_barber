import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../app/app_theme.dart';

class WeatherData {
  const WeatherData({
    required this.temp,
    required this.description,
    required this.weatherCode,
  });

  final int temp;
  final String description;
  final int weatherCode;
}

String _weatherEmoji(int code) {
  if (code == 113) return '☀️';
  if (code == 116) return '🌤️';
  if (code == 119 || code == 122) return '☁️';
  if (code == 143 || code == 248 || code == 260) return '🌫️';
  if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 353, 356, 359]
      .contains(code)) return '🌧️';
  if ([
    179, 182, 185, 311, 314, 317, 320, 323, 326,
    329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377
  ].contains(code)) return '❄️';
  if ([200, 386, 389, 392, 395].contains(code)) return '⛈️';
  return '🌡️';
}

String _descriptionTr(int code) {
  return switch (code) {
    113 => 'Açık ve güneşli',
    116 => 'Parçalı bulutlu',
    119 => 'Bulutlu',
    122 => 'Kapalı',
    143 => 'Sisli',
    176 => 'Yer yer yağmurlu',
    179 => 'Yer yer karlı',
    182 || 185 => 'Karla karışık yağmur',
    200 => 'Gök gürültülü',
    248 || 260 => 'Yoğun sis',
    263 || 266 => 'Hafif çisenti',
    293 || 296 => 'Hafif yağmur',
    299 || 302 => 'Orta yağmur',
    305 || 308 => 'Kuvvetli yağmur',
    311 || 314 => 'Buz yağışı',
    317 || 320 => 'Hafif kar yağışı',
    323 || 326 => 'Hafif kar',
    329 || 332 => 'Orta kar',
    335 || 338 => 'Yoğun kar',
    350 => 'Dolu',
    353 => 'Hafif sağanak',
    356 => 'Orta sağanak',
    359 => 'Şiddetli sağanak',
    362 || 365 => 'Karla karışık sağanak',
    368 || 371 => 'Karlı sağanak',
    374 || 377 => 'Taneli kar sağanağı',
    386 => 'Gök gürültülü sağanak',
    389 => 'Şiddetli gök gürültülü yağmur',
    392 => 'Gök gürültülü kar sağanağı',
    395 => 'Şiddetli karlı fırtına',
    _ => 'Hava durumu',
  };
}

Future<WeatherData?> _fetchWeather() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return null;

  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    return null;
  }

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
  );

  final uri = Uri.parse(
    'https://wttr.in/${pos.latitude},${pos.longitude}?format=j1',
  );

  final res = await http
      .get(uri, headers: {'User-Agent': 'BerberPro/1.0'})
      .timeout(const Duration(seconds: 10));

  if (res.statusCode != 200) return null;

  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final current =
      (json['current_condition'] as List).first as Map<String, dynamic>;
  final code =
      int.tryParse(current['weatherCode'] as String? ?? '113') ?? 113;

  return WeatherData(
    temp: int.tryParse(current['temp_C'] as String? ?? '0') ?? 0,
    description: _descriptionTr(code),
    weatherCode: code,
  );
}

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherData? _data;
  bool _loading = true;
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _unavailable = false;
    });
    try {
      final data = await _fetchWeather();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _unavailable = data == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _unavailable = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 28,
        width: 28,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
      );
    }

    if (_unavailable || _data == null) return const SizedBox.shrink();

    final d = _data!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _weatherEmoji(d.weatherCode),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 5),
          Text(
            '${d.temp}°  ${d.description}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
