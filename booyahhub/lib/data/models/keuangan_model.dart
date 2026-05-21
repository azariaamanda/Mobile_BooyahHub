import 'scrim_model.dart';

class KeuanganScrim {
  final int idKeuangan;
  final int idScrim;
  final double totalPendaftaran;
  final double feePlatform5persen;
  final double feeAdmin10persen;
  final double sisaHadiah;
  final double juara150persen;
  final double juara230persen;
  final double juara320persen;
  final DateTime dibuatPada;

  // Relasi
  final Scrim? scrim;

  KeuanganScrim({
    required this.idKeuangan,
    required this.idScrim,
    required this.totalPendaftaran,
    required this.feePlatform5persen,
    required this.feeAdmin10persen,
    required this.sisaHadiah,
    required this.juara150persen,
    required this.juara230persen,
    required this.juara320persen,
    required this.dibuatPada,
    this.scrim,
  });

  factory KeuanganScrim.fromJson(Map<String, dynamic> json) {
    return KeuanganScrim(
      idKeuangan: json['id_keuangan'] ?? 0,
      idScrim: json['id_scrim'] ?? 0,
      totalPendaftaran: (json['total_pendaftaran'] ?? 0).toDouble(),
      feePlatform5persen: (json['fee_platform_5persen'] ?? 0).toDouble(),
      feeAdmin10persen: (json['fee_admin_10persen'] ?? 0).toDouble(),
      sisaHadiah: (json['sisa_hadiah'] ?? 0).toDouble(),
      juara150persen: (json['juara1_50persen'] ?? 0).toDouble(),
      juara230persen: (json['juara2_30persen'] ?? 0).toDouble(),
      juara320persen: (json['juara3_20persen'] ?? 0).toDouble(),
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : DateTime.now(),
      scrim: json['scrim'] != null ? Scrim.fromJson(json['scrim']) : null,
    );
  }

  // Hitung total fee platform + admin
  double get totalFee => feePlatform5persen + feeAdmin10persen;

  // Format persentase
  String get persentaseFeePlatform => '5%';
  String get persentaseFeeAdmin => '10%';
  String get persentaseJuara1 => '50%';
  String get persentaseJuara2 => '30%';
  String get persentaseJuara3 => '20%';
}