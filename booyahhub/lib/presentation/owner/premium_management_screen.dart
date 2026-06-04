import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class PremiumManagementScreen extends StatelessWidget {
  const PremiumManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          children: [
            _buildAppBar(),
            const SizedBox(height: 32),
            _buildHeader(),
            const SizedBox(height: 32),
            _buildPremiumCard(
              title: 'Elite Commander',
              tierBadgeText: 'PRO LEVEL',
              tierBadgeColor: const Color(0xFFFFD700),
              isTierBadgeOutline: true,
              statusBadgeText: 'AKTIF',
              statusBadgeColor: const Color(0xFF00FF87),
              price: 'Rp 100.000',
              priceColor: const Color(0xFFFFD700),
              duration: '30 Hari',
              features: [
                _FeatureItem(icon: Icons.verified_rounded, text: 'Dukungan Prioritas 24/7', color: const Color(0xFFFFD700)),
                _FeatureItem(icon: Icons.campaign_rounded, text: 'Sorotan Spanduk Premium', color: const Color(0xFFFFD700)),
                _FeatureItem(icon: Icons.analytics_rounded, text: 'Analisis Tim Tingkat Lanjut', color: const Color(0xFFFFD700)),
              ],
              usersCount: 192,
              hasLeftBorder: true,
            ),
            const SizedBox(height: 16),
            _buildPremiumCard(
              title: 'Rookie Boost',
              tierBadgeText: 'ENTRY LEVEL',
              tierBadgeColor: Colors.white54,
              isTierBadgeOutline: true,
              statusBadgeText: 'NONAKTIF',
              statusBadgeColor: Colors.white54,
              price: 'Rp 45.000',
              priceColor: Colors.white70,
              duration: '30 Hari',
              features: [
                _FeatureItem(icon: Icons.bolt_rounded, text: 'Paket Kinerja Standar', color: Colors.white54),
                _FeatureItem(icon: Icons.visibility_rounded, text: 'Visibilitas Terbatas', color: Colors.white54),
              ],
              usersCount: 0,
              hasLeftBorder: false,
            ),
            const SizedBox(height: 16),
            _buildPremiumCard(
              title: 'Strategic Master',
              tierBadgeText: 'TEAM SCALE',
              tierBadgeColor: const Color(0xFF00E5FF),
              isTierBadgeOutline: false,
              statusBadgeText: 'AKTIF',
              statusBadgeColor: const Color(0xFF00FF87),
              price: 'Rp 250.000',
              priceColor: const Color(0xFF00E5FF),
              duration: '30 Hari',
              features: [
                _FeatureItem(icon: Icons.groups_rounded, text: 'Paket Kinerja Standar', color: const Color(0xFF00E5FF)),
                _FeatureItem(icon: Icons.visibility_rounded, text: 'Visibilitas Terbatas', color: const Color(0xFF00E5FF)),
              ],
              usersCount: 8,
              hasLeftBorder: false,
            ),
            const SizedBox(height: 16),
            _buildFooterCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFD700)),
            const SizedBox(width: 12),
            Text(
              'Layanan Premium',
              style: AppTextStyles.poppinsHeadline.copyWith(
                color: const Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STRATEGI PENDAPATAN',
          style: AppTextStyles.interCaption.copyWith(
            color: const Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'BOOYAHHUB',
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard({
    required String title,
    required String tierBadgeText,
    required Color tierBadgeColor,
    required bool isTierBadgeOutline,
    required String statusBadgeText,
    required Color statusBadgeColor,
    required String price,
    required Color priceColor,
    required String duration,
    required List<_FeatureItem> features,
    required int usersCount,
    required bool hasLeftBorder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: hasLeftBorder
                ? const Border(left: BorderSide(color: Color(0xFFFFD700), width: 4))
                : null,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isTierBadgeOutline ? Colors.transparent : tierBadgeColor.withValues(alpha: 0.15),
                      border: isTierBadgeOutline ? Border.all(color: tierBadgeColor.withValues(alpha: 0.5)) : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tierBadgeText,
                      style: AppTextStyles.interCaption.copyWith(
                        color: tierBadgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBadgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusBadgeText,
                      style: AppTextStyles.interCaption.copyWith(
                        color: statusBadgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.poppinsHeadline.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: AppTextStyles.poppinsHeadline.copyWith(
                      color: priceColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '/ Bulan',
                      style: AppTextStyles.interCaption.copyWith(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      duration,
                      style: AppTextStyles.interCaption.copyWith(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Icon(f.icon, color: f.color, size: 16),
                        const SizedBox(width: 12),
                        Text(
                          f.text,
                          style: AppTextStyles.interCaption.copyWith(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Digunakan oleh $usersCount Admin',
                        style: AppTextStyles.interCaption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANALISIS EKOSISTEM',
            style: AppTextStyles.interCaption.copyWith(
              color: const Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optimize your service tier strategy',
            style: AppTextStyles.interBody.copyWith(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String text;
  final Color color;

  _FeatureItem({required this.icon, required this.text, required this.color});
}
