import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSummaryGrid(),
                const SizedBox(height: 32),
                _buildChartSection(),
                const SizedBox(height: 32),
                _buildActionList(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'AA',
              style: AppTextStyles.poppinsHeadline.copyWith(
                color: AppColors.black,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang, Azaria',
                style: AppTextStyles.poppinsSubtitle.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Owner',
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildSummaryCard(
          title: 'PENDAPATAN',
          icon: Icons.account_balance_wallet_outlined,
          value: 'Rp\n12.000.000',
          subtitle: '+12.5%',
          subtitleColor: AppColors.success,
          iconColor: AppColors.primary,
        ),
        _buildSummaryCard(
          title: 'TAGIHAN\nMENUNGGU',
          icon: Icons.receipt_long_outlined,
          value: '12 Tagihan',
          subtitle: 'menunggu review',
          subtitleColor: AppColors.primary,
          iconColor: AppColors.textSecondary,
        ),
        _buildSummaryCard(
          title: 'SESI AKTIF',
          icon: Icons.videogame_asset_outlined,
          value: '24 Sesi',
          subtitle: 'Berlangsung Sekarang',
          subtitleColor: AppColors.textHint,
          iconColor: AppColors.textSecondary,
        ),
        _buildSummaryCard(
          title: 'ADMIN',
          icon: Icons.people_outline,
          value: '1.250 Admin',
          subtitle: 'admin terverifikasi',
          subtitleColor: AppColors.textHint,
          iconColor: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.poppinsHeadline.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (subtitleColor == AppColors.success)
                    const Icon(Icons.arrow_drop_up, color: AppColors.success, size: 16)
                  else if (subtitleColor == AppColors.textHint)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    subtitle,
                    style: AppTextStyles.interCaption.copyWith(
                      color: subtitleColor,
                      fontSize: 10,
                      fontStyle: subtitleColor == AppColors.primary ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Analisis Pendapatan',
              style: AppTextStyles.poppinsSubtitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '6 Bulan terakhir',
              style: AppTextStyles.interCaption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Grid lines
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(3, (index) => const Divider(color: AppColors.divider)),
                    ),
                    // Placeholder Curve
                    CustomPaint(
                      size: const Size(double.infinity, double.infinity),
                      painter: _CurvePainter(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildChartLabel('Jan'),
                  _buildChartLabel('Feb'),
                  _buildChartLabel('Apr'),
                  _buildChartLabel('Jun'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildActionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perlu Tindakan Owner',
          style: AppTextStyles.poppinsSubtitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Tagihan Menunggu Verifikasi',
          badgeText: '8 Menunggu',
          description: 'Admin sudah upload\nbukti',
          borderColor: AppColors.primary,
          badgeColor: AppColors.primary.withOpacity(0.2),
          badgeTextColor: AppColors.primary,
          buttonText: 'VERIFIKASI',
          buttonColor: AppColors.primary,
          buttonTextColor: AppColors.black,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Admin Melewati Limit Utang',
          badgeText: '3 Admin',
          description: 'Admin melewati limit',
          borderColor: AppColors.error,
          badgeColor: AppColors.error.withOpacity(0.2),
          badgeTextColor: AppColors.textSecondary,
          buttonText: 'LIHAT',
          buttonColor: AppColors.surfaceVariant,
          buttonTextColor: AppColors.textSecondary,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Paket Premium Menunggu Aktivasi',
          badgeText: '8 Menunggu',
          description: 'Pembayaran Premium\nperlu dicek',
          borderColor: AppColors.success,
          badgeColor: AppColors.success.withOpacity(0.2),
          badgeTextColor: AppColors.success,
          buttonText: 'LIHAT',
          buttonColor: AppColors.surfaceVariant,
          buttonTextColor: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String badgeText,
    required String description,
    required Color borderColor,
    required Color badgeColor,
    required Color badgeTextColor,
    required String buttonText,
    required Color buttonColor,
    required Color buttonTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.interBody.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: AppTextStyles.interCaption.copyWith(
                          color: badgeTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        description,
                        style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: buttonTextColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              buttonText,
              style: AppTextStyles.interCaption.copyWith(
                fontWeight: FontWeight.bold,
                color: buttonTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard, 'DASHBOARD', 0),
          _buildNavItem(Icons.people, 'ADMIN', 1),
          _buildNavItem(Icons.receipt_long, 'TAGIHAN', 2),
          _buildNavItem(Icons.stars, 'BANNER/PREMIUM', 3),
          _buildNavItem(Icons.person, 'PROFIL', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.interCaption.copyWith(
                color: color,
                fontSize: 8,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.6, size.width * 0.4, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.3, size.width * 0.7, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.9, size.width * 0.9, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.95, size.height * 0.1, size.width, size.height * 0.4);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
