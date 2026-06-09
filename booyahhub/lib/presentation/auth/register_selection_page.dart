import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class RegisterSelectionPage extends StatelessWidget {
  const RegisterSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Text(
                      'Ayo Mulai!',
                      style: AppTextStyles.poppinsHeadline.copyWith(
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      'Pilih tipe akun yang ingin Anda buat',
                      style: AppTextStyles.interBody.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Card Admin
              _buildRoleCard(
                title: 'Admin',
                description: 'Mendaftar sebagai penyelenggara turnamen',
                icon: Icons.admin_panel_settings_rounded,
                color: const Color(0xFF2196F3),
                onTap: () => context.go('/register/admin'),
              ),
              
              const SizedBox(height: AppConstants.paddingM),
              
              // Card User
              _buildRoleCard(
                title: 'Pengguna / Tim',
                description: 'Mendaftar sebagai peserta turnamen',
                icon: Icons.sports_esports_rounded,
                color: const Color(0xFF4CAF50),
                onTap: () => context.go('/register/pengguna'),
              ),
              
              const Spacer(),
              
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: AppTextStyles.interBody.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Masuk',
                      style: AppTextStyles.interLink.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.paddingM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.poppinsTitleSmall.copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.interCaption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}