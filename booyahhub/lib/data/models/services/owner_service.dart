import '../../../config/supabase_client.dart';

import '../profil_model.dart';
import '../keuangan_model.dart';
import '../klaim_model.dart';

class OwnerService {
  final _supabase = SupabaseClientHelper.client;

  // ============================================================
  // GET ALL PENDING ADMIN VERIFICATIONS
  // ============================================================
  Future<List<ProfilAdmin>> getPendingAdminVerifications() async {
    try {
      final response = await _supabase
          .from('profil_admin')
          .select('''
            *,
            akun:akun(*)
          ''')
          .eq('status_verifikasi_ktp', 'pending');

      return response.map((json) => ProfilAdmin.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // VERIFY ADMIN KTP
  // ============================================================
  Future<Map<String, dynamic>> verifyAdminKtp({
    required int idAkun,
    required bool diterima,
    String? alasanPenolakan,
  }) async {
    try {
      final status = diterima ? 'terverifikasi' : 'ditolak';

      // Update status verifikasi admin
      await _supabase
          .from('profil_admin')
          .update({'status_verifikasi_ktp': status})
          .eq('akun_id', idAkun);

      // Jika diterima, update status akun menjadi aktif
      if (diterima) {
        await _supabase
            .from('akun')
            .update({'status_akun': 'aktif'})
            .eq('id_akun', idAkun);
      }

      return {
        'success': true,
        'message': diterima ? 'Admin diverifikasi' : 'Admin ditolak',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ============================================================
  // GET FINANCIAL REPORT (KEUANGAN SCRIM)
  // ============================================================
  Future<List<KeuanganScrim>> getFinancialReport() async {
    try {
      final response = await _supabase
          .from('keuangan_scrim')
          .select('''
            *,
            scrim:scrim(*)
          ''')
          .order('dibuat_pada', ascending: false);

      return response.map((json) => KeuanganScrim.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // GET TOTAL REVENUE (PENDAPATAN PLATFORM)
  // ============================================================
  Future<Map<String, dynamic>> getTotalRevenue() async {
    try {
      final response = await _supabase
          .from('keuangan_scrim')
          .select('total_pendaftaran, fee_platform_5persen, fee_admin_10persen');

      double totalPendaftaran = 0;
      double totalFeePlatform = 0;
      double totalFeeAdmin = 0;

      for (var item in response) {
        totalPendaftaran += (item['total_pendaftaran'] ?? 0).toDouble();
        totalFeePlatform += (item['fee_platform_5persen'] ?? 0).toDouble();
        totalFeeAdmin += (item['fee_admin_10persen'] ?? 0).toDouble();
      }

      return {
        'total_pendaftaran': totalPendaftaran,
        'total_fee_platform': totalFeePlatform,
        'total_fee_admin': totalFeeAdmin,
        'total_pendapatan_platform': totalFeePlatform + totalFeeAdmin,
      };
    } catch (e) {
      return {
        'total_pendaftaran': 0,
        'total_fee_platform': 0,
        'total_fee_admin': 0,
        'total_pendapatan_platform': 0,
      };
    }
  }

  // ============================================================
  // GET KLAIM MENUNGGU OWNER
  // ============================================================
  Future<List<KlaimHadiah>> getClaimsWaitingForOwner() async {
    try {
      final response = await _supabase
          .from('klaim_hadiah')
          .select('''
            *,
            pendaftaran:pendaftaran_tim(
              *,
              tim:akun(*),
              sesi:sesi_scrim(scrim:scrim(*))
            )
          ''')
          .eq('status_klaim', 'disetujui_admin')
          .order('disetujui_admin_pada', ascending: true);

      return response.map((json) => KlaimHadiah.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // OWNER APPROVE PAYMENT (CAIRKAN DANA)
  // ============================================================
  Future<Map<String, dynamic>> approvePayment(int idKlaim) async {
    try {
      await _supabase.from('klaim_hadiah').update({
        'status_klaim': 'dibayar',
        'dibayar_pada': DateTime.now().toIso8601String(),
      }).eq('id_klaim', idKlaim);

      return {
        'success': true,
        'message': 'Pembayaran klaim berhasil dicairkan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ============================================================
  // GET DASHBOARD STATS (UNTUK OWNER DASHBOARD)
  // ============================================================
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Total admin pending
      final pendingAdminRows = await _supabase
          .from('profil_admin')
          .select('id_profil_admin')
          .eq('status_verifikasi_ktp', 'pending');

      // Total klaim pending
      final pendingClaimsRows = await _supabase
          .from('klaim_hadiah')
          .select('id_klaim')
          .eq('status_klaim', 'disetujui_admin');

      // Total scrim aktif
      final activeScrimRows = await _supabase
          .from('scrim')
          .select('id_scrim')
          .eq('status_scrim', 'aktif');

      // Total pendapatan platform
      final revenue = await getTotalRevenue();

      return {
        'total_admin_pending': pendingAdminRows.length,
        'total_claims_pending': pendingClaimsRows.length,
        'total_scrim_aktif': activeScrimRows.length,
        'total_pendapatan_platform': revenue['total_pendapatan_platform'],
      };
    } catch (e) {
      return {
        'total_admin_pending': 0,
        'total_claims_pending': 0,
        'total_scrim_aktif': 0,
        'total_pendapatan_platform': 0,
      };
    }
  }
}