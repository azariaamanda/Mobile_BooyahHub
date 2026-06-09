// lib/data/models/services/auth_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_client.dart';
import '../akun_model.dart';
import '../profil_model.dart';

class AuthService {
  final _supabase = SupabaseClientHelper.client;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ============================================================
  // LOGIN - TANPA SUPABASE AUTH (LANGSUNG CEK DATABASE)
  // ============================================================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password, // password sudah dalam bentuk hash dari UI
  }) async {
    try {
      // Cari user di tabel akun berdasarkan email
      final userData = await _supabase
          .from('akun')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (userData == null) {
        return {'success': false, 'message': 'Email tidak terdaftar'};
      }

      // Bandingkan hash password
      if (userData['kata_sandi'] != password) {
        return {'success': false, 'message': 'Password salah'};
      }

      // Cek status akun
      final statusAkun = userData['status_akun'];
      if (statusAkun != 'aktif') {
        return {'success': false, 'message': 'Akun Anda belum aktif atau diblokir'};
      }

      // Optional: Login ke Supabase Auth untuk session (pakai password asli, bukan hash)
      // Tapi karena kita sudah verifikasi, bisa skip atau pakai hash juga
      try {
        // Untuk session, kita perlu password asli. Tapi kita tidak punya.
        // Jadi lebih baik tidak pakai Supabase Auth session.
        // await _supabase.auth.signInWithPassword(
        //   email: email,
        //   password: password, // ini hash, bakal gagal
        // );
      } catch (_) {}

      final akun = Akun.fromJson(userData);

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
    required String password, // password sudah dalam bentuk hash
  }) async {
    try {
      final akunData = await _supabase
          .from('akun')
          .insert({
            'email': email,
            'kata_sandi': password,
            'role': 'pengguna',
            'status_akun': 'aktif'
          })
          .select()
          .single();

      final akun = Akun.fromJson(akunData);

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
    required String password, // password sudah dalam bentuk hash
    String? fotoProfilPath,
    required String fotoKtpPath,
  }) async {
    try {
      final akunData = await _supabase
          .from('akun')
          .insert({
            'email': email,
            'kata_sandi': password,
            'role': 'admin',
            'status_akun': 'pending'
          })
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
    required String password, // password sudah dalam bentuk hash
    String? bankOwner,
    String? nomorRekening,
  }) async {
    try {
      final akunData = await _supabase
          .from('akun')
          .insert({
            'email': email,
            'kata_sandi': password,
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
    Uint8List? newFotoProfil,
  }) async {
    try {
      if (!isLoggedIn) return {'success': false, 'message': 'Belum login'};
      
      final email = currentUser!.email!;

      if (oldPassword != null && oldPassword.isNotEmpty && newPassword != null && newPassword.isNotEmpty) {
        // Cek password lama dengan hash
        final userData = await _supabase
            .from('akun')
            .select('kata_sandi')
            .eq('email', email)
            .single();
        
        final hashedOldPassword = _hashPassword(oldPassword);
        if (userData['kata_sandi'] != hashedOldPassword) {
          return {'success': false, 'message': 'Password lama salah'};
        }

        final hashedNewPassword = _hashPassword(newPassword);
        
        // Update password di database
        await _supabase
            .from('akun')
            .update({'kata_sandi': hashedNewPassword})
            .eq('email', email);
      }

      // Upload foto profil jika ada
      String? publicUrl;
      if (newFotoProfil != null) {
        final fileName = '${currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('foto_profil').uploadBinary(
          fileName,
          newFotoProfil,
          fileOptions: const FileOptions(upsert: true),
        );
        publicUrl = _supabase.storage.from('foto_profil').getPublicUrl(fileName);
      }

      // Update nama profil
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