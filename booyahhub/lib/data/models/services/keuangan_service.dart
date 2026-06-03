import 'package:supabase_flutter/supabase_flutter.dart';
import '../transaksi_keuangan_model.dart';
import '../saldo_pengguna_model.dart';

class KeuanganService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── FETCH SALDO PENGGUNA ───
  Future<SaldoPengguna?> fetchSaldoPengguna(int idAkun) async {
    try {
      final response = await _supabase
          .from('saldo_pengguna')
          .select()
          .eq('id_akun', idAkun)
          .maybeSingle();

      if (response == null) {
        // Return default saldo kosong jika record belum ada di DB
        return SaldoPengguna(
          idSaldo: 0,
          idAkun: idAkun,
          saldoTotal: 0,
          saldoDitahan: 0,
          saldoKlaimHadiah: 0,
          dibuatPada: DateTime.now(),
        );
      }
      return SaldoPengguna.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching saldo: $e');
    }
  }

  // ─── FETCH TRANSAKSI PENGGUNA ───
  Future<List<TransaksiKeuangan>> fetchTransaksiPengguna(
    int idAkun, {
    String? tipeFilter,
    String? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      dynamic query = _supabase.from('transaksi_keuangan').select();

      query = query.eq('id_akun', idAkun);

      if (tipeFilter != null && tipeFilter.isNotEmpty) {
        query = query.eq('tipe_transaksi', tipeFilter);
      }

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      query = query.order('dibuat_pada', ascending: false);
      query = query.range(offset, offset + limit - 1);

      final response = await query;
      return (response as List)
          .map(
            (item) => TransaksiKeuangan.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Error fetching transaksi: $e');
    }
  }

  // ─── FETCH ALL TRANSAKSI (FOR ADMIN) ───
  Future<List<TransaksiKeuangan>> fetchAllTransaksi({
    String? tipeFilter,
    String? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      dynamic query = _supabase.from('transaksi_keuangan').select();

      if (tipeFilter != null && tipeFilter.isNotEmpty) {
        query = query.eq('tipe_transaksi', tipeFilter);
      }

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      query = query.order('dibuat_pada', ascending: false);
      query = query.range(offset, offset + limit - 1);

      final response = await query;
      return (response as List)
          .map(
            (item) => TransaksiKeuangan.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Error fetching all transaksi: $e');
    }
  }

  // ─── CREATE PENARIKAN / WITHDRAWAL ───
  Future<TransaksiKeuangan> createPenarikan({
    required int idAkun,
    required double nominal,
    required String nomorRekening,
    required String namaBank,
    required String namaAtas,
  }) async {
    try {
      // Validasi saldo
      final saldo = await fetchSaldoPengguna(idAkun);
      if (saldo == null || saldo.saldoBisaDitarik < nominal) {
        throw Exception('Saldo tidak cukup');
      }

      // Create withdrawal request
      final response = await _supabase.from('transaksi_keuangan').insert({
        'id_akun': idAkun,
        'tipe_transaksi': 'penarikan',
        'nominal': nominal,
        'status': 'pending',
        'deskripsi': 'Penarikan dana ke $namaBank',
        'nomor_rekening': nomorRekening,
        'nama_bank': namaBank,
        'nama_atas': namaAtas,
        'dibuat_pada': DateTime.now().toIso8601String(),
      }).select();

      return TransaksiKeuangan.fromJson(response.first);
    } catch (e) {
      throw Exception('Error creating penarikan: $e');
    }
  }

  // ─── FETCH RINCIAN TRANSAKSI ───
  Future<TransaksiKeuangan?> fetchDetailTransaksi(int idTransaksi) async {
    try {
      final response = await _supabase
          .from('transaksi_keuangan')
          .select()
          .eq('id_transaksi', idTransaksi)
          .maybeSingle();

      if (response == null) return null;
      return TransaksiKeuangan.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching detail transaksi: $e');
    }
  }

  // ─── UPDATE TRANSAKSI STATUS ───
  Future<void> updateTransaksiStatus(int idTransaksi, String status) async {
    try {
      await _supabase
          .from('transaksi_keuangan')
          .update({
            'status': status,
            'diperbarui': DateTime.now().toIso8601String(),
          })
          .eq('id_transaksi', idTransaksi);
    } catch (e) {
      throw Exception('Error updating transaksi status: $e');
    }
  }

  // ─── FETCH STATISTIK KEUANGAN ───
  Future<Map<String, dynamic>> fetchStatistikKeuangan(int idAkun) async {
    try {
      final transaksi = await fetchTransaksiPengguna(idAkun, limit: 1000);
      final saldo = await fetchSaldoPengguna(idAkun);

      double totalPemasukan = 0;
      double totalPenarikan = 0;
      double totalHadiah = 0;

      for (var tx in transaksi) {
        if (tx.isSuccess) {
          if (tx.isPemasukan) {
            totalPemasukan += tx.nominal;
          } else if (tx.isPenarikan) {
            totalPenarikan += tx.nominal;
          } else if (tx.isHadiah) {
            totalHadiah += tx.nominal;
          }
        }
      }

      return {
        'total_pemasukan': totalPemasukan,
        'total_penarikan': totalPenarikan,
        'total_hadiah': totalHadiah,
        'saldo_current': saldo?.saldoTotal ?? 0,
        'saldo_bisa_ditarik': saldo?.saldoBisaDitarik ?? 0,
      };
    } catch (e) {
      throw Exception('Error fetching statistik: $e');
    }
  }

  // ─── GET TRANSAKSI BULAN INI ───
  Future<List<TransaksiKeuangan>> fetchTransaksiThisMonth(int idAkun) async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      final response = await _supabase
          .from('transaksi_keuangan')
          .select()
          .eq('id_akun', idAkun)
          .gte('dibuat_pada', firstDay.toIso8601String())
          .lte('dibuat_pada', lastDay.toIso8601String())
          .order('dibuat_pada', ascending: false);

      return (response as List)
          .map(
            (item) => TransaksiKeuangan.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Error fetching transaksi bulan ini: $e');
    }
  }
}
