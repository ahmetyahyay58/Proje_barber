import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';
import 'barber_store.dart';

class AppointmentStore {
  AppointmentStore._() {
    unawaited(_init());
  }

  static final AppointmentStore instance = AppointmentStore._();
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSubscription;

  final ValueNotifier<List<Appointment>> appointments =
      ValueNotifier<List<Appointment>>(<Appointment>[]);

  Future<void> _init() async {
    await refreshAppointments();
    _subscribeRealtime();
    _authSubscription?.cancel();
    _authSubscription = _client.auth.onAuthStateChange.listen((_) {
      unawaited(refreshAppointments());
    });
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = _client.channel('public:appointments').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'appointments',
      callback: (_) {
        unawaited(refreshAppointments());
      },
    );
    _channel!.subscribe();
  }

  Future<void> refreshAppointments() async {
    try {
      final rows = await _client.from('appointments').select().order('start_at', ascending: true);
      final rawRows = (rows as List<dynamic>).cast<Map<String, dynamic>>();
      final visibleRows = rawRows
          .where((row) => (row['status']?.toString() ?? 'pending') != 'cancelled')
          .toList();

      final ids = visibleRows
          .map((e) => e['customer_id']?.toString())
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final profileById = <String, Map<String, dynamic>>{};
      if (ids.isNotEmpty) {
        final profileRows = await _client
            .from('profiles')
            .select('id,full_name,phone')
            .inFilter('id', ids);
        for (final row in (profileRows as List<dynamic>).cast<Map<String, dynamic>>()) {
          profileById[row['id']?.toString() ?? ''] = row;
        }
      }

      appointments.value = visibleRows.map((row) {
        final customerId = row['customer_id']?.toString();
        final profile = customerId == null ? null : profileById[customerId];
        return Appointment(
          id: row['id']?.toString() ?? '',
          barberId: row['barber_id']?.toString() ?? '',
          barberName: row['barber_name_snapshot']?.toString() ?? '',
          dateTime: DateTime.tryParse(row['start_at']?.toString() ?? '') ?? DateTime.now(),
          durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 30,
          totalAmount: (row['total_amount'] as num?)?.toInt() ?? 0,
          customerId: customerId,
          customerName: (profile?['full_name']?.toString().trim().isNotEmpty ?? false)
              ? profile!['full_name'].toString().trim()
              : row['customer_name_snapshot']?.toString(),
          customerPhone: profile?['phone']?.toString(),
          serviceNames: (row['service_names'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e.toString())
              .toList(),
          masterName: row['master_name']?.toString(),
          rating: (row['rating'] as num?)?.toDouble(),
          note: row['note']?.toString(),
        );
      }).toList();
    } catch (e, st) {
      debugPrint('AppointmentStore.refreshAppointments error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> addAppointment(Appointment appointment) async {
    final user = _client.auth.currentUser;
    final payload = <String, dynamic>{
      'customer_id': user?.id,
      'customer_name_snapshot': appointment.customerName,
      'barber_id': appointment.barberId,
      'barber_name_snapshot': appointment.barberName,
      'start_at': appointment.dateTime.toUtc().toIso8601String(),
      'duration_minutes': appointment.durationMinutes,
      'total_amount': appointment.totalAmount,
      'service_names': appointment.serviceNames,
      'master_name': appointment.masterName,
    };
    try {
      await _client.from('appointments').insert(payload);
    } on PostgrestException catch (e) {
      // Overbooking engeli (exclusion constraint) → kullanıcıya daha anlaşılır hata.
      // Postgres: exclusion_violation = 23P01
      if (e.code == '23P01') {
        throw const AppointmentSlotTakenException();
      }
      // Eski schema'da customer_name_snapshot kolonu yoksa tekrar deneriz.
      if (e.code == 'PGRST204' &&
          (e.message.contains('customer_name_snapshot') ||
              e.message.contains('total_amount'))) {
        final fallback = Map<String, dynamic>.from(payload)
          ..remove('customer_name_snapshot')
          ..remove('total_amount');
        await _client.from('appointments').insert(fallback);
      } else {
        rethrow;
      }
    }
    await refreshAppointments();
  }

  Future<void> updateRating({
    required String id,
    required double rating,
    String? note,
  }) async {
    await _client.from('appointments').update({
      'rating': rating,
      'note': note,
    }).eq('id', id);
    await refreshAppointments();
    await BarberStore.instance.refreshBarbers();
  }

  Future<void> cancelAppointment(String id) async {
    await _client.from('appointments').update({
      'status': 'cancelled',
    }).eq('id', id);
    await refreshAppointments();
  }
}

class AppointmentSlotTakenException implements Exception {
  const AppointmentSlotTakenException();
}

