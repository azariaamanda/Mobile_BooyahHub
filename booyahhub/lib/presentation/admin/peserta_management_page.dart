// lib/presentation/admin/peserta_management_page.dart
//
// Isi tab "Peserta" pada AdminMainNavigator.
// PENTING: halaman ini TIDAK punya bottomNavigationBar sendiri —
// bottom nav sudah disediakan oleh AdminMainNavigator. Kalau halaman
// tab juga menaruh bottom nav, akan muncul DUA bar bertumpuk.

import 'package:flutter/material.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/peserta_verifikasi_model.dart';
import 'participant_detail_page.dart';

class PesertaManagementPage extends StatefulWidget {
  const PesertaManagementPage({super.key});

  @override
  State<PesertaManagementPage> createState() => _PesertaManagementPageState();
}

class _PesertaManagementPageState extends State<PesertaManagementPage> {
  int _selectedTab = 0;
  static const _tabs = ['Semua', 'Menunggu', 'Konfirmasi', 'Ditolak'];

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
    if (updated != null && mounted) {
      setState(() {
        final i = _peserta.indexWhere(
          (p) => p.idPendaftaran == updated.idPendaftaran,
        );
        if (i != -1) _peserta[i] = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    // Tanpa Scaffold sendiri: AdminMainNavigator sudah menyediakan Scaffold.
    // Cukup kembalikan Column. SafeArea atas untuk status bar.
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          const SizedBox(height: AppConstants.paddingS),
          Expanded(
            child: list.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    primary: false,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.paddingM,
                      AppConstants.paddingS,
                      AppConstants.paddingM,
                      // ruang supaya kartu terakhir tidak ketutup nav bar
                      110,
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
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingM,
        AppConstants.paddingL,
        AppConstants.paddingM,
        AppConstants.paddingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manajemen Peserta', style: AppTextStyles.poppinsHeadline),
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
          Icon(Icons.inbox_outlined, size: 56, color: AppColors.textDisabled),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            'Belum ada peserta',
            style: AppTextStyles.interBody.copyWith(color: AppColors.textHint),
          ),
        ],
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
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
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
                padding: EdgeInsets.symmetric(vertical: AppConstants.paddingM),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              Row(
                children: [
                  Expanded(child: _miniInfo('SCRIM', peserta.namaScrim)),
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
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
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
// BADGE STATUS — dipakai di list & detail peserta
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
