import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/transaksi_keuangan_model.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransaksiKeuangan transaksi;

  const TransactionDetailPage({super.key, required this.transaksi});

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

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingL),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    transaksi.tipeText,
                    style: AppTextStyles.interBodyMedium.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  Text(
                    transaksi.displayNominal,
                    style: AppTextStyles.poppinsMoneyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingM,
                      vertical: AppConstants.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaksi.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Text(
                      transaksi.statusText,
                      style: AppTextStyles.poppinsTitleSmall.copyWith(
                        color: _getStatusColor(transaksi.status),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Details Section
            Text('Detail Transaksi', style: AppTextStyles.poppinsSectionTitle),
            const SizedBox(height: AppConstants.paddingM),

            // Detail Items
            _DetailItem(
              icon: Icons.fingerprint,
              label: 'ID Transaksi',
              value: transaksi.idTransaksi.toString(),
            ),
            const SizedBox(height: AppConstants.paddingM),
            _DetailItem(
              icon: Icons.calendar_today,
              label: 'Tanggal & Waktu',
              value: dateFormatter.format(transaksi.dibuatPada),
            ),
            const SizedBox(height: AppConstants.paddingM),
            _DetailItem(
              icon: Icons.info_outline,
              label: 'Deskripsi',
              value: transaksi.deskripsi.isEmpty ? '-' : transaksi.deskripsi,
              isMultiline: true,
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Withdrawal Details (if applicable)
            if (transaksi.isPenarikan) ...[
              Text('Data Rekening', style: AppTextStyles.poppinsSectionTitle),
              const SizedBox(height: AppConstants.paddingM),
              _DetailItem(
                icon: Icons.account_balance,
                label: 'Bank/E-Wallet',
                value: transaksi.namaBank ?? '-',
              ),
              const SizedBox(height: AppConstants.paddingM),
              _DetailItem(
                icon: Icons.numbers,
                label: 'Nomor Rekening',
                value: transaksi.nomorRekening ?? '-',
              ),
              const SizedBox(height: AppConstants.paddingM),
              _DetailItem(
                icon: Icons.person,
                label: 'Atas Nama',
                value: transaksi.namaAtas ?? '-',
              ),
              const SizedBox(height: AppConstants.paddingL),
            ],

            // Status Timeline
            if (transaksi.diperbarui != null) ...[
              Text('Timeline', style: AppTextStyles.poppinsSectionTitle),
              const SizedBox(height: AppConstants.paddingM),
              _TimelineItem(
                status: 'Dibuat',
                date: dateFormatter.format(transaksi.dibuatPada),
                isCompleted: true,
              ),
              _TimelineItem(
                status: transaksi.statusText,
                date: dateFormatter.format(transaksi.diperbarui!),
                isCompleted: transaksi.isSuccess,
              ),
              const SizedBox(height: AppConstants.paddingL),
            ],

            // Info Box
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: Text(
                      'Jika ada pertanyaan tentang transaksi ini, silakan hubungi customer support kami.',
                      style: AppTextStyles.interCaption,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Copy transaction ID
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ID Transaksi disalin'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.content_copy),
                label: const Text('Salin ID Transaksi'),
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMultiline;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: AppConstants.paddingS),
              Text(label, style: AppTextStyles.interCaption),
            ],
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            value,
            style: AppTextStyles.interBodyMedium,
            maxLines: isMultiline ? null : 1,
            overflow: isMultiline
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String status;
  final String date;
  final bool isCompleted;

  const _TimelineItem({
    required this.status,
    required this.date,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.success : AppColors.warning,
              ),
            ),
            if (!isCompleted)
              Container(width: 2, height: 30, color: AppColors.divider),
          ],
        ),
        const SizedBox(width: AppConstants.paddingM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status, style: AppTextStyles.poppinsTitleSmall),
            const SizedBox(height: AppConstants.paddingXS),
            Text(date, style: AppTextStyles.interCaption),
          ],
        ),
      ],
    );
  }
}
