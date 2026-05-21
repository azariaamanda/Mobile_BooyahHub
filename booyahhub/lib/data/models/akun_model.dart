class Akun {
  final int idAkun;
  final String email;
  final String role;
  final String statusAkun;
  final DateTime dibuatPada;

  Akun({
    required this.idAkun,
    required this.email,
    required this.role,
    required this.statusAkun,
    required this.dibuatPada,
  });

  factory Akun.fromJson(Map<String, dynamic> json) {
    return Akun(
      idAkun: json['id_akun'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? 'pengguna',
      statusAkun: json['status_akun'] ?? 'pending',
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_akun': idAkun,
      'email': email,
      'role': role,
      'status_akun': statusAkun,
      'dibuat_pada': dibuatPada.toIso8601String(),
    };
  }

  // Copy dengan nilai yang diubah
  Akun copyWith({
    int? idAkun,
    String? email,
    String? role,
    String? statusAkun,
    DateTime? dibuatPada,
  }) {
    return Akun(
      idAkun: idAkun ?? this.idAkun,
      email: email ?? this.email,
      role: role ?? this.role,
      statusAkun: statusAkun ?? this.statusAkun,
      dibuatPada: dibuatPada ?? this.dibuatPada,
    );
  }
}