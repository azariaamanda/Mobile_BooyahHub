// lib/data/models/keuangan_admin_model.dart
//
// View-model ringan untuk layar admin "Keuangan" & "Klaim Hadiah".
// Saat integrasi, mapping bisa diambil dari tabel `keuangan_scrim`
// dan `klaim_hadiah` (lihat keuangan_model.dart & klaim_model.dart).

// ============================================================
// LAYAR KEUANGAN — kartu ringkasan + daftar klaim aktif
// ============================================================

enum KlaimCardStatus { urgent, completed }

class KlaimAktif {
  final int idScrim;
  final String namaScrim;
  final String tanggal;
  final int nominal;
  final KlaimCardStatus status;
  final int? jumlahPending; // hanya untuk status urgent
  final int? jumlahTim; // hanya untuk status urgent
  final String? catatan; // mis. "Selesai dalam 45 menit"

  const KlaimAktif({
    required this.idScrim,
    required this.namaScrim,
    required this.tanggal,
    required this.nominal,
    required this.status,
    this.jumlahPending,
    this.jumlahTim,
    this.catatan,
  });
}

class RingkasanKeuangan {
  final int totalPendapatan;
  final double pertumbuhanPersen;
  final int danaKeluar;
  final int persenTersalurkan;
  final int klaimPending;

  const RingkasanKeuangan({
    required this.totalPendapatan,
    required this.pertumbuhanPersen,
    required this.danaKeluar,
    required this.persenTersalurkan,
    required this.klaimPending,
  });
}

// ============================================================
// LAYAR KLAIM HADIAH — sesi, rincian keuangan, status pemenang
// ============================================================

/// Status verifikasi klaim seorang pemenang.
enum WinnerClaimStatus { belumVerifikasi, sudahVerifikasi, ditolak, sedangDicairkan }

extension WinnerClaimStatusX on WinnerClaimStatus {
  String get label {
    switch (this) {
      case WinnerClaimStatus.belumVerifikasi:
        return 'BELUM VERIFIKASI';
      case WinnerClaimStatus.sudahVerifikasi:
        return 'SUDAH VERIFIKASI';
      case WinnerClaimStatus.ditolak:
        return 'DITOLAK';
      case WinnerClaimStatus.sedangDicairkan:
        return 'SEDANG DICAIRKAN';
    }
  }
}

/// Satu baris pada timeline "Riwayat Status".
class TimelineEntry {
  final String label;
  final String? waktu;
  final bool done; // sudah lewat (titik penuh)
  final bool pending; // sedang menunggu (titik berkedip / kuning)

  const TimelineEntry({
    required this.label,
    this.waktu,
    this.done = false,
    this.pending = false,
  });
}

class WinnerClaim {
  final int rank; // 1, 2, 3
  final String namaTim;
  final int nominal;
  final String metode; // "BCA", "DANA", "GoPay"
  final String nomorRekening;
  final String namaPemilik;
  WinnerClaimStatus status;

  WinnerClaim({
    required this.rank,
    required this.namaTim,
    required this.nominal,
    required this.metode,
    required this.nomorRekening,
    required this.namaPemilik,
    this.status = WinnerClaimStatus.belumVerifikasi,
  });

  /// Timeline dibangun otomatis dari status terkini.
  List<TimelineEntry> get timeline {
    switch (status) {
      case WinnerClaimStatus.belumVerifikasi:
        return const [
          TimelineEntry(label: 'Klaim Diajukan', waktu: '12 Okt, 14:20', done: true),
          TimelineEntry(label: 'Menunggu Verifikasi Admin', pending: true),
        ];
      case WinnerClaimStatus.sudahVerifikasi:
        return const [
          TimelineEntry(label: 'Klaim Diajukan', waktu: '12 Okt, 14:20', done: true),
          TimelineEntry(label: 'Disetujui Admin', waktu: '12 Okt, 14:45', done: true),
        ];
      case WinnerClaimStatus.ditolak:
        return const [
          TimelineEntry(label: 'Klaim Diajukan', waktu: '12 Okt, 14:20', done: true),
          TimelineEntry(label: 'Ditolak Admin', waktu: '12 Okt, 14:45', done: true),
        ];
      case WinnerClaimStatus.sedangDicairkan:
        return const [
          TimelineEntry(label: 'Klaim Diajukan', waktu: '12 Okt, 14:20', done: true),
          TimelineEntry(label: 'Disetujui Admin', waktu: '12 Okt, 14:45', done: true),
          TimelineEntry(label: 'Diteruskan ke Owner', waktu: '13 Okt, 08:15', done: true),
        ];
    }
  }
}

class SesiOption {
  final int id;
  final String label;
  const SesiOption({required this.id, required this.label});
}

class RincianKeuanganSesi {
  final int totalPendapatan;
  final int jumlahTim;
  final int feePlatform; // 5%
  final int feeAdmin; // 10%
  final int sisaHadiah; // 85%
  final int juara1; // 50%
  final int juara2; // 30%
  final int juara3; // 20%

  const RincianKeuanganSesi({
    required this.totalPendapatan,
    required this.jumlahTim,
    required this.feePlatform,
    required this.feeAdmin,
    required this.sisaHadiah,
    required this.juara1,
    required this.juara2,
    required this.juara3,
  });

  /// Hitung otomatis dari total pendapatan & jumlah tim.
  factory RincianKeuanganSesi.hitung(int total, int tim) {
    final platform = (total * 0.05).round();
    final admin = (total * 0.10).round();
    final sisa = total - platform - admin;
    return RincianKeuanganSesi(
      totalPendapatan: total,
      jumlahTim: tim,
      feePlatform: platform,
      feeAdmin: admin,
      sisaHadiah: sisa,
      juara1: (sisa * 0.50).round(),
      juara2: (sisa * 0.30).round(),
      juara3: (sisa * 0.20).round(),
    );
  }
}

// ============================================================
// FORMAT RUPIAH
// ============================================================
String formatRupiah(int value) {
  final str = value.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
  }
  return '${value < 0 ? '-' : ''}Rp $buffer';
}

/// Format ringkas: 12400000 -> "Rp 12.4M".
String formatRupiahRingkas(int value) {
  if (value >= 1000000000) {
    return 'Rp ${(value / 1000000000).toStringAsFixed(1)}B';
  }
  if (value >= 1000000) {
    return 'Rp ${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return 'Rp ${(value / 1000).toStringAsFixed(0)}K';
  }
  return formatRupiah(value);
}

// ============================================================
// DATA DUMMY — hapus / ganti dengan query Supabase saat integrasi
// ============================================================

const mockRingkasan = RingkasanKeuangan(
  totalPendapatan: 12400000,
  pertumbuhanPersen: 4.2,
  danaKeluar: 10200000,
  persenTersalurkan: 80,
  klaimPending: 12,
);

const mockKlaimAktif = [
  KlaimAktif(
    idScrim: 12,
    namaScrim: 'Ultimate Pro League - S12',
    tanggal: '24 Okt 2023',
    nominal: 600000,
    status: KlaimCardStatus.urgent,
    jumlahPending: 12,
    jumlahTim: 8,
  ),
  KlaimAktif(
    idScrim: 9,
    namaScrim: 'Elite Weekly Cup',
    tanggal: '25 Okt 2023',
    nominal: 1200000,
    status: KlaimCardStatus.completed,
    catatan: 'Selesai dalam 45 menit',
  ),
];

const mockSesiList = [
  SesiOption(id: 1, label: 'Sesi 1: 08.00 - 09.00'),
  SesiOption(id: 2, label: 'Sesi 2: 10.00 - 11.00'),
  SesiOption(id: 3, label: 'Sesi 3: 13.00 - 14.00'),
];

List<WinnerClaim> buildMockWinners() => [
      WinnerClaim(
        rank: 1,
        namaTim: 'Evos Glory',
        nominal: 255000,
        metode: 'BCA',
        nomorRekening: '8821 0941 12',
        namaPemilik: 'MUHAMMAD RIDWAN',
      ),
      WinnerClaim(
        rank: 2,
        namaTim: 'RRQ Hoshi',
        nominal: 153000,
        metode: 'DANA',
        nomorRekening: '0812 9342 123',
        namaPemilik: 'ANDIKA PRATAMA',
      ),
      WinnerClaim(
        rank: 3,
        namaTim: 'Bigetron Alpha',
        nominal: 102000,
        metode: 'GoPay',
        nomorRekening: '8857 1123 661',
        namaPemilik: 'RIZKY FAUZI',
      ),
    ];
