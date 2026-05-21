// Model untuk master_mode_pertandingan
class ModePertandingan {
  final int idMode;
  final String namaMode;
  final DateTime dibuatPada;

  ModePertandingan({
    required this.idMode,
    required this.namaMode,
    required this.dibuatPada,
  });

  factory ModePertandingan.fromJson(Map<String, dynamic> json) {
    return ModePertandingan(
      idMode: json['id_mode'] ?? 0,
      namaMode: json['nama_mode'] ?? '',
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : DateTime.now(),
    );
  }
}

// Model untuk scrim (turnamen)
class Scrim {
  final int idScrim;
  final int idAdmin;
  final int idMode;
  final String namaScrim;
  final double biayaPendaftaran;
  final double totalHadiah;
  final int maksPeserta;
  final int jumlahMatch;
  final String? deskripsi;
  final String? syaratKetentuan;
  final String? poster;
  final String statusScrim;
  final DateTime dibuatPada;

  // Relasi (opsional, untuk join)
  final List<SesiScrim>? sesiList;
  final ModePertandingan? mode;

  Scrim({
    required this.idScrim,
    required this.idAdmin,
    required this.idMode,
    required this.namaScrim,
    required this.biayaPendaftaran,
    required this.totalHadiah,
    required this.maksPeserta,
    required this.jumlahMatch,
    this.deskripsi,
    this.syaratKetentuan,
    this.poster,
    required this.statusScrim,
    required this.dibuatPada,
    this.sesiList,
    this.mode,
  });

  factory Scrim.fromJson(Map<String, dynamic> json) {
    return Scrim(
      idScrim: json['id_scrim'] ?? 0,
      idAdmin: json['id_admin'] ?? 0,
      idMode: json['id_mode'] ?? 0,
      namaScrim: json['nama_scrim'] ?? '',
      biayaPendaftaran: (json['biaya_pendaftaran'] ?? 0).toDouble(),
      totalHadiah: (json['total_hadiah'] ?? 0).toDouble(),
      maksPeserta: json['maks_peserta'] ?? 12,
      jumlahMatch: json['jumlah_match'] ?? 3,
      deskripsi: json['deskripsi'],
      syaratKetentuan: json['syarat_ketentuan'],
      poster: json['poster'],
      statusScrim: json['status_scrim'] ?? 'aktif',
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : DateTime.now(),
      sesiList: json['sesi_scrim'] != null
          ? (json['sesi_scrim'] as List)
              .map((e) => SesiScrim.fromJson(e))
              .toList()
          : null,
      mode: json['mode_pertandingan'] != null
          ? ModePertandingan.fromJson(json['mode_pertandingan'])
          : null,
    );
  }
}

// Model untuk sesi_scrim
class SesiScrim {
  final int idSesi;
  final int idScrim;
  final String namaSesi;
  final DateTime waktuMulai;
  final DateTime waktuSelesai;
  final int slotMaksimal;
  final String? roomId;

  // Hitungan slot terisi (dari pendaftaran)
  int? slotTerisi;

  SesiScrim({
    required this.idSesi,
    required this.idScrim,
    required this.namaSesi,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.slotMaksimal,
    this.roomId,
    this.slotTerisi,
  });

  factory SesiScrim.fromJson(Map<String, dynamic> json) {
    return SesiScrim(
      idSesi: json['id_sesi'] ?? 0,
      idScrim: json['id_scrim'] ?? 0,
      namaSesi: json['nama_sesi'] ?? '',
      waktuMulai: json['waktu_mulai'] != null
          ? DateTime.parse(json['waktu_mulai'])
          : DateTime.now(),
      waktuSelesai: json['waktu_selesai'] != null
          ? DateTime.parse(json['waktu_selesai'])
          : DateTime.now(),
      slotMaksimal: json['slot_maksimal'] ?? 12,
      roomId: json['room_id'],
      slotTerisi: json['slot_terisi'],
    );
  }

  // Getter untuk sisa slot
  int get sisaSlot => slotMaksimal - (slotTerisi ?? 0);
  bool get isFull => sisaSlot <= 0;

  // Format waktu untuk ditampilkan
  String get formatWaktu {
    final startHour = waktuMulai.hour.toString().padLeft(2, '0');
    final startMinute = waktuMulai.minute.toString().padLeft(2, '0');
    final endHour = waktuSelesai.hour.toString().padLeft(2, '0');
    final endMinute = waktuSelesai.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  String get formatTanggal {
    return '${waktuMulai.day} ${_getBulan(waktuMulai.month)} ${waktuMulai.year}';
  }

  String _getBulan(int month) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return bulan[month - 1];
  }
}