import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'scrim_points_page.dart';
import 'scrim_leaderboard_page.dart';

class DetailSessionPage extends StatefulWidget {
  final int sesiId;
  const DetailSessionPage({super.key, required this.sesiId});

  @override
  State<DetailSessionPage> createState() => _DetailSessionPageState();
}

class _DetailSessionPageState extends State<DetailSessionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _scrim;
  List<Map<String, dynamic>> _teams = [];
  int _jumlahMatch = 4;
  int _selectedMatch = 1;
  final List<bool> _isDistributed = [];

  final List<TextEditingController> _roomIdControllers = [];
  final List<TextEditingController> _passwordControllers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _roomIdControllers) { c.dispose(); }
    for (var c in _passwordControllers) { c.dispose(); }
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final sessionData = await _supabase
          .from('sesi_scrim')
          .select('*')
          .eq('id_sesi', widget.sesiId)
          .maybeSingle();

      if (sessionData == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      _session = sessionData;

      final scrimData = await _supabase
          .from('scrim')
          .select('*, mode:master_mode_pertandingan(*)')
          .eq('id_scrim', sessionData['id_scrim'])
          .maybeSingle();

      if (scrimData == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      _scrim = scrimData;
      _jumlahMatch = scrimData['jumlah_match'] ?? 4;
      _selectedMatch = 1;

      final pendaftaran = await _supabase
          .from('pendaftaran_tim')
          .select('''
            id_pendaftaran, 
            akun_id, 
            nama_kapten,
            akun:akun_id (
              profil_pengguna (
                nama_tim
              )
            )
          ''')
          .eq('id_sesi', widget.sesiId)
          .eq('status_pembayaran', 'dikonfirmasi');

      List<Map<String, dynamic>> teamList = [];
      for (var p in pendaftaran) {
        final akunId = p['akun_id'] as int?;
        String namaTim = 'Tim ${akunId ?? '?'}';
        String kapten = p['nama_kapten'] ?? '';

        try {
          final akunData = p['akun'];
          if (akunData != null && akunData['profil_pengguna'] != null) {
            final profilData = akunData['profil_pengguna'];
            if (profilData['nama_tim'] != null && profilData['nama_tim'].toString().isNotEmpty) {
              namaTim = profilData['nama_tim'];
            }
          }
        } catch (e) {}
        teamList.add({
          'id_pendaftaran': p['id_pendaftaran'],
          'nama_tim': namaTim,
          'kapten': kapten,
        });
      }
      _teams = teamList;

      // ✅ OPTIMASI: 1 QUERY UNTUK SEMUA MATCH
      final allExisting = await _supabase
          .from('hasil_pertandingan')
          .select('match_ke, room_id, password')
          .eq('id_sesi', widget.sesiId);
      
      final Map<int, Map<String, dynamic>> existingMap = {};
      for (var e in allExisting) {
        existingMap[e['match_ke']] = e;
      }

      for (var c in _roomIdControllers) { c.dispose(); }
      for (var c in _passwordControllers) { c.dispose(); }
      
      _roomIdControllers.clear();
      _passwordControllers.clear();
      _isDistributed.clear();
      
      for (int i = 0; i < _jumlahMatch; i++) {
        final matchKe = i + 1;
        final roomController = TextEditingController();
        final passController = TextEditingController();
        
        final existing = existingMap[matchKe];
        final hasRoomId = existing != null && existing['room_id'] != null && existing['room_id'].toString().isNotEmpty;
        
        if (existing != null) {
          roomController.text = existing['room_id'] ?? '';
          passController.text = existing['password'] ?? '';
        }
        
        _roomIdControllers.add(roomController);
        _passwordControllers.add(passController);
        _isDistributed.add(hasRoomId);
      }
      
    } catch (e) {
      print('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _distributeToAll(int matchKe) async {
    if (_roomIdControllers.length < matchKe || _passwordControllers.length < matchKe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data belum siap'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada tim terdaftar'), backgroundColor: AppColors.error),
      );
      return;
    }

    final roomId = _roomIdControllers[matchKe - 1].text.trim();
    final password = _passwordControllers[matchKe - 1].text.trim();

    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room ID wajib diisi!'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password wajib diisi!'), backgroundColor: AppColors.error),
      );
      return;
    }

    int successCount = 0;
    int failCount = 0;

    try {
      for (int teamIdx = 0; teamIdx < _teams.length; teamIdx++) {
        final team = _teams[teamIdx];
        final pendaftaranId = team['id_pendaftaran'] as int?;

        if (pendaftaranId == null) {
          failCount++;
          continue;
        }

        try {
          final existing = await _supabase
              .from('hasil_pertandingan')
              .select('id_hasil')
              .eq('id_pendaftaran', pendaftaranId)
              .eq('match_ke', matchKe)
              .maybeSingle();

          if (existing != null) {
            await _supabase.from('hasil_pertandingan').update({
              'room_id': roomId,
              'password': password,
            }).eq('id_hasil', existing['id_hasil']);
          } else {
            await _supabase.from('hasil_pertandingan').insert({
              'id_pendaftaran': pendaftaranId,
              'id_sesi': widget.sesiId,
              'match_ke': matchKe,
              'room_id': roomId,
              'password': password,
            });
          }
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (successCount > 0 && mounted) {
        setState(() {
          _isDistributed[matchKe - 1] = true;
        });
      }

      if (mounted) {
        final message = failCount == 0
            ? 'Match $matchKe berhasil di-distribute ke $successCount tim'
            : 'Match $matchKe: $successCount berhasil, $failCount gagal';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: failCount == 0 ? AppColors.success : AppColors.warning),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal distribute: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Detail Sesi', style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.primary)),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRoomIdTab(),
                ScrimPointsPage(sesiId: widget.sesiId),
                ScrimLeaderboardPage(sesiId: widget.sesiId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Set Room ID'),
          Tab(text: 'Poin'),
          Tab(text: 'Leaderboard'),
        ],
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: AppTextStyles.interLabel,
        dividerColor: Colors.transparent,
      ),
    );
  }

  Widget _buildRoomIdTab() {
    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Belum ada tim terdaftar', style: AppTextStyles.interBody),
          ],
        ),
      );
    }

    final roomIdIndex = _selectedMatch - 1;
    if (roomIdIndex < 0 || roomIdIndex >= _roomIdControllers.length) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final currentRoomId = _roomIdControllers[roomIdIndex].text.trim();
    final currentPassword = _passwordControllers[roomIdIndex].text.trim();
    final isAlreadyDistributed = _isDistributed.length > roomIdIndex && _isDistributed[roomIdIndex];
    final isFormValid = currentRoomId.isNotEmpty && currentPassword.isNotEmpty && !isAlreadyDistributed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_jumlahMatch, (i) {
              final matchNum = i + 1;
              final isSelected = _selectedMatch == matchNum;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMatch = matchNum),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary, width: isSelected ? 2 : 1),
                    ),
                    child: Center(
                      child: Text(
                        'Match $matchNum',
                        style: AppTextStyles.interBodyMedium.copyWith(
                          color: isSelected ? Colors.black : AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('MATCH $_selectedMatch', style: AppTextStyles.poppinsTitleSmall.copyWith(color: AppColors.primary)),
                    const Spacer(),
                    if (isAlreadyDistributed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DISTRIBUTED',
                          style: AppTextStyles.interCaption.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'ROOM ID *',
                  controller: _roomIdControllers[roomIdIndex],
                  hint: 'Masukkan Room ID (wajib)',
                  onChanged: (_) => setState(() {}),
                  enabled: !isAlreadyDistributed,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'PASSWORD *',
                  controller: _passwordControllers[roomIdIndex],
                  hint: 'Masukkan Password (wajib)',
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  enabled: !isAlreadyDistributed,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isFormValid ? () => _distributeToAll(_selectedMatch) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    ),
                    child: Text(
                      isAlreadyDistributed
                          ? 'SUDAH DIDISTRIBUSIKAN'
                          : 'DISTRIBUSIKAN MATCH $_selectedMatch KE SEMUA TIM',
                      style: AppTextStyles.poppinsButton.copyWith(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('PESERTA TERDAFTAR', style: AppTextStyles.interLabel.copyWith(color: AppColors.primary, letterSpacing: 1)),
          const SizedBox(height: 12),
          ..._teams.asMap().entries.map((entry) {
            final idx = entry.key;
            final team = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${idx + 1}', style: AppTextStyles.poppinsTitleSmall.copyWith(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(team['nama_tim'], style: AppTextStyles.poppinsTitleSmall),
                        Text('Kapten: ${team['kapten']}', style: AppTextStyles.interCaption),
                      ],
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscureText = false,
    Function(String)? onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: AppTextStyles.interInput,
          onChanged: onChanged,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.interHint,
            filled: true,
            fillColor: enabled ? AppColors.inputFill : AppColors.inputFill.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}