import 'package:flutter/material.dart';
import '../../../config/app_color.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';
import '../../../data/models/transaksi_keuangan_model.dart';

class TransactionCard extends StatelessWidget {
  final TransaksiKeuangan transaksi;
  final VoidCallback? onTap;

  const TransactionCard({super.key, required this.transaksi, this.onTap});

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'berhasil':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'gagal':
      case 'ditolak':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTransactionIcon() {
    if (transaksi.isPemasukan) {
      return Icons.call_received;
    } else if (transaksi.isPenarikan) {
      return Icons.call_made;
    } else if (transaksi.isHadiah) {
      return Icons.card_giftcard;
    }
    return Icons.swap_horiz;
  }

  Color _getIconBackgroundColor() {
    if (transaksi.isPenarikan) {
      return AppColors.accentRed.withOpacity(0.1);
    } else if (transaksi.isHadiah) {
      return AppColors.primary.withOpacity(0.1);
    }
    return AppColors.success.withOpacity(0.1);
  }

  Color _getIconColor() {
    if (transaksi.isPenarikan) {
      return AppColors.accentRed;
    } else if (transaksi.isHadiah) {
      return AppColors.primary;
    }
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingM,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTransactionIcon(),
                  color: _getIconColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaksi.tipeText,
                      style: AppTextStyles.poppinsTitleSmall,
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(
                      transaksi.deskripsi.isEmpty
                          ? transaksi.statusText
                          : transaksi.deskripsi,
                      style: AppTextStyles.interCaption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Amount and Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaksi.displayNominal,
                    style: AppTextStyles.poppinsMoney.copyWith(
                      color: transaksi.isPenarikan
                          ? AppColors.accentRed
                          : AppColors.success,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingS,
                      vertical: AppConstants.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaksi.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Text(
                      transaksi.statusText,
                      style: AppTextStyles.interCaption.copyWith(
                        color: _getStatusColor(transaksi.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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
}
