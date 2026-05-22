import 'package:flutter/material.dart';
// IMPORT WAJIB: Sesuaikan manajemen aset dengan milik tim lu
import '../../../config/app_color.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';

class ScrimItemCard extends StatelessWidget {
  final int idScrim;
  final String title;
  final String prize;
  final String fee;
  final String slotsInfo;
  final String posterImage; // Variabel ini sudah berisi URL lengkap dari Home Screen
  final Color primaryYellow;

  const ScrimItemCard({
    super.key,
    required this.idScrim,
    required this.title,
    required this.prize,
    required this.fee,
    required this.slotsInfo,
    required this.posterImage,
    required this.primaryYellow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusM), // Memakai config radius
        image: DecorationImage(
          // LANGSUNG TEMPEL VARIABEL posterImage KARENA LINK-NYA SUDAH UTUH DARI HOME SCREEN
          image: posterImage.isNotEmpty 
              ? NetworkImage(posterImage) 
              : const AssetImage('assets/images/default_poster.png') as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [AppColors.black.withOpacity(0.95), AppColors.black.withOpacity(0.2)],
          ),
        ),
        padding: const EdgeInsets.all(AppConstants.paddingM), // Memakai config padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingS, 
                vertical: AppConstants.paddingXS
              ),
              decoration: BoxDecoration(
                color: AppColors.primary, // Memakai warna emas utama asli
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                'Terpopuler', 
                style: AppTextStyles.interStatus.copyWith(color: AppColors.buttonText),
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              title, 
              style: AppTextStyles.poppinsTitleSmall, // Memakai text style poppins title small
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppConstants.paddingXS),
            Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.primary, size: 14),
                const SizedBox(width: AppConstants.paddingXS),
                Text(prize, style: AppTextStyles.interCaption.copyWith(color: AppColors.white)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.payments, color: AppColors.primary, size: 14),
                const SizedBox(width: AppConstants.paddingXS),
                Text(fee, style: AppTextStyles.interCaption.copyWith(color: AppColors.white)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.people, color: AppColors.primary, size: 14),
                const SizedBox(width: AppConstants.paddingXS),
                Text(slotsInfo, style: AppTextStyles.interCaption.copyWith(color: AppColors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 