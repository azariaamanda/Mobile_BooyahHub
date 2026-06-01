import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class ClaimPrizePage extends StatelessWidget {
  final int? pendaftaranId;
  const ClaimPrizePage({super.key, this.pendaftaranId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Klaim Hadiah',
          style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Penghargaan Kamu',
                style: AppTextStyles.poppinsHeadline.copyWith(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kelola semua hadiah dari turnamen dan scrim yang telah kamu menangkan di arena',
                style: AppTextStyles.interBody,
              ),
              const SizedBox(height: 32),
              
              // Belum Diklaim Card
              _buildPrizeCard(
                context,
                statusText: 'PERLU TINDAKAN',
                statusColor: AppColors.urgent,
                title: 'Scrim Ganteng',
                badgeText: 'Belum Diklaim',
                badgeColor: AppColors.urgent.withOpacity(0.2),
                badgeTextColor: const Color(0xFFF44336), // error / bright red
                rank: 'Juara 1',
                prize: 'Rp 250.000',
                actionWidget: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 24),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ajukan Klaim',
                          style: AppTextStyles.poppinsButton.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: AppColors.black, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Diproses Card
              _buildPrizeCard(
                context,
                statusText: 'TRANSAKSI SEDANG BERLANGSUNG',
                statusColor: AppColors.textHint,
                title: 'Scrim Ganteng',
                badgeText: 'Diproses',
                badgeColor: AppColors.warning.withOpacity(0.15),
                badgeTextColor: AppColors.warning,
                rank: 'Juara 1',
                prize: 'Rp 250.000',
                actionWidget: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'Estimasi transfer 1 - 2 hari kerja',
                      style: AppTextStyles.interCaption,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selesai Card
              _buildPrizeCard(
                context,
                statusText: 'TRANSAKSI SELESAI',
                statusColor: AppColors.textHint,
                title: 'Scrim Ganteng',
                badgeText: 'Selesai',
                badgeColor: AppColors.surfaceVariant,
                badgeTextColor: AppColors.textSecondary,
                rank: 'Juara 1',
                prize: 'Rp 250.000',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrizeCard(
    BuildContext context, {
    required String statusText,
    required Color statusColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String rank,
    required String prize,
    Widget? actionWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: AppTextStyles.interCaption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: AppTextStyles.poppinsTitleSmall.copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.interCaption.copyWith(
                    color: badgeTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text('Rank', style: AppTextStyles.interCaption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rank,
                    style: AppTextStyles.poppinsTitleSmall.copyWith(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Hadiah', style: AppTextStyles.interCaption),
                  const SizedBox(height: 4),
                  Text(
                    prize,
                    style: AppTextStyles.poppinsMoneySmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (actionWidget != null) actionWidget,
        ],
      ),
    );
  }
}
