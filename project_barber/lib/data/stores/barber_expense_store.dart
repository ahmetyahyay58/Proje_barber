import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/barber_expense.dart';
import 'barber_store.dart';

class BarberExpenseStore {
  BarberExpenseStore._();

  static final BarberExpenseStore instance = BarberExpenseStore._();
  final _client = Supabase.instance.client;

  final ValueNotifier<List<BarberExpense>> expenses =
      ValueNotifier<List<BarberExpense>>(<BarberExpense>[]);

  Future<void> refreshExpenses() async {
    final barber = BarberStore.instance.currentUserBarber;
    if (barber == null) {
      expenses.value = const <BarberExpense>[];
      return;
    }
    List<dynamic> rows;
    try {
      rows = await _client
          .from('barber_expenses')
          .select('id,barber_id,title,amount,incurred_on,image_url,description,created_at')
          .eq('barber_id', barber.id)
          .order('incurred_on', ascending: false);
    } on PostgrestException catch (e) {
      // Eski schema'da description kolonu olmayabilir.
      if ((e.code == 'PGRST204' || e.code == '42703') &&
          e.message.toLowerCase().contains('description')) {
        rows = await _client
            .from('barber_expenses')
            .select('id,barber_id,title,amount,incurred_on,image_url,created_at')
            .eq('barber_id', barber.id)
            .order('incurred_on', ascending: false);
      } else {
        rethrow;
      }
    }
    expenses.value = rows.cast<Map<String, dynamic>>().map((row) {
      return BarberExpense(
        id: row['id']?.toString() ?? '',
        barberId: row['barber_id']?.toString() ?? '',
        title: row['title']?.toString() ?? '',
        amount: (row['amount'] as num?)?.toInt() ?? 0,
        incurredOn: DateTime.tryParse(row['incurred_on']?.toString() ?? '') ?? DateTime.now(),
        description: row['description']?.toString(),
        imageUrl: row['image_url']?.toString(),
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      );
    }).toList();
  }

  Future<void> addExpense({
    required String title,
    required int amount,
    required DateTime incurredOn,
    String? description,
    String? imageUrl,
  }) async {
    final barber = BarberStore.instance.currentUserBarber;
    if (barber == null) return;
    final payload = {
      'barber_id': barber.id,
      'title': title,
      'amount': amount,
      'incurred_on': DateTime(incurredOn.year, incurredOn.month, incurredOn.day)
          .toUtc()
          .toIso8601String(),
      'description': (description ?? '').trim().isEmpty ? null : description!.trim(),
      'image_url': imageUrl,
    };
    try {
      await _client.from('barber_expenses').insert(payload);
    } on PostgrestException catch (e) {
      if ((e.code == 'PGRST204' || e.code == '42703') &&
          e.message.toLowerCase().contains('description')) {
        final fallback = Map<String, dynamic>.from(payload)..remove('description');
        await _client.from('barber_expenses').insert(fallback);
      } else {
        rethrow;
      }
    }
    await refreshExpenses();
  }
}

