import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_color.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';
import '../../../data/models/saldo_pengguna_model.dart';

class FinancialDashboardWidget extends StatelessWidget {
  final SaldoPengguna? saldo;
  final bool isLoading;
  final VoidCallback? onViewMore;
  final VoidCallback? onWithdraw;

  const FinancialDashboardWidget({
    super.key,
    this.saldo,
    this.isLoading = false,
    this.onViewMore,
    this.onWithdraw,
  });

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}JT';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: const Column(
          children: [
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            SizedBox(height: 20),
          ],
        ),
      );
    }

    if (saldo == null) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Text(
                'Gagal memuat data keuangan',
                style: AppTextStyles.interCaption,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.85),
            AppColors.primaryDark.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Anda',
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.8),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(AppConstants.paddingS),
                child: const Icon(
                  Icons.wallet_outlined,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),

          // Amount
          Text(
            _formatCurrency(saldo!.saldoTotal),
            style: AppTextStyles.poppinsMoneyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            'Bisa Ditarik: ${_formatCurrency(saldo!.saldoBisaDitarik)}',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppConstants.paddingL),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onWithdraw,
                  icon: const Icon(Icons.call_made, size: 16),
                  label: const Text('Tarik'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonText.withOpacity(0.95),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingS,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewMore,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Detail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white.withOpacity(0.15),
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingS,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
