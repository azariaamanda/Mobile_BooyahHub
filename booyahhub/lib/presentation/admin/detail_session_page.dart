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
  int _totalPeserta = 0;
  int _slotMaksimal = 12;
  int _jumlahMatch = 4;

  final List<TextEditingController> _roomIdControllers = [];
  final List<TextEditingController> _passwordControllers = [];

  String? _posterPublicUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return _supabase.storage.from('posters').getPublicUrl(path);
  }

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
          .single();
      _session = sessionData;
      _slotMaksimal = sessionData['slot_maksimal'] ?? 12;

      final scrimData = await _supabase
          .from('scrim')
          .select('*, mode:master_mode_pertandingan(*)')
          .eq('id_scrim', sessionData['id_scrim'])
          .single();
      _scrim = scrimData;
      _jumlahMatch = scrimData['jumlah_match'] ?? 4;

      final pendaftaran = await _supabase
          .from('pendaftaran_tim')
          .select('id_pendaftaran, akun_id, nama_kapten')
          .eq('id_sesi', widget.sesiId)
          .eq('status_pembayaran', 'dikonfirmasi');
      _totalPeserta = pendaftaran.length;

      List<Map<String, dynamic>> teamList = [];
      for (var p in pendaftaran) {
        final akunId = p['akun_id'] as int?;
        String namaTim = 'Tim ${akunId ?? '?'}';
        String kapten = p['nama_kapten'] ?? '';
        
        if (akunId != null) {
          final profilData = await _supabase
              .from('profil_pengguna')
              .select('nama_tim')
              .eq('akun_id', akunId)
              .maybeSingle();
          
          if (profilData != null && profilData['nama_tim'] != null) {
            namaTim = profilData['nama_tim'];
          }
        }
        
        teamList.add({
          'id_pendaftaran': p['id_pendaftaran'],
          'nama_tim': namaTim,
          'kapten': kapten,
        });
      }
      _teams = teamList;

      _roomIdControllers.clear();
      _passwordControllers.clear();
      for (int i = 0; i < _jumlahMatch; i++) {
        _roomIdControllers.add(TextEditingController());
        _passwordControllers.add(TextEditingController());
        
        final existing = await _supabase
            .from('hasil_pertandingan')
            .select('room_id, password')
            .eq('id_sesi', widget.sesiId)
            .eq('match_ke', i + 1)
            .maybeSingle();
            
        if (existing != null) {
          _roomIdControllers[i].text = existing['room_id'] ?? '';
          _passwordControllers[i].text = existing['password'] ?? '';
        }
      }

    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRoomId(int matchKe, String roomId, String password) async {
    try {
      final existing = await _supabase
          .from('hasil_pertandingan')
          .select()
          .eq('id_sesi', widget.sesiId)
          .eq('match_ke', matchKe)
          .maybeSingle();
          
      if (existing != null) {
        await _supabase.from('hasil_pertandingan').update({
          'room_id': roomId.isEmpty ? null : roomId,
          'password': password.isEmpty ? null : password,
        }).eq('id_hasil', existing['id_hasil']);
      } else {
        await _supabase.from('hasil_pertandingan').insert({
          'id_sesi': widget.sesiId,
          'match_ke': matchKe,
          'room_id': roomId.isEmpty ? null : roomId,
          'password': password.isEmpty ? null : password,
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room ID Match $matchKe disimpan'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _distributeToAll(int matchKe, String roomId, String password) async {
    if (_teams.isEmpty) return;
    
    try {
      for (var team in _teams) {
        final existing = await _supabase
            .from('hasil_pertandingan')
            .select()
            .eq('id_pendaftaran', team['id_pendaftaran'])
            .eq('match_ke', matchKe)
            .maybeSingle();
            
        if (existing != null) {
          await _supabase.from('hasil_pertandingan').update({
            'room_id': roomId.isEmpty ? null : roomId,
            'password': password.isEmpty ? null : password,
          }).eq('id_hasil', existing['id_hasil']);
        } else {
          await _supabase.from('hasil_pertandingan').insert({
            'id_pendaftaran': team['id_pendaftaran'],
            'id_sesi': widget.sesiId,
            'match_ke': matchKe,
            'room_id': roomId.isEmpty ? null : roomId,
            'password': password.isEmpty ? null : password,
          });
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Match $matchKe didistribusikan ke semua tim'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '-';
    final date = DateTime.parse(dateTimeStr);
    return '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null) return '-';
    final date = DateTime.parse(dateTimeStr);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}'.toUpperCase();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'aktif': return AppColors.success;
      case 'selesai': return AppColors.textSecondary;
      case 'dibatalkan': return AppColors.error;
      default: return AppColors.warning;
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

    final posterUrl = _posterPublicUrl(_scrim?['poster'] as String?);
    final status = _scrim?['status_scrim'] as String? ?? 'aktif';
    final mode = _scrim?['mode'];

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
          _buildHeroCard(status, posterUrl, mode),
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

  Widget _buildHeroCard(String status, String? posterUrl, dynamic mode) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        children: [
          _buildPosterImage(posterUrl),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBadge(status, _statusColor(status)),
                const SizedBox(height: 10),
                Text(
                  _scrim?['nama_scrim'] ?? '',
                  style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                if (mode != null)
                  Text(
                    mode['nama_mode'] ?? '',
                    style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatTime(_session?['waktu_mulai'])} - ${_formatTime(_session?['waktu_selesai'])}',
                      style: AppTextStyles.interLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(_session?['waktu_mulai']),
                      style: AppTextStyles.interLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SLOT TERISI', style: AppTextStyles.interLabel.copyWith(fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            '$_totalPeserta/$_slotMaksimal',
                            style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterImage(String? url) {
    const double height = 140;
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _gradientPlaceholder(height)),
      );
    }
    return _gradientPlaceholder(height);
  }

  Widget _gradientPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0A1A26), Color(0xFF1A2B38)])),
      child: Center(child: Icon(Icons.sports_esports_outlined, size: 40, color: AppColors.primary.withOpacity(0.4))),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text(status.toUpperCase(), style: AppTextStyles.interLabel.copyWith(color: color, fontWeight: FontWeight.w700)),
      ]),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Room & Password',
            style: AppTextStyles.poppinsTitleSmall.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 12),

          Row(
            children: List.generate(_jumlahMatch, (i) => Expanded(
              child: _matchButton(i + 1),
            )),
          ),
          const SizedBox(height: 16),

          ...List.generate(_jumlahMatch, (matchIndex) {
            final matchNum = matchIndex + 1;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MATCH $matchNum',
                    style: AppTextStyles.poppinsTitleSmall.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'ROOM ID - MATCH $matchNum',
                    controller: _roomIdControllers[matchIndex],
                    hint: 'Masukkan Room ID',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'PASSWORD - MATCH $matchNum',
                    controller: _passwordControllers[matchIndex],
                    hint: 'Masukkan Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveRoomId(
                            matchNum,
                            _roomIdControllers[matchIndex].text,
                            _passwordControllers[matchIndex].text,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                          ),
                          child: Text('SET MATCH $matchNum ID & PASSWORD', style: AppTextStyles.poppinsButton.copyWith(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => _distributeToAll(
                        matchNum,
                        _roomIdControllers[matchIndex].text,
                        _passwordControllers[matchIndex].text,
                      ),
                      child: Text(
                        'Distribusikan Match $matchNum ke Semua',
                        style: AppTextStyles.interLink.copyWith(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          Text(
            'PENDAFTAR',
            style: AppTextStyles.interLabel.copyWith(color: AppColors.primary, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                child: Text('Lihat Semua', style: AppTextStyles.interLink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._teams.map((team) => Container(
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
                    child: Text(
                      team['nama_tim'][0].toUpperCase(),
                      style: AppTextStyles.poppinsTitleSmall.copyWith(color: AppColors.primary),
                    ),
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
          )),
        ],
      ),
    );
  }

  Widget _matchButton(int match) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary),
      ),
      child: Center(
        child: Text(
          'Match $match',
          style: AppTextStyles.interBodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscureText = false,
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.interHint,
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}