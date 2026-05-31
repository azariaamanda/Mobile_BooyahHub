import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class HistoryDetailScrimPage extends StatelessWidget {
  const HistoryDetailScrimPage({super.key});

  // ─── DUMMY DATA (nanti ganti dari Supabase) ──────────────────────────────
  Map<String, dynamic> _getScrimData() {
    return {
      'nama_scrim': 'Scrim Ganteng',
      'bulan': 'APR',
      'tanggal_angka': '15',
      'jam': '18.30',
      'zona_waktu': 'WIB',
      'nama_tim': 'Rafif Killer',
      'peringkat_akhir': 'JUARA 1',
      'total_poin': 150,
      'total_kills': 15,
      'status': 'selesai',
      'id_sesi': 1,
      'id_pendaftaran': 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _getScrimData();
    final bool isCancelled = data['status'] == 'dibatalkan';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detail Riwayat Scrim',
          style: AppTextStyles.poppinsTitle.copyWith(fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingM),

              // ─── 1. CARD INFO SESI SCRIM ──────────────────────────────────
              _buildScrimInfoCard(data),

              const SizedBox(height: AppConstants.paddingXL),

              // ─── 2. SECTION HEADER "Hasil Scrim" ──────────────────────────
              Text(
                'Hasil Scrim',
                style: AppTextStyles.poppinsSectionTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppConstants.paddingM),

              // ─── 3. PERINGKAT AKHIR CARD ──────────────────────────────────
              _buildPeringkatCard(data, isCancelled),

              const SizedBox(height: AppConstants.paddingM),

              // ─── 4. TOTAL POIN & KILLS ────────────────────────────────────
              _buildStatsRow(data),

              const SizedBox(height: AppConstants.paddingXL),

              // ─── 5. TOMBOL AJUKAN KLAIM ───────────────────────────────────
              if (!isCancelled) ...[
                _buildClaimButton(context, data),
                const SizedBox(height: AppConstants.paddingM),

                // ─── 6. TOMBOL LIHAT LEADERBOARD ──────────────────────────────
                _buildLeaderboardButton(context, data),
                const SizedBox(height: AppConstants.paddingXL),
              ],

              if (isCancelled) ...[
                _buildCancelledInfo(),
                const SizedBox(height: AppConstants.paddingXL),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET: SCRIM INFO CARD (Bagian Atas)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildScrimInfoCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Atas: Label + Nama Scrim + Badge Tanggal
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kiri: Label + Nama Scrim
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SESI SCRIM',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['nama_scrim'],
                        style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ),

                // Kanan: Badge Tanggal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(color: AppColors.inputBorder, width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        data['bulan'],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['tanggal_angka'],
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
            child: Divider(color: AppColors.inputBorder.withOpacity(0.5), thickness: 1),
          ),

          // Bagian Bawah: Time & Your Team
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Row(
              children: [
                // TIME
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIME',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${data['jam']}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            data['zona_waktu'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // YOUR TEAM
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR TEAM',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['nama_tim'],
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET: PERINGKAT AKHIR CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPeringkatCard(Map<String, dynamic> data, bool isCancelled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingL,
      ),
      decoration: BoxDecoration(
        gradient: isCancelled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2A1A1A),
                  const Color(0xFF1A0F0F),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A2308),
                  Color(0xFF1A1605),
                  Color(0xFF0F0D03),
                ],
              ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        children: [
          // Kiri: Label + Peringkat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERINGKAT AKHIR',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCancelled ? AppColors.error : AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCancelled ? 'DIBATALKAN' : data['peringkat_akhir'],
                  style: GoogleFonts.poppins(
                    fontSize: isCancelled ? 28 : 40,
                    fontWeight: FontWeight.w900,
                    color: isCancelled
                        ? AppColors.error.withOpacity(0.8)
                        : AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // Kanan: Icon chevron up
          if (!isCancelled)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.keyboard_double_arrow_up_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),

          if (isCancelled)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.cancel_outlined,
                color: AppColors.error.withOpacity(0.6),
                size: 32,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET: STATS ROW (Total Poin & Total Kills)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Row(
      children: [
        // Total Poin
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              border: Border.all(
                color: AppColors.inputBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL POIN',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${data['total_poin']}',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PTS',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppConstants.paddingM),

        // Total Kills
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              border: Border.all(
                color: AppColors.inputBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL KILLS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${data['total_kills']}',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'kill',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET: TOMBOL AJUKAN KLAIM (Kuning)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildClaimButton(BuildContext context, Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: () {
          context.push('/user/klaim/${data['id_pendaftaran']}');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ajukan Klaim',
              style: AppTextStyles.poppinsButton.copyWith(fontSize: 16),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET: TOMBOL LIHAT LEADERBOARD (Outline)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLeaderboardButton(BuildContext context, Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: OutlinedButton(
        onPressed: () {
          context.push('/user/leaderboard/${data['id_sesi']}');
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.inputBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.textPrimary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Lihat Leaderboard',
              style: AppTextStyles.poppinsButton.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET: INFO DIBATALKAN
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCancelledInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A1A),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scrim ini telah dibatalkan. Tidak ada data hasil yang tersedia.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
