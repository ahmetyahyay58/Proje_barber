import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/barber.dart';

class BarberStore {
  BarberStore._() {
    unawaited(refreshBarbers());
  }

  static final BarberStore instance = BarberStore._();

  final _client = Supabase.instance.client;
  final ValueNotifier<List<Barber>> barbers = ValueNotifier<List<Barber>>(
    const <Barber>[],
  );

  void addBarber(Barber barber) {
    final next = List<Barber>.from(barbers.value)
      ..removeWhere((b) => b.id == barber.id)
      ..add(barber);
    barbers.value = next;
  }

  Future<void> refreshBarbers() async {
    try {
      final barberRows = await _client
          .from('barbers')
          .select()
          .order('created_at', ascending: false);
      final serviceRows = await _client
          .from('barber_services')
          .select()
          .order('created_at', ascending: true);

      final servicesByBarber = <String, List<BarberService>>{};
      for (final row in (serviceRows as List<dynamic>).cast<Map<String, dynamic>>()) {
        final barberId = row['barber_id']?.toString() ?? '';
        if (barberId.isEmpty) continue;
        servicesByBarber.putIfAbsent(barberId, () => <BarberService>[]).add(
              BarberService(
                id: row['id']?.toString() ?? '',
                name: row['name']?.toString() ?? 'Hizmet',
                durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 30,
                price: (row['price'] as num?)?.toInt() ?? 0,
              ),
            );
      }

      final mapped = (barberRows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((row) => _fromDb(row, servicesByBarber[row['id']?.toString() ?? ''] ?? const <BarberService>[]))
          .toList();
      barbers.value = mapped;
    } catch (e, st) {
      debugPrint('BarberStore.refreshBarbers error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> upsertCurrentUserBarber({
    required String name,
    required String city,
    required String district,
    required String address,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Önce giriş yapılmalı.');
    }

    final payload = <String, dynamic>{
      'owner_id': user.id,
      'name': name,
      'city': city,
      'district': district,
      'address': address,
      'min_price': 200,
      'max_price': 500,
    };

    final existing = await _client
        .from('barbers')
        .select('id')
        .eq('owner_id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _client.from('barbers').insert(payload);
    } else {
      await _client.from('barbers').update(payload).eq('id', existing['id']);
    }

    await refreshBarbers();
  }

  Barber? get currentUserBarber {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      return barbers.value.firstWhere((b) => b.ownerId == uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateMasters(List<String> masters) async {
    final barber = currentUserBarber;
    if (barber == null) return;
    await _client.from('barbers').update({
      'masters': masters,
    }).eq('id', barber.id);
    await refreshBarbers();
  }

  Future<void> updateCurrentBarberProfile({
    String? name,
    String? about,
    String? avatarUrl,
    List<String>? galleryUrls,
  }) async {
    final barber = currentUserBarber;
    if (barber == null) return;
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (about != null) payload['about'] = about;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    if (galleryUrls != null) payload['gallery_urls'] = galleryUrls;
    if (payload.isEmpty) return;
    await _client.from('barbers').update(payload).eq('id', barber.id);
    await refreshBarbers();
  }

  Future<void> upsertService({
    String? id,
    required String name,
    required int durationMinutes,
    required int price,
  }) async {
    final barber = currentUserBarber;
    if (barber == null) return;
    final payload = <String, dynamic>{
      'barber_id': barber.id,
      'name': name,
      'duration_minutes': durationMinutes,
      'price': price,
    };
    if (id == null || id.isEmpty) {
      await _client.from('barber_services').insert(payload);
    } else {
      await _client.from('barber_services').update(payload).eq('id', id);
    }
    await refreshBarbers();
  }

  Future<void> deleteService(String id) async {
    await _client.from('barber_services').delete().eq('id', id);
    await refreshBarbers();
  }

  Barber _fromDb(Map<String, dynamic> row, List<BarberService> services) {
    return Barber(
      id: row['id']?.toString() ?? '',
      ownerId: row['owner_id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      city: row['city']?.toString() ?? '',
      district: row['district']?.toString() ?? '',
      address: row['address']?.toString() ?? '',
      rating: (row['rating'] as num?)?.toDouble() ?? 0,
      minPrice: (row['min_price'] as num?)?.toInt() ?? 0,
      maxPrice: (row['max_price'] as num?)?.toInt() ?? 0,
      avatarPath: row['avatar_url']?.toString(),
      about: row['about']?.toString(),
      masters: (row['masters'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      galleryPaths:
          (row['gallery_urls'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e.toString())
              .toList(),
      services: services,
    );
  }
}

