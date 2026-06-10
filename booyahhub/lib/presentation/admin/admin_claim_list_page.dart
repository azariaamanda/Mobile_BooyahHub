import 'dart:math';

import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'claim_detail_page.dart';

class AdminClaimListPage extends StatelessWidget {
  const AdminClaimListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Keuangan',
          style: AppTextStyles.poppinsTitleSmall.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          // ===== TOTAL PENDAPATAN =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: AppColors.divider),
              color: AppColors.backgroundCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL PENDAPATAN',
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textHint,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Rp 12.4M', style: AppTextStyles.poppinsMoneyLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text('+4.2% bln ini', style: AppTextStyles.percentageUp),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ===== DANA KELUAR + KLAIM PENDING =====
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DANA KELUAR',
                        style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.textHint,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp 10.2M',
                        style: AppTextStyles.poppinsTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '80% Tersalurkan',
                        style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KLAIM PENDING',
                        style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.textHint,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '12',
                        style: AppTextStyles.poppinsTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Segera Proses',
                        style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text('Daftar Klaim Aktif', style: AppTextStyles.poppinsSectionTitle),

          const SizedBox(height: 12),

          // ===== KARTU URGENT (dengan hex pattern background) =====
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D1C2E),
                        Color(0xFF060F1A),
                      ],
                    ),
                  ),
                ),
                // Hex pattern overlay
                Positioned.fill(
                  child: CustomPaint(painter: _HexPatternPainter()),
                ),
                // Gold border overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'URGENT',
                              style: AppTextStyles.interStatus.copyWith(
                                color: AppColors.buttonText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '24 Okt 2023',
                            style: AppTextStyles.interCaption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ultimate Pro League - S12',
                              style: AppTextStyles.poppinsTitleSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '12 Pending',
                              style: AppTextStyles.interStatus.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text('12 Tim', style: AppTextStyles.interCaption),
                          Text(
                            '   •   ',
                            style: AppTextStyles.interCaption.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                          Text('Rp 600.000', style: AppTextStyles.goldHighlight),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ClaimDetailPage(
                                namaScrim: 'Ultimate Pro League - S12',
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(
                            Icons.receipt_long,
                            size: 18,
                            color: AppColors.buttonText,
                          ),
                          label: Text(
                            'Detail Klaim',
                            style: AppTextStyles.poppinsButton.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ===== KARTU COMPLETED =====
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('25 Okt 2023', style: AppTextStyles.interCaption),
                    Text(
                      '  •  ',
                      style: AppTextStyles.interCaption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'COMPLETED',
                      style: AppTextStyles.interStatus.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Elite Weekly Cup',
                  style: AppTextStyles.poppinsTitleSmall,
                ),
                const SizedBox(height: 4),
                Text('Rp 1.200.000', style: AppTextStyles.poppinsMoney),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selesai dalam 45 menit',
                        style: AppTextStyles.interCaption,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(
                        Icons.history,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      label: Text(
                        'Lihat Riwayat',
                        style: AppTextStyles.interLabel.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Hex grid pattern painter untuk background kartu URGENT
class _HexPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9A227).withValues(alpha: 0.07)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const hexRadius = 22.0;
    final hexWidth = hexRadius * 2;
    final hexHeight = sqrt(3) * hexRadius;
    final colStep = hexWidth * 0.75;
    final rowStep = hexHeight;

    int cols = (size.width / colStep).ceil() + 2;
    int rows = (size.height / rowStep).ceil() + 2;

    for (int col = -1; col < cols; col++) {
      for (int row = -1; row < rows; row++) {
        final cx = col * colStep;
        final cy = row * rowStep + (col.isOdd ? rowStep / 2 : 0);
        _drawHex(canvas, paint, Offset(cx, cy), hexRadius);
      }
    }
  }

  void _drawHex(Canvas canvas, Paint paint, Offset center, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 180) * (60 * i - 30);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
