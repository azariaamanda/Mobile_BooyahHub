class SaldoPengguna {
  final int idSaldo;
  final int idAkun;
  final double saldoTotal;
  final double saldoDitahan; // saldo yang sedang pending/diproses
  final double saldoKlaimHadiah;
  final DateTime dibuatPada;
  final DateTime? diperbarui;

  SaldoPengguna({
    required this.idSaldo,
    required this.idAkun,
    required this.saldoTotal,
    required this.saldoDitahan,
    required this.saldoKlaimHadiah,
    required this.dibuatPada,
    this.diperbarui,
  });

  factory SaldoPengguna.fromJson(Map<String, dynamic> json) {
    return SaldoPengguna(
      idSaldo: json['id_saldo'] ?? 0,
      idAkun: json['id_akun'] ?? 0,
      saldoTotal: (json['saldo_total'] ?? 0).toDouble(),
      saldoDitahan: (json['saldo_ditahan'] ?? 0).toDouble(),
      saldoKlaimHadiah: (json['saldo_klaim_hadiah'] ?? 0).toDouble(),
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : DateTime.now(),
      diperbarui: json['diperbarui'] != null
          ? DateTime.parse(json['diperbarui'])
          : null,
    );
  }

  // Saldo yang bisa ditarik (total - pending - hadiah)
  double get saldoBisaDitarik {
    return saldoTotal - saldoDitahan - saldoKlaimHadiah;
  }

  // Format display
  String get displaySaldoTotal =>
      'Rp ${saldoTotal.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';

  String get displaySaldoDitahan =>
      'Rp ${saldoDitahan.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';

  String get displaySaldoKlaimHadiah =>
      'Rp ${saldoKlaimHadiah.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';

  String get displaySaldoBisaDitarik =>
      'Rp ${saldoBisaDitarik.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';
}
