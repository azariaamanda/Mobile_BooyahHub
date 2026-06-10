// lib/data/models/admin_model.dart

class AdminModel {
  final int idAkun;
  final String email;
  final String role;
  final String statusAkun;
  final double totalUtang;
  final double limitUtang;
  final int? idProfilAdmin;
  final String? namaLengkap;
  final String? noHandphone;
  final String? fotoProfil;
  final String? fotoKtp;
  final String? statusVerifikasiKtp;

  AdminModel({
    required this.idAkun,
    required this.email,
    required this.role,
    required this.statusAkun,
    required this.totalUtang,
    required this.limitUtang,
    this.idProfilAdmin,
    this.namaLengkap,
    this.noHandphone,
    this.fotoProfil,
    this.fotoKtp,
    this.statusVerifikasiKtp,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    // Ambil data dari profil_admin jika ada (join)
    final profil = json['profil_admin'] as Map<String, dynamic>?;
    
    return AdminModel(
      idAkun: json['id_akun'],
      email: json['email'] ?? '',
      role: json['role'] ?? 'admin',
      statusAkun: json['status_akun'] ?? 'aktif',
      totalUtang: (profil?['total_utang'] ?? 0).toDouble(),
      limitUtang: (profil?['limit_utang'] ?? 100000).toDouble(),
      idProfilAdmin: profil?['id_profil_admin'],
      namaLengkap: profil?['nama_lengkap'],
      noHandphone: profil?['no_handphone'],
      fotoProfil: profil?['foto_profil'],
      fotoKtp: profil?['foto_ktp'],
      statusVerifikasiKtp: profil?['status_verifikasi_ktp'],
    );
  }

  // Helper getters
  bool get isSuspended => statusAkun == 'suspended';
  bool get isAktif => statusAkun == 'aktif';
  bool get melebihiLimit => totalUtang >= limitUtang;
  double get sisaLimit => limitUtang - totalUtang;
  
  String get formattedTotalUtang => _formatRupiah(totalUtang);
  String get formattedLimit => _formatRupiah(limitUtang);
  String get formattedSisaLimit => _formatRupiah(sisaLimit);

  String _formatRupiah(double value) {
    return 'Rp ${value.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }
}