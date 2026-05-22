// lib/presentation/admin/admin_claim_list_page.dart
//
// Isi tab "Klaim" pada AdminMainNavigator (layar Keuangan).
// PENTING: TIDAK ada bottomNavigationBar di sini — kalau ada, akan
// muncul DUA bar bertumpuk dengan bottom nav milik AdminMainNavigator.

import 'package:flutter/material.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/keuangan_admin_model.dart';
import 'claim_detail_page.dart';

class AdminClaimListPage extends StatelessWidget {
  const AdminClaimListPage({super.key});

  @override
  Widget build(BuildContext context) {
    const ringkasan = mockRingkasan;
    const klaimList = mockKlaimAktif;

    // Tanpa Scaffold & bottomNavigationBar sendiri.
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingM,
              AppConstants.paddingS,
              AppConstants.paddingM,
              // ruang supaya konten tidak ketutup nav bar AdminMainNavigator
              110,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _TotalPendapatanCard(ringkasan: ringkasan),
                const SizedBox(height: AppConstants.paddingM),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        label: 'DANA KELUAR',
                        value: formatRupiahRingkas(ringkasan.danaKeluar),
                        caption:
                            '${ringkasan.persenTersalurkan}% Tersalurkan',
                        captionColor: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingM),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'KLAIM PENDING',
                        value: '${ringkasan.klaimPending}',
                        caption: 'Segera Proses',
                        captionColor: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingL),
                Text('Daftar Klaim Aktif',
                    style: AppTextStyles.poppinsSectionTitle),
                const SizedBox(height: AppConstants.paddingM),
                ...klaimList.map(
                  (k) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppConstants.paddingM),
                    child: _KlaimAktifCard(
                      klaim: k,
                      onDetail: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ClaimDetailPage(namaScrim: k.namaScrim),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
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
        AppConstants.paddingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Keuangan', style: AppTextStyles.poppinsHeadline),
          const SizedBox(height: AppConstants.paddingXS),
          Text('Ringkasan pendapatan & klaim hadiah',
              style: AppTextStyles.interBody),
        ],
      ),
    );
  }
}

// ============================================================
// KARTU TOTAL PENDAPATAN
// ============================================================
class _TotalPendapatanCard extends StatelessWidget {
  final RingkasanKeuangan ringkasan;
  const _TotalPendapatanCard({required this.ringkasan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.backgroundCard],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL PENDAPATAN',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textHint,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            formatRupiahRingkas(ringkasan.totalPendapatan),
            style: AppTextStyles.poppinsMoneyLarge,
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                '+${ringkasan.pertumbuhanPersen}% bln ini',
                style: AppTextStyles.percentageUp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// KARTU STATISTIK KECIL
// ============================================================
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color captionColor;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textHint,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            value,
            style: AppTextStyles.poppinsTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: AppTextStyles.interCaption.copyWith(color: captionColor),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// KARTU KLAIM AKTIF
// ============================================================
class _KlaimAktifCard extends StatelessWidget {
  final KlaimAktif klaim;
  final VoidCallback onDetail;

  const _KlaimAktifCard({required this.klaim, required this.onDetail});

  bool get _urgent => klaim.status == KlaimCardStatus.urgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: _urgent
              ? AppColors.primary.withOpacity(0.35)
              : AppColors.divider,
        ),
      ),
      child: _urgent ? _buildUrgent() : _buildCompleted(),
    );
  }

  Widget _buildUrgent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                'URGENT',
                style: AppTextStyles.interStatus.copyWith(
                  color: AppColors.buttonText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Text(klaim.tanggal,
                style: AppTextStyles.interCaption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          children: [
            Expanded(
              child: Text(klaim.namaScrim,
                  style: AppTextStyles.poppinsTitleSmall),
            ),
            const SizedBox(width: AppConstants.paddingS),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                '${klaim.jumlahPending} Pending',
                style: AppTextStyles.interStatus
                    .copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.groups_outlined, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text('${klaim.jumlahTim} Tim', style: AppTextStyles.interCaption),
            Text('   •   ',
                style: AppTextStyles.interCaption
                    .copyWith(color: AppColors.textDisabled)),
            Text(formatRupiah(klaim.nominal),
                style: AppTextStyles.goldHighlight),
          ],
        ),
        const SizedBox(height: AppConstants.paddingM),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
            ),
            icon: const Icon(Icons.receipt_long,
                size: 18, color: AppColors.buttonText),
            label: Text('Detail Klaim',
                style: AppTextStyles.poppinsButton.copyWith(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(klaim.tanggal, style: AppTextStyles.interCaption),
            Text('  •  ',
                style: AppTextStyles.interCaption
                    .copyWith(color: AppColors.textDisabled)),
            Row(
              children: [
                Icon(Icons.check_circle, size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text('COMPLETED',
                    style: AppTextStyles.interStatus
                        .copyWith(color: AppColors.success)),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingS),
        Text(klaim.namaScrim, style: AppTextStyles.poppinsTitleSmall),
        const SizedBox(height: 4),
        Text(formatRupiah(klaim.nominal), style: AppTextStyles.poppinsMoney),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppConstants.paddingM),
          child: Divider(height: 1, color: AppColors.divider),
        ),
        Row(
          children: [
            Expanded(
              child: Text(klaim.catatan ?? '',
                  style: AppTextStyles.interCaption),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingM, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
              ),
              icon: const Icon(Icons.history,
                  size: 14, color: AppColors.textSecondary),
              label: Text(
                'Lihat Riwayat',
                style: AppTextStyles.interLabel
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
