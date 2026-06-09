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
  List<Map<String, dynamic>> _pendingPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchPackages(), _fetchPendingPayments()]);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPendingPayments() async {
    try {
      // Join dengan akun untuk mendapat nama/email admin
      final data = await _supabase
          .from('transaksi_premium')
          .select('*, akun(email, profil_admin(nama_lengkap))')
          .eq('status', 'menunggu')
          .order('dibuat_pada', ascending: true);
      if (mounted) {
        setState(() {
          _pendingPayments = List<Map<String, dynamic>>.from(data as List);
        });
      }
    } catch (e) {
      debugPrint('Error fetching pending premium payments: $e');
    }
  }

  Future<void> _konfirmasiPembayaran(int txId) async {
    try {
      await _supabase
          .from('transaksi_premium')
          .update({'status': 'aktif'})
          .eq('id', txId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium admin berhasil diaktifkan'),
            backgroundColor: Color(0xFF00FF87),
          ),
        );
        _fetchPendingPayments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal konfirmasi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _tolakPembayaran(int txId) async {
    try {
      await _supabase
          .from('transaksi_premium')
          .update({'status': 'ditolak'})
          .eq('id', txId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran premium ditolak')),
        );
        _fetchPendingPayments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal tolak: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _lihatBukti(String filePath) async {
    try {
      final url = await _supabase.storage
          .from('bukti_bayar')
          .createSignedUrl(filePath, 3600);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: const Color(0xFF0D1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Gagal memuat gambar', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup', style: TextStyle(color: Color(0xFFFFD700))),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat bukti: $e')),
      );
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
                  if (_pendingPayments.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildPendingSectionTitle(),
                    const SizedBox(height: 16),
                    ..._pendingPayments.map((tx) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPendingCard(tx),
                        )),
                  ],
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

  Widget _buildPendingSectionTitle() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'PEMBAYARAN PREMIUM PENDING',
          style: AppTextStyles.interCaption.copyWith(
            color: const Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${_pendingPayments.length}',
            style: AppTextStyles.interCaption.copyWith(
              color: const Color(0xFFFFD700),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> tx) {
    final akun = tx['akun'] as Map<String, dynamic>?;
    final profil = (akun?['profil_admin'] is List
            ? (akun?['profil_admin'] as List).firstOrNull
            : akun?['profil_admin']) as Map<String, dynamic>?;
    final namaAdmin = profil?['nama_lengkap'] as String? ?? akun?['email'] as String? ?? '-';
    final namaPaket = tx['nama_paket'] as String? ?? '-';
    final harga = tx['harga'];
    final durasiHari = tx['durasi_hari'] as int? ?? 30;
    final buktiPath = tx['bukti_pembayaran'] as String?;
    final txId = tx['id'] as int;

    final hargaStr = harga != null
        ? 'Rp ${(harga as num).toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}'
        : '-';

    final tglStr = tx['dibuat_pada'] != null
        ? () {
            final dt = DateTime.tryParse(tx['dibuat_pada'].toString());
            if (dt == null) return '-';
            return '${dt.day}/${dt.month}/${dt.year}';
          }()
        : '-';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaAdmin,
                      style: AppTextStyles.poppinsTitleSmall.copyWith(fontSize: 14),
                    ),
                    Text(
                      '$namaPaket · $hargaStr · $durasiHari hari',
                      style: AppTextStyles.interCaption.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Text(
                tglStr,
                style: AppTextStyles.interCaption.copyWith(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (buktiPath != null && buktiPath.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _lihatBukti(buktiPath),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.image_outlined, size: 16, color: Colors.white54),
                    label: Text(
                      'Lihat Bukti',
                      style: AppTextStyles.interCaption.copyWith(color: Colors.white54),
                    ),
                  ),
                ),
              if (buktiPath != null && buktiPath.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _tolakPembayaran(txId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.15),
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                  ),
                  child: Text(
                    'Tolak',
                    style: AppTextStyles.interCaption.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _konfirmasiPembayaran(txId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF87).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF00FF87),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: const Color(0xFF00FF87).withValues(alpha: 0.4)),
                    ),
                  ),
                  child: Text(
                    'Konfirmasi',
                    style: AppTextStyles.interCaption.copyWith(
                      color: const Color(0xFF00FF87),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
