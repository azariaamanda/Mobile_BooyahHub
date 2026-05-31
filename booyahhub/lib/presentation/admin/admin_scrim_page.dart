import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class ScrimSummary {
  final String id;
  final String namaScrim;
  final String statusScrim;
  final int totalSesi;
  final int biayaPendaftaran;
  final int totalHadiah;

  ScrimSummary({
    required this.id,
    required this.namaScrim,
    required this.statusScrim,
    required this.totalSesi,
    required this.biayaPendaftaran,
    required this.totalHadiah,
  });
}

class AdminScrimPage extends StatefulWidget {
  const AdminScrimPage({super.key});

  @override
  State<AdminScrimPage> createState() => _AdminScrimPageState();
}

class _AdminScrimPageState extends State<AdminScrimPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  List<ScrimSummary> _allScrims = [];

  final List<String> _tabs = ['Semua', 'Aktif', 'Selesai', 'Dibatalkan'];
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchScrims();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchScrims() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail == null) throw Exception('Sesi habis');

      final akunResponse = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', userEmail)
          .maybeSingle();

      if (akunResponse == null) throw Exception('Akun tidak ditemukan');
      final adminId = akunResponse['id_akun'];

      final scrimResponse = await _supabase
          .from('scrim')
          .select('''
            id_scrim,
            nama_scrim,
            status_scrim,
            biaya_pendaftaran,
            total_hadiah,
            dibuat_pada
          ''')
          .eq('id_admin', adminId)
          .order('dibuat_pada', ascending: false);

      List<ScrimSummary> tempList = [];

      for (var scrim in scrimResponse) {
        final sesiResponse = await _supabase
            .from('sesi_scrim')
            .select('id_sesi')
            .eq('id_scrim', scrim['id_scrim']);

        final totalSesi = sesiResponse.length;

        tempList.add(ScrimSummary(
          id: scrim['id_scrim'].toString(),
          namaScrim: scrim['nama_scrim'] ?? '',
          statusScrim: scrim['status_scrim'] ?? 'aktif',
          totalSesi: totalSesi,
          biayaPendaftaran: (scrim['biaya_pendaftaran'] as num?)?.toInt() ?? 0,
          totalHadiah: (scrim['total_hadiah'] as num?)?.toInt() ?? 0,
        ));
      }

      _allScrims = tempList;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteScrim(String scrimId) async {
    final confirm = await _showDeleteDialog();
    if (!confirm) return;

    try {
      await _supabase.from('scrim').delete().eq('id_scrim', int.parse(scrimId));
      _fetchScrims();
      _showSnackBar('Scrim berhasil dihapus', isError: false);
    } catch (e) {
      _showSnackBar('Gagal menghapus scrim: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.interBody),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
      ),
    );
  }

  Future<bool> _showDeleteDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusL)),
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
        ) ??
        false;
  }

  String _formatRupiah(int amount) {
    if (amount == 0) return 'Rp 0';
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  List<ScrimSummary> _filteredScrims(int tabIndex) {
    if (tabIndex == 0) return _allScrims;
    final statusMap = {1: 'aktif', 2: 'selesai', 3: 'dibatalkan'};
    return _allScrims
        .where((s) => s.statusScrim == statusMap[tabIndex])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(
                  _tabs.length,
                  (index) => _buildTabContent(index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingM,
        AppConstants.paddingM,
        AppConstants.paddingM,
        AppConstants.paddingS,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Scrim',
                  style: AppTextStyles.poppinsHeadline,
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  'Kelola semua scrimmu',
                  style: AppTextStyles.interBody,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await context.push('/admin/scrim/buat');
              _fetchScrims();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.black, size: 18),
                  const SizedBox(width: AppConstants.paddingXS),
                  Text(
                    'Tambah Scrim',
                    style: AppTextStyles.poppinsButton.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _tabController.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(i);
                setState(() {}); // <-- TAMBAHKAN INI AGAR UI UPDATE
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _tabs[i],
                    style: AppTextStyles.interBodyMedium.copyWith(
                      color: selected ? AppColors.primary : AppColors.textHint,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: AppConstants.animationDuration,
                    height: 3,
                    width: selected ? 22 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: AppConstants.paddingM),
              Text('Gagal memuat data', style: AppTextStyles.poppinsTitle),
              const SizedBox(height: AppConstants.paddingS),
              Text(_error!, style: AppTextStyles.interCaption, textAlign: TextAlign.center),
              const SizedBox(height: AppConstants.paddingL),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                onPressed: _fetchScrims,
                icon: const Icon(Icons.refresh),
                label: Text('Coba Lagi', style: AppTextStyles.poppinsButton),
              ),
            ],
          ),
        ),
      );
    }

    final scrims = _filteredScrims(tabIndex);

    if (scrims.isEmpty) {
      return _buildEmptyState(tabIndex);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.backgroundCard,
      onRefresh: _fetchScrims,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingM,
          AppConstants.paddingM,
          AppConstants.paddingM,
          AppConstants.paddingL,
        ),
        itemCount: scrims.length,
        itemBuilder: (context, index) => _buildScrimCard(scrims[index]),
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    final isAll = tabIndex == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAll ? Icons.sports_esports_outlined : Icons.inbox_outlined,
                color: AppColors.textSecondary,
                size: 44,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              isAll ? 'Belum Ada Scrim' : 'Tidak Ada Scrim',
              style: AppTextStyles.poppinsTitle,
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              isAll
                  ? 'Buat scrim pertamamu dan mulai kelola turnamen!'
                  : 'Tidak ada scrim dengan status ini.',
              textAlign: TextAlign.center,
              style: AppTextStyles.interBody,
            ),
            if (isAll) ...[
              const SizedBox(height: AppConstants.paddingL),
              GestureDetector(
                onTap: () async {
                  await context.push('/admin/scrim/buat');
                  _fetchScrims();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingL,
                    vertical: AppConstants.paddingM,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.black, size: 18),
                      const SizedBox(width: AppConstants.paddingS),
                      Text(
                        'Buat Scrim Baru',
                        style: AppTextStyles.poppinsButton,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScrimCard(ScrimSummary scrim) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        onTap: () async {
          await context.push('/admin/scrim/detail/${scrim.id}');
          _fetchScrims();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      scrim.namaScrim,
                      style: AppTextStyles.poppinsTitle,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  _buildStatusBadge(scrim.statusScrim),
                ],
              ),
              const SizedBox(height: AppConstants.paddingM),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      label: 'TOTAL SESI',
                      value: scrim.totalSesi.toString(),
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoTile(
                      label: 'TOTAL HADIAH',
                      value: _formatRupiah(scrim.totalHadiah),
                      icon: Icons.emoji_events_outlined,
                      valueColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingM),
              Divider(color: AppColors.surfaceVariant, height: 1),
              const SizedBox(height: AppConstants.paddingM),
              Row(
                children: [
                  Icon(Icons.payments_outlined, color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: AppConstants.paddingXS),
                  Text(
                    'Pendaftaran: ${_formatRupiah(scrim.biayaPendaftaran)}',
                    style: AppTextStyles.interCaption,
                  ),
                  const Spacer(),
                  _buildActionBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    onTap: () async {
                      await context.push('/admin/scrim/edit/${scrim.id}');
                      _fetchScrims();
                    },
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  _buildActionBtn(
                    icon: Icons.delete_outline,
                    color: AppColors.error,
                    onTap: () => _deleteScrim(scrim.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'aktif':
        color = AppColors.success;
        label = 'AKTIF';
        break;
      case 'selesai':
        color = AppColors.textSecondary;
        label = 'SELESAI';
        break;
      case 'dibatalkan':
        color = AppColors.error;
        label = 'DIBATALKAN';
        break;
      default:
        color = AppColors.warning;
        label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingS, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.interCaption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.interLabel.copyWith(fontSize: 10)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: valueColor ?? AppColors.textPrimary, size: 14),
            const SizedBox(width: AppConstants.paddingXS),
            Flexible(
              child: Text(
                value,
                style: AppTextStyles.poppinsMoneySmall.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingS),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}