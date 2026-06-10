import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class ScrimLeaderboardPage extends StatefulWidget {
  final int sesiId;
  const ScrimLeaderboardPage({super.key, required this.sesiId});

  @override
  State<ScrimLeaderboardPage> createState() => _ScrimLeaderboardPageState();
}

class _ScrimLeaderboardPageState extends State<ScrimLeaderboardPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> _poinSystem = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Ambil sistem poin
      final poinData = await _supabase
          .from('sistem_poin')
          .select('placement, poin_placement')
          .order('placement', ascending: true);
      _poinSystem = List<Map<String, dynamic>>.from(poinData);

      // Ambil data leaderboard
      await _fetchLeaderboard();
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      // Ambil current user
      final userEmail = _supabase.sessionEmail;
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
        _leaderboard = [];
        setState(() => _isLoading = false);
        return;
      }

      // Ambil SEMUA hasil pertandingan (tidak filter match_ke!)
      final results = await _supabase
          .from('hasil_pertandingan')
          .select('total_poin, total_kill, id_pendaftaran')
          .eq('id_sesi', widget.sesiId);
          // HAPUS: .eq('match_ke', 1);

      // Aggregate data per tim
      Map<int, Map<String, dynamic>> teamAggregate = {};
      
      for (var p in pendaftaranList) {
        final akunId = p['akun_id'] as int?;
        if (akunId == null) continue;
        
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
        
        // Filter results untuk pendaftaran ini dan sum semua match
        final teamResults = results.where((r) => r['id_pendaftaran'] == p['id_pendaftaran']).toList();
        
        int totalPoin = 0;
        int totalKill = 0;
        
        for (var result in teamResults) {
          totalPoin += (result['total_poin'] ?? 0) as int;
          totalKill += (result['total_kill'] ?? 0) as int;
        }
        
        teamAggregate[akunId]!['total_poin'] = totalPoin;
        teamAggregate[akunId]!['total_kill'] = totalKill;
      }
      
      // Konversi ke list dan urutkan
      List<Map<String, dynamic>> leaderboard = teamAggregate.values.toList();
      leaderboard.sort((a, b) => (b['total_poin'] ?? 0).compareTo(a['total_poin'] ?? 0));
      
      // Tambahkan posisi
      for (int i = 0; i < leaderboard.length; i++) {
        leaderboard[i]['pos'] = i + 1;
        leaderboard[i]['isMyTeam'] = (_currentUserId != null && leaderboard[i]['akun_id'] == _currentUserId);
      }
      
      setState(() => _leaderboard = leaderboard);
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Belum ada data skor', style: AppTextStyles.interBody),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                SizedBox(width: 50, child: Text('Rank', style: AppTextStyles.interLabel)),
                Expanded(child: Text('Tim', style: AppTextStyles.interLabel)),
                SizedBox(width: 60, child: Text('Kill', style: AppTextStyles.interLabel)),
                SizedBox(width: 60, child: Text('Poin', style: AppTextStyles.interLabel)),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: _leaderboard.length,
              itemBuilder: (context, index) {
                final team = _leaderboard[index];
                final rank = team['pos'];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          rank.toString(),
                          style: rank <= 3
                              ? AppTextStyles.poppinsMoney.copyWith(
                                  color: AppColors.primary, fontSize: 16)
                              : AppTextStyles.interBody,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(team['nama_tim'], style: AppTextStyles.poppinsTitleSmall),
                            Text('Kapten: ${team['kapten']}', style: AppTextStyles.interCaption),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${team['total_kill']}',
                          style: AppTextStyles.interBody,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${team['total_poin']}',
                          style: AppTextStyles.poppinsMoney.copyWith(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}