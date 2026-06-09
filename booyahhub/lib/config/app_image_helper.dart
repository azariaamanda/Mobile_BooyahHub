import 'package:flutter/foundation.dart';
import 'supabase_client.dart';

class AppImageHelper {
  AppImageHelper._();

  static final _supabase = SupabaseClientHelper.client;

  static String getPublicUrl(String bucket, String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  static Future<String?> getSignedUrl(String bucket, String? path, {int expiresIn = 3600}) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    try {
      return await _supabase.storage.from(bucket).createSignedUrl(path, expiresIn);
    } catch (e) {
      debugPrint('Error getting signed URL from $bucket: $e');
      return null;
    }
  }

  // BUCKET: foto_profil (PUBLIC)
  static String fotoProfil(String? path) => getPublicUrl('foto_profil', path);

  static String fotoProfilByEmail(String? email, {String defaultFile = 'foto.jpg'}) {
    if (email == null || email.isEmpty) return '';
    return getPublicUrl('foto_profil', '$email/$defaultFile');
  }

  // BUCKET: posters (PUBLIC)
  static String posterScrim(String? path) => getPublicUrl('posters', path);

  static String posterByIdScrim(int? idScrim) {
    if (idScrim == null) return '';
    return getPublicUrl('posters', '$idScrim/poster.jpg');
  }

  // BUCKET: ktp (PRIVATE)
  static Future<String?> fotoKtp(String? path) async {
    if (path == null || path.isEmpty) return null;
    return await getSignedUrl('ktp', path);
  }

  // BUCKET: dokumen_qris (PRIVATE)
  static Future<String?> qrisImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    return await getSignedUrl('qr_qris', path);
  }

  // BUCKET: bukti_bayar (PRIVATE)
  static Future<String?> buktiBayar(String? path) async {
    if (path == null || path.isEmpty) return null;
    return await getSignedUrl('bukti_bayar', path);
  }

  static String getDefaultAvatar(String? role) {
    if (role == 'admin') {
      return 'https://ui-avatars.com/api/?background=C9A227&color=020C15&name=Admin';
    }
    return 'https://ui-avatars.com/api/?background=2A3A48&color=C4C7CB&name=Tim';
  }
}