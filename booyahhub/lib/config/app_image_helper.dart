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

  // BUCKET: foto_profil (Public)
  static String fotoProfil(String? path) =>
      getPublicUrl('foto_profil', path);

  static String fotoProfilByEmail(String? email, {String defaultFile = 'foto.jpg'}) {
    if (email == null || email.isEmpty) return '';
    return getPublicUrl('foto_profil', '$email/$defaultFile');
  }

  // BUCKET: posters (Public)
  static String posterScrim(String? path) =>
      getPublicUrl('posters', path);

  static String posterByIdScrim(int? idScrim) {
    if (idScrim == null) return '';
    return getPublicUrl('posters', '$idScrim/poster.jpg');
  }

  // BUCKET: ktp (Private)
  static Future<String?> fotoKtp(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      return await _supabase.storage.from('ktp').createSignedUrl(path, 3600);
    } catch (e) {
      debugPrint('Error getting signed URL for ktp: $e');
      return null;
    }
  }

  // BUCKET: bukti_bayar (Private)
  static Future<String?> buktiBayar(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    
    try {
      final signedUrl = await _supabase.storage
          .from('bukti_bayar')
          .createSignedUrl(path, 3600);
      debugPrint('Signed URL: $signedUrl');
      return signedUrl;
    } catch (e) {
      debugPrint('Error getting signed URL for bukti_bayar: $e');
      return null;
    }
  }

  static String getDefaultAvatar(String? role) {
    if (role == 'admin') {
      return 'https://ui-avatars.com/api/?background=C9A227&color=020C15&name=Admin';
    }
    return 'https://ui-avatars.com/api/?background=2A3A48&color=C4C7CB&name=Tim';
  }
}