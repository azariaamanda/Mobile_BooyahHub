import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/admin_service.dart';

class ScrimLeaderboardPage extends StatefulWidget {
  final int sesiId;

  const ScrimLeaderboardPage({
    super.key,
    required this.sesiId,
  });

  @override
  State<ScrimLeaderboardPage> createState() => _ScrimLeaderboardPageState();
}

class _ScrimLeaderboardPageState extends State<ScrimLeaderboardPage> {
  final _adminService = AdminService();
  bool _isLoading = true;
  bool _isBagiHadiah = false;
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

      // 1. Ambil info Sesi Scrim
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

      // 2. Ambil semua pendaftaran tim untuk sesi ini
      final pendaftaranList = await supabase
          .from('pendaftaran_tim')
          .select('id_pendaftaran, akun_id, nama_kapten, dibuat_pada')
          .eq('id_sesi', widget.sesiId)
          .eq('status_pembayaran', 'dikonfirmasi');

      if (pendaftaranList.isEmpty) {
        if (mounted) {
          setState(() {
            _leaderboardData = [];
            _isLoading = false;
          });
        }
        return;
      }

      // 3. Ambil semua hasil pertandingan untuk sesi ini
      final hasilList = await supabase
          .from('hasil_pertandingan')
          .select('*')
          .eq('id_sesi', widget.sesiId)
          .order('diupdate_pada', ascending: false); // Urutkan dari yang terbaru

      // Buat mapping hasil per pendaftaran (TOTAL semua match)
      // Tapi untuk akun yang sama, ambil dari pendaftaran terbaru
      Map<int, Map<String, dynamic>> hasilPerPendaftaran = {};
      
      for (var h in hasilList) {
        final idPendaftaran = h['id_pendaftaran'];
        final totalKill = h['total_kill'] ?? 0;
        final totalPoin = h['total_poin'] ?? 0;
        
        if (!hasilPerPendaftaran.containsKey(idPendaftaran)) {
          hasilPerPendaftaran[idPendaftaran] = {
            'total_kill': 0,
            'total_poin': 0,
            'match_ke': h['match_ke'] ?? 0,
          };
        }
        
        hasilPerPendaftaran[idPendaftaran]!['total_kill'] += totalKill;
        hasilPerPendaftaran[idPendaftaran]!['total_poin'] += totalPoin;
      }

      // 4. Ambil profil pengguna untuk semua akun_id
      Set<int> akunIds = {};
      for (var p in pendaftaranList) {
        if (p['akun_id'] != null) {
          akunIds.add(p['akun_id']);
        }
      }

      Map<int, String> mapNamaTim = {};
      Map<int, String> mapFotoProfil = {};
      if (akunIds.isNotEmpty) {
        final profilRes = await supabase
            .from('profil_pengguna')
            .select('akun_id, nama_tim, foto_profil')
            .inFilter('akun_id', akunIds.toList());
        for (var prof in profilRes) {
          mapNamaTim[prof['akun_id']] = prof['nama_tim'];
          mapFotoProfil[prof['akun_id']] = prof['foto_profil'];
        }
      }

      // 5. Cari pendaftaran terbaru untuk setiap akun
      Map<int, Map<String, dynamic>> pendaftaranTerbaruPerAkun = {};
      
      // Urutkan pendaftaran dari yang terbaru
      List<Map<String, dynamic>> sortedPendaftaran = List.from(pendaftaranList);
      sortedPendaftaran.sort((a, b) {
        DateTime aDate = DateTime.parse(a['dibuat_pada'] ?? '2000-01-01');
        DateTime bDate = DateTime.parse(b['dibuat_pada'] ?? '2000-01-01');
        return bDate.compareTo(aDate);
      });
      
      for (var p in sortedPendaftaran) {
        final akunId = p['akun_id'];
        if (akunId != null && !pendaftaranTerbaruPerAkun.containsKey(akunId)) {
          pendaftaranTerbaruPerAkun[akunId] = {
            'id_pendaftaran': p['id_pendaftaran'],
            'akun_id': akunId,
            'nama_kapten': p['nama_kapten'] ?? '',
          };
        }
      }

      // 6. Proses data leaderboard per akun (ambil dari pendaftaran terbaru)
      List<Map<String, dynamic>> teamList = [];

      for (var entry in pendaftaranTerbaruPerAkun.entries) {
        final akunId = entry.key;
        final pendaftaranData = entry.value;
        final pendaftaranId = pendaftaranData['id_pendaftaran'];
        final hasil = hasilPerPendaftaran[pendaftaranId] ?? {'total_kill': 0, 'total_poin': 0};
        
        String namaTim = mapNamaTim[akunId] ?? pendaftaranData['nama_kapten'] ?? 'Team $akunId';
        String? fotoProfil = mapFotoProfil[akunId];
        
        teamList.add({
          'akun_id': akunId,
          'nama_tim': namaTim,
          'foto_profil': fotoProfil,
          'total_kill': hasil['total_kill'],
          'total_poin': hasil['total_poin'],
        });
      }

      // 7. Urutkan berdasarkan total poin
      teamList.sort((a, b) {
        int cmp = (b['total_poin'] as int).compareTo(a['total_poin'] as int);
        if (cmp == 0) {
          return (b['total_kill'] as int).compareTo(a['total_kill'] as int);
        }
        return cmp;
      });

      // 8. Beri rank
      for (int i = 0; i < teamList.length; i++) {
        teamList[i]['rank'] = i + 1;
      }

      if (mounted) {
        setState(() {
          _leaderboardData = teamList;
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
    return {'rank': rank, 'nama_tim': '-', 'total_kill': 0, 'total_poin': 0, 'foto_profil': null};
  }

  Future<void> _dobagiHadiah() async {
    setState(() => _isBagiHadiah = true);
    final result = await _adminService.bagiHadiah(widget.sesiId);
    if (!mounted) return;
    setState(() => _isBagiHadiah = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor:
            (result['success'] as bool? ?? false) ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    await _fetchLeaderboard();
  }

  Widget _buildBagiHadiahButton() {
    final hasPoinData = _leaderboardData.any((team) => (team['total_poin'] ?? 0) > 0);
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingM,
        AppConstants.paddingS,
        AppConstants.paddingM,
        AppConstants.paddingM + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            elevation: 0,
          ),
          onPressed: (_isBagiHadiah || !hasPoinData) ? null : _dobagiHadiah,
          child: _isBagiHadiah
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.emoji_events, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Bagi Hadiah ke Pemenang',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
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
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Leaderboard',
            style: AppTextStyles.poppinsTitle.copyWith(fontSize: 18),
          ),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final allPlayers = _leaderboardData;
    
    final top1 = allPlayers.firstWhere((p) => p['rank'] == 1, orElse: () => _emptyPlayer(1));
    final top2 = allPlayers.firstWhere((p) => p['rank'] == 2, orElse: () => _emptyPlayer(2));
    final top3 = allPlayers.firstWhere((p) => p['rank'] == 3, orElse: () => _emptyPlayer(3));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchLeaderboard,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            child: Column(
              children: [
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                  child: _buildPodiumSection(top1, top2, top3),
                ),
                
                const SizedBox(height: 24),

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

                if (allPlayers.isEmpty)
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
                    itemCount: allPlayers.length,
                    itemBuilder: (context, index) {
                      final player = allPlayers[index];
                      return _buildLeaderboardRow(player);
                    },
                  ),
                  
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBagiHadiahButton(),
    );
  }

  Widget _buildPodiumSection(Map<String, dynamic> top1, Map<String, dynamic> top2, Map<String, dynamic> top3) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPodiumPillar(
          playerData: top2,
          pillarHeight: 110,
          pillarColor: AppColors.backgroundCard,
          avatarBgColor: AppColors.backgroundCard,
          rankNumber: '2',
        ),
        const SizedBox(width: 12),

        _buildPodiumPillar(
          playerData: top1,
          pillarHeight: 145,
          pillarColor: AppColors.primary,
          avatarBgColor: AppColors.primary.withOpacity(0.2),
          rankNumber: '1',
          isFirstPlace: true,
        ),
        const SizedBox(width: 12),

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
                        child: Icon(Icons.groups_rounded, color: isFirstPlace ? AppColors.primary : AppColors.textPrimary, size: 28),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Icon(Icons.groups_rounded, color: isFirstPlace ? AppColors.primary : AppColors.textPrimary, size: 28),
                  ),
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
          Text(
            '${playerData['total_poin']}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
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

  Widget _buildLeaderboardRow(Map<String, dynamic> player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${player['rank']}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.6),
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
                    child: const Icon(Icons.groups_rounded, color: AppColors.textSecondary, size: 18),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['nama_tim'],
                  style: AppTextStyles.poppinsHeadline.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${player['total_kill']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '${player['total_poin']}',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}