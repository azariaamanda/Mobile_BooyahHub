import 'package:flutter/material.dart';
import '../../../config/app_color.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';

class StatisticCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatisticCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: AppConstants.paddingM),
              Text(title, style: AppTextStyles.interCaption),
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                amount,
                style: AppTextStyles.poppinsTitleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
