import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_constants.dart';

class ScrimLimitPage extends StatelessWidget {
  const ScrimLimitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Scrim',
          style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.primary),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Batas Scrim Tercapai',
                style: AppTextStyles.poppinsHeadline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Admin standar hanya dapat membuat maksimal 1 scrim.\nUpgrade ke Premium untuk membuat scrim tanpa batas.',
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/admin/premium');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  icon: const Icon(Icons.stars_rounded, size: 20),
                  label: Text('Upgrade ke Premium', style: AppTextStyles.poppinsButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
