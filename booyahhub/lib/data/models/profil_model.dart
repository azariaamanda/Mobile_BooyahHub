// Model untuk profil_pengguna (tim)
class ProfilPengguna {
  final int idProfil;
  final int idAkun;
  final String namaTim;
  final String? fotoProfil;
  final DateTime dibuatPada;

  ProfilPengguna({
    required this.idProfil,
    required this.idAkun,
    required this.namaTim,
    this.fotoProfil,
    required this.dibuatPada,
  });

  factory ProfilPengguna.fromJson(Map<String, dynamic> json) {
    return ProfilPengguna(
      idProfil: json['id_profil'] ?? 0,
      idAkun: json['akun_id'] ?? 0,
      namaTim: json['nama_tim'] ?? '',
      fotoProfil: json['foto_profil'],
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_profil': idProfil,
      'akun_id': idAkun,
      'nama_tim': namaTim,
      'foto_profil': fotoProfil,
      'dibuat_pada': dibuatPada.toIso8601String(),
    };
  }
}

// Model untuk profil_admin
class ProfilAdmin {
  final int idProfil;
  final int idAkun;
  final String namaLengkap;
  final String noHandphone;
  final String? fotoProfil;
  final String fotoKtp;
  final String statusVerifikasiKtp;
  final DateTime dibuatPada;

  ProfilAdmin({
    required this.idProfil,
    required this.idAkun,
    required this.namaLengkap,
    required this.noHandphone,
    this.fotoProfil,
    required this.fotoKtp,
    required this.statusVerifikasiKtp,
    required this.dibuatPada,
  });

  factory ProfilAdmin.fromJson(Map<String, dynamic> json) {
    return ProfilAdmin(
      idProfil: json['id_profil_admin'] ?? 0,
      idAkun: json['akun_id'] ?? 0,
      namaLengkap: json['nama_lengkap'] ?? '',
      noHandphone: json['no_handphone'] ?? '',
      fotoProfil: json['foto_profil'],
      fotoKtp: json['foto_ktp'] ?? '',
      statusVerifikasiKtp: json['status_verifikasi_ktp'] ?? 'pending',
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_profil_admin': idProfil,
      'akun_id': idAkun,
      'nama_lengkap': namaLengkap,
      'no_handphone': noHandphone,
      'foto_profil': fotoProfil,
      'foto_ktp': fotoKtp,
      'status_verifikasi_ktp': statusVerifikasiKtp,
      'dibuat_pada': dibuatPada.toIso8601String(),
    };
  }
}

// Model untuk profil_owner
class ProfilOwner {
  final int idProfil;
  final int idAkun;
  final String namaLengkap;
  final String noHandphone;
  final String? bankOwner;
  final String? nomorRekening;
  final DateTime dibuatPada;

  ProfilOwner({
    required this.idProfil,
    required this.idAkun,
    required this.namaLengkap,
    required this.noHandphone,
    this.bankOwner,
    this.nomorRekening,
    required this.dibuatPada,
  });

  factory ProfilOwner.fromJson(Map<String, dynamic> json) {
    return ProfilOwner(
      idProfil: json['id_profil_owner'] ?? 0,
      idAkun: json['akun_id'] ?? 0,
      namaLengkap: json['nama_lengkap'] ?? '',
      noHandphone: json['no_handphone'] ?? '',
      bankOwner: json['bank_owner'],
      nomorRekening: json['nomor_rekening'],
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : DateTime.now(),
    );
  }
}