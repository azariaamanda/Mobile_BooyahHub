import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_image_helper.dart';
import '../../config/app_text_styles.dart';
import '../../config/supabase_client.dart';
import 'user_widgets/claim_prize_notification.dart';
import 'user_widgets/team_profile_header.dart';
import 'user_widgets/scrim_item_card.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => UserHomeScreenState();
}

<<<<<<< HEAD
class UserHomeScreenState extends State<UserHomeScreen> {
  void refreshProfile() {
    setState(() {});
  }
  int _selectedModeId = 0; // PERBAIKAN: jadikan variable, bukan final
=======
class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedModeId = 0;
>>>>>>> cd46f7c90299f509cb5b215a9b37f9b4a06185d1
  String _selectedSort = 'semua';
  int _unreadNotifCount = 0;
  final _supabase = Supabase.instance.client;

  final List<Map<String, String>> _sortOptions = [
    {'value': 'semua', 'label': 'Semua'},
    {'value': 'terpopuler', 'label': 'Terpopuler'},
    {'value': 'terlama', 'label': 'Terlama'},
    {'value': 'terbaru', 'label': 'Terkini'},
  ];

  List<Map<String, dynamic>> _modes = [];
  bool _isLoadingModes = true;

  @override
  void initState() {
    super.initState();
    _fetchModes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showUnreadNotifications();
    });
  }

  Future<void> _showUnreadNotifications() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final prefKey = 'read_notifications_$userId';
      final readIds = prefs.getStringList(prefKey) ?? [];

      final response = await Supabase.instance.client
          .from('notifikasi')
          .select('id_notifikasi, judul, pesan')
          .order('dikirim_pada', ascending: false);

      if (!mounted) return;

      final unread = (response as List)
          .where((item) =>
              !readIds.contains(item['id_notifikasi'].toString()))
          .toList();

      if (mounted) setState(() => _unreadNotifCount = unread.length);

      if (unread.isEmpty) return;

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      final String popupTitle = unread.length == 1
          ? (unread[0]['judul'] ?? 'Notifikasi Baru')
          : '${unread.length} Notifikasi Baru';

      final String popupMessage = unread.length == 1
          ? (unread[0]['pesan'] ?? '')
          : 'Anda memiliki ${unread.length} notifikasi yang belum dibaca';

      NotificationPopup.show(
        context,
        title: popupTitle,
        message: popupMessage,
        icon: Icons.notifications_rounded,
        iconColor: AppColors.primary,
        onTap: () => context.pushNamed('notifikasi'),
      );
    } catch (e) {
      debugPrint('Error fetching unread notifications: $e');
    }
  }

  Future<void> _markAllUnreadAsRead(
    List<dynamic> unreadItems,
    List<String> currentReadIds,
    SharedPreferences prefs,
    String prefKey,
  ) async {
    for (final item in unreadItems) {
      final id = item['id_notifikasi'].toString();
      if (!currentReadIds.contains(id)) {
        currentReadIds.add(id);
      }
    }
    await prefs.setStringList(prefKey, currentReadIds);
  }

  Future<void> _markNotificationRead(
    String id,
    List<String> currentReadIds,
    SharedPreferences prefs,
    String prefKey,
  ) async {
    if (!currentReadIds.contains(id)) {
      currentReadIds.add(id);
      await prefs.setStringList(prefKey, currentReadIds);
    }
  }

  // ─── FUNGSI AMBIL MODE ───
  Future<void> _fetchModes() async {
    try {
      final modes = await fetchModes();
      setState(() {
        _modes = modes;
        _isLoadingModes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingModes = false;
      });
      debugPrint('Error fetching modes: $e');
    }
  }

  // ─── FUNGSI AMBIL DATA PROFIL DARI DATABASE ───
  Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null || currentUser.email == null) return null;

      final response = await _supabase
          .from('profil_pengguna')
          .select('nama_tim, foto_profil, akun!inner(email)')
          .eq('akun.email', currentUser.email!)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // LOGIKA GAMBAR
  String? _getPosterUrl(String? path, dynamic idScrim) {
    if (path == null || path.isEmpty) {
      return AppImageHelper.posterByIdScrim(idScrim);
    }
    if (path.startsWith('http')) return path;

    final fullPath = path.startsWith('posters/') ? path : 'posters/$path';
    return _supabase.storage.from('posters').getPublicUrl(fullPath);
  }

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
        .eq('status_scrim', 'aktif') // PERBAIKAN: hanya scrim aktif
        .order('dibuat_pada', ascending: false)
        .limit(3);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchScrimData() async {
    dynamic query = SupabaseClientHelper.client
        .from('scrim')
        .select()
        .eq('status_scrim', 'aktif');

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
    final scrims = List<Map<String, dynamic>>.from(response);
    if (scrims.isEmpty) return scrims;

    // Hitung slot terisi per scrim (semua yg bukan ditolak)
    final scrimIds = scrims.map((s) => s['id_scrim'] as int).toList();
    final sessions = await SupabaseClientHelper.client
        .from('sesi_scrim')
        .select('id_sesi, id_scrim')
        .inFilter('id_scrim', scrimIds);

    final sesiToScrim = <int, int>{
      for (final s in sessions as List)
        s['id_sesi'] as int: s['id_scrim'] as int,
    };
    final sesiIds = sesiToScrim.keys.toList();

    final terisiMap = <int, int>{};
    if (sesiIds.isNotEmpty) {
      final pendaftaran = await SupabaseClientHelper.client
          .from('pendaftaran_tim')
          .select('id_sesi, status_pembayaran')
          .inFilter('id_sesi', sesiIds);
      for (final p in pendaftaran as List) {
        if ((p['status_pembayaran'] as String? ?? '') != 'ditolak') {
          final scrimId = sesiToScrim[p['id_sesi'] as int];
          if (scrimId != null)
            terisiMap[scrimId] = (terisiMap[scrimId] ?? 0) + 1;
        }
      }
    }

    return scrims
        .map(
          (s) => {...s, 'terisi_count': terisiMap[s['id_scrim'] as int] ?? 0},
        )
        .toList();
  }

  // ─── BUILD MODE FILTER CHIP (DITAMBAHKAN) ───
  Widget _buildModeFilter() {
    if (_isLoadingModes) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final isAllMode = index == 0;
          final isSelected = isAllMode
              ? _selectedModeId == 0
              : _selectedModeId == _modes[index - 1]['id_mode'];
          final label = isAllMode ? 'Semua' : _modes[index - 1]['nama_mode'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedModeId = isAllMode ? 0 : _modes[index - 1]['id_mode'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: AppConstants.paddingS),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingXS,
              ),
              child: Text(
                label,
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

  // ─── BUILD SECTION TITLE (DIPERBAIKI "LIHAT LAINNYA") ───
  Widget _buildSectionTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, color: AppColors.primary),
            const SizedBox(width: AppConstants.paddingS),
            Text('Scrim Terkini', style: AppTextStyles.poppinsSectionTitle),
          ],
        ),
        TextButton(
          onPressed: () {
            context.pushNamed('scrim_page');
          },
          child: Row(
            children: [
              Text('Lihat Lainnya', style: AppTextStyles.interLink),
              const Icon(
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
          final String value = sort['value'] ?? 'semua';
          final isSelected = _selectedSort == value;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSort = value;
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
                sort['label'] ?? '',
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
          itemCount: listScrim.length > 4
              ? 4
              : listScrim.length, // Hanya tampilkan 4 di home
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final scrim = listScrim[index];

            final double biaya =
                double.tryParse(scrim['biaya_pendaftaran'].toString()) ?? 0;
            final double hadiah =
                double.tryParse(scrim['total_hadiah'].toString()) ?? 0;
            final int maksPeserta = scrim['maks_peserta'] ?? 16;

            final String? posterUrl = _getPosterUrl(
              scrim['poster'] as String?,
              scrim['id_scrim'],
            );
            final int terisi = scrim['terisi_count'] as int? ?? 0;

            return GestureDetector(
              onTap: () {
                context.pushNamed(
                  'detail_scrim',
                  pathParameters: {'idScrim': scrim['id_scrim'].toString()},
                );
              },
              child: ScrimItemCard(
                idScrim: scrim['id_scrim'],
                title: scrim['nama_scrim'] ?? 'No Title',
                prize: _formatRupiah(hadiah),
                fee: biaya == 0 ? 'Free' : _formatRupiah(biaya),
                slotsInfo: '$terisi/$maksPeserta terisi',
                posterImage: posterUrl ?? '',
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
<<<<<<< HEAD
                // Header Profil
                FutureBuilder<Map<String, dynamic>?>(
                  future: fetchUserData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const TeamProfileHeader(
                        namaTim: "Memuat...",
                        fotoProfilUrl: null,
                      );
                    }

                    final userData = snapshot.data;
                    final String namaTim =
                        userData?['nama_tim'] ?? "No Team Name";
                    String? fotoProfil = userData?['foto_profil'];

                    if (fotoProfil != null && fotoProfil.isNotEmpty) {
                      final separator = fotoProfil.contains('?') ? '&' : '?';
                      fotoProfil = '$fotoProfil${separator}v=${DateTime.now().millisecondsSinceEpoch}';
                    }

                    return TeamProfileHeader(
                      namaTim: namaTim,
                      fotoProfilUrl: fotoProfil,
                    );
                  },
=======
                // Header Profil + Bell Notifikasi
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>?>(
                        future: fetchUserData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const TeamProfileHeader(
                              namaTim: 'Memuat...',
                              fotoProfilUrl: null,
                            );
                          }
                          final userData = snapshot.data;
                          return TeamProfileHeader(
                            namaTim: userData?['nama_tim'] ?? 'No Team Name',
                            fotoProfilUrl: userData?['foto_profil'],
                          );
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pushNamed('notifikasi'),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusM,
                              ),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                          ),
                          if (_unreadNotifCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  _unreadNotifCount > 99
                                      ? '99+'
                                      : '$_unreadNotifCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
>>>>>>> cd46f7c90299f509cb5b215a9b37f9b4a06185d1
                ),
                const SizedBox(height: AppConstants.paddingL),

                // Banner Slider
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchBannerScrimData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox(height: 180);
                    }
                    return HomeBannerSlider(
                      banners: snapshot.data!,
                      getPosterUrl: _getPosterUrl,
                    );
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

// ─── WIDGET BANNER SLIDER (SAMA SEPERTI SEBELUMNYA) ───
class HomeBannerSlider extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final String? Function(String?, dynamic) getPosterUrl;

  const HomeBannerSlider({
    super.key,
    required this.banners,
    required this.getPosterUrl,
  });

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
    _bannerTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!_bannerController.hasClients) return;
      if (widget.banners.isEmpty) return;

      final nextPage = (_currentBanner + 1) % widget.banners.length;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
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
    if (widget.banners.isEmpty) {
      return const SizedBox(height: 180);
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBanner = index;
              });
            },
            itemBuilder: (context, index) {
              final bannerScrim = widget.banners[index];

              final String bannerImageUrl =
                  widget.getPosterUrl(
                    bannerScrim['poster'] as String?,
                    bannerScrim['id_scrim'],
                  ) ??
                  '';

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
                          AppColors.black.withValues(alpha: 0.8),
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
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusXL,
                            ),
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
          children: List.generate(widget.banners.length, (index) {
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
          }),
        ),
      ],
    );
  }
}
