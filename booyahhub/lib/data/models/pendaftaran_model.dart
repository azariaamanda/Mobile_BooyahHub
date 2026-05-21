import 'akun_model.dart';
import 'scrim_model.dart';

class PendaftaranTim {
  final int idPendaftaran;
  final int idSesi;
  final int idTim;
  final String namaKapten;
  final String whatsappKapten;
  final String idPlayer1;
  final String? idPlayer2;
  final String? idPlayer3;
  final String? idPlayer4;
  final String metodePembayaranDaftar;
  final String? buktiPembayaran;
  final String statusPembayaran;
  final DateTime? diverifikasiPada;
  final DateTime dibuatPada;

  // Relasi (opsional)
  final Akun? tim;
  final SesiScrim? sesi;

  PendaftaranTim({
    required this.idPendaftaran,
    required this.idSesi,
    required this.idTim,
    required this.namaKapten,
    required this.whatsappKapten,
    required this.idPlayer1,
    this.idPlayer2,
    this.idPlayer3,
    this.idPlayer4,
    required this.metodePembayaranDaftar,
    this.buktiPembayaran,
    required this.statusPembayaran,
    this.diverifikasiPada,
    required this.dibuatPada,
    this.tim,
    this.sesi,
  });

  factory PendaftaranTim.fromJson(Map<String, dynamic> json) {
    return PendaftaranTim(
      idPendaftaran: json['id_pendaftaran'] ?? 0,
      idSesi: json['id_sesi'] ?? 0,
      idTim: json['id_tim'] ?? 0,
      namaKapten: json['nama_kapten'] ?? '',
      whatsappKapten: json['whatsapp_kapten'] ?? '',
      idPlayer1: json['id_player_1'] ?? '',
      idPlayer2: json['id_player_2'],
      idPlayer3: json['id_player_3'],
      idPlayer4: json['id_player_4'],
      metodePembayaranDaftar: json['metode_pembayaran_daftar'] ?? 'bank_transfer',
      buktiPembayaran: json['bukti_pembayaran'],
      statusPembayaran: json['status_pembayaran'] ?? 'menunggu',
      diverifikasiPada: json['diverifikasi_pada'] != null
          ? DateTime.parse(json['diverifikasi_pada'])
          : null,
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : DateTime.now(),
      tim: json['tim'] != null ? Akun.fromJson(json['tim']) : null,
      sesi: json['sesi'] != null ? SesiScrim.fromJson(json['sesi']) : null,
    );
  }

  // Daftar ID player
  List<String> get listIdPlayer {
    final list = [idPlayer1];
    if (idPlayer2 != null && idPlayer2!.isNotEmpty) list.add(idPlayer2!);
    if (idPlayer3 != null && idPlayer3!.isNotEmpty) list.add(idPlayer3!);
    if (idPlayer4 != null && idPlayer4!.isNotEmpty) list.add(idPlayer4!);
    return list;
  }

  // Warna status pembayaran
  String get statusColor {
    switch (statusPembayaran) {
      case 'dikonfirmasi':
        return 'success';
      case 'ditolak':
        return 'error';
      default:
        return 'warning';
    }
  }

  // Label status
  String get statusLabel {
    switch (statusPembayaran) {
      case 'menunggu':
        return 'Menunggu Verifikasi';
      case 'dikonfirmasi':
        return 'Terverifikasi';
      case 'ditolak':
        return 'Ditolak';
      default:
        return statusPembayaran;
    }
  }
}