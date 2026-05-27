import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_image_helper.dart';
import '../../config/app_text_styles.dart';
import '../../config/supabase_client.dart';
import 'user_widgets/team_profile_header.dart';
import 'user_widgets/scrim_item_card.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedModeId = 0;
  String _selectedSort = 'terbaru';

  final List<Map<String, String>> _sortOptions = [
    {'value': 'semua', 'label': 'Semua'},
    {'value': 'terpopuler', 'label': 'Terpopuler'},
    {'value': 'terlama', 'label': 'Terlama'},
    {'value': 'terbaru', 'label': 'Terkini'},
  ];

  // FIX: Kita buang variabel late di initState biar gak crash pas apps baru nyala bray

  Future<List<Map<String, dynamic>>> fetchModes() async {
    final response = await SupabaseClientHelper.client
        .from('master_mode_pertandingan')
        .select('id_mode, nama_mode')
        .order('id_mode', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchBannerScrimData() async {
    final response = await SupabaseClientHelper.client
        .from('scrim')
        .select()
        .order('dibuat_pada', ascending: false)
        .limit(3);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchScrimData() async {
    dynamic query = SupabaseClientHelper.client.from('scrim').select();

    if (_selectedModeId != 0) {
      query = query.eq('id_mode', _selectedModeId);
    }

    switch (_selectedSort) {
      case 'terbaru':
        query = query.order('dibuat_pada', ascending: false);
        break;
      case 'terlama':
        query = query.order('dibuat_pada', ascending: true);
        break;
      case 'terpopuler':
        query = query.order('total_hadiah', ascending: false);
        break;
      case 'semua':
      default:
        query = query.order('id_scrim', ascending: false);
        break;
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Widget _buildSectionTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, color: AppColors.primary),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              'Scrim Terkini',
              style: AppTextStyles.poppinsSectionTitle,
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Row(
            children: [
              Text('Lihat Lainnya', style: AppTextStyles.interLink),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortFilter() {
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sortOptions.length,
        itemBuilder: (context, index) {
          final sort = _sortOptions[index];
          final isSelected = _selectedSort == sort['value'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSort = sort['value']!;
                // Pas filter diklik, halaman bakal nge-trigger fetchScrimData otomatis bray
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: AppConstants.paddingS),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.chipActive : Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.inputBorder,
                ),
              ),
              child: Text(
                sort['label']!,
                style: isSelected
                    ? AppTextStyles.goldHighlight
                    : AppTextStyles.interBodyMedium,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrimGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchScrimData(), // Langsung panggil fungsinya di sini bray, aman dari late error
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingXL),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Gagal memuat data scrim atau data kosong.',
              style: AppTextStyles.interBody,
            ),
          );
        }

        final listScrim = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listScrim.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final scrim = listScrim[index];

            final double biaya = double.tryParse(scrim['biaya_pendaftaran'].toString()) ?? 0;
            final double hadiah = double.tryParse(scrim['total_hadiah'].toString()) ?? 0;
            final int maksPeserta = scrim['maks_peserta'] ?? 16;

            return GestureDetector(
              onTap: () {
                context.pushNamed(
                  'detail_scrim',
                  pathParameters: {
                    'idScrim': scrim['id_scrim'].toString(),
                  },
                );
              },
              child: ScrimItemCard(
                idScrim: scrim['id_scrim'],
                title: scrim['nama_scrim'] ?? 'No Title',
                prize: _formatRupiah(hadiah),
                fee: biaya == 0 ? 'Free' : _formatRupiah(biaya),
                slotsInfo: '0/$maksPeserta terisi',
                posterImage: AppImageHelper.posterByIdScrim(scrim['id_scrim']),
                primaryYellow: AppColors.primary,
              ),
            );
          },
        );
      },
    );
  }

  String _formatRupiah(dynamic value) {
    final double nominal = double.tryParse(value.toString()) ?? 0;
    return 'Rp. ${nominal.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TeamProfileHeader(
                  namaTim: "Azaria Amanda",
                  fotoProfilName: "azariaamanda@gmail.com",
                ),
                const SizedBox(height: AppConstants.paddingL),

                // FIX: Panggil fetchBanner langsung di dalam FutureBuilder bray
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchBannerScrimData(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox(height: 180);
                    }
                    return HomeBannerSlider(banners: snapshot.data!);
                  },
                ),

                const SizedBox(height: AppConstants.paddingL),
                _buildSectionTitle(),
                const SizedBox(height: AppConstants.paddingS),
                _buildSortFilter(),
                const SizedBox(height: AppConstants.paddingM),
                _buildScrimGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── WIDGET MANDIRI BANNER SLIDER (TETAP TERPISAH AGAR TIDAK REFRESH) ───
class HomeBannerSlider extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  const HomeBannerSlider({super.key, required this.banners});

  @override
  State<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<HomeBannerSlider> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBanner = 0;

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(
      const Duration(seconds: 7),
      (_) {
        if (!_bannerController.hasClients) return;

        final nextPage = (_currentBanner + 1) % widget.banners.length;

        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  String _formatRupiah(dynamic value) {
    final double nominal = double.tryParse(value.toString()) ?? 0;
    return 'Rp. ${nominal.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              // setState di sini AMAN bray, cuma ngeremart area HomeBannerSlider doang!
              setState(() {
                _currentBanner = index;
              });
            },
            itemBuilder: (context, index) {
              final bannerScrim = widget.banners[index];
              final bannerImageUrl = AppImageHelper.posterByIdScrim(bannerScrim['id_scrim']);

              return GestureDetector(
                onTap: () {
                  context.pushNamed(
                    'detail_scrim',
                    pathParameters: {
                      'idScrim': bannerScrim['id_scrim'].toString(),
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    image: DecorationImage(
                      image: NetworkImage(bannerImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingS,
                            vertical: AppConstants.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                          ),
                          child: Text(
                            'Rekomendasi Scrim',
                            style: AppTextStyles.interStatus.copyWith(
                              color: AppColors.buttonText,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingXS),
                        Text(
                          bannerScrim['nama_scrim'] ?? '',
                          style: AppTextStyles.poppinsTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Total Hadiah: ${_formatRupiah(bannerScrim['total_hadiah'])}',
                          style: AppTextStyles.interCaption,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (index) {
              final bool isActive = index == _currentBanner;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}