import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class HistoryScrimPage extends StatefulWidget {
  const HistoryScrimPage({super.key});

  @override
  State<HistoryScrimPage> createState() => _HistoryScrimPageState();
}

class _HistoryScrimPageState extends State<HistoryScrimPage> {
  String _selectedStatusFilter = 'all'; // 'all', 'selesai', 'dibatalkan'

  // ─── DATA HARDCODE STRUKTUR MIRIP SUPABASE ──────────────────────────────────
  final List<Map<String, dynamic>> _dummyHistory = [
    {
      'id_scrim': 101,
      'nama_scrim': 'Scrim Ganteng',
      'tanggal': '18 Apr 2023',
      'jam': '19:00 WIB',
      'status': 'selesai', // selesai / dibatalkan
      'badge_text': 'JUARA 1',
      'peringkat_info': 'Peringkat 1 dari 12 tim',
      'has_rank': true,
    },
    {
      'id_scrim': 102,
      'nama_scrim': 'Scrim Ganteng',
      'tanggal': '18 Apr 2023',
      'jam': '19:00 WIB',
      'status': 'selesai',
      'badge_text': 'JUARA 2',
      'peringkat_info': 'Peringkat 3 dari 12 tim',
      'has_rank': true,
    },
    {
      'id_scrim': 103,
      'nama_scrim': 'Scrim Ganteng',
      'tanggal': '18 Apr 2023',
      'jam': '19:00 WIB',
      'status': 'dibatalkan',
      'badge_text': 'CANCELLED',
      'peringkat_info': '',
      'has_rank': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Logika menyaring data lokal berdasarkan tombol filter yang aktif bray
    final filteredList = _dummyHistory.where((item) {
      if (_selectedStatusFilter == 'all') return true;
      return item['status'] == _selectedStatusFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      // ─── APP BAR SESUAI GAMBAR ─────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Riwayat Scrim',
          style: AppTextStyles.poppinsTitle.copyWith(fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingS),

              // ─── 1. BUTTON DATE FILTER (MOCK FILTER BULAN) ─────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Oct 2023',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              // ─── 2. HORIZONTAL STATUS FILTER ───────────────────────────────
              Row(
                children: [
                  _buildStatusChip('All Scrims', 'all'),
                  const SizedBox(width: AppConstants.paddingS),
                  _buildStatusChip('Selesai', 'selesai'),
                  const SizedBox(width: AppConstants.paddingS),
                  _buildStatusChip('Dibatalkan', 'dibatalkan'),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              // ─── 3. LIST HISTORY CARDS ─────────────────────────────────────
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada riwayat pada kategori ini bray.',
                          style: AppTextStyles.interBody,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final history = filteredList[index];
                          final bool isCancelled = history['status'] == 'dibatalkan';
                          final bool isJuara1 = history['badge_text'] == 'JUARA 1';

                          return GestureDetector(
                            onTap: () {
                              context.push('/user/history-detail');
                            },
                            child: Container(
                            margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              borderRadius: BorderRadius.circular(AppConstants.radiusL),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Bagian Atas: Info Utama Scrim
                                Padding(
                                  padding: const EdgeInsets.all(AppConstants.paddingM),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Foto Banner / Avatar Bulat Kotak
                                      Container(
                                        width: 65,
                                        height: 65,
                                        decoration: BoxDecoration(
                                          color: isCancelled ? Colors.grey.shade300 : Colors.black26,
                                          borderRadius: BorderRadius.circular(20),
                                          image: isCancelled
                                              ? null
                                              : const DecorationImage(
                                                  image: NetworkImage('https://via.placeholder.com/150'), // Nanti ganti AppImageHelper bray
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        child: isCancelled
                                            ? const Icon(Icons.person, color: Colors.grey, size: 30)
                                            : null,
                                      ),
                                      const SizedBox(width: AppConstants.paddingM),

                                      // Teks Detail Tengah
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              history['nama_scrim'],
                                              style: AppTextStyles.poppinsSectionTitle.copyWith(fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              history['tanggal'],
                                              style: AppTextStyles.interBodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 13),
                                            ),
                                            Text(
                                              history['jam'],
                                              style: AppTextStyles.interBodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Badge Juara / Status Sebelah Kanan
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isCancelled
                                                  ? const Color(0xFF4A2829) // Merah redup kalem
                                                  : (isJuara1 ? AppColors.primary : Colors.white),
                                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                            ),
                                            child: Text(
                                              history['badge_text'],
                                              style: TextStyle(
                                                color: isCancelled
                                                    ? Colors.redAccent
                                                    : (isJuara1 ? AppColors.buttonText : Colors.black),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isCancelled ? Colors.red : Colors.green,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isCancelled ? 'Dibatalkan' : 'Selesai',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Garis Pembatas Menengah & Info Peringkat Bawah (Jika Ada)
                                if (history['has_rank']) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                                    child: Divider(color: AppColors.inputBorder, thickness: 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppConstants.paddingM,
                                      vertical: AppConstants.paddingS,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.keyboard_double_arrow_up, color: AppColors.textSecondary, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              history['peringkat_info'],
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ]
                              ],
                            ),
                          ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WIDGET BUILDER UNTUK FILTER CHIP ATAS ──────────────────────────────────
  Widget _buildStatusChip(String label, String value) {
    final bool isSelected = _selectedStatusFilter == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatusFilter = value;
          });
        },
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}