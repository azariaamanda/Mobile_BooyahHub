import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handler pesan FCM saat app di-background (harus top-level function)
@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  // Firebase sudah otomatis menampilkan notifikasi sistem — tidak perlu kode tambahan
}

class FcmService {
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  /// Panggil sekali setelah Firebase.initializeApp() di main.dart
  Future<void> initialize() async {
    // Daftarkan background handler
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

    // Minta izin notifikasi (wajib untuk iOS, best-practice untuk Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground notification display (Android)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Panggil setelah user login untuk menyimpan token ke DB
  Future<void> saveToken(int akunId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _supabase.from('fcm_tokens').upsert(
        {
          'akun_id': akunId,
          'token': token,
          'platform': 'android',
        },
        onConflict: 'akun_id,platform',
      );

      // Update token saat diperbarui oleh FCM
      _messaging.onTokenRefresh.listen((newToken) async {
        await _supabase.from('fcm_tokens').upsert(
          {
            'akun_id': akunId,
            'token': newToken,
            'platform': 'android',
          },
          onConflict: 'akun_id,platform',
        );
      });
    } catch (_) {}
  }

  /// Panggil saat logout untuk menghapus token
  Future<void> deleteToken(int akunId) async {
    try {
      await _supabase
          .from('fcm_tokens')
          .delete()
          .eq('akun_id', akunId);
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
