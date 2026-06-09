import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchOwnerProfile();
    _fetchTotalAdmin();
    _fetchActiveSessions();
    _fetchPendingBills();
    _fetchTotalRevenue();

    // Tampilkan popup notifikasi belum terbaca
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
              'pesan': 'Akun admin $adminName telah otomatis di-suspend karena utangnya (Rp$totalUtang) melebihi batas limit (Rp$limitUtang).'
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
            MaterialPageRoute(builder: (context) => const OwnerNotificationPage()),
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

  Future<void> _fetchTotalRevenue() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('pelunasan_utang_admin')
          .select() // Ambil semua kolom untuk jaga-jaga
          .eq('status', 'diverifikasi');

      double total = 0;
      final now = DateTime.now();
      List<double> tempMonthly = List.filled(6, 0.0);

      for (var row in response as List) {
        double nominal = (row['nominal'] ?? 0).toDouble();
        total += nominal;
        
        // Coba cari tanggal mana saja yang tersedia
        final dateStr = row['diverifikasi_pada'] ?? row['created_at'] ?? row['dibuat_pada'] ?? row['tanggal'];
        if (dateStr != null) {
          final date = DateTime.parse(dateStr.toString());
          // Hitung selisih bulan
          int monthDiff = (now.year - date.year) * 12 + now.month - date.month;
          if (monthDiff >= 0 && monthDiff < 6) {
             // Index 5 adalah bulan ini, 0 adalah 5 bulan lalu
             tempMonthly[5 - monthDiff] += nominal;
          }
        } else {
          // Jika tidak ada data tanggal sama sekali, masukkan ke bulan ini
          tempMonthly[5] += nominal;
        }
      }

      // Generate nama bulan (Jan, Feb, ...)
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      List<String> tempLabels = [];
      for (int i = 5; i >= 0; i--) {
        int m = now.month - i - 1;
        if (m < 0) m += 12;
        tempLabels.add(monthNames[m]);
      }

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
      if (mounted) {
        setState(() {
          _isLoadingRevenue = false;
        });
      }
    }
  }

  Future<void> _fetchOwnerProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser?.email == null) return;

      final response = await supabase
          .from('profil_owner')
          .select('nama_lengkap, foto_profil, akun!inner(email)')
          .eq('akun.email', currentUser!.email!)
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
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700), // Yellow
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang,\n$_ownerName',
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
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OwnerNotificationPage()),
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
                value: _isLoadingRevenue ? '...' : _formatCompactCurrency(_totalRevenue),
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
                value: _isLoadingPendingBills ? '...' : '$_totalPendingBills Pengajuan',
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
                value: _isLoadingActiveSessions ? '...' : '$_totalActiveSessions Scrim',
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
          child: _isLoadingRevenue 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
              : Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(6, (index) {
                    double maxVal = _monthlyRevenue.reduce((curr, next) => curr > next ? curr : next);
                    if (maxVal == 0) maxVal = 1; // Hindari division by zero
                    double heightRatio = _monthlyRevenue[index] / maxVal;
                    
                    return Tooltip(
                      message: _formatCompactCurrency(_monthlyRevenue[index]),
                      child: Container(
                        width: 24,
                        height: 90 * heightRatio + 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            if (heightRatio > 0)
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, -2),
                              )
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
                   return _buildChartLabel(_monthLabels.isNotEmpty ? _monthLabels[index] : '');
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
