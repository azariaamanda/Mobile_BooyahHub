// lib/services/admin_utang_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUtangService {
  final _supabase = Supabase.instance.client;
  
  // Fee per slot (Rp 1.000 per slot)
  static const double FEE_PER_SLOT = 1000;

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================
  String formatRupiah(double value) {
    return 'Rp ${value.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  // ============================================================
  // TAMBAH UTANG SAAT ADMIN VERIFIKASI PENDAFTARAN
  // ============================================================
  Future<Map<String, dynamic>> tambahUtang({
    required int adminId,
    required int jumlahSlot,
  }) async {
    try {
      final fee = FEE_PER_SLOT * jumlahSlot;

      final adminData = await _supabase
          .from('akun')
          .select('''
            id_akun,
            status_akun,
            profil_admin!inner (
              total_utang,
              limit_utang
            )
          ''')
          .eq('id_akun', adminId)
          .single();

      final profil = adminData['profil_admin'] as Map<String, dynamic>;
      final double totalUtangSekarang = (profil['total_utang'] ?? 0).toDouble();
      final double limitUtang = (profil['limit_utang'] ?? 100000).toDouble();
      final double totalUtangBaru = totalUtangSekarang + fee;
      
      final bool melebihiLimit = totalUtangBaru >= limitUtang;
      final String statusBaru = melebihiLimit ? 'suspended' : adminData['status_akun'];

      await _supabase
          .from('profil_admin')
          .update({'total_utang': totalUtangBaru})
          .eq('akun_id', adminId);

      if (melebihiLimit) {
        await _supabase
            .from('akun')
            .update({'status_akun': 'suspended'})
            .eq('id_akun', adminId);
      }

      await _supabase.from('transaksi_fee_admin').insert({
        'admin_id': adminId,
        'nominal': fee,
        'jumlah_slot': jumlahSlot,
        'sisa_limit_setelah': limitUtang - totalUtangBaru,
      });

      return {
        'success': true,
        'total_utang_baru': totalUtangBaru,
        'melebihi_limit': melebihiLimit,
        'status_baru': statusBaru,
        'message': melebihiLimit 
            ? 'Akun telah mencapai limit utang. Silakan lunasi tagihan.'
            : 'Berhasil diverifikasi.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal menambah utang: $e'};
    }
  }

  // ============================================================
  // HITUNG UTANG DINAMIS
  // Utang = fee platform dari pendaftaran dikonfirmasi di scrim aktif
  // Rumus per scrim: biaya_pendaftaran × jumlah_dikonfirmasi × fee_platform_persen/100
  //                  (minimum nominal_minimum_platform jika ada pendaftaran)
  // ============================================================
  Future<double> hitungUtangDinamis(int adminId) async {
    try {
      // Ambil pengaturan fee platform
      final feeSettings = await _supabase
          .from('pengaturan_fee')
          .select('fee_platform_persen')
          .maybeSingle();
      final int feePersen = (feeSettings?['fee_platform_persen'] as num? ?? 25).toInt();

      // Ambil scrim aktif milik admin beserta biaya_pendaftaran
      final scrims = await _supabase
          .from('scrim')
          .select('id_scrim, biaya_pendaftaran')
          .eq('id_admin', adminId)
          .eq('status_scrim', 'aktif');

      if ((scrims as List).isEmpty) return 0;

      final scrimBiayaMap = <int, double>{
        for (var s in scrims)
          s['id_scrim'] as int: (s['biaya_pendaftaran'] as num? ?? 0).toDouble(),
      };
      final scrimIds = scrimBiayaMap.keys.toList();

      // Ambil sesi dari scrim aktif
      final sesis = await _supabase
          .from('sesi_scrim')
          .select('id_sesi, id_scrim')
          .inFilter('id_scrim', scrimIds);

      if ((sesis as List).isEmpty) return 0;

      final sesiToScrim = <int, int>{
        for (var s in sesis) s['id_sesi'] as int: s['id_scrim'] as int,
      };
      final sesiIds = sesiToScrim.keys.toList();

      // Hitung pendaftaran dikonfirmasi per scrim
      final pendaftaran = await _supabase
          .from('pendaftaran_tim')
          .select('id_sesi')
          .inFilter('id_sesi', sesiIds)
          .eq('status_pembayaran', 'dikonfirmasi');

      final Map<int, int> countPerScrim = {};
      for (final p in pendaftaran as List) {
        final scrimId = sesiToScrim[p['id_sesi'] as int] ?? 0;
        if (scrimId != 0) countPerScrim[scrimId] = (countPerScrim[scrimId] ?? 0) + 1;
      }

      // Hitung total utang fee platform per scrim
      double totalUtang = 0;
      for (final entry in countPerScrim.entries) {
        final biaya = scrimBiayaMap[entry.key] ?? 0;
        final rawFee = biaya * entry.value * feePersen / 100;
        totalUtang += rawFee;
      }

      return totalUtang;
    } catch (e) {
      debugPrint('Error hitungUtangDinamis: $e');
      return 0;
    }
  }

  // ============================================================
  // CEK STATUS ADMIN
  // ============================================================
  Future<Map<String, dynamic>> cekStatusAdmin(int adminId) async {
    try {
      final data = await _supabase
          .from('akun')
          .select('''
            id_akun,
            status_akun,
            profil_admin!inner (
              limit_utang
            )
          ''')
          .eq('id_akun', adminId)
          .single();

      final profil = data['profil_admin'] as Map<String, dynamic>;
      final double limitUtang = (profil['limit_utang'] ?? 100000).toDouble();
      final String statusAkun = data['status_akun'];

      // Hitung utang dari scrim yang masih aktif (belum selesai)
      final double totalUtang = await hitungUtangDinamis(adminId);

      final bool melebihiLimit = totalUtang >= limitUtang;
      final bool bisaBuatScrim = statusAkun == 'aktif' && !melebihiLimit;

      if (melebihiLimit && statusAkun != 'suspended') {
        await _supabase
            .from('akun')
            .update({'status_akun': 'suspended'})
            .eq('id_akun', adminId);
      }

      return {
        'success': true,
        'status_akun': melebihiLimit ? 'suspended' : statusAkun,
        'total_utang': totalUtang,
        'limit_utang': limitUtang,
        'bisa_buat_scrim': bisaBuatScrim,
        'sisa_limit': limitUtang - totalUtang,
        'message': bisaBuatScrim
            ? 'Aman. Sisa limit: ${formatRupiah(limitUtang - totalUtang)}'
            : 'Akun ditangguhkan. Silakan lunasi tagihan.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal cek status: $e'};
    }
  }

  // ============================================================
  // ADMIN AJUKAN PELUNASAN (UPLOAD BUKTI)
  // ============================================================
  Future<Map<String, dynamic>> ajukanPelunasan({
    required int adminId,
    required double nominal,
    required String buktiBayarUrl,
    required String metodeBayar,
    String? catatan,
  }) async {
    try {
      final profilData = await _supabase
          .from('profil_admin')
          .select('total_utang')
          .eq('akun_id', adminId)
          .single();
      
      final double totalUtang = (profilData['total_utang'] ?? 0).toDouble();
      
      if (nominal > totalUtang) {
        return {'success': false, 'message': 'Nominal melebihi total utang'};
      }

      final result = await _supabase
          .from('pelunasan_utang_admin')
          .insert({
            'admin_id': adminId,
            'nominal': nominal,
            'bukti_bayar': buktiBayarUrl,
            'metode_bayar': metodeBayar,
            'catatan': catatan,
            'status': 'menunggu',
          })
          .select()
          .single();

      return {
        'success': true,
        'id_pelunasan': result['id_pelunasan'],
        'message': 'Bukti pembayaran terkirim. Menunggu verifikasi owner.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengajukan: $e'};
    }
  }

  // ============================================================
  // OWNER VERIFIKASI PELUNASAN ADMIN
  // ============================================================
  Future<Map<String, dynamic>> verifikasiPelunasan({
    required int idPelunasan,
    required int adminId,
    required bool disetujui,
    String? alasanPenolakan,
  }) async {
    try {
      if (disetujui) {
        final pelunasan = await _supabase
            .from('pelunasan_utang_admin')
            .select('nominal')
            .eq('id_pelunasan', idPelunasan)
            .single();
        
        final double nominalBayar = (pelunasan['nominal'] ?? 0).toDouble();

        final profilData = await _supabase
            .from('profil_admin')
            .select('total_utang')
            .eq('akun_id', adminId)
            .single();
        
        final double totalUtangSekarang = (profilData['total_utang'] ?? 0).toDouble();
        final double totalUtangBaru = (totalUtangSekarang - nominalBayar).clamp(0, double.infinity);

        await _supabase
            .from('pelunasan_utang_admin')
            .update({
              'status': 'diverifikasi',
              'diverifikasi_pada': DateTime.now().toIso8601String(),
            })
            .eq('id_pelunasan', idPelunasan);

        await _supabase
            .from('profil_admin')
            .update({'total_utang': totalUtangBaru})
            .eq('akun_id', adminId);

        await _supabase
            .from('akun')
            .update({'status_akun': 'aktif'})
            .eq('id_akun', adminId);

        return {
          'success': true,
          'message': 'Pelunasan diverifikasi. Sisa utang: ${formatRupiah(totalUtangBaru)}',
        };
      } else {
        await _supabase
            .from('pelunasan_utang_admin')
            .update({
              'status': 'ditolak',
              'alasan_penolakan': alasanPenolakan,
            })
            .eq('id_pelunasan', idPelunasan);

        return {
          'success': true,
          'message': 'Pelunasan ditolak: $alasanPenolakan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal verifikasi: $e'};
    }
  }

  // ============================================================
  // OWNER UPDATE LIMIT UTANG ADMIN
  // ============================================================
  Future<Map<String, dynamic>> updateLimitUtang({
    required int adminId,
    required double limitBaru,
  }) async {
    try {
      await _supabase
          .from('profil_admin')
          .update({'limit_utang': limitBaru})
          .eq('akun_id', adminId);

      return {'success': true, 'message': 'Limit utang berhasil diupdate'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal update limit: $e'};
    }
  }

  // ============================================================
  // AMBIL DAFTAR SEMUA ADMIN (UNTUK OWNER)
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllAdmin() async {
    try {
      final response = await _supabase
          .from('akun')
          .select('''
            id_akun,
            email,
            status_akun,
            profil_admin (
              id_profil_admin,
              nama_lengkap,
              no_handphone,
              total_utang,
              limit_utang,
              status_verifikasi_ktp
            )
          ''')
          .eq('role', 'admin');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getAllAdmin: $e');
      return [];
    }
  }

  // ============================================================
  // AMBIL DAFTAR SEMUA ADMIN DENGAN URUTAN (UNTUK OWNER)
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllAdminWithUtang() async {
    try {
      final response = await _supabase
          .from('akun')
          .select('''
            id_akun,
            email,
            status_akun,
            dibuat_pada,
            profil_admin (
              id_profil_admin,
              nama_lengkap,
              no_handphone,
              total_utang,
              limit_utang,
              status_verifikasi_ktp
            )
          ''')
          .eq('role', 'admin')
          .order('id_akun', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getAllAdminWithUtang: $e');
      return [];
    }
  }

  // ============================================================
  // RESET TOTAL UTANG ADMIN (UNTUK OWNER)
  // ============================================================
  Future<Map<String, dynamic>> resetUtangAdmin({
    required int adminId,
  }) async {
    try {
      await _supabase
          .from('profil_admin')
          .update({'total_utang': 0})
          .eq('akun_id', adminId);

      await _supabase
          .from('akun')
          .update({'status_akun': 'aktif'})
          .eq('id_akun', adminId);

      return {'success': true, 'message': 'Utang admin berhasil direset ke 0'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal reset utang: $e'};
    }
  }

  Future<String?> getSignedUrlForPelunasan(String filePath) async {
    try {
      final signedUrl = await _supabase.storage
          .from('bukti_bayar')
          .createSignedUrl(filePath, 3600);
      return signedUrl;
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      return null;
    }
  }
}