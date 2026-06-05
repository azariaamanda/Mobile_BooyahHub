import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/paket_premium_model.dart';

class PremiumManagementScreen extends StatefulWidget {
  const PremiumManagementScreen({super.key});

  @override
  State<PremiumManagementScreen> createState() => _PremiumManagementScreenState();
}

class _PremiumManagementScreenState extends State<PremiumManagementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<PaketPremiumModel> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    try {
      final data = await _supabase.from('paket_premium').select().order('harga', ascending: false);
      if (mounted) {
        setState(() {
          _packages = (data as List).map((e) => PaketPremiumModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching premium packages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  if (_packages.isEmpty)
                    Center(
                      child: Text(
                        'Belum ada paket premium.',
                        style: AppTextStyles.interBody.copyWith(color: Colors.white54),
                      ),
                    )
                  else
                    ..._packages.map((pkg) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildDynamicPremiumCard(pkg),
                    )),
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
        Text(
          'Layanan Premium',
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: const Color(0xFFFFD700),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () async {
            await context.push('/owner/edit-premium');
            _fetchPackages();
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
          ),
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

  Widget _buildDynamicPremiumCard(PaketPremiumModel pkg) {
    Color tierColor = Colors.white54;
    bool isOutline = true;
    bool hasLeftBorder = false;

    // Stylings based on tier level naming conventions
    if (pkg.tierLevel?.toUpperCase() == 'PRO LEVEL') {
      tierColor = const Color(0xFFFFD700);
      isOutline = true;
      hasLeftBorder = true;
    } else if (pkg.tierLevel?.toUpperCase() == 'TEAM SCALE') {
      tierColor = const Color(0xFF00E5FF);
      isOutline = false;
    } else if (pkg.tierLevel?.toUpperCase() == 'ENTRY LEVEL') {
      tierColor = Colors.white54;
      isOutline = true;
    }

    // Default status handling
    bool isAktif = pkg.status?.toLowerCase() == 'aktif';
    Color statusColor = isAktif ? const Color(0xFF00FF87) : Colors.white54;

    // Map features to _FeatureItem
    List<_FeatureItem> dynamicFeatures = [];
    if (pkg.fiturPaket != null) {
      for (String f in pkg.fiturPaket!) {
        dynamicFeatures.add(_FeatureItem(
          icon: Icons.check_circle_outline_rounded,
          text: f,
          color: tierColor,
        ));
      }
    }

    return _buildPremiumCard(
      pkg: pkg,
      context: context,
      title: pkg.namaPaket,
      tierBadgeText: pkg.tierLevel ?? 'UMUM',
      tierBadgeColor: tierColor,
      isTierBadgeOutline: isOutline,
      statusBadgeText: isAktif ? 'AKTIF' : 'NONAKTIF',
      statusBadgeColor: statusColor,
      price: 'Rp ${(pkg.harga ?? 0).toInt().toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
      priceColor: tierColor,
      duration: '${pkg.durasiHari ?? 30} Hari',
      features: dynamicFeatures,
      usersCount: pkg.totalPengguna ?? 0,
      hasLeftBorder: hasLeftBorder,
    );
  }

  Widget _buildPremiumCard({
    required PaketPremiumModel pkg,
    required BuildContext context,
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
    return GestureDetector(
      onTap: () async {
        await context.push('/owner/edit-premium', extra: pkg);
        _fetchPackages();
      },
      child: Container(
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
                          Expanded(
                            child: Text(
                              f.text,
                              style: AppTextStyles.interCaption.copyWith(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
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
