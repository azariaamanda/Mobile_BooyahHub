import 'package:flutter/material.dart';
import '../../../config/app_color.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';

class BalanceCard extends StatelessWidget {
  final double saldoTotal;
  final double saldoBisaDitarik;
  final double saldoDitahan;
  final double saldoHadiah;
  final VoidCallback? onWithdrawPressed;

  const BalanceCard({
    super.key,
    required this.saldoTotal,
    required this.saldoBisaDitarik,
    required this.saldoDitahan,
    required this.saldoHadiah,
    this.onWithdrawPressed,
  });

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.primaryDark.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Total',
                    style: AppTextStyles.interCaption.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    _formatCurrency(saldoTotal),
                    style: AppTextStyles.poppinsMoneyLarge,
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: const Icon(
                  Icons.wallet_outlined,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingL),

          // Breakdown row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BreakdownItem(label: 'Bisa Ditarik', amount: saldoBisaDitarik),
              Container(
                width: 1,
                height: 50,
                color: AppColors.white.withOpacity(0.2),
              ),
              _BreakdownItem(label: 'Ditahan', amount: saldoDitahan),
              Container(
                width: 1,
                height: 50,
                color: AppColors.white.withOpacity(0.2),
              ),
              _BreakdownItem(label: 'Hadiah', amount: saldoHadiah),
            ],
          ),
          const SizedBox(height: AppConstants.paddingL),

          // Withdraw button
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: onWithdrawPressed,
              icon: const Icon(Icons.call_made, size: 18),
              label: const Text('Tarik Dana'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonText.withOpacity(0.95),
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final double amount;

  const _BreakdownItem({required this.label, required this.amount});

  String _formatCurrency(double amt) {
    if (amt >= 1000000) {
      return 'Rp ${(amt / 1000000).toStringAsFixed(1)}JT';
    } else if (amt >= 1000) {
      return 'Rp ${(amt / 1000).toStringAsFixed(0)}K';
    }
    return 'Rp ${amt.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textPrimary.withOpacity(0.7),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            _formatCurrency(amount),
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
