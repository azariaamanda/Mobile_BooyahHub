import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // extra padding for floating navbar
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildSummaryGrid(context),
            const SizedBox(height: 32),
            _buildChartSection(),
            const SizedBox(height: 32),
            _buildActionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700), // Yellow
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'AA',
                  style: AppTextStyles.poppinsHeadline.copyWith(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang, Azaria',
                  style: AppTextStyles.poppinsTitleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Owner',
                  style: AppTextStyles.interBody.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'PENDAPATAN',
                icon: Icons.account_balance_wallet_rounded,
                value: 'Rp\n12.000.000',
                subtitle: '+12.5%',
                subtitleColor: const Color(0xFF00FF87),
                iconColor: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'TAGIHAN\nMENUNGGU',
                icon: Icons.receipt_long_rounded,
                value: '12 Tagihan',
                subtitle: 'menunggu review',
                subtitleColor: const Color(0xFFFFD700),
                iconColor: const Color(0xFFFFD700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'SESI AKTIF',
                icon: Icons.videogame_asset_rounded,
                value: '24 Sesi',
                subtitle: 'Berlangsung Sekarang',
                subtitleColor: Colors.blueGrey,
                iconColor: const Color(0xFFFFD700),
                isDot: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'ADMIN',
                icon: Icons.people_alt_rounded,
                value: '1.250 Admin',
                subtitle: 'admin terverifikasi',
                subtitleColor: const Color(0xFFFFD700),
                iconColor: const Color(0xFFFFD700),
              ),
            ),
          ],
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
    bool isDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D), // Darker card background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.interCaption.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTextStyles.poppinsHeadline.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isDot)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(color: Colors.blueGrey, shape: BoxShape.circle),
                )
              else if (subtitleColor == const Color(0xFF00FF87))
                const Padding(
                  padding: EdgeInsets.only(right: 2.0),
                  child: Icon(Icons.arrow_drop_up, color: Color(0xFF00FF87), size: 16),
                ),
              Expanded(
                child: Text(
                  subtitle,
                  style: AppTextStyles.interCaption.copyWith(
                    color: subtitleColor,
                    fontSize: 8,
                    fontStyle: FontStyle.italic,
                  ),
                ),
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
              style: AppTextStyles.poppinsTitleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '6 Bulan terakhir',
              style: AppTextStyles.interCaption.copyWith(
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF131F2D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  // Safe mockup line chart instead of CustomPaint
                  child: Container(
                    width: double.infinity,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: Colors.white24,
                margin: const EdgeInsets.only(bottom: 8),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
      style: AppTextStyles.interCaption.copyWith(color: Colors.white70, fontSize: 11),
    );
  }

  Widget _buildActionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perlu Tindakan Owner',
          style: AppTextStyles.poppinsTitleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Tagihan Menunggu Verifikasi',
          badgeText: '8 Menunggu',
          description: 'Admin sudah upload bukti',
          borderColor: const Color(0xFFFFD700),
          badgeColor: const Color(0xFFFFD700).withValues(alpha: 0.15),
          badgeTextColor: const Color(0xFFFFD700),
          buttonText: 'VERIFIKASI',
          buttonColor: const Color(0xFFFFD700),
          buttonTextColor: Colors.black,
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Admin Melewati Limit Utang',
          badgeText: '3 Admin',
          description: 'Admin melewati limit',
          borderColor: Colors.redAccent,
          badgeColor: Colors.redAccent.withValues(alpha: 0.15),
          badgeTextColor: Colors.redAccent,
          buttonText: 'LIHAT',
          buttonColor: Colors.white12,
          buttonTextColor: Colors.white70,
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Paket Premium Menunggu Aktivasi',
          badgeText: '8 Menunggu',
          description: 'perlu dicek',
          borderColor: const Color(0xFF00FF87),
          badgeColor: const Color(0xFF00FF87).withValues(alpha: 0.15),
          badgeTextColor: const Color(0xFF00FF87),
          buttonText: 'LIHAT',
          buttonColor: Colors.white12,
          buttonTextColor: Colors.white70,
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
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
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
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.interCaption.copyWith(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                  elevation: 0,
                  minimumSize: const Size(80, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  buttonText,
                  style: AppTextStyles.interCaption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: buttonTextColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
