import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerProfileData {
  const CustomerProfileData({
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
    this.city,
    this.district,
  });

  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? city;
  final String? district;

  String? get locationLabel {
    final c = city?.trim() ?? '';
    final d = district?.trim() ?? '';
    if (c.isEmpty && d.isEmpty) return null;
    if (d.isEmpty) return c;
    if (c.isEmpty) return d;
    return '$c / $d';
  }
}

class CustomerProfileStore {
  CustomerProfileStore._();

  static final CustomerProfileStore instance = CustomerProfileStore._();

  final _client = Supabase.instance.client;
  final ValueNotifier<CustomerProfileData?> profile =
      ValueNotifier<CustomerProfileData?>(null);

  Future<void> ensureProfileExists({String? fallbackName}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;
    await _client.from('profiles').insert({
      'id': user.id,
      'role': 'customer',
      'full_name': fallbackName ?? user.email,
    });
  }

  Future<void> refreshProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      profile.value = null;
      return;
    }
    Map<String, dynamic>? row;
    try {
      row = await _client
          .from('profiles')
          .select('full_name,phone,avatar_url')
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      // Eski schema'da avatar_url kolonu olmayabilir.
      if (_isMissingAvatarColumnError(e)) {
        row = await _client
            .from('profiles')
            .select('full_name,phone')
            .eq('id', user.id)
            .maybeSingle();
      } else {
        rethrow;
      }
    }
    profile.value = CustomerProfileData(
      fullName: row?['full_name']?.toString(),
      phone: row?['phone']?.toString(),
      avatarUrl: row?['avatar_url']?.toString(),
      city: row?['city']?.toString(),
      district: row?['district']?.toString(),
    );
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final payload = <String, dynamic>{
      'id': user.id,
      'role': 'customer',
      'full_name': (fullName ?? '').trim().isEmpty ? null : fullName!.trim(),
      'phone': (phone ?? '').trim().isEmpty ? null : phone!.trim(),
      'avatar_url': avatarUrl,
    };
    try {
      await _client.from('profiles').upsert(payload);
    } catch (e) {
      if (_isMissingAvatarColumnError(e)) {
        final fallback = Map<String, dynamic>.from(payload)..remove('avatar_url');
        await _client.from('profiles').upsert(fallback);
      } else {
        rethrow;
      }
    }
    await refreshProfile();
  }

  bool _isMissingAvatarColumnError(Object e) {
    if (e is PostgrestException) {
      final code = e.code ?? '';
      final message = e.message.toLowerCase();
      if ((code == 'PGRST204' || code == '42703') &&
          message.contains('avatar_url')) {
        return true;
      }
    }
    final raw = e.toString().toLowerCase();
    return raw.contains('avatar_url') &&
        (raw.contains('42703') ||
            raw.contains('pgrst204') ||
            raw.contains('does not exist'));
  }
}

