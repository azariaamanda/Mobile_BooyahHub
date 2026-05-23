// lib/data/models/sesi_scrim_model.dart

class SesiScrimModel {
  final int idSesi;
  final int idScrim;
  final String namaSesi;
  final DateTime waktuMulai;
  final DateTime waktuSelesai;
  final int slotMaksimal;
  final int slotTerisi;

  const SesiScrimModel({
    required this.idSesi,
    required this.idScrim,
    required this.namaSesi,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.slotMaksimal,
    required this.slotTerisi,
  });

  // Getter untuk menghitung sisa slot secara realtime di UI
  int get sisaSlot => slotMaksimal - slotTerisi;
  
  // Getter untuk ngecek apakah sesi sudah penuh
  bool get isFull => sisaSlot <= 0;
}