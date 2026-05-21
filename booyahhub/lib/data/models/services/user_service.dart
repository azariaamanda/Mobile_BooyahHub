import '../../../config/supabase_client.dart';
import '../scrim_model.dart';
import '../pendaftaran_model.dart';
import '../hasil_match_model.dart';
import '../klaim_model.dart';

class UserService {
  final _supabase = SupabaseClientHelper.client;

  // ============================================================
  // GET ALL ACTIVE SCRIM (untuk user)
  // ============================================================
  Future<List<Scrim>> getActiveScrimList() async {
    try {
      final response = await _supabase
          .from('scrim')
          .select('''
            *,
            sesi_scrim(*),
            mode_pertandingan:master_mode_pertandingan(*)
          ''')
          .eq('status_scrim', 'aktif')
          .order('dibuat_pada', ascending: false);

      return response.map((json) => Scrim.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // GET DETAIL SCRIM BY ID
  // ============================================================
  Future<Scrim?> getScrimDetail(int scrimId) async {
    try {
      final response = await _supabase
          .from('scrim')
          .select('''
            *,
            sesi_scrim(*),
            mode_pertandingan:master_mode_pertandingan(*)
          ''')
          .eq('id_scrim', scrimId)
          .single();

      return Scrim.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // GET SESSION DETAIL WITH SLOT COUNT
  // ============================================================
  Future<SesiScrim?> getSessionDetail(int sesiId) async {
    try {
      // Ambil data sesi
      final sesiData = await _supabase
          .from('sesi_scrim')
          .select('*')
          .eq('id_sesi', sesiId)
          .single();

      // Hitung slot terisi
      final countData = await _supabase
          .from('pendaftaran_tim')
          .select('id_pendaftaran')
          .eq('id_sesi', sesiId)
          .eq('status_pembayaran', 'dikonfirmasi');

      final slotTerisi = (countData as List).length;

      final sesi = SesiScrim.fromJson(sesiData);
      sesi.slotTerisi = slotTerisi;

      return sesi;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // BOOKING SCRIM (PENDAFTARAN TIM)
  // ============================================================
  Future<Map<String, dynamic>> bookingScrim({
    required int idSesi,
    required int idTim,
    required String namaKapten,
    required String whatsappKapten,
    required String idPlayer1,
    String? idPlayer2,
    String? idPlayer3,
    String? idPlayer4,
    required String metodePembayaranDaftar,
  }) async {
    try {
      // Cek apakah sudah terdaftar
      final existing = await _supabase
          .from('pendaftaran_tim')
          .select()
          .eq('id_sesi', idSesi)
          .eq('id_tim', idTim)
          .maybeSingle();

      if (existing != null) {
        return {
          'success': false,
          'message': 'Tim sudah terdaftar di sesi ini',
        };
      }

      // Cek slot tersisa
      final sesi = await getSessionDetail(idSesi);
      if (sesi != null && sesi.isFull) {
        return {
          'success': false,
          'message': 'Slot sudah penuh',
        };
      }

      // Insert pendaftaran
      final response = await _supabase.from('pendaftaran_tim').insert({
        'id_sesi': idSesi,
        'id_tim': idTim,
        'nama_kapten': namaKapten,
        'whatsapp_kapten': whatsappKapten,
        'id_player_1': idPlayer1,
        'id_player_2': idPlayer2,
        'id_player_3': idPlayer3,
        'id_player_4': idPlayer4,
        'metode_pembayaran_daftar': metodePembayaranDaftar,
        'status_pembayaran': 'menunggu',
      }).select().single();

      return {
        'success': true,
        'message': 'Pendaftaran berhasil! Silakan upload bukti pembayaran.',
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
  // UPLOAD BUKTI PEMBAYARAN
  // ============================================================
  Future<Map<String, dynamic>> uploadBuktiPembayaran({
    required int idPendaftaran,
    required String buktiPath,
  }) async {
    try {
      await _supabase.from('pendaftaran_tim').update({
        'bukti_pembayaran': buktiPath,
      }).eq('id_pendaftaran', idPendaftaran);

      return {
        'success': true,
        'message': 'Bukti pembayaran berhasil diupload',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ============================================================
  // GET MY BOOKINGS (RIWAYAT SCRIM USER)
  // ============================================================
  Future<List<PendaftaranTim>> getMyBookings(int idTim) async {
    try {
      final response = await _supabase
          .from('pendaftaran_tim')
          .select('''
            *,
            sesi:sesi_scrim(
              *,
              scrim:scrim(*)
            )
          ''')
          .eq('id_tim', idTim)
          .order('dibuat_pada', ascending: false);

      return response.map((json) => PendaftaranTim.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // GET LEADERBOARD (HASIL PERTANDINGAN)
  // ============================================================
  Future<List<HasilPertandingan>> getLeaderboard(int idSesi) async {
    try {
      final response = await _supabase
          .from('hasil_pertandingan')
          .select('''
            *,
            pendaftaran:pendaftaran_tim(
              *,
              tim:akun(*)
            )
          ''')
          .eq('id_sesi', idSesi)
          .order('total_poin', ascending: false);

      return response.map((json) => HasilPertandingan.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // AJUKAN KLAIM HADIAH
  // ============================================================
  Future<Map<String, dynamic>> ajukanKlaim({
    required int idPendaftaran,
    required double jumlahKlaim,
    required String metodeKlaim,
    String? namaBank,
    String? nomorRekening,
    String? namaPemilikRekening,
    String? kodeQris,
  }) async {
    try {
      // Cek apakah sudah ada klaim
      final existing = await _supabase
          .from('klaim_hadiah')
          .select()
          .eq('id_pendaftaran', idPendaftaran)
          .maybeSingle();

      if (existing != null) {
        return {
          'success': false,
          'message': 'Klaim sudah diajukan sebelumnya',
        };
      }

      final data = {
        'id_pendaftaran': idPendaftaran,
        'jumlah_klaim': jumlahKlaim,
        'metode_klaim': metodeKlaim,
        'status_klaim': 'diajukan',
        'diajukan_pada': DateTime.now().toIso8601String(),
      };

      if (metodeKlaim == 'bank_transfer') {
        data['nama_bank'] = namaBank ?? '';
        data['nomor_rekening'] = nomorRekening ?? '';
        data['nama_pemilik_rekening'] = namaPemilikRekening ?? '';
      } else if (metodeKlaim == 'qris') {
        data['kode_qris'] = kodeQris ?? '';
      }

      await _supabase.from('klaim_hadiah').insert(data);

      return {
        'success': true,
        'message': 'Klaim berhasil diajukan, menunggu verifikasi admin',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ============================================================
  // GET STATUS KLAIM
  // ============================================================
  Future<KlaimHadiah?> getStatusKlaim(int idPendaftaran) async {
    try {
      final response = await _supabase
          .from('klaim_hadiah')
          .select('*')
          .eq('id_pendaftaran', idPendaftaran)
          .maybeSingle();

      if (response == null) return null;
      return KlaimHadiah.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}