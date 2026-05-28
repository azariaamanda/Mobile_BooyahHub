import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_image_helper.dart';
import '../../config/app_text_styles.dart';
import '../../config/supabase_client.dart';
import 'user_widgets/scrim_item_card.dart';

class ScrimPage extends StatefulWidget {
  const ScrimPage({super.key});

  @override
  State<ScrimPage> createState() => _ScrimPageState();
}

class _ScrimPageState extends State<ScrimPage> {
  String _selectedSort = 'terpopuler';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _sortOptions = [
    {'value': 'terpopuler', 'label': 'Terpopuler'},
    {'value': 'terbaru', 'label': 'Terkini'},
    {'value': 'semua', 'label': 'Semua'},
  ];

  Future<List<Map<String, dynamic>>> fetchAllScrims() async {
    try {
      dynamic query = SupabaseClientHelper.client.from('scrim').select();

      // Logika pencarian berdasarkan nama scrim bray
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('nama_scrim', '%$_searchQuery%');
      }

      // Logika filter sorting sesuai gambar
      switch (_selectedSort) {
        case 'terpopuler':
          query = query.order('total_hadiah', ascending: false);
          break;
        case 'terbaru':
          query = query.order('dibuat_pada', ascending: false);
          break;
        case 'semua':
        default:
          query = query.order('id_scrim', ascending: false);
          break;
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('EROR FETCH SCRIM PAGE: $e');
      return [];
    }
  }

  String _formatRupiah(dynamic value) {
    if (value == null) return 'Rp 0';
    // Solusi ampuh pencegah FormatException desimal .0 bray
    final double nominal = double.tryParse(value.toString()) ?? 0;
    return 'Rp ${nominal.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. BAR PENCARIAN (SEARCH BAR) ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                  border: Border.all(color: AppColors.inputBorder, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textDisabled, size: 20),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Cari turnamen atau scrim...',
                          hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        child: Icon(Icons.clear, color: AppColors.textDisabled, size: 18),
                      ),
                  ],
                ),
              ),
            ),

            // ─── 2. BARIS CHIP FILTER (HORIZONTAL SCROLL) ───────────────────
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                itemCount: _sortOptions.length,
                itemBuilder: (context, index) {
                  final option = _sortOptions[index];
                  final isSelected = _selectedSort == option['value'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSort = option['value']!;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: AppConstants.paddingS),
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.inputBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        option['label']!,
                        style: TextStyle(
                          color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),

            // ─── 3. GRID CONTENT 2 KOLOM (DENGAN FUTUREBUILDER) ─────────────
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchAllScrims(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada scrim ditemukan bray.',
                        style: AppTextStyles.interBody,
                      ),
                    );
                  }

                  final listScrim = snapshot.data!;

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                    itemCount: listScrim.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.73, // Disesuaikan biar proporsi pas bray
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}