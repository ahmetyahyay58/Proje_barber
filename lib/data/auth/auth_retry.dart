import 'package:supabase_flutter/supabase_flutter.dart';

Future<T> runWithAuthRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 2,
  Duration delay = const Duration(milliseconds: 350),
}) async {
  Object? lastError;
  StackTrace? lastStack;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } on AuthException catch (e, st) {
      lastError = e;
      lastStack = st;

      final msg = e.message.toLowerCase();
      final retryable =
          msg.contains('timeout') ||
          msg.contains('timed out') ||
          msg.contains('upstream') ||
          msg.contains('bad gateway') ||
          msg.contains('gateway') ||
          msg.contains('temporarily') ||
          msg.contains('try again');

      if (!retryable || attempt == maxAttempts) {
        Error.throwWithStackTrace(e, st);
      }

      await Future<void>.delayed(delay * attempt);
    } catch (e, st) {
      lastError = e;
      lastStack = st;
      rethrow;
    }
  }

  // Should be unreachable, but keeps analyzer happy if loops change later.
  Error.throwWithStackTrace(lastError!, lastStack!);
}
