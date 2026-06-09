import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSession {
  static String? _email;
  static String? _userId;

  static String? get email =>
      _email;

  static String? get userId => _userId;

  static Future<void> save({required String email, String? userId}) async {
    _email = email;
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_email', email);
    if (userId != null) await prefs.setString('session_user_id', userId);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString('session_email');
    _userId = prefs.getString('session_user_id');
  }

  static Future<void> clear() async {
    _email = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_email');
    await prefs.remove('session_user_id');
  }
}

extension SupabaseClientSession on SupabaseClient {
  /// Returns email from Supabase Auth session OR fallback from AppSession (SharedPreferences).
  /// Use this instead of auth.currentUser?.email everywhere.
  String? get sessionEmail => auth.currentUser?.email ?? AppSession.email;

  /// Returns user id from Supabase Auth session OR fallback from AppSession.
  String? get sessionUserId => auth.currentUser?.id ?? AppSession.userId;
}
