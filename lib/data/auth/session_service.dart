import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { customer, barber }

class SessionService {
  static const _roleKey = 'saved_user_role';

  static Future<void> saveRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
  }

  static Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }

  /// Aktif Supabase oturumu varsa kaydedilmiş rolü döner, yoksa null.
  static Future<UserRole?> getSavedRole() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roleKey);
    if (raw == null) return null;

    return UserRole.values.where((r) => r.name == raw).firstOrNull;
  }
}
