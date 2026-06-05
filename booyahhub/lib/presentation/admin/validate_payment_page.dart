import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/peserta_verifikasi_model.dart';
import '../../data/models/services/admin_utang_service.dart';
import 'participant_detail_page.dart';

class ValidatePaymentPage extends StatefulWidget {
  const ValidatePaymentPage({super.key});

  @override
  State<ValidatePaymentPage> createState() => _ValidatePaymentPageState();
}

class _ValidatePaymentPageState extends State<ValidatePaymentPage> {
  // 0 = Semua, lalu Menunggu / Konfirmasi / Ditolak
  int _selectedTab = 0;
  static const _tabs = ['Semua', 'Menunggu', 'Konfirmasi', 'Ditolak'];

  // Sumber data (sementara mock — ganti dengan query Supabase).
  final List<PesertaVerifikasi> _peserta = List.of(mockPesertaList);

  List<PesertaVerifikasi> get _filtered {
    if (_selectedTab == 0) return _peserta;
    final target = _tabs[_selectedTab];
    return _peserta.where((p) => p.status.tab == target).toList();
  }

  Future<void> _openDetail(PesertaVerifikasi peserta) async {
    final updated = await Navigator.of(context).push<PesertaVerifikasi>(
      MaterialPageRoute(
        builder: (_) => ParticipantDetailPage(peserta: peserta),
      ),
    );
    // Detail mengembalikan peserta dengan status terbaru setelah aksi admin.
    if (updated != null && mounted) {
      if (updated.status == StatusPeserta.dikonfirmasi && 
          peserta.status != StatusPeserta.dikonfirmasi) {
        await _tambahUtangAdmin(updated);
      }
      
      setState(() {
        final i = _peserta.indexWhere(
          (p) => p.idPendaftaran == updated.idPendaftaran,
        );
        if (i != -1) _peserta[i] = updated;
      });
    }
  }

  Future<void> _tambahUtangAdmin(PesertaVerifikasi peserta) async {
    try {
      final supabase = Supabase.instance.client;
      final adminUtangService = AdminUtangService();
      final scrimData = await supabase
          .from('scrim')
          .select('id_admin')
          .eq('id_scrim', peserta.idScrim)
          .maybeSingle();
      
      if (scrimData == null) {
        debugPrint('Scrim tidak ditemukan untuk id_scrim: ${peserta.idScrim}');
        return;
      }
      
      final int adminId = scrimData['id_admin'];
      
      // 2. Tambah utang admin (1 slot = 1 pendaftaran)
      final result = await adminUtangService.tambahUtang(
        adminId: adminId,
        jumlahSlot: 1,
      );
      
      if (!result['success']) {
        debugPrint('Gagal tambah utang: ${result['message']}');
      } else if (result['melebihi_limit'] == true) {
        // Tampilkan notifikasi bahwa admin sudah melebihi limit
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error tambah utang admin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            _buildHeader(),
            _buildTabBar(),
            const SizedBox(height: AppConstants.paddingS),
            Expanded(
              child: list.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.paddingM,
                        AppConstants.paddingS,
                        AppConstants.paddingM,
                        120, // ruang untuk bottom nav
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppConstants.paddingM),
                      itemBuilder: (_, i) => _PesertaCard(
                        peserta: list[i],
                        onTap: () => _openDetail(list[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ===================== APP BAR =====================
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingS,
        AppConstants.paddingS,
        AppConstants.paddingM,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          Text(
            'Verifikasi Peserta',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingM,
        AppConstants.paddingS,
        AppConstants.paddingM,
        AppConstants.paddingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daftar Peserta', style: AppTextStyles.poppinsHeadline),
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            'Kelola peserta & verifikasi pembayaran',
            style: AppTextStyles.interBody,
          ),
        ],
      ),
    );
  }

  // ===================== TAB BAR =====================
  Widget _buildTabBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
        itemCount: _tabs.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppConstants.paddingL),
        itemBuilder: (_, i) {
          final selected = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _tabs[i],
                  style: AppTextStyles.interBodyMedium.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textHint,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
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
          );
        },
      ),
    );
  }

  // ===================== EMPTY STATE =====================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56, color: AppColors.textDisabled),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            'Belum ada peserta',
            style: AppTextStyles.interBody.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== BOTTOM NAV =====================
  Widget _buildBottomNav() {
    const items = [
      Icons.grid_view_rounded,
      Icons.sports_esports_outlined,
      Icons.groups_rounded, // aktif (verifikasi peserta)
      Icons.card_giftcard_rounded,
      Icons.person_outline_rounded,
    ];
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppConstants.paddingM),
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingS),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final active = i == 2;
            return active
                ? Container(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(items[i],
                        color: AppColors.primary, size: 24),
                  )
                : Icon(items[i], color: AppColors.background, size: 24);
          }),
        ),
      ),
    );
  }
}

// ============================================================
// KARTU PESERTA
// ============================================================
class _PesertaCard extends StatelessWidget {
  final PesertaVerifikasi peserta;
  final VoidCallback onTap;

  const _PesertaCard({required this.peserta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama tim + badge status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      peserta.namaTim,
                      style: AppTextStyles.poppinsTitleSmall,
                    ),
                  ),
                  StatusBadge(status: peserta.status),
                ],
              ),
              const SizedBox(height: AppConstants.paddingXS),
              // Kapten
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Capt: ${peserta.namaKapten}',
                    style: AppTextStyles.interCaption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding:
                    EdgeInsets.symmetric(vertical: AppConstants.paddingM),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              // Scrim + Sesi
              Row(
                children: [
                  Expanded(
                    child: _miniInfo('SCRIM', peserta.namaScrim),
                  ),
                  Expanded(
                    child: _miniInfo(
                      'SESI',
                      '${peserta.tanggal.split(' ').take(2).join(' ')}, '
                          '${peserta.waktu}',
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.interCaption.copyWith(
            color: AppColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: AppTextStyles.interBodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BADGE STATUS — dipakai di list & detail
// ============================================================
class StatusBadge extends StatelessWidget {
  final StatusPeserta status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    switch (status) {
      case StatusPeserta.dikonfirmasi:
        color = AppColors.success;
        break;
      case StatusPeserta.ditolak:
        color = AppColors.error;
        break;
      case StatusPeserta.menunggu:
        color = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.interStatus.copyWith(color: color),
      ),
    );
  }
}