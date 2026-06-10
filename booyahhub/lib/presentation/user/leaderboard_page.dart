import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class LeaderboardPage extends StatefulWidget {
  final int sesiId;

  const LeaderboardPage({
    super.key,
    required this.sesiId,
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaderboardData = [];
  String _dateSubtitle = '';
  String _scrimTitle = '';
  String _sesiTitle = '';

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Ambil info Sesi Scrim (termasuk tanggal dan nama turnamen)
      final sesiRes = await supabase
          .from('sesi_scrim')
          .select('waktu_mulai, nama_sesi, scrim(nama_scrim)')
          .eq('id_sesi', widget.sesiId)
          .maybeSingle();

      if (sesiRes != null) {
        if (sesiRes['waktu_mulai'] != null) {
          DateTime dt = DateTime.parse(sesiRes['waktu_mulai']).toLocal();
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
          _dateSubtitle = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
        }
        
        _sesiTitle = sesiRes['nama_sesi'] ?? '';
        final scrimObj = sesiRes['scrim'];
        if (scrimObj is Map && scrimObj['nama_scrim'] != null) {
          _scrimTitle = scrimObj['nama_scrim'];
        }
      }

      // 2. Ambil Akun ID pengguna saat ini untuk highlight "Kamu"
      int? currentUserAkunId;
      final currentUserEmail = supabase.sessionEmail;
      if (currentUserEmail != null) {
        final akunRes = await supabase
            .from('akun')
            .select('id_akun')
            .eq('email', currentUserEmail)
            .maybeSingle();
        if (akunRes != null) {
          currentUserAkunId = akunRes['id_akun'];
        }
      }

      // 3. Ambil data Hasil Pertandingan yang di-join dengan Pendaftaran Tim
      final response = await supabase
          .from('hasil_pertandingan')
          .select('''
            total_kill,
            total_poin,
            pendaftaran_tim!inner (
              akun_id,
              nama_kapten
            )
          ''')
          .eq('id_sesi', widget.sesiId);

      // Ambil semua akun_id unik dari pendaftaran untuk fetch profil_pengguna
      Set<int> akunIds = {};
      for (var row in response) {
        final pendaftaran = row['pendaftaran_tim'];
        if (pendaftaran != null && pendaftaran['akun_id'] != null) {
          akunIds.add(pendaftaran['akun_id']);
        }
      }

      // Fetch nama_tim dan foto_profil secara manual untuk menghindari error relasi foreign key
      Map<int, String> mapNamaTim = {};
      Map<int, String> mapFotoProfil = {};
      if (akunIds.isNotEmpty) {
        final profilRes = await supabase
            .from('profil_pengguna')
            .select('akun_id, nama_tim, foto_profil')
            .inFilter('akun_id', akunIds.toList());
        for (var prof in profilRes) {
          mapNamaTim[prof['akun_id']] = prof['nama_tim'];
          if (prof['foto_profil'] != null) {
            mapFotoProfil[prof['akun_id']] = prof['foto_profil'];
          }
        }
      }

      // 4. Proses agregasi poin per tim
      Map<int, Map<String, dynamic>> teamStats = {};

      for (var row in response) {
        final pendaftaran = row['pendaftaran_tim'];
        if (pendaftaran == null) continue;
        
        final akunId = pendaftaran['akun_id'];
        if (akunId == null) continue;

        String namaTim = mapNamaTim[akunId] ?? pendaftaran['nama_kapten'] ?? 'Unknown Team';
        String? fotoProfil = mapFotoProfil[akunId];

        if (!teamStats.containsKey(akunId)) {
          teamStats[akunId] = {
            'akun_id': akunId,
            'nama_tim': namaTim,
            'foto_profil': fotoProfil,
            'kills': 0,
            'points': 0,
          };
        }

        teamStats[akunId]!['kills'] += (row['total_kill'] as num?)?.toInt() ?? 0;
        teamStats[akunId]!['points'] += (row['total_poin'] as num?)?.toInt() ?? 0;
      }

      // 5. Konversi Map ke List dan urutkan
      List<Map<String, dynamic>> sortedList = teamStats.values.toList();
      sortedList.sort((a, b) {
        int cmp = (b['points'] as int).compareTo(a['points'] as int);
        if (cmp == 0) {
          return (b['kills'] as int).compareTo(a['kills'] as int);
        }
        return cmp;
      });

      // 6. Beri rank & tandai user current
      for (int i = 0; i < sortedList.length; i++) {
        sortedList[i]['rank'] = i + 1;
        sortedList[i]['is_user'] = (sortedList[i]['akun_id'] == currentUserAkunId);
      }

      if (mounted) {
        setState(() {
          _leaderboardData = sortedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Leaderboard Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _emptyPlayer(int rank) {
    return {'rank': rank, 'nama_tim': '-', 'kills': 0, 'points': 0, 'is_user': false, 'foto_profil': null};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Leaderboard',
            style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.primary, fontSize: 18),
          ),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final allPlayers = _leaderboardData;
    
    // Ambil top 3 buat podium luar (aman jika data kosong/sedikit)
    final top1 = allPlayers.firstWhere((p) => p['rank'] == 1, orElse: () => _emptyPlayer(1));
    final top2 = allPlayers.firstWhere((p) => p['rank'] == 2, orElse: () => _emptyPlayer(2));
    final top3 = allPlayers.firstWhere((p) => p['rank'] == 3, orElse: () => _emptyPlayer(3));

    // List rank 1 ke bawah (semua peringkat)
    final listPlayers = allPlayers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Leaderboard',
          style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.primary, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLeaderboard,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            child: Column(
              children: [
                // HEADER TURNAMEN (Stylized Card)
                if (_scrimTitle.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.inputBorder.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _scrimTitle.toUpperCase(),
                                style: AppTextStyles.poppinsHeadline.copyWith(
                                  fontSize: 16,
                                  color: AppColors.white,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (_sesiTitle.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _sesiTitle.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (_dateSubtitle.isNotEmpty)
                                    Text(
                                      _dateSubtitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
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
                const SizedBox(height: 24),

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

                // ─── 2. LIST ROW SEMUA PERINGKAT ──────────────────────────────
                if (listPlayers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Belum ada tim yang mencetak poin.',
                      style: AppTextStyles.interCaption,
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: 8),
                    itemCount: listPlayers.length,
                    itemBuilder: (context, index) {
                      final player = listPlayers[index];
                      return _buildLeaderboardRow(player);
                    },
                  ),
                  
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET KELOMPOK PODIUM
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPodiumSection(Map<String, dynamic> top1, Map<String, dynamic> top2, Map<String, dynamic> top3) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
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
                if (playerData['foto_profil'] != null && playerData['foto_profil'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      playerData['foto_profil'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.groups_rounded, 
                          color: isFirstPlace ? AppColors.primary : AppColors.textPrimary, 
                          size: 28,
                        ),
                      ),
                    ),
                  )
                else
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
    final bool isUser = player['is_user'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
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
            child: player['foto_profil'] != null && player['foto_profil'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      player['foto_profil'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.groups_rounded, color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                  )
                : Center(
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