import 'supabase_client.dart';


class AppImageHelper {
  AppImageHelper._();

  static final _supabase = SupabaseClientHelper.client;

  static String getPublicUrl(String bucket, String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  static String getPrivateUrl(String bucket, String? path) {
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
  static String fotoKtp(String? path) =>
      getPrivateUrl('ktp', path);

  // BUCKET: bukti_bayar (Private)
  static String buktiBayar(String? path) =>
      getPrivateUrl('bukti_bayar', path);

  static String getDefaultAvatar(String? role) {
    if (role == 'admin') {
      return 'https://ui-avatars.com/api/?background=C9A227&color=020C15&name=Admin';
    }
    return 'https://ui-avatars.com/api/?background=2A3A48&color=C4C7CB&name=Tim';
  }
}