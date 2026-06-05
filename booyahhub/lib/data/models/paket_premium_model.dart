// lib/data/models/paket_premium_model.dart

class PaketPremiumModel {
  final int? idLangganan;
  final String namaPaket;
  final String? tierLevel;
  final double? harga;
  final int? durasiHari;
  final String? status;
  final List<String>? fiturPaket;
  final int? totalPengguna;

  PaketPremiumModel({
    this.idLangganan,
    required this.namaPaket,
    this.tierLevel,
    this.harga,
    this.durasiHari,
    this.status,
    this.fiturPaket,
    this.totalPengguna,
  });

  factory PaketPremiumModel.fromJson(Map<String, dynamic> json) {
    List<String>? fiturList;
    if (json['fitur_paket'] != null) {
      if (json['fitur_paket'] is List) {
        fiturList = List<String>.from(json['fitur_paket']);
      } else if (json['fitur_paket'] is String) {
        fiturList = (json['fitur_paket'] as String).split(',');
      }
    }

    return PaketPremiumModel(
      idLangganan: json['id_langganan'],
      namaPaket: json['nama_paket'] ?? '',
      tierLevel: json['tier_level'],
      harga: json['harga'] != null ? (json['harga'] as num).toDouble() : null,
      durasiHari: json['durasi_hari'],
      status: json['status'],
      fiturPaket: fiturList,
      totalPengguna: json['total_pengguna'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_langganan': idLangganan,
      'nama_paket': namaPaket,
      'tier_level': tierLevel,
      'harga': harga,
      'durasi_hari': durasiHari,
      'status': status,
      'fitur_paket': fiturPaket,
      'total_pengguna': totalPengguna,
    };
  }

  PaketPremiumModel copyWith({
    int? idLangganan,
    String? namaPaket,
    String? tierLevel,
    double? harga,
    int? durasiHari,
    String? status,
    List<String>? fiturPaket,
    int? totalPengguna,
  }) {
    return PaketPremiumModel(
      idLangganan: idLangganan ?? this.idLangganan,
      namaPaket: namaPaket ?? this.namaPaket,
      tierLevel: tierLevel ?? this.tierLevel,
      harga: harga ?? this.harga,
      durasiHari: durasiHari ?? this.durasiHari,
      status: status ?? this.status,
      fiturPaket: fiturPaket ?? this.fiturPaket,
      totalPengguna: totalPengguna ?? this.totalPengguna,
    );
  }

  String get tierLabel {
    switch (tierLevel) {
      case 'basic':
        return 'Basic';
      case 'pro':
        return 'Pro';
      case 'enterprise':
        return 'Enterprise';
      default:
        return tierLevel ?? 'Premium';
    }
  }

  String get formattedHarga {
    if (harga == null || harga == 0) return 'Gratis';
    return 'Rp ${harga!.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  String get formattedDurasi {
    if (durasiHari == null) return '-';
    if (durasiHari! >= 30) {
      final bulan = durasiHari! ~/ 30;
      return '$bulan bulan';
    }
    return '$durasiHari hari';
  }
}