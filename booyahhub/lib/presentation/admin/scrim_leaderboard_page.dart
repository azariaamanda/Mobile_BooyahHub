import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/admin_service.dart';

class ScrimLeaderboardPage extends StatefulWidget {
  final int sesiId;
  const ScrimLeaderboardPage({super.key, required this.sesiId});

  @override
  State<ScrimLeaderboardPage> createState() => _ScrimLeaderboardPageState();
}

class _ScrimLeaderboardPageState extends State<ScrimLeaderboardPage> {
  final _supabase = Supabase.instance.client;
  final _adminService = AdminService();

  bool _isLoading = true;
  bool _isBagiHadiah = false;
  List<Map<String, dynamic>> _leaderboardData = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      // Ambil current user
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail != null) {
        final userData = await _supabase
            .from('akun')
            .select('id_akun')
            .eq('email', userEmail)
            .maybeSingle();
        _currentUserId = userData?['id_akun'];
      }

      // Ambil semua pendaftaran tim untuk sesi ini
      final pendaftaranList = await _supabase
          .from('pendaftaran_tim')
          .select('id_pendaftaran, akun_id, nama_kapten')
          .eq('id_sesi', widget.sesiId)
          .eq('status_pembayaran', 'dikonfirmasi');

      if (pendaftaranList.isEmpty) {
        _leaderboardData = [];
        setState(() => _isLoading = false);
        return;
      }

      // Ambil semua hasil pertandingan untuk sesi ini
      final results = await _supabase
          .from('hasil_pertandingan')
          .select('total_poin, total_kill, id_pendaftaran')
          .eq('id_sesi', widget.sesiId);

      // Buat mapping pendaftaran_id ke hasil
      final Map<int, Map<String, dynamic>> hasilMap = {};
      for (var r in results) {
        hasilMap[r['id_pendaftaran']] = r;
      }

      // Aggregate data per tim
      Map<int, Map<String, dynamic>> teamAggregate = {};
      
      for (var p in pendaftaranList) {
        final akunId = p['akun_id'] as int?;
        if (akunId == null) continue;
        
        final hasil = hasilMap[p['id_pendaftaran']] ?? {};
        
        String namaTim = 'Tim $akunId';
        
        // Ambil nama tim dari profil_pengguna
        final profilData = await _supabase
            .from('profil_pengguna')
            .select('nama_tim')
            .eq('akun_id', akunId)
            .maybeSingle();
        
        if (profilData != null && profilData['nama_tim'] != null) {
          namaTim = profilData['nama_tim'];
        }
        
        if (!teamAggregate.containsKey(akunId)) {
          teamAggregate[akunId] = {
            'akun_id': akunId,
            'nama_tim': namaTim,
            'kapten': p['nama_kapten'] ?? '',
            'total_poin': 0,
            'total_kill': 0,
          };
        }
        
        teamAggregate[akunId]!['total_poin'] = (teamAggregate[akunId]!['total_poin'] ?? 0) + (hasil['total_poin'] ?? 0);
        teamAggregate[akunId]!['total_kill'] = (teamAggregate[akunId]!['total_kill'] ?? 0) + (hasil['total_kill'] ?? 0);
      }
      
      // Konversi ke list dan urutkan
      List<Map<String, dynamic>> leaderboard = teamAggregate.values.toList();
      leaderboard.sort((a, b) => (b['total_poin'] ?? 0).compareTo(a['total_poin'] ?? 0));
      
      // Tambahkan posisi
      for (int i = 0; i < leaderboard.length; i++) {
        leaderboard[i]['pos'] = i + 1;
        leaderboard[i]['isMyTeam'] = (_currentUserId != null && leaderboard[i]['akun_id'] == _currentUserId);
      }
      
      setState(() => _leaderboardData = leaderboard);
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
  }

  Widget _buildBagiHadiahButton() {
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
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            elevation: 0,
          ),
          onPressed: _isBagiHadiah ? null : _dobagiHadiah,
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

  Widget _avatar(String teamName, double size, {Color? borderColor}) {
    final initials = teamName.trim().split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
        border: Border.all(
          color: borderColor ?? AppColors.inputBorder,
          width: borderColor != null ? 2.5 : 1.5,
        ),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : '?',
          style: TextStyle(
            color: borderColor ?? AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.3,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_leaderboardData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Belum ada data leaderboard', style: AppTextStyles.interBody),
          ],
        ),
      );
    }

    // Pastikan data cukup untuk podium
    final hasPodium = _leaderboardData.length >= 3;
    
    if (!hasPodium) {
      // Hanya tampilkan tabel jika kurang dari 3 tim
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: _buildTable(_leaderboardData),
        ),
        bottomNavigationBar: _buildBagiHadiahButton(),
      );
    }

    final top3 = _leaderboardData.take(3).toList();
    final rest = _leaderboardData.skip(3).toList();

    final podiumOrder = [top3[1], top3[0], top3[2]];
    final podiumColors = [
      const Color(0xFFC0C0C0),
      const Color(0xFFC9A227),
      const Color(0xFFCD7F32),
    ];
    final podiumRanks = [2, 1, 3];
    final podiumHeights = [90.0, 120.0, 75.0];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPodium(podiumOrder, podiumColors, podiumRanks, podiumHeights),
            const SizedBox(height: 28),
            if (rest.isNotEmpty) _buildTable(rest),
          ],
        ),
      ),
      bottomNavigationBar: _buildBagiHadiahButton(),
    );
  }

  Widget _buildPodium(
    List<Map<String, dynamic>> order,
    List<Color> colors,
    List<int> ranks,
    List<double> podiumHeights,
  ) {
    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final item = order[i];
          final color = colors[i];
          final rank = ranks[i];
          final isCenter = rank == 1;
          final teamName = item['nama_tim'] ?? 'Team';
          final totalPoin = item['total_poin'] ?? 0;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    _avatar(
                      teamName,
                      isCenter ? 72 : 52,
                      borderColor: color,
                    ),
                    if (isCenter)
                      Positioned(
                        top: -22,
                        child: Icon(Icons.workspace_premium_rounded, color: color, size: 28),
                      ),
                    if (!isCenter)
                      Positioned(
                        bottom: -2,
                        right: 8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    teamName,
                    style: AppTextStyles.poppinsTitleSmall.copyWith(
                      fontSize: isCenter ? 13 : 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalPoin',
                  style: AppTextStyles.poppinsMoneyLarge.copyWith(
                    fontSize: isCenter ? 28 : 20,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: podiumHeights[i],
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.12),
                    border: Border(
                      top: BorderSide(color: color, width: 2),
                      left: BorderSide(color: color.withValues(alpha:0.3), width: 1),
                      right: BorderSide(color: color.withValues(alpha:0.3), width: 1),
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: isCenter ? 22 : 17,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: AppColors.surfaceVariant)),
            ),
            child: Row(
              children: [
                _headerCell('POS', width: 38),
                const SizedBox(width: 12),
                Expanded(child: _headerText('TEAM / PLAYER')),
                _headerCell('KILLS', width: 46),
                const SizedBox(width: 8),
                _headerCell('POIN', width: 46),
              ],
            ),
          ),
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final isLast = i == items.length - 1;
            final isMyTeam = item['isMyTeam'] == true;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: isMyTeam ? AppColors.primary.withValues(alpha:0.07) : Colors.transparent,
                borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(13)) : BorderRadius.zero,
                border: !isLast ? Border(bottom: BorderSide(color: AppColors.surfaceVariant)) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Center(
                      child: Text(
                        '${item['pos']}',
                        style: AppTextStyles.poppinsTitleSmall.copyWith(
                          color: isMyTeam ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _avatar(item['nama_tim'], 34, borderColor: isMyTeam ? AppColors.primary : null),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nama_tim'],
                          style: AppTextStyles.poppinsTitleSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item['kapten'] != null && item['kapten'].isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Capt: ${item['kapten']}',
                            style: AppTextStyles.interCaption.copyWith(
                              fontSize: 10.5,
                              color: isMyTeam ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isMyTeam ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 46,
                    child: Center(
                      child: Text(
                        '${item['total_kill']}',
                        style: AppTextStyles.interBody.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 46,
                    child: Center(
                      child: Text(
                        '${item['total_poin']}',
                        style: AppTextStyles.poppinsMoneySmall.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isMyTeam ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required double width}) {
    return SizedBox(
      width: width,
      child: Center(child: _headerText(text)),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: AppTextStyles.interLabel.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }
}