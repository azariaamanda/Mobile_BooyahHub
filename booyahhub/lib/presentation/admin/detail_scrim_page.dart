import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'scrim_sessions_page.dart'; // import file sesi
import 'scrim_points_page.dart'; // import file poin
import 'scrim_leaderboard_page.dart'; // import file leaderboard

class DetailScrimPage extends StatefulWidget {
  final int scrimId;
  const DetailScrimPage({super.key, required this.scrimId});

  @override
  State<DetailScrimPage> createState() => _DetailScrimPageState();
}

class _DetailScrimPageState extends State<DetailScrimPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isDeleting = false;
  Map<String, dynamic>? _scrim;
  String? _namaMode;
  List<Map<String, dynamic>> _sessions = [];

  String? _posterPublicUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return _supabase.storage.from('posters').getPublicUrl(path);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Hanya 2 tab
    _fetchDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final scrimData = await _supabase
          .from('scrim')
          .select('*')
          .eq('id_scrim', widget.scrimId)
          .single();
      _scrim = scrimData;

      final idMode = scrimData['id_mode'];
      print('=== DEBUG ===');
      print('id_mode dari scrim: $idMode');
      print('id_scrim: ${scrimData['id_scrim']}');

      if (idMode != null) {
        final modeData = await _supabase
            .from('master_mode_pertandingan')
            .select('nama_mode')
            .eq('id_mode', idMode)
            .maybeSingle();

        print('modeData: $modeData');

        if (modeData != null && modeData['nama_mode'] != null) {
          _namaMode = modeData['nama_mode'].toString();
        } else {
          // Fallback hardcoded
          switch (idMode) {
            case 1:
              _namaMode = 'Clash Squad';
              break;
            case 2:
              _namaMode = 'Battle Royale';
              break;
            case 3:
              _namaMode = 'Ranked BR';
              break;
            case 4:
              _namaMode = 'Solo Vs Squad';
              break;
            default:
              _namaMode = 'Mode $idMode';
          }
        }
      } else {
        _namaMode = 'Mode tidak diatur';
      }

      print('_namaMode: $_namaMode');
      print('================');

      final sesiData = await _supabase
          .from('sesi_scrim')
          .select('*')
          .eq('id_scrim', widget.scrimId)
          .order('waktu_mulai', ascending: true);
      _sessions = List<Map<String, dynamic>>.from(sesiData);
    } catch (e) {
      debugPrint('Error fetchDetail: $e');
      _namaMode = 'Error loading mode';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteScrim() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Scrim', style: AppTextStyles.poppinsTitle),
        content: Text(
          'Yakin ingin menghapus scrim ini? Semua data sesi terkait akan ikut terhapus.',
          style: AppTextStyles.interBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppTextStyles.interLink),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: AppTextStyles.poppinsButton),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _supabase.from('scrim').delete().eq('id_scrim', widget.scrimId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Scrim berhasil dihapus'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/admin/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  String _formatRupiah(dynamic amount) {
    final val = (amount ?? 0).toInt();
    if (val == 0) return 'Rp 0';
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'aktif':
        return AppColors.success;
      case 'selesai':
        return AppColors.textSecondary;
      case 'dibatalkan':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_scrim == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: _backButton(),
          title: Text('Detail Scrim', style: AppTextStyles.poppinsTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Scrim tidak ditemukan', style: AppTextStyles.interBody),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/admin/dashboard'),
                child: Text('Kembali', style: AppTextStyles.poppinsButton),
              ),
            ],
          ),
        ),
      );
    }

    final status = _scrim!['status_scrim'] as String? ?? 'aktif';
    final posterUrl = _posterPublicUrl(_scrim!['poster'] as String?);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Column(
                children: [
                  _buildHeroCard(status, posterUrl),
                  const SizedBox(height: 8),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(),
                        ScrimSessionsPage(
                          scrimId: widget.scrimId,
                        ), // langsung panggil widget dari file terpisah
                        ScrimPointsPage(
                          sesiId: widget.scrimId,
                        ), // langsung panggil widget dari file terpisah
                        ScrimLeaderboardPage(
                          sesiId: widget.scrimId,
                        ), // langsung panggil widget dari file terpisah
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          _backButton(),
          Text(
            'Detail Scrim',
            style: AppTextStyles.poppinsTitle.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: AppColors.primary,
        size: 20,
      ),
      onPressed: () => context.pop(),
    );
  }

  Widget _buildHeroCard(String status, String? posterUrl) {
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
                  _scrim!['nama_scrim'] ?? '',
                  style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Edit',
                        Icons.edit_outlined,
                        AppColors.primary,
                        () =>
                            context.push('/admin/scrim/edit/${widget.scrimId}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        'Hapus',
                        Icons.delete_outline,
                        AppColors.error,
                        _deleteScrim,
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
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _gradientPlaceholder(height),
        ),
      );
    }
    return _gradientPlaceholder(height);
  }

  Widget _gradientPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1A26), Color(0xFF1A2B38)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_outlined,
          size: 40,
          color: AppColors.primary.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: AppTextStyles.interLabel.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL SESI',
                style: AppTextStyles.interLabel.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${_sessions.length} Sesi',
                    style: AppTextStyles.poppinsMoneyLarge.copyWith(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FINANSIAL',
                style: AppTextStyles.interLabel.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on_outlined,
                    size: 13,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatRupiah(_scrim!['biaya_pendaftaran']),
                    style: AppTextStyles.poppinsMoney.copyWith(
                      fontSize: 12,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatRupiah(_scrim!['total_hadiah']),
                    style: AppTextStyles.poppinsMoney.copyWith(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.poppinsButton.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Informasi'),
          Tab(text: 'Sesi'),
        ],
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: AppTextStyles.interLabel,
        dividerColor: Colors.transparent, // ← TAMBAHKAN INI
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      // ← TAMBAHKAN INI
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _sectionCard(
            title: 'Info Scrim',
            child: Column(
              children: [
                _infoRow(
                  'Biaya Pendaftaran',
                  _formatRupiah(_scrim!['biaya_pendaftaran']),
                ),
                _infoRow(
                  'Total Hadiah',
                  _formatRupiah(_scrim!['total_hadiah']),
                  valueColor: AppColors.primary,
                ),
                _infoRow('Mode Pertandingan', _namaMode ?? '-'),
                _infoRow('Match', '${_scrim!['jumlah_match'] ?? 3}'),
                _infoRow(
                  'Slot Per Sesi',
                  '${_scrim!['maks_peserta'] ?? 12} Tim',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            title: 'Deskripsi',
            child: Text(
              _scrim!['deskripsi'] ?? '-',
              style: AppTextStyles.interBody.copyWith(
                color: AppColors.textSecondary,
                height: 1.65,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            title: 'Ketentuan',
            child: _buildKetentuanList(_scrim!['syarat_ketentuan']),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.poppinsTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.interLabel.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: AppTextStyles.poppinsMoney.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (!isLast)
          Divider(color: AppColors.surfaceVariant, height: 22, thickness: 1),
      ],
    );
  }

  Widget _buildKetentuanList(String? raw) {
    if (raw == null || raw.trim().isEmpty)
      return Text(
        '-',
        style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary),
      );
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length <= 1)
      return Text(
        raw,
        style: AppTextStyles.interBody.copyWith(
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.map((e) {
        final cleaned = e.value.trim().replaceFirst(
          RegExp(r'^\d+[\.\)]\s*'),
          '',
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${e.key + 1}.',
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cleaned,
                  style: AppTextStyles.interBody.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
