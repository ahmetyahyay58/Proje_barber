import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_retry.dart';

Future<void> requestEmailOtp({
  required String email,
  bool shouldCreateUser = true,
}) async {
  await runWithAuthRetry(() async {
    await Supabase.instance.client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: shouldCreateUser,
    );
  });
}
