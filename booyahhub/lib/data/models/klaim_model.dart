import 'pendaftaran_model.dart';

class KlaimHadiah {
  final int idKlaim;
  final int idPendaftaran;
  final String statusKlaim;
  final double jumlahKlaim;
  final String metodeKlaim;

  // Untuk bank_transfer
  final String? namaBank;
  final String? nomorRekening;
  final String? namaPemilikRekening;

  // Untuk qris
  final String? kodeQris;
  final String? idTransaksiQris;

  // Waktu
  final DateTime? diajukanPada;
  final DateTime? disetujuiAdminPada;
  final DateTime? diteruskanOwnerPada;
  final DateTime? dibayarPada;

  // Relasi
  final PendaftaranTim? pendaftaran;

  KlaimHadiah({
    required this.idKlaim,
    required this.idPendaftaran,
    required this.statusKlaim,
    required this.jumlahKlaim,
    required this.metodeKlaim,
    this.namaBank,
    this.nomorRekening,
    this.namaPemilikRekening,
    this.kodeQris,
    this.idTransaksiQris,
    this.diajukanPada,
    this.disetujuiAdminPada,
    this.diteruskanOwnerPada,
    this.dibayarPada,
    this.pendaftaran,
  });

  factory KlaimHadiah.fromJson(Map<String, dynamic> json) {
    return KlaimHadiah(
      idKlaim: json['id_klaim'] ?? 0,
      idPendaftaran: json['id_pendaftaran'] ?? 0,
      statusKlaim: json['status_klaim'] ?? 'belum_diajukan',
      jumlahKlaim: (json['jumlah_klaim'] ?? 0).toDouble(),
      metodeKlaim: json['metode_klaim'] ?? 'bank_transfer',
      namaBank: json['nama_bank'],
      nomorRekening: json['nomor_rekening'],
      namaPemilikRekening: json['nama_pemilik_rekening'],
      kodeQris: json['kode_qris'],
      idTransaksiQris: json['id_transaksi_qris'],
      diajukanPada: json['diajukan_pada'] != null
          ? DateTime.parse(json['diajukan_pada'])
          : null,
      disetujuiAdminPada: json['disetujui_admin_pada'] != null
          ? DateTime.parse(json['disetujui_admin_pada'])
          : null,
      diteruskanOwnerPada: json['diteruskan_owner_pada'] != null
          ? DateTime.parse(json['diteruskan_owner_pada'])
          : null,
      dibayarPada: json['dibayar_pada'] != null
          ? DateTime.parse(json['dibayar_pada'])
          : null,
      pendaftaran: json['pendaftaran'] != null
          ? PendaftaranTim.fromJson(json['pendaftaran'])
          : null,
    );
  }

  // Status label untuk UI
  String get statusLabel {
    switch (statusKlaim) {
      case 'belum_diajukan':
        return 'Belum Diajukan';
      case 'diajukan':
        return 'Diajukan';
      case 'disetujui_admin':
        return 'Disetujui Admin';
      case 'diteruskan_owner':
        return 'Diteruskan ke Owner';
      case 'dibayar':
        return 'Dibayar';
      default:
        return statusKlaim;
    }
  }

  // Warna status
  String get statusColor {
    switch (statusKlaim) {
      case 'belum_diajukan':
        return 'gray';
      case 'diajukan':
        return 'warning';
      case 'disetujui_admin':
        return 'info';
      case 'diteruskan_owner':
        return 'primary';
      case 'dibayar':
        return 'success';
      default:
        return 'gray';
    }
  }

  // Urutan status (untuk timeline)
  int get statusOrder {
    switch (statusKlaim) {
      case 'belum_diajukan':
        return 0;
      case 'diajukan':
        return 1;
      case 'disetujui_admin':
        return 2;
      case 'diteruskan_owner':
        return 3;
      case 'dibayar':
        return 4;
      default:
        return 0;
    }
  }

  // Apakah sudah mencapai status tertentu
  bool get isDiajukan => statusOrder >= 1;
  bool get isDisetujuiAdmin => statusOrder >= 2;
  bool get isDiteruskanOwner => statusOrder >= 3;
  bool get isDibayar => statusOrder >= 4;
}