import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class UserPremiumPage extends StatelessWidget {
  const UserPremiumPage({super.key});

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
          'Upgrade Premium',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Intro Section
              Text(
                'Layanan Premium',
                style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Dapatkan akses eksklusif ke fitur premium dan nikmati pengalaman bermain yang lebih baik',
                style: AppTextStyles.interBody,
              ),
              const SizedBox(height: 32),

              // Current Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  border: Border.all(color: AppColors.inputBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status Saat Ini', style: AppTextStyles.interLabel),
                    const SizedBox(height: 12),
                    Text('Pengguna Standar', style: AppTextStyles.poppinsTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Anda bisa mengupgrade ke premium untuk membuka fitur eksklusif',
                      style: AppTextStyles.interBody,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Premium Tier Card
              _buildPremiumTierCard(
                context,
                title: 'Elite Commander',
                price: 'Rp 500.000',
                description: 'Upgrade Produk Terbaru',
                features: [
                  'Akses unlimited ke semua turnamen premium',
                  'Auto-match ID tersedia',
                  'Prioritas support 24/7',
                  'Bonus poin 50% lebih banyak',
                  'Badge eksklusif di profil',
                ],
                isPremium: true,
              ),
              const SizedBox(height: 24),

              // Other Plans
              Text('Paket Lainnya', style: AppTextStyles.poppinsSectionTitle),
              const SizedBox(height: 16),

              _buildPremiumTierCard(
                context,
                title: 'Pro Player',
                price: 'Rp 250.000',
                description: 'Paket Standar',
                features: [
                  'Akses ke turnamen premium tertentu',
                  'Bonus poin 25% lebih banyak',
                  'Support prioritas',
                ],
                isPremium: false,
              ),
              const SizedBox(height: 24),

              // FAQ Section
              Text('Pertanyaan Umum', style: AppTextStyles.poppinsSectionTitle),
              const SizedBox(height: 16),
              _buildFAQItem(
                'Bagaimana cara mengupgrade?',
                'Klik tombol "Upgrade Sekarang" dan ikuti instruksi pembayaran yang tersedia.',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                'Apakah ada garansi uang kembali?',
                'Ya, kami memberikan garansi 7 hari untuk semua paket premium.',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                'Kapan saya bisa membatalkan?',
                'Anda bisa membatalkan kapan saja di menu pengaturan akun Anda.',
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTierCard(
    BuildContext context, {
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required bool isPremium,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: isPremium ? AppColors.primary : AppColors.inputBorder,
          width: isPremium ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Text('Paket Pilihan', style: AppTextStyles.goldHighlight),
            ),
          if (isPremium) const SizedBox(height: 12),
          Text(title, style: AppTextStyles.poppinsTitleSmall),
          const SizedBox(height: 4),
          Text(description, style: AppTextStyles.interCaption),
          const SizedBox(height: 12),
          Text(price, style: AppTextStyles.poppinsMoneyLarge),
          const SizedBox(height: 24),

          // Features List
          ...features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 2),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(feature, style: AppTextStyles.interBody),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handle upgrade
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upgrade ke $title'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              child: Text(
                'Upgrade Sekarang',
                style: AppTextStyles.poppinsButton,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: AppTextStyles.poppinsTitleSmall),
      backgroundColor: AppColors.backgroundCard,
      collapsedBackgroundColor: AppColors.backgroundCard,
      tilePadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingM,
      ),
      childrenPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingM,
      ),
      children: [Text(answer, style: AppTextStyles.interBody)],
    );
  }
}
