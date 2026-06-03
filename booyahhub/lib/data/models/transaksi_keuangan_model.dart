class TransaksiKeuangan {
  final int idTransaksi;
  final int idAkun;
  final String tipeTransaksi; // 'pemasukan', 'penarikan', 'hadiah'
  final double nominal;
  final String status; // 'pending', 'berhasil', 'gagal', 'ditolak'
  final String deskripsi;
  final DateTime dibuatPada;
  final DateTime? diperbarui;
  final String? nomorRekening;
  final String? namaBank;
  final String? namaAtas;

  TransaksiKeuangan({
    required this.idTransaksi,
    required this.idAkun,
    required this.tipeTransaksi,
    required this.nominal,
    required this.status,
    required this.deskripsi,
    required this.dibuatPada,
    this.diperbarui,
    this.nomorRekening,
    this.namaBank,
    this.namaAtas,
  });

  factory TransaksiKeuangan.fromJson(Map<String, dynamic> json) {
    return TransaksiKeuangan(
      idTransaksi: json['id_transaksi'] ?? 0,
      idAkun: json['id_akun'] ?? 0,
      tipeTransaksi: json['tipe_transaksi'] ?? 'pemasukan',
      nominal: (json['nominal'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      deskripsi: json['deskripsi'] ?? '',
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : DateTime.now(),
      diperbarui: json['diperbarui'] != null
          ? DateTime.parse(json['diperbarui'])
          : null,
      nomorRekening: json['nomor_rekening'] ?? '',
      namaBank: json['nama_bank'] ?? '',
      namaAtas: json['nama_atas'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_transaksi': idTransaksi,
      'id_akun': idAkun,
      'tipe_transaksi': tipeTransaksi,
      'nominal': nominal,
      'status': status,
      'deskripsi': deskripsi,
      'dibuat_pada': dibuatPada.toIso8601String(),
      'diperbarui': diperbarui?.toIso8601String(),
      'nomor_rekening': nomorRekening,
      'nama_bank': namaBank,
      'nama_atas': namaAtas,
    };
  }

  // Status styling
  bool get isPending => status == 'pending';
  bool get isSuccess => status == 'berhasil';
  bool get isFailed => status == 'gagal';
  bool get isRejected => status == 'ditolak';

  // Type styling
  bool get isPemasukan => tipeTransaksi == 'pemasukan';
  bool get isPenarikan => tipeTransaksi == 'penarikan';
  bool get isHadiah => tipeTransaksi == 'hadiah';

  // Get display nominal with sign
  String get displayNominal {
    if (isPenarikan) {
      return '-Rp ${nominal.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';
    } else {
      return '+Rp ${nominal.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';
    }
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'berhasil':
        return 'Berhasil';
      case 'gagal':
        return 'Gagal';
      case 'ditolak':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String get tipeText {
    switch (tipeTransaksi) {
      case 'pemasukan':
        return 'Pemasukan';
      case 'penarikan':
        return 'Penarikan';
      case 'hadiah':
        return 'Hadiah';
      default:
        return tipeTransaksi;
    }
  }

  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final date = dibuatPada.toLocal();
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
  }
}
