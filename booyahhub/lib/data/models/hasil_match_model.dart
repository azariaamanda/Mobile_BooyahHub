import 'pendaftaran_model.dart';

class SistemPoin {
  final int idSistemPoin;
  final int peringkatKe;
  final int poin;
  final bool isDefault;

  SistemPoin({
    required this.idSistemPoin,
    required this.peringkatKe,
    required this.poin,
    required this.isDefault,
  });

  factory SistemPoin.fromJson(Map<String, dynamic> json) {
    return SistemPoin(
      idSistemPoin: json['id_sistem_poin'] ?? 0,
      peringkatKe: json['peringkat_ke'] ?? 0,
      poin: json['poin'] ?? 0,
      isDefault: json['is_default'] ?? true,
    );
  }

  static List<SistemPoin> get defaultPoinList {
    return [
      SistemPoin(idSistemPoin: 0, peringkatKe: 1, poin: 12, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 2, poin: 10, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 3, poin: 8, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 4, poin: 7, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 5, poin: 6, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 6, poin: 5, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 7, poin: 4, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 8, poin: 3, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 9, poin: 2, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 10, poin: 1, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 11, poin: 0, isDefault: true),
      SistemPoin(idSistemPoin: 0, peringkatKe: 12, poin: 0, isDefault: true),
    ];
  }
}

class HasilPertandingan {
  final int idHasil;
  final int idPendaftaran;
  final int idSesi;
  final int matchKe;
  final int? peringkat;
  final int? poinPlacement;
  final int totalKill;
  final int totalPoin;
  final DateTime diupdatePada;

  // Relasi
  final PendaftaranTim? pendaftaran;

  HasilPertandingan({
    required this.idHasil,
    required this.idPendaftaran,
    required this.idSesi,
    required this.matchKe,
    this.peringkat,
    this.poinPlacement,
    required this.totalKill,
    required this.totalPoin,
    required this.diupdatePada,
    this.pendaftaran,
  });

  factory HasilPertandingan.fromJson(Map<String, dynamic> json) {
    return HasilPertandingan(
      idHasil: json['id_hasil'] ?? 0,
      idPendaftaran: json['id_pendaftaran'] ?? 0,
      idSesi: json['id_sesi'] ?? 0,
      matchKe: json['match_ke'] ?? 1,
      peringkat: json['peringkat'],
      poinPlacement: json['poin_placement'],
      totalKill: json['total_kill'] ?? 0,
      totalPoin: json['total_poin'] ?? 0,
      diupdatePada: json['diupdate_pada'] != null
          ? DateTime.parse(json['diupdate_pada'])
          : DateTime.now(),
      pendaftaran: json['pendaftaran'] != null
          ? PendaftaranTim.fromJson(json['pendaftaran'])
          : null,
    );
  }

  // Hitung total poin
  static int hitungTotalPoin(int poinPlacement, int totalKill) {
    return poinPlacement + totalKill;
  }
}