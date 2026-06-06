import '../../../config/supabase_client.dart';

import '../scrim_model.dart';
import '../pendaftaran_model.dart';
import '../klaim_model.dart';

class AdminService {
  final _supabase = SupabaseClientHelper.client;

  // ============================================================
  // GET MY SCRIM LIST (untuk dashboard admin)
  // ============================================================
  Future<List<Scrim>> getMyScrimList(int idAdmin) async {
    try {
      final response = await _supabase
          .from('scrim')
          .select('''
            *,
            sesi_scrim(*),
            mode_pertandingan:master_mode_pertandingan(*)
          ''')
          .eq('id_admin', idAdmin)
          .order('dibuat_pada', ascending: false);

      return response.map((json) => Scrim.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // CREATE SCRIM BARU
  // ============================================================
  Future<Map<String, dynamic>> createScrim({
    required int idAdmin,
    required int idMode,
    required String namaScrim,
    required double biayaPendaftaran,
    required double totalHadiah,
    required int maksPeserta,
    required int jumlahMatch,
    String? deskripsi,
    String? syaratKetentuan,
    String? poster,
  }) async {
    try {
      final response = await _supabase.from('scrim').insert({
        'id_admin': idAdmin,
        'id_mode': idMode,
        'nama_scrim': namaScrim,
        'biaya_pendaftaran': biayaPendaftaran,
        'total_hadiah': totalHadiah,
        'maks_peserta': maksPeserta,
        'jumlah_match': jumlahMatch,
        'deskripsi': deskripsi,
        'syarat_ketentuan': syaratKetentuan,
        'poster': poster,
        'status_scrim': 'aktif',
      }).select().single();

      return {
        'success': true,
        'message': 'Scrim berhasil dibuat',
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ============================================================
  // TAMBAH SESI SCRIM
  // ============================================================
  Future<Map<String, dynamic>> addSesiScrim({
    required int idScrim,
    required String namaSesi,
    required DateTime waktuMulai,
    required DateTime waktuSelesai,
    required int slotMaksimal,
  }) async {
    try {
      final response = await _supabase.from('sesi_scrim').insert({
        'id_scrim': idScrim,
        'nama_sesi': namaSesi,
        'waktu_mulai': waktuMulai.toIso8601String(),
        'waktu_selesai': waktuSelesai.toIso8601String(),
        'slot_maksimal': slotMaksimal,
      }).select().single();

      return {
        'success': true,
        'message': 'Sesi berhasil ditambahkan',
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ============================================================
  // GET PENDING PAYMENTS (PENDAFTARAN MENUNGGU VERIFIKASI)
  // ============================================================
  Future<List<PendaftaranTim>> getPendingPayments(int idScrim) async {
    try {
      final response = await _supabase
          .from('pendaftaran_tim')
          .select('''
            *,
            tim:akun(*),
            sesi:sesi_scrim(*)
          ''')
          .eq('sesi_scrim.id_scrim', idScrim)
          .eq('status_pembayaran', 'menunggu');

      return response.map((json) => PendaftaranTim.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // VERIFIKASI PEMBAYARAN
  // ============================================================
  Future<Map<String, dynamic>> verifikasiPembayaran({
    required int idPendaftaran,
    required bool diterima,
    String? alasanPenolakan,
  }) async {
    try {
      final status = diterima ? 'dikonfirmasi' : 'ditolak';

      await _supabase.from('pendaftaran_tim').update({
        'status_pembayaran': status,
        'diverifikasi_pada': DateTime.now().toIso8601String(),
        if (!diterima && alasanPenolakan != null)
          'alasan_penolakan': alasanPenolakan,
      }).eq('id_pendaftaran', idPendaftaran);

      return {
        'success': true,
        'message': diterima ? 'Pembayaran diverifikasi' : 'Pembayaran ditolak',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ============================================================
  // INPUT SCORE MATCH
  // ============================================================
  Future<Map<String, dynamic>> inputScore({
    required int idPendaftaran,
    required int idSesi,
    required int matchKe,
    required int peringkat,
    required int poinPlacement,
    required int totalKill,
  }) async {
    try {
      final totalPoin = poinPlacement + totalKill;

      final existing = await _supabase
          .from('hasil_pertandingan')
          .select()
          .eq('id_pendaftaran', idPendaftaran)
          .eq('match_ke', matchKe)
          .maybeSingle();

      if (existing != null) {
        // Langsung cast ke int (lebih sederhana)
        final idHasilValue = existing['id_hasil'] as int;
        
        await _supabase.from('hasil_pertandingan').update({
          'peringkat': peringkat,
          'poin_placement': poinPlacement,
          'total_kill': totalKill,
          'total_poin': totalPoin,
        }).eq('id_hasil', idHasilValue);
      } else {
        await _supabase.from('hasil_pertandingan').insert({
          'id_pendaftaran': idPendaftaran,
          'id_sesi': idSesi,
          'match_ke': matchKe,
          'peringkat': peringkat,
          'poin_placement': poinPlacement,
          'total_kill': totalKill,
          'total_poin': totalPoin,
        });
      }

      return {
        'success': true,
        'message': 'Skor berhasil disimpan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ============================================================
  // BAGI HADIAH — panggil SQL function fn_bagi_hadiah via RPC
  // Dipanggil setelah admin selesai input skor semua match.
  // Function ini otomatis membuat klaim_hadiah untuk juara 1/2/3
  // berdasarkan leaderboard hasil_pertandingan.
  // ============================================================
  Future<Map<String, dynamic>> bagiHadiah(int idSesi) async {
    try {
      final result = await _supabase.rpc(
        'fn_bagi_hadiah',
        params: {'p_id_sesi': idSesi},
      );

      final data = result as Map<String, dynamic>;
      final bool success = data['success'] as bool? ?? false;
      final String message = data['message'] as String? ?? '';

      return {'success': success, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal membagi hadiah: $e',
      };
    }
  }

  // ============================================================
  // GET KLAIM MENUNGGU ADMIN
  // ============================================================
  Future<List<KlaimHadiah>> getPendingClaims() async {
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
          .eq('status_klaim', 'diajukan')
          .order('diajukan_pada', ascending: true);

      return response.map((json) => KlaimHadiah.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // ADMIN APPROVE KLAIM
  // ============================================================
  Future<Map<String, dynamic>> approveClaim(int idKlaim) async {
    try {
      await _supabase.from('klaim_hadiah').update({
        'status_klaim': 'disetujui_admin',
        'disetujui_admin_pada': DateTime.now().toIso8601String(),
      }).eq('id_klaim', idKlaim);

      return {
        'success': true,
        'message': 'Klaim disetujui, diteruskan ke owner',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ============================================================
  // GET METODE PEMBAYARAN ADMIN
  // ============================================================
  Future<List<Map<String, dynamic>>> getPaymentMethods(int idAdmin) async {
    try {
      final response = await _supabase
          .from('metode_pembayaran_penyelenggara')
          .select()
          .eq('id_admin', idAdmin)
          .order('is_default', ascending: false);

      return (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // TAMBAH METODE PEMBAYARAN ADMIN
  // ============================================================
  Future<Map<String, dynamic>> addPaymentMethod({
    required int idAdmin,
    required String jenisMetode,
    String? namaBank,
    String? namaPemilik,
    String? nomorRekening,
    String? kodeQris,
    bool isDefault = false,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'id_admin': idAdmin,
        'jenis_metode': jenisMetode,
        'is_default': isDefault,
      };

      if (jenisMetode == 'bank_transfer') {
        // Hanya tambahkan jika nilai tidak null
        if (namaBank != null && namaBank.isNotEmpty) {
          data['nama_bank'] = namaBank;
        }
        if (namaPemilik != null && namaPemilik.isNotEmpty) {
          data['nama_pemilik'] = namaPemilik;
        }
        if (nomorRekening != null && nomorRekening.isNotEmpty) {
          data['nomor_rekening'] = nomorRekening;
        }
      } else if (jenisMetode == 'qris') {
        if (kodeQris != null && kodeQris.isNotEmpty) {
          data['kode_qris'] = kodeQris;
        }
      }

      await _supabase.from('metode_pembayaran_penyelenggara').insert(data);

      return {
        'success': true,
        'message': 'Metode pembayaran berhasil ditambahkan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}

