import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_client.dart';
import '../akun_model.dart';
import '../profil_model.dart';

class AuthService {
  final _supabase = SupabaseClientHelper.client;

  // ============================================================
  // LOGIN
  // ============================================================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Login ke Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {'success': false, 'message': 'Email atau password salah'};
      }

      // 2. Ambil data akun dari tabel akun
      final userData = await _supabase
          .from('akun')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (userData == null) {
        return {
          'success': false,
          'message': 'Data akun tidak ditemukan di database',
        };
      }

      final akun = Akun.fromJson(userData);

      // 3. Ambil profil sesuai role
      Map<String, dynamic> profil = {};
      if (akun.role == 'pengguna') {
        final profilData = await _supabase
            .from('profil_pengguna')
            .select()
            .eq('akun_id', akun.idAkun)
            .maybeSingle();
        if (profilData != null) {
          profil = ProfilPengguna.fromJson(profilData).toJson();
        }
      } else if (akun.role == 'admin') {
        final profilData = await _supabase
            .from('profil_admin')
            .select()
            .eq('akun_id', akun.idAkun)
            .maybeSingle();
        if (profilData != null) {
          profil = ProfilAdmin.fromJson(profilData).toJson();
        }
      } else if (akun.role == 'owner') {
        final profilData = await _supabase
            .from('profil_owner')
            .select()
            .eq('akun_id', akun.idAkun)
            .maybeSingle();
        if (profilData != null) {
          profil = profilData;
        }
      }

      return {
        'success': true,
        'message': 'Login berhasil',
        'akun': akun,
        'profil': profil,
        'role': akun.role,
      };
    } on AuthException catch (e) {
      // Pesan error Supabase Auth lebih spesifik
      String message = 'Email atau password salah';
      if (e.message.contains('Email not confirmed')) {
        message = 'Email belum dikonfirmasi. Cek inbox kamu.';
      } else if (e.message.contains('Invalid login credentials')) {
        message = 'Email atau password salah';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============================================================
  // REGISTER PENGGUNA (TIM)
  // ============================================================
  Future<Map<String, dynamic>> registerPengguna({
    required String namaTim,
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Gagal membuat akun'};
      }

      final akunData = await _supabase
          .from('akun')
          .insert({'email': email, 'role': 'pengguna', 'status_akun': 'aktif'})
          .select()
          .single();

      final akun = Akun.fromJson(akunData);

      // 3. Insert ke tabel profil_pengguna
      final profilData = await _supabase
          .from('profil_pengguna')
          .insert({'akun_id': akun.idAkun, 'nama_tim': namaTim})
          .select()
          .single();

      final profil = ProfilPengguna.fromJson(profilData);

      return {
        'success': true,
        'message': 'Pendaftaran berhasil! Silakan login.',
        'akun': akun,
        'profil': profil,
      };
    } on AuthException catch (e) {
      String message = 'Gagal mendaftar';
      if (e.message.contains('over_email_send_rate_limit')) {
        message =
            'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi.';
      } else if (e.message.contains('User already registered')) {
        message = 'Email sudah terdaftar. Silakan login.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============================================================
  // REGISTER ADMIN
  // ============================================================
  Future<Map<String, dynamic>> registerAdmin({
    required String namaLengkap,
    required String email,
    required String noHandphone,
    required String password,
    String? fotoProfilPath,
    required String fotoKtpPath,
  }) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Gagal membuat akun'};
      }

      final akunData = await _supabase
          .from('akun')
          .insert({'email': email, 'role': 'admin', 'status_akun': 'pending'})
          .select()
          .single();

      final akun = Akun.fromJson(akunData);

      final profilData = await _supabase
          .from('profil_admin')
          .insert({
            'akun_id': akun.idAkun,
            'nama_lengkap': namaLengkap,
            'no_handphone': noHandphone,
            'foto_profil': fotoProfilPath,
            'foto_ktp': fotoKtpPath,
            'status_verifikasi_ktp': 'pending',
          })
          .select()
          .single();

      final profil = ProfilAdmin.fromJson(profilData);

      return {
        'success': true,
        'message': 'Pendaftaran admin berhasil! Menunggu verifikasi owner.',
        'akun': akun,
        'profil': profil,
      };
    } on AuthException catch (e) {
      String message = 'Gagal mendaftar';
      if (e.message.contains('over_email_send_rate_limit')) {
        message =
            'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi.';
      } else if (e.message.contains('User already registered')) {
        message = 'Email sudah terdaftar.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

    // ============================================================
  // REGISTER OWNER
  // ============================================================
  Future<Map<String, dynamic>> registerOwner({
    required String namaLengkap,
    required String email,
    required String noHandphone,
    required String password,
    String? bankOwner,
    String? nomorRekening,
  }) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Gagal membuat akun'};
      }

      final akunData = await _supabase
          .from('akun')
          .insert({
            'email': email,
            'role': 'owner',
            'status_akun': 'aktif'
          })
          .select()
          .single();

      final akun = Akun.fromJson(akunData);

      final profilData = await _supabase
          .from('profil_owner')
          .insert({
            'akun_id': akun.idAkun,
            'nama_lengkap': namaLengkap,
            'no_handphone': noHandphone,
            'bank_owner': bankOwner,
            'nomor_rekening': nomorRekening,
            'foto_profil': null,
          })
          .select()
          .single();

      return {
        'success': true,
        'message': 'Pendaftaran owner berhasil! Silakan login.',
        'akun': akun,
        'profil': profilData,
      };
    } on AuthException catch (e) {
      String message = 'Gagal mendaftar';
      if (e.message.contains('over_email_send_rate_limit')) {
        message = 'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi.';
      } else if (e.message.contains('User already registered')) {
        message = 'Email sudah terdaftar. Silakan login.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ============================================================
  // GET CURRENT USER
  // ============================================================
  User? get currentUser => _supabase.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  // ============================================================
  // GET CURRENT AKUN & PROFIL
  // ============================================================
  Future<Map<String, dynamic>?> getCurrentAkunAndProfil() async {
    if (!isLoggedIn) return null;

    final email = currentUser!.email!;

    try {
      final akunData = await _supabase
          .from('akun')
          .select()
          .eq('email', email)
          .single();

      final akun = Akun.fromJson(akunData);

      Map<String, dynamic>? profil;

      if (akun.role == 'pengguna') {
        final profilData = await _supabase
            .from('profil_pengguna')
            .select()
            .eq('akun_id', akun.idAkun)
            .maybeSingle();
        if (profilData != null) profil = profilData;
      } else if (akun.role == 'admin') {
        final profilData = await _supabase
            .from('profil_admin')
            .select()
            .eq('akun_id', akun.idAkun)
            .maybeSingle();
        if (profilData != null) profil = profilData;
      } else if (akun.role == 'owner') {
        final profilData = await _supabase
            .from('profil_owner')
            .select()
            .eq('akun_id', akun.idAkun)
            .maybeSingle();
        if (profilData != null) profil = profilData;
      }

      return {'akun': akun, 'profil': profil, 'role': akun.role};
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // UPDATE PROFIL & PASSWORD
  // ============================================================
  Future<Map<String, dynamic>> updateProfileAndPassword({
    String? newName,
    String? oldPassword,
    String? newPassword,
    File? newFotoProfil,
  }) async {
    try {
      if (!isLoggedIn) return {'success': false, 'message': 'Belum login'};
      
      final email = currentUser!.email!;

      // 1. Verifikasi Password Lama & Update Password Baru
      if (oldPassword != null && oldPassword.isNotEmpty && newPassword != null && newPassword.isNotEmpty) {
        try {
          // Re-authenticate untuk memastikan password lama benar
          await _supabase.auth.signInWithPassword(email: email, password: oldPassword);
        } catch (e) {
          return {'success': false, 'message': 'Password lama salah'};
        }

        // Update ke password baru
        await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      }

      // 2. Upload Foto Profil jika ada
      String? publicUrl;
      String? publicUrlClean;
      if (newFotoProfil != null) {
        final ext = newFotoProfil.path.split('.').last;
        final path = 'pengguna/${currentUser!.id}/avatar.$ext';
        
        // Upload foto dengan upsert=true agar menimpa foto lama
        await _supabase.storage.from('foto_profil').upload(
          path,
          newFotoProfil,
          fileOptions: const FileOptions(upsert: true),
        );
        publicUrlClean = _supabase.storage.from('foto_profil').getPublicUrl(path);
        // URL bersih untuk disimpan ke database
        publicUrl = publicUrlClean;
      }

      // 3. Update Nama Profil (dan Foto jika ada)
      if ((newName != null && newName.isNotEmpty) || publicUrl != null) {
        final akunData = await _supabase.from('akun').select().eq('email', email).single();
        final role = akunData['role'];
        final akunId = akunData['id_akun'];
        
        final Map<String, dynamic> updateData = {};
        if (newName != null && newName.isNotEmpty) {
          if (role == 'pengguna') updateData['nama_tim'] = newName;
          if (role == 'admin') updateData['nama_lengkap'] = newName;
          if (role == 'owner') updateData['nama_lengkap'] = newName;
        }
        if (publicUrl != null) {
          updateData['foto_profil'] = publicUrl;
        }

        if (updateData.isNotEmpty) {
          if (role == 'pengguna') {
            await _supabase.from('profil_pengguna').update(updateData).eq('akun_id', akunId);
          } else if (role == 'admin') {
            await _supabase.from('profil_admin').update(updateData).eq('akun_id', akunId);
          } else if (role == 'owner') {
            await _supabase.from('profil_owner').update(updateData).eq('akun_id', akunId);
          }
        }
      }

      return {'success': true, 'message': 'Profil berhasil diperbarui'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}