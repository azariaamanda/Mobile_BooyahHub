import 'package:flutter/material.dart';
// IMPORT SEMUA CONFIG ASLI TIM LU
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

  // Menggunakan SupabaseClientHelper.client buatan tim lu
  Future<List<Map<String, dynamic>>> fetchModes() async {
    final response = await SupabaseClientHelper.client
        .from('master_mode_pertandingan')
        .select('id_mode, nama_mode')
        .order('id_mode', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Menggunakan SupabaseClientHelper.client buatan tim lu
  Future<List<Map<String, dynamic>>> fetchScrimData() async {
    var query = SupabaseClientHelper.client.from('scrim').select();
    if (_selectedModeId != 0) {
      query = query.eq('id_mode', _selectedModeId);
    }
    final response = await query.order('id_scrim', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background scaffold otomatis mengikuti AppTheme bawaan (AppColors.background)
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM), // Memakai config padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TeamProfileHeader(
                  namaTim: "Azaria Amanda",
                  fotoProfilName: "azariaamanda@gmail.com",
                ),
                const SizedBox(height: AppConstants.paddingL),

                // ================= 1. BANNER REKOMENDASI =================
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: SupabaseClientHelper.client.from('scrim').select().limit(1),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox(height: 180);
                    }
                    final bannerScrim = snapshot.data!.first;
                    final double totalHadiah = double.tryParse(bannerScrim['total_hadiah'].toString()) ?? 0;
                    final bannerImageUrl = AppImageHelper.posterByIdScrim(bannerScrim['id_scrim']);

                    return Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.radiusL), // Memakai config radius
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
                            colors: [AppColors.black.withOpacity(0.8), Colors.transparent],
                          ),
                        ),
                        padding: const EdgeInsets.all(AppConstants.paddingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingS, vertical: AppConstants.paddingXS),
                              decoration: BoxDecoration(
                                color: AppColors.primary, // Memakai Emas Utama
                                borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                              ),
                              child: Text(
                                'Rekomendasi Scrim',
                                style: AppTextStyles.interStatus.copyWith(color: AppColors.buttonText),
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingXS),
                            Text(
                              bannerScrim['nama_scrim'] ?? '',
                              style: AppTextStyles.poppinsTitle, // Memakai font standard
                            ),
                            Text(
                              'Total Hadiah: Rp. ${totalHadiah.toStringAsFixed(0)}',
                              style: AppTextStyles.interCaption, // Memakai font standard Abu-abu hint
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),
                
                // Indikator Titik Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == 0 ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == 0 ? AppColors.primary : AppColors.textDisabled,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
                const SizedBox(height: AppConstants.paddingL),

                // ================= 2. JUDUL SECTION (SCRIM TERKINI) =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // FIX ERROR .between
                  children: [
                    Row(
                      children: [
                        Container(width: 4, height: 20, color: AppColors.primary),
                        const SizedBox(width: AppConstants.paddingS),
                        Text(
                          'Scrim Terkini',
                          style: AppTextStyles.poppinsSectionTitle, // Memakai font section title asli
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Row(
                        children: [
                          Text('Lihat Lainnya', style: AppTextStyles.interLink), // Menggunakan InterLink
                          const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                        ],
                      ),
                    )
                  ],
                ),

                // ================= 3. FILTER KATEGORI (CHIP STYLE) =================
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchModes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 35);
                    
                    final modes = [
                      {'id_mode': 0, 'nama_mode': 'Semua'},
                      ...snapshot.data!
                    ];

                    return SizedBox(
                      height: 35,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: modes.length,
                        itemBuilder: (context, index) {
                          final mode = modes[index];
                          final isSelected = mode['id_mode'] == _selectedModeId;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedModeId = mode['id_mode'] as int;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: AppConstants.paddingS),
                              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                // Memakai manajemen warna chip milik tim lu
                                color: isSelected ? AppColors.chipActive : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                                border: Border.all(color: isSelected ? AppColors.primary : AppColors.inputBorder),
                              ),
                              child: Text(
                                mode['nama_mode'].toString(),
                                style: isSelected ? AppTextStyles.goldHighlight : AppTextStyles.interBodyMedium,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),

                // ================= 4. GRID DATA SCRIM =================
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchScrimData(),
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
                        child: Text('Gagal memuat data scrim atau data kosong.', style: AppTextStyles.interBody),
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

                        return ScrimItemCard(
                          idScrim: scrim['id_scrim'],
                          title: scrim['nama_scrim'] ?? 'No Title',
                          prize: 'Rp. ${hadiah.toStringAsFixed(0)}',
                          fee: biaya == 0 ? 'Free' : 'Rp. ${biaya.toStringAsFixed(0)}',
                          slotsInfo: '0/$maksPeserta terisi',
                          posterImage: AppImageHelper.posterByIdScrim(scrim['id_scrim']), // Memakai asset link murni helper tim lu
                          primaryYellow: AppColors.primary,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}