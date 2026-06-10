import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_refresh.dart';
import '../../config/app_session.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import 'owner_notification_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../user/user_widgets/claim_prize_notification.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _totalAdmin = 0;
  bool _isLoadingAdmin = true;

  int _totalActiveSessions = 0;
  bool _isLoadingActiveSessions = true;

  int _totalPendingBills = 0;
  bool _isLoadingPendingBills = true;

  String _ownerName = 'Memuat...';
  String? _ownerPhotoUrl;
  bool _isLoadingProfile = true;

  double _totalRevenue = 0.0;
  List<double> _monthlyRevenue = List.filled(6, 0.0);
  List<String> _monthLabels = [];
  bool _isLoadingRevenue = true;

  // Action list data
  int _pendingTagihan = 0;
  int _adminMelampauiLimit = 0;
  int _premiumMenunggu = 0;
  bool _isLoadingActions = true;

  @override
  void initState() {
    super.initState();
    AppRefresh.instance.addListener(_onRefresh);
    _fetchOwnerProfile();
    _fetchTotalAdmin();
    _fetchActiveSessions();
    _fetchPendingBills();
    _fetchTotalRevenue();
    _fetchActionData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showUnreadNotifications();
    });
  }

  void _onRefresh() {
    if (!mounted) return;
    _fetchOwnerProfile();
    _fetchTotalAdmin();
    _fetchActiveSessions();
    _fetchPendingBills();
    _fetchTotalRevenue();
    _fetchActionData();
  }

  @override
  void dispose() {
    AppRefresh.instance.removeListener(_onRefresh);
    super.dispose();
  }

  Future<void> _showUnreadNotifications() async {
    try {
      final userId = Supabase.instance.client.sessionUserId;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final prefKey = 'read_notifications_$userId';
      final readIds = prefs.getStringList(prefKey) ?? [];

      final response = await Supabase.instance.client
          .from('profil_admin')
          .select('akun_id, nama_lengkap, total_utang, limit_utang');

      final List<Map<String, dynamic>> unread = [];
      for (var item in response) {
        final totalUtang = item['total_utang'] ?? 0;
        final limitUtang = item['limit_utang'] ?? 0;

        if (totalUtang >= limitUtang && limitUtang > 0) {
          final notifId = 'suspend_${item['akun_id']}';
          if (!readIds.contains(notifId)) {
            final adminName = item['nama_lengkap'] ?? 'Admin';
            unread.add({
              'id': notifId,
              'judul': 'Admin Terkena Suspend',
              'pesan':
                  'Akun admin $adminName telah otomatis di-suspend karena utangnya (Rp$totalUtang) melebihi batas limit (Rp$limitUtang).',
            });
          }
        }
      }

      if (!mounted || unread.isEmpty) return;

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      final String popupTitle = unread.length == 1
          ? (unread[0]['judul'] ?? 'Notifikasi Baru')
          : '${unread.length} Notifikasi Baru';

      final String popupMessage = unread.length == 1
          ? (unread[0]['pesan'] ?? '')
          : 'Ada ${unread.length} admin yang terkena suspend dan belum Anda cek';

      NotificationPopup.show(
        context,
        title: popupTitle,
        message: popupMessage,
        icon: Icons.notifications_rounded,
        iconColor: AppColors.error,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OwnerNotificationPage(),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error fetching unread notifications for popup: $e');
    }
  }

  String _formatCompactCurrency(double value) {
    if (value == 0) return 'Rp 0';
    return 'Rp ${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> _fetchActionData() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Tagihan menunggu verifikasi (pelunasan_utang_admin status pending)
      final tagihanRes = await supabase
          .from('pelunasan_utang_admin')
          .select('id_pelunasan')
          .eq('status', 'pending');

      // 2. Admin yang melewati limit utang
      final adminRes = await supabase
          .from('profil_admin')
          .select('akun_id, total_utang, limit_utang');
      final int melampauiLimit = (adminRes as List).where((a) {
        final total = (a['total_utang'] as num? ?? 0);
        final limit = (a['limit_utang'] as num? ?? 0);
        return limit > 0 && total >= limit;
      }).length;

      // 3. Paket premium menunggu aktivasi
      final premiumRes = await supabase
          .from('transaksi_premium')
          .select('id_transaksi')
          .eq('status', 'menunggu');

      if (mounted) {
        setState(() {
          _pendingTagihan = (tagihanRes as List).length;
          _adminMelampauiLimit = melampauiLimit;
          _premiumMenunggu = (premiumRes as List).length;
          _isLoadingActions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch action data: $e');
      if (mounted) setState(() => _isLoadingActions = false);
    }
  }

  Future<void> _fetchTotalRevenue() async {
    try {
      final supabase = Supabase.instance.client;

      // Ambil fee_platform_persen
      final feeSettings = await supabase
          .from('pengaturan_fee')
          .select('fee_platform_persen')
          .maybeSingle();
      final int feePersen = (feeSettings?['fee_platform_persen'] as num? ?? 25)
          .toInt();

      // Ambil semua scrim + biaya_pendaftaran
      final scrims = await supabase
          .from('scrim')
          .select('id_scrim, biaya_pendaftaran');
      final scrimBiayaMap = <int, double>{
        for (var s in scrims as List)
          s['id_scrim'] as int: (s['biaya_pendaftaran'] as num? ?? 0)
              .toDouble(),
      };

      // Ambil semua sesi_scrim
      final sesis = await supabase
          .from('sesi_scrim')
          .select('id_sesi, id_scrim');
      final sesiToScrim = <int, int>{
        for (var s in sesis as List) s['id_sesi'] as int: s['id_scrim'] as int,
      };
      final sesiIds = sesiToScrim.keys.toList();

      if (sesiIds.isEmpty) {
        if (mounted) setState(() => _isLoadingRevenue = false);
        return;
      }

      // Ambil semua pendaftaran dikonfirmasi
      final regs = await supabase
          .from('pendaftaran_tim')
          .select('id_sesi, diverifikasi_pada')
          .inFilter('id_sesi', sesiIds)
          .eq('status_pembayaran', 'dikonfirmasi');

      // Hitung fee platform per scrim
      final Map<int, int> countPerScrim = {};
      final Map<int, List<DateTime>> datesByScrim = {};

      for (final r in regs as List) {
        final sesiId = r['id_sesi'] as int?;
        if (sesiId == null) continue;
        final scrimId = sesiToScrim[sesiId] ?? 0;
        if (scrimId == 0) continue;
        countPerScrim[scrimId] = (countPerScrim[scrimId] ?? 0) + 1;
        final tglStr = r['diverifikasi_pada'] as String?;
        if (tglStr != null) {
          try {
            datesByScrim
                .putIfAbsent(scrimId, () => [])
                .add(DateTime.parse(tglStr).toLocal());
          } catch (_) {}
        }
      }

      final now = DateTime.now();
      double total = 0;
      List<double> tempMonthly = List.filled(6, 0.0);

      for (final entry in countPerScrim.entries) {
        final biaya = scrimBiayaMap[entry.key] ?? 0;
        final rawFee = biaya * entry.value * feePersen / 100;
        total += rawFee;

        // Distribusikan fee ke bulan sesuai tanggal konfirmasi
        final feePerReg = rawFee / entry.value;
        for (final tgl in datesByScrim[entry.key] ?? <DateTime>[]) {
          final int monthDiff =
              (now.year - tgl.year) * 12 + now.month - tgl.month;
          if (monthDiff >= 0 && monthDiff < 6) {
            tempMonthly[5 - monthDiff] += feePerReg;
          }
        }
      }

      // Premium package revenue (full harga when status = aktif)
      final premiumRows = await supabase
          .from('transaksi_premium')
          .select('harga, tanggal_mulai')
          .eq('status', 'aktif');
      for (final tx in premiumRows as List) {
        final harga = (tx['harga'] as num? ?? 0).toDouble();
        total += harga;
        final rawDate = tx['tanggal_mulai']?.toString();
        if (rawDate != null) {
          final tgl = DateTime.tryParse(rawDate)?.toLocal();
          if (tgl != null) {
            final int monthDiff = (now.year - tgl.year) * 12 + now.month - tgl.month;
            if (monthDiff >= 0 && monthDiff < 6) {
              tempMonthly[5 - monthDiff] += harga;
            }
          }
        }
      }

      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final tempLabels = List.generate(6, (i) {
        int m = now.month - (5 - i) - 1;
        if (m < 0) m += 12;
        return monthNames[m];
      });

      if (mounted) {
        setState(() {
          _totalRevenue = total;
          _monthlyRevenue = tempMonthly;
          _monthLabels = tempLabels;
          _isLoadingRevenue = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch revenue: $e');
      if (mounted) setState(() => _isLoadingRevenue = false);
    }
  }

  Future<void> _fetchOwnerProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final email = supabase.sessionEmail;
      if (email == null) return;

      final response = await supabase
          .from('profil_owner')
          .select('nama_lengkap, foto_profil, akun!inner(email)')
          .eq('akun.email', email)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _ownerName = response['nama_lengkap'] ?? 'Owner';
          _ownerPhotoUrl = response['foto_profil'];
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch owner profile: $e');
      if (mounted) {
        setState(() {
          _ownerName = 'Owner';
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _fetchPendingBills() async {
    try {
      final supabase = Supabase.instance.client;
      // Mengambil pelunasan utang admin yang sedang menunggu (pending)
      final response = await supabase
          .from('pelunasan_utang_admin')
          .select('id_pelunasan')
          .eq('status', 'pending');

      if (mounted) {
        setState(() {
          _totalPendingBills = (response as List).length;
          _isLoadingPendingBills = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch pending bills: $e');
      if (mounted) {
        setState(() {
          _isLoadingPendingBills = false;
        });
      }
    }
  }

  Future<void> _fetchActiveSessions() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('scrim')
          .select('id_scrim')
          .eq('status_scrim', 'aktif');

      if (mounted) {
        setState(() {
          _totalActiveSessions = (response as List).length;
          _isLoadingActiveSessions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch active sessions: $e');
      if (mounted) {
        setState(() {
          _isLoadingActiveSessions = false;
        });
      }
    }
  }

  Future<void> _fetchTotalAdmin() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profil_admin')
          .select('id_profil_admin')
          .eq('status_verifikasi_ktp', 'terverifikasi');

      if (mounted) {
        setState(() {
          _totalAdmin = (response as List).length;
          _isLoadingAdmin = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch total admin: $e');
      if (mounted) {
        setState(() {
          _isLoadingAdmin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => AppRefresh.instance.refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            shape: BoxShape.circle,
            image: _ownerPhotoUrl != null && _ownerPhotoUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(_ownerPhotoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _ownerPhotoUrl == null || _ownerPhotoUrl!.isEmpty
              ? Center(
                  child: Text(
                    _ownerName.isNotEmpty ? _ownerName[0].toUpperCase() : 'O',
                    style: AppTextStyles.poppinsHeadline.copyWith(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang,',
                style: AppTextStyles.interBody.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                _ownerName,
                style: AppTextStyles.poppinsTitleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OwnerNotificationPage(),
              ),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
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
                value: _isLoadingRevenue
                    ? '...'
                    : _formatCompactCurrency(_totalRevenue),
                subtitle: 'Total klaim dilunasi',
                subtitleColor: Colors.blueGrey,
                iconColor: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'PELUNASAN\nMENUNGGU',
                icon: Icons.receipt_long_rounded,
                value: _isLoadingPendingBills
                    ? '...'
                    : '$_totalPendingBills Pengajuan',
                subtitle: 'menunggu verifikasi',
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
                title: 'SCRIM AKTIF',
                icon: Icons.videogame_asset_rounded,
                value: _isLoadingActiveSessions
                    ? '...'
                    : '$_totalActiveSessions Scrim',
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
                value: _isLoadingAdmin ? '...' : '$_totalAdmin Admin',
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
                  decoration: const BoxDecoration(
                    color: Colors.blueGrey,
                    shape: BoxShape.circle,
                  ),
                )
              else if (subtitleColor == const Color(0xFF00FF87))
                const Padding(
                  padding: EdgeInsets.only(right: 2.0),
                  child: Icon(
                    Icons.arrow_drop_up,
                    color: Color(0xFF00FF87),
                    size: 16,
                  ),
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
          child: _isLoadingRevenue
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(6, (index) {
                          double maxVal = _monthlyRevenue.reduce(
                            (curr, next) => curr > next ? curr : next,
                          );
                          if (maxVal == 0)
                            maxVal = 1; // Hindari division by zero
                          double heightRatio = _monthlyRevenue[index] / maxVal;

                          return Tooltip(
                            message: _formatCompactCurrency(
                              _monthlyRevenue[index],
                            ),
                            child: Container(
                              width: 24,
                              height: 90 * heightRatio + 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  if (heightRatio > 0)
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFFD700,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, -2),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
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
                      children: List.generate(6, (index) {
                        return _buildChartLabel(
                          _monthLabels.isNotEmpty ? _monthLabels[index] : '',
                        );
                      }),
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
      style: AppTextStyles.interCaption.copyWith(
        color: Colors.white70,
        fontSize: 11,
      ),
    );
  }

  Widget _buildActionList() {
    final bool adaTindakan =
        _pendingTagihan > 0 || _adminMelampauiLimit > 0 || _premiumMenunggu > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row dengan badge count
        Row(
          children: [
            Text(
              'Perlu Tindakan Owner',
              style: AppTextStyles.poppinsTitleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            if (!_isLoadingActions)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: adaTindakan
                      ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: adaTindakan
                        ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                        : Colors.white24,
                    width: 1,
                  ),
                ),
                child: Text(
                  adaTindakan
                      ? '${_pendingTagihan + _adminMelampauiLimit + _premiumMenunggu} item'
                      : 'Semua beres',
                  style: AppTextStyles.interCaption.copyWith(
                    color: adaTindakan
                        ? const Color(0xFFFFD700)
                        : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Loading state
        if (_isLoadingActions)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF131F2D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
                strokeWidth: 2,
              ),
            ),
          )
        // Empty state
        else if (!adaTindakan)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF131F2D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF87).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00FF87).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF00FF87),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Semua Sudah Ditangani',
                  style: AppTextStyles.poppinsTitleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tidak ada tindakan yang perlu\ndilakukan saat ini.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.interCaption.copyWith(
                    color: Colors.white38,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          )
        // Action cards
        else
          Column(
            children: [
              if (_pendingTagihan > 0) ...[
                _buildActionCard(
                  title: 'Tagihan Menunggu Verifikasi',
                  badgeText: '$_pendingTagihan Menunggu',
                  description: 'Admin sudah upload bukti',
                  borderColor: const Color(0xFFFFD700),
                  badgeColor: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  badgeTextColor: const Color(0xFFFFD700),
                  buttonText: 'VERIFIKASI',
                  buttonColor: const Color(0xFFFFD700),
                  buttonTextColor: Colors.black,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/owner/payment-verification',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_adminMelampauiLimit > 0) ...[
                _buildActionCard(
                  title: 'Admin Melewati Limit Utang',
                  badgeText: '$_adminMelampauiLimit Admin',
                  description: 'Admin melewati limit',
                  borderColor: Colors.redAccent,
                  badgeColor: Colors.redAccent.withValues(alpha: 0.15),
                  badgeTextColor: Colors.redAccent,
                  buttonText: 'LIHAT',
                  buttonColor: Colors.white12,
                  buttonTextColor: Colors.white70,
                  onTap: () =>
                      Navigator.pushNamed(context, '/owner/admin-verification'),
                ),
                const SizedBox(height: 16),
              ],
              if (_premiumMenunggu > 0)
                _buildActionCard(
                  title: 'Paket Premium Menunggu Aktivasi',
                  badgeText: '$_premiumMenunggu Menunggu',
                  description: 'perlu dicek',
                  borderColor: const Color(0xFF00FF87),
                  badgeColor: const Color(0xFF00FF87).withValues(alpha: 0.15),
                  badgeTextColor: const Color(0xFF00FF87),
                  buttonText: 'LIHAT',
                  buttonColor: Colors.white12,
                  buttonTextColor: Colors.white70,
                  onTap: () =>
                      Navigator.pushNamed(context, '/owner/premium-management'),
                ),
            ],
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
    VoidCallback? onTap,
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
            border: Border(left: BorderSide(color: borderColor, width: 4)),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                onPressed: onTap,
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
