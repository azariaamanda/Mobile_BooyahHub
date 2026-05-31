import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_color.dart'; // Sesuaikan dengan path project lu bray
import '../../config/app_constants.dart'; 
import '../../config/app_text_styles.dart';

class LeaderboardPage extends StatelessWidget {
  final int sesiId; // Ditambahkan agar match dengan app_router.dart

  const LeaderboardPage({
    super.key,
    required this.sesiId,
  });

  // ─── DUMMY DATA LEADERBOARD (Sesuai mockup dark theme lu) ─────────────────
  List<Map<String, dynamic>> _getLeaderboardData() {
    return [
      {'rank': 1, 'nama_tim': 'Scrim Ganteng', 'kills': 15, 'points': 150, 'is_user': false},
      {'rank': 2, 'nama_tim': 'Scrim Ganteng', 'kills': 15, 'points': 150, 'is_user': false},
      {'rank': 3, 'nama_tim': 'Scrim Ganteng', 'kills': 15, 'points': 150, 'is_user': false},
      {'rank': 4, 'nama_tim': 'Scrim Ganteng', 'kills': 15, 'points': 150, 'is_user': false},
      {'rank': 5, 'nama_tim': 'Kamu', 'kills': 15, 'points': 150, 'is_user': true}, // Highlight Gold
      {'rank': 6, 'nama_tim': 'Scrim Ganteng', 'kills': 15, 'points': 150, 'is_user': false},
      {'rank': 7, 'nama_tim': 'Scrim Ganteng', 'kills': 15, 'points': 150, 'is_user': false},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final allPlayers = _getLeaderboardData();
    
    // Ambil top 3 buat podium luar
    final top1 = allPlayers.firstWhere((p) => p['rank'] == 1);
    final top2 = allPlayers.firstWhere((p) => p['rank'] == 2);
    final top3 = allPlayers.firstWhere((p) => p['rank'] == 3);

    // List rank 4 ke bawah
    final listPlayers = allPlayers.where((p) => p['rank'] > 3).toList();

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
          'Leaderboard',
          style: AppTextStyles.poppinsTitle.copyWith(fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Subtitle Tanggal di bawah Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '15 Apr 2023',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── 1. AREA PODIUM (RANK 1, 2, 3) ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: _buildPodiumSection(top1, top2, top3),
            ),
            
            const SizedBox(height: 24),

            // Header kolom list: POS, TEAM / PLAYER, KILLS, POINTS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXL),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('POS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary.withOpacity(0.6), letterSpacing: 1)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('TEAM / PLAYER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary.withOpacity(0.6), letterSpacing: 1)),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text('KILLS', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary.withOpacity(0.6), letterSpacing: 1)),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text('POINTS', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary.withOpacity(0.6), letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ─── 2. LIST ROW RANK 4 SAMPAI BAWAH ──────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: 8),
                itemCount: listPlayers.length,
                itemBuilder: (context, index) {
                  final player = listPlayers[index];
                  return _buildLeaderboardRow(player);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET KELOMPOK PODIUM (3 Pilar Juara) -> Perbaikan properti Row di sini!
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPodiumSection(Map<String, dynamic> top1, Map<String, dynamic> top2, Map<String, dynamic> top3) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end, // Menggantikan properti alignment yang error kemarin
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // PILAR JUARA 2 (Kiri)
        _buildPodiumPillar(
          playerData: top2,
          pillarHeight: 110,
          pillarColor: AppColors.backgroundCard,
          avatarBgColor: AppColors.backgroundCard,
          rankNumber: '2',
        ),
        const SizedBox(width: 12),

        // PILAR JUARA 1 (Tengah - Glowing & Menonjol)
        _buildPodiumPillar(
          playerData: top1,
          pillarHeight: 145,
          pillarColor: AppColors.primary,
          avatarBgColor: AppColors.primary.withOpacity(0.2),
          rankNumber: '1',
          isFirstPlace: true,
        ),
        const SizedBox(width: 12),

        // PILAR JUARA 3 (Kanan)
        _buildPodiumPillar(
          playerData: top3,
          pillarHeight: 85,
          pillarColor: AppColors.backgroundCard,
          avatarBgColor: AppColors.backgroundCard,
          rankNumber: '3',
        ),
      ],
    );
  }

  // WIDGET SATUAN PILAR PODIUM
  Widget _buildPodiumPillar({
    required Map<String, dynamic> playerData,
    required double pillarHeight,
    required Color pillarColor,
    required Color avatarBgColor,
    required String rankNumber,
    bool isFirstPlace = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar Kotak Berwarna Sesuai Rank
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: avatarBgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isFirstPlace ? AppColors.primary : AppColors.inputBorder.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: isFirstPlace 
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 15, spreadRadius: 1)]
                : [],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    Icons.groups_rounded, 
                    color: isFirstPlace ? AppColors.primary : AppColors.textPrimary, 
                    size: 28,
                  ),
                ),
                // Badge Angka Posisi di Bawah Avatar
                Positioned(
                  bottom: -8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isFirstPlace ? AppColors.primary : AppColors.inputBorder.withOpacity(0.5), 
                          width: 1
                        ),
                      ),
                      child: Text(
                        rankNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isFirstPlace ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Nama Tim
          Text(
            playerData['nama_tim'],
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.poppinsHeadline.copyWith(
              fontSize: 13, 
              fontWeight: isFirstPlace ? FontWeight.bold : FontWeight.w500,
              color: isFirstPlace ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          // Skor Poin Kecil
          Text(
            '${playerData['points']}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),

          // Balok Tiang Podium
          Container(
            height: pillarHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: pillarColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Container(
                width: 2,
                height: pillarHeight * 0.4,
                color: isFirstPlace ? AppColors.background.withOpacity(0.4) : AppColors.inputBorder.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET ROW LIST LEADERBOARD (Rank 4++)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLeaderboardRow(Map<String, dynamic> player) {
    final bool isUser = player['is_user'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        // Border emas tipis khusus buat row player login ('Kamu')
        border: Border.all(
          color: isUser ? AppColors.primary : Colors.transparent,
          width: isUser ? 1.5 : 0,
        ),
      ),
      child: Row(
        children: [
          // 1. Posisi Rank
          SizedBox(
            width: 30,
            child: Text(
              '${player['rank']}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isUser ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 2. Avatar Thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.background.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: isUser
                  ? Text(
                      'KM',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.background),
                    )
                  : const Icon(Icons.groups_rounded, color: AppColors.textSecondary, size: 18),
            ),
          ),
          const SizedBox(width: 12),

          // 3. Nama Player / Tim
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['nama_tim'],
                  style: AppTextStyles.poppinsHeadline.copyWith(
                    fontSize: 14,
                    color: isUser ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isUser ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isUser)
                  Text(
                    'YOUR TEAM',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary.withOpacity(0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),

          // 4. Kill Stat
          SizedBox(
            width: 50,
            child: Text(
              '${player['kills']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // 5. Total Points
          SizedBox(
            width: 60,
            child: Text(
              '${player['points']}',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isUser ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}