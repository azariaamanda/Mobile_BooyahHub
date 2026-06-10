enum StatusPeserta { belumBayar, menunggu, dikonfirmasi, ditolak }

extension StatusPesertaX on StatusPeserta {
  String get label {
    switch (this) {
      case StatusPeserta.belumBayar:
        return 'BELUM BAYAR';
      case StatusPeserta.menunggu:
        return 'MENUNGGU';
      case StatusPeserta.dikonfirmasi:
        return 'DIKONFIRMASI';
      case StatusPeserta.ditolak:
        return 'DITOLAK';
    }
  }

  String get tab {
    switch (this) {
      case StatusPeserta.belumBayar:
        return 'Belum Bayar';
      case StatusPeserta.menunggu:
        return 'Menunggu';
      case StatusPeserta.dikonfirmasi:
        return 'Konfirmasi';
      case StatusPeserta.ditolak:
        return 'Ditolak';
    }
  }

  static StatusPeserta fromString(String value) {
    switch (value.toLowerCase()) {
      case 'dikonfirmasi':
        return StatusPeserta.dikonfirmasi;
      case 'ditolak':
        return StatusPeserta.ditolak;
      case 'menunggu':
        return StatusPeserta.menunggu;
      case 'belum_bayar':
        return StatusPeserta.belumBayar;
      default:
        return StatusPeserta.menunggu;
    }
  }
}

class PesertaVerifikasi {
  final int idPendaftaran;
  final int idScrim;
  final String namaTim;
  final String namaKapten;
  final String whatsappKapten;
  final StatusPeserta status;
  final String namaScrim;
  final String slotId;
  final String tanggal;
  final String waktu;
  final int nominal;
  final String bankPengirim;
  final String namaPengirim;
  final String? buktiPembayaranUrl;
  final String? idPlayer1;
  final String? idPlayer2;
  final String? idPlayer3;
  final String? idPlayer4;

  const PesertaVerifikasi({
    required this.idPendaftaran,
    required this.idScrim,
    required this.namaTim,
    required this.namaKapten,
    required this.whatsappKapten,
    required this.status,
    required this.namaScrim,
    required this.slotId,
    required this.tanggal,
    required this.waktu,
    required this.nominal,
    required this.bankPengirim,
    required this.namaPengirim,
    this.buktiPembayaranUrl,
    this.idPlayer1,
    this.idPlayer2,
    this.idPlayer3,
    this.idPlayer4,
  });

  factory PesertaVerifikasi.fromJson(Map<String, dynamic> json) {
    return PesertaVerifikasi(
      idPendaftaran: json['id_pendaftaran'] ?? 0,
      idScrim: json['id_scrim'] ?? 0,
      namaTim: json['nama_tim'] ?? '-',
      namaKapten: json['nama_kapten'] ?? '-',
      whatsappKapten: json['whatsapp_kapten'] ?? '-',
      status: StatusPesertaX.fromString(json['status_pembayaran'] ?? 'menunggu'),
      namaScrim: json['nama_scrim'] ?? '-',
      slotId: json['slot_id'] ?? '-',
      tanggal: json['tanggal'] ?? '-',
      waktu: json['waktu'] ?? '-',
      nominal: json['nominal'] ?? 0,
      bankPengirim: json['bank_pengirim'] ?? '-',
      namaPengirim: json['nama_pengirim'] ?? '-',
      buktiPembayaranUrl: json['bukti_pembayaran'],
      idPlayer1: json['id_player_1'] as String?,
      idPlayer2: json['id_player_2'] as String?,
      idPlayer3: json['id_player_3'] as String?,
      idPlayer4: json['id_player_4'] as String?,
    );
  }

  PesertaVerifikasi copyWith({StatusPeserta? status}) {
    return PesertaVerifikasi(
      idPendaftaran: idPendaftaran,
      idScrim: idScrim,
      namaTim: namaTim,
      namaKapten: namaKapten,
      whatsappKapten: whatsappKapten,
      status: status ?? this.status,
      namaScrim: namaScrim,
      slotId: slotId,
      tanggal: tanggal,
      waktu: waktu,
      nominal: nominal,
      bankPengirim: bankPengirim,
      namaPengirim: namaPengirim,
      buktiPembayaranUrl: buktiPembayaranUrl,
      idPlayer1: idPlayer1,
      idPlayer2: idPlayer2,
      idPlayer3: idPlayer3,
      idPlayer4: idPlayer4,
    );
  }

  List<String> get listIdPlayer {
    final list = <String>[];
    if (idPlayer1 != null && idPlayer1!.isNotEmpty) list.add(idPlayer1!);
    if (idPlayer2 != null && idPlayer2!.isNotEmpty) list.add(idPlayer2!);
    if (idPlayer3 != null && idPlayer3!.isNotEmpty) list.add(idPlayer3!);
    if (idPlayer4 != null && idPlayer4!.isNotEmpty) list.add(idPlayer4!);
    return list;
  }

  String get nominalFormatted {
    final str = nominal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }
}

const List<PesertaVerifikasi> mockPesertaList = [
  PesertaVerifikasi(
    idPendaftaran: 1,
    idScrim: 1,
    namaTim: 'EVOS Divine',
    namaKapten: 'Sam13',
    whatsappKapten: '+62 812-1111-2222',
    status: StatusPeserta.dikonfirmasi,
    namaScrim: 'Ultimate Pro League',
    slotId: '#SLOT-010',
    tanggal: '24 Okt 2023',
    waktu: '08.00 - 09.00',
    nominal: 50000,
    bankPengirim: 'BCA Digital',
    namaPengirim: 'Sam13',
  ),
  PesertaVerifikasi(
    idPendaftaran: 2,
    idScrim: 1,
    namaTim: 'RRQ Kazu',
    namaKapten: 'Legaeloth',
    whatsappKapten: '+62 812-3456-7890',
    status: StatusPeserta.menunggu,
    namaScrim: 'Ultimate Pro League',
    slotId: '#SLOT-012',
    tanggal: '24 Okt 2023',
    waktu: '08.00 - 09.00',
    nominal: 50000,
    bankPengirim: 'BCA Digital',
    namaPengirim: 'Legaeloth',
  ),
  PesertaVerifikasi(
    idPendaftaran: 3,
    idScrim: 1,
    namaTim: 'Genesis Dogma',
    namaKapten: 'NiciL.',
    whatsappKapten: '+62 813-9999-0000',
    status: StatusPeserta.ditolak,
    namaScrim: 'Ultimate Pro League',
    slotId: '#SLOT-014',
    tanggal: '24 Okt 2023',
    waktu: '08.00 - 09.00',
    nominal: 50000,
    bankPengirim: 'BCA Digital',
    namaPengirim: 'NiciL.',
  ),
];