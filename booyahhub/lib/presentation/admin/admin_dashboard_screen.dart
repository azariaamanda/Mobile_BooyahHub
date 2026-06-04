import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'admin_notification_page.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppConstants.paddingS),

            // ── Header ──
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'AA',
                    style: AppTextStyles.poppinsButton.copyWith(
                      color: AppColors.background,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo,',
                      style: AppTextStyles.interBody.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Anugerah',
                      style: AppTextStyles.poppinsTitleSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminNotificationPage(),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingL),

            // ── Grid Stats 2x2 ──
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Booking Hari Ini',
                    value: '24',
                    subtitle: 'Total Booking',
                    badge: '12.5% Vs kemarin',
                    badgeUp: true,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: _StatCard(
                    title: 'Verifikasi',
                    value: '12',
                    subtitle: 'Pembayaran',
                    badge: 'Menunggu Verifikasi',
                    badgeUp: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingS),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Sisa Slot',
                    value: '23',
                    subtitle: 'Slot Tersisa',
                    badge: 'Dari 50 Total Slot',
                    badgeUp: null,
                    highlightBadge: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingL),

            // ── Keuangan ──
            _RevenueCard(),
            const SizedBox(height: AppConstants.paddingL),

            // ── Tren Booking ──
            Text(
              'Tren Booking',
              style: AppTextStyles.poppinsTitleSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            _TrendChart(),

            const SizedBox(height: AppConstants.paddingM),
          ],
        ),
      ),
    );
  }
}

// ── Revenue Card ──
class _RevenueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendapatan Bulan Ini',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp 750.000',
            style: AppTextStyles.poppinsHeadline.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '12.5%',
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Vs bulan lalu',
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String badge;
  final bool? badgeUp;
  final bool highlightBadge;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.badge,
    required this.badgeUp,
    this.highlightBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.poppinsHeadline.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (badgeUp != null)
                Icon(
                  badgeUp!
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
              if (badgeUp != null) const SizedBox(width: 3),
              Flexible(
                child: Text(
                  badge,
                  style: AppTextStyles.interBody.copyWith(
                    color: highlightBadge
                        ? AppColors.textSecondary
                        : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Trend Chart ──
class _TrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '7 HARI TERAKHIR',
            style: AppTextStyles.interLabel.copyWith(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(painter: _ChartPainter(), size: Size.infinite),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  static const _days = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];
  static const _data = [1.0, 3.0, 15.0, 13.0, 11.0, 16.0, 27.0];

  @override
  void paint(Canvas canvas, Size size) {
    const maxVal = 30.0;
    const labelHeight = 18.0;
    final chartH = size.height - labelHeight;
    final stepX = size.width / (_data.length - 1);

    // Y gridlines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = chartH - (chartH * i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Convert data to offsets
    List<Offset> pts = [];
    for (int i = 0; i < _data.length; i++) {
      final x = stepX * i;
      final y = chartH - (chartH * _data[i] / maxVal);
      pts.add(Offset(x, y));
    }

    // Fill gradient under line
    final fillPath = Path()..moveTo(pts.first.dx, chartH);
    for (final p in pts) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(pts.last.dx, chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFD4AF37).withOpacity(0.3),
          const Color(0xFFD4AF37).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotFill = Paint()..color = const Color(0xFF0A1628);
    final dotBorder = Paint()
      ..color = const Color(0xFFD4AF37)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final p in pts) {
      canvas.drawCircle(p, 4, dotFill);
      canvas.drawCircle(p, 4, dotBorder);
    }

    // Day labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < _days.length; i++) {
      tp.text = TextSpan(
        text: _days[i],
        style: const TextStyle(
          color: Color(0xFF8899AA),
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(stepX * i - tp.width / 2, chartH + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
