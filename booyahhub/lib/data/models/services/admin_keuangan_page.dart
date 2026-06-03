import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/transaksi_keuangan_model.dart';
import '../../data/models/services/keuangan_service.dart';
import '../../data/models/services/owner_service.dart';
import 'daftar_klaim_aktif_page.dart';

class AdminKeuanganPage extends StatefulWidget {
  const AdminKeuanganPage({super.key});

  @override
  State<AdminKeuanganPage> createState() => _AdminKeuanganPageState();
}

class _AdminKeuanganPageState extends State<AdminKeuanganPage> {
  final KeuanganService _keuanganService = KeuanganService();
  final OwnerService _ownerService = OwnerService();
  bool _isLoading = true;
  double _totalPendapatan = 0;
  List<TransaksiKeuangan> _recentTransactions = [];
  int _currentIndex = 3; // Index aktif bottom navigation bar

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final revenueData = await _ownerService.getTotalRevenue();
      _totalPendapatan = (revenueData['total_pendapatan_platform'] ?? 0)
          .toDouble();

      final transactions = await _keuanganService.fetchAllTransaksi(limit: 5);

      setState(() {
        _recentTransactions = transactions;
      });
    } catch (e) {
      debugPrint('Error fetching financial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    String displayPendapatan =
        'Rp ${(_totalPendapatan / 1000000).toStringAsFixed(1)}M';
    if (_totalPendapatan < 1000000) {
      displayPendapatan = 'Rp ${_totalPendapatan.toInt()}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Keuangan',
          style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CARD UTAMA: TOTAL SALDO ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                border: Border.all(color: AppColors.divider.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Saldo Keuangan',
                    style: AppTextStyles.interLabel.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${_totalPendapatan.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
                    style: AppTextStyles.poppinsMoneyLarge.copyWith(
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+0% Bulan ini', // Placeholder, bisa dihitung jika ada data perbandingan
                        style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- AKSI CEPAT / TOMBOL NAVIGASI ---
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.money_off,
                    label: 'Dana Keluar',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.outbox,
                    label: 'Tarik Tunai',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DaftarKlaimAktifPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // --- SECTION: RIWAYAT TRANSAKSI ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Transaksi',
                  style: AppTextStyles.poppinsSectionTitle.copyWith(
                    fontSize: 18,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DaftarKlaimAktifPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Semua',
                          style: AppTextStyles.interLabel.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.primary,
                          size: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // LIST RIWAYAT TRANSAKSI
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = _recentTransactions[index];
                bool isIncome = tx.isPemasukan || tx.isHadiah;
                Color color = isIncome ? AppColors.success : AppColors.error;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(
                          isIncome ? Icons.call_received : Icons.call_made,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.deskripsi,
                              style: AppTextStyles.interBodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx.formattedDate,
                              style: AppTextStyles.interCaption,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        tx.displayNominal,
                        style: AppTextStyles.poppinsMoneySmall.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      // --- BOTTOM NAVIGATION BAR (WARNA EMAS SESUAI GAMBAR) ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary, // Warna dasar emas/kuning tua
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(Icons.dashboard, 0),
                _buildBottomNavItem(Icons.add_circle_outline, 1),
                _buildBottomNavItem(Icons.people_outline, 2),
                _buildBottomNavActiveItem(
                  Icons.account_balance_wallet,
                  'Keuan...',
                ),
                _buildBottomNavItem(Icons.settings_outlined, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk Tombol Aksi (Isi Saldo / Tarik Tunai)
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.divider.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.interBody),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Item Navigasi yang Tidak Aktif
  Widget _buildBottomNavItem(IconData icon, int index) {
    return IconButton(
      icon: Icon(icon, color: Colors.black87),
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  // Widget Helper untuk Item Navigasi yang Sedang Aktif (Berbentuk Kapsul Hitam)
  Widget _buildBottomNavActiveItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background, // Kapsul Hitam
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20), // Icon Emas
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.interBodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
