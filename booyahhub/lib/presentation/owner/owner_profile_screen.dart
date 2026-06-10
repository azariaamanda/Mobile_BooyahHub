import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/auth_service.dart';
import 'owner_notification_page.dart';

class OwnerProfileScreen extends StatefulWidget {
  final void Function(int index)? onNavigateTab;
  const OwnerProfileScreen({super.key, this.onNavigateTab});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _authService = AuthService();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  Map<String, dynamic>? _akunData;
  Map<String, dynamic>? _profilData;

  double _revenueHariIni = 0;
  double _revenueKemarin = 0;
  double _revenueAllTime = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([_loadProfile(), _fetchRevenue()]);
  }

  Future<void> _fetchRevenue() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));

      // 1. Fee settings
      final feeSettings = await _supabase
          .from('pengaturan_fee')
          .select('fee_platform_persen, nominal_minimum_platform')
          .maybeSingle();
      final int feePersen = (feeSettings?['fee_platform_persen'] as num? ?? 25)
          .toInt();

      // 2. All scrims biaya
      final scrims = await _supabase
          .from('scrim')
          .select('id_scrim, biaya_pendaftaran');
      final Map<int, double> scrimBiayaMap = {
        for (final s in scrims as List)
          (s['id_scrim'] as int): (s['biaya_pendaftaran'] as num? ?? 0)
              .toDouble(),
      };

      // 3. All sesi_scrim → scrim mapping
      final sesis = await _supabase
          .from('sesi_scrim')
          .select('id_sesi, id_scrim');
      final Map<int, int> sesiToScrim = {
        for (final s in sesis as List)
          (s['id_sesi'] as int): (s['id_scrim'] as int),
      };

      // 4. All confirmed registrations
      final regs = await _supabase
          .from('pendaftaran_tim')
          .select('id_sesi, diverifikasi_pada')
          .eq('status_pembayaran', 'dikonfirmasi');

      // 5. Group confirmed count + dates per scrim
      final Map<int, int> countPerScrim = {};
      final Map<int, List<DateTime>> datesByScrim = {};
      for (final r in regs as List) {
        final sesiId = r['id_sesi'] as int?;
        if (sesiId == null) continue;
        final scrimId = sesiToScrim[sesiId];
        if (scrimId == null) continue;
        countPerScrim[scrimId] = (countPerScrim[scrimId] ?? 0) + 1;
        final rawDate = r['diverifikasi_pada']?.toString();
        if (rawDate != null) {
          final tgl = DateTime.tryParse(rawDate)?.toLocal();
          if (tgl != null) datesByScrim.putIfAbsent(scrimId, () => []).add(tgl);
        }
      }

      // 6. Hitung fee per scrim dan distribusikan ke hariIni/kemarin/allTime
      double hariIni = 0, kemarin = 0, allTime = 0;
      for (final entry in countPerScrim.entries) {
        final biaya = scrimBiayaMap[entry.key] ?? 0;
        final rawFee = biaya * entry.value * feePersen / 100;
        final feePerReg = rawFee / entry.value;

        for (final tgl in datesByScrim[entry.key] ?? <DateTime>[]) {
          allTime += feePerReg;
          final tglDay = DateTime(tgl.year, tgl.month, tgl.day);
          if (!tglDay.isBefore(todayStart)) hariIni += feePerReg;
          if (tglDay == yesterdayStart) kemarin += feePerReg;
        }
      }

      // 7. Premium package revenue (full harga when status = aktif)
      final premiumRows = await _supabase
          .from('transaksi_premium')
          .select('harga, tanggal_mulai')
          .eq('status', 'aktif');
      for (final tx in premiumRows as List) {
        final harga = (tx['harga'] as num? ?? 0).toDouble();
        final rawDate = tx['tanggal_mulai']?.toString();
        if (rawDate != null) {
          final tgl = DateTime.tryParse(rawDate)?.toLocal();
          if (tgl != null) {
            allTime += harga;
            final tglDay = DateTime(tgl.year, tgl.month, tgl.day);
            if (!tglDay.isBefore(todayStart)) hariIni += harga;
            if (tglDay == yesterdayStart) kemarin += harga;
          }
        }
      }

      if (mounted) {
        setState(() {
          _revenueHariIni = hariIni;
          _revenueKemarin = kemarin;
          _revenueAllTime = allTime;
        });
      }
    } catch (e) {
      debugPrint('Error fetch revenue profile: $e');
    }
  }

  String _formatRupiah(double value) {
    if (value >= 1000000000)
      return 'Rp ${(value / 1000000000).toStringAsFixed(1)}M';
    if (value >= 1000000)
      return 'Rp ${(value / 1000000).toStringAsFixed(1)} Jt';
    if (value >= 1000) return 'Rp ${(value / 1000).toStringAsFixed(0)} Rb';
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  String get _badgeHariIni {
    if (_revenueKemarin == 0) return 'Hari ini';
    final pct = (_revenueHariIni - _revenueKemarin) / _revenueKemarin * 100;
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}% vs kemarin';
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _authService.getCurrentAkunAndProfil();
    if (data != null && mounted) {
      setState(() {
        _akunData = data['akun'].toJson();
        _profilData = data['profil'] as Map<String, dynamic>?;

        if (_profilData != null &&
            _profilData!['foto_profil'] != null &&
            _profilData!['foto_profil'].toString().isNotEmpty) {
          final url = _profilData!['foto_profil'].toString();
          final separator = url.contains('?') ? '&' : '?';
          _profilData!['foto_profil'] =
              '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
        }

        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 32),
                    _buildProfileInfo(),
                    const SizedBox(height: 32),
                    _buildStatCard(
                      icon: Icons.account_balance_wallet_rounded,
                      iconBgColor: const Color(0xFF3B331A),
                      iconColor: const Color(0xFFFFD700),
                      badgeText: _badgeHariIni,
                      badgeBgColor: const Color(0xFF3B331A),
                      badgeTextColor: const Color(0xFFFFD700),
                      title: 'Pendapatan Hari Ini',
                      value: _formatRupiah(_revenueHariIni),
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      icon: Icons.account_balance_rounded,
                      iconBgColor: Colors.white10,
                      iconColor: Colors.white70,
                      badgeText: 'All-Time',
                      badgeBgColor: Colors.white10,
                      badgeTextColor: Colors.white70,
                      title: 'Total Pendapatan',
                      value: _formatRupiah(_revenueAllTime),
                    ),
                    const SizedBox(height: 32),
                    _buildMenuSection(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'BOOYAHHUB',
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: const Color(0xFFFFD700),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 24), // Balance the back button
      ],
    );
  }

  Widget _buildProfileInfo() {
    final name = _profilData?['nama_lengkap'] ?? 'Unknown';
    final email = _akunData?['email'] ?? 'Unknown Email';
    final fotoUrl = _profilData?['foto_profil'] as String?;

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF131F2D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700), width: 3),
            image: fotoUrl != null
                ? DecorationImage(
                    image: NetworkImage(fotoUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: fotoUrl == null
              ? Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'O',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppTextStyles.interCaption.copyWith(
            color: const Color(0xFFFFD700).withValues(alpha: 0.8),
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.interCaption.copyWith(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.interCaption.copyWith(
              color: const Color(0xFFFFD700),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.poppinsHeadline.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.person_rounded,
          title: 'Edit Profil & Password',
          onTap: () async {
            await context.push('/owner/edit-profile');
            _loadProfile();
          },
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Kelola Fee',
          onTap: () => context.push('/owner/manage-fee'),
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.stars_rounded,
          title: 'Layanan Premium',
          onTap: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(2);
            } else {
              context.push('/owner/premium-management');
            }
          },
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.notifications_rounded,
          title: 'Notifikasi Owner',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OwnerNotificationPage()),
          ),
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.logout_rounded,
          title: 'Logout',
          isDestructive: true,
          onTap: () {
            _authService.logout();
            context.go('/login');
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final Color itemColor = isDestructive ? Colors.redAccent : Colors.white;
    final Color iconBgColor = isDestructive
        ? Colors.redAccent.withValues(alpha: 0.1)
        : Colors.white10;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.redAccent : Colors.white70,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.interBody.copyWith(
            color: itemColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDestructive
              ? Colors.redAccent.withValues(alpha: 0.5)
              : Colors.white54,
          size: 20,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }
}
