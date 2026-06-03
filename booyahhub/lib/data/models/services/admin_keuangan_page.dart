import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/transaksi_keuangan_model.dart';
import '../../data/models/saldo_pengguna_model.dart';
import '../../data/models/services/keuangan_service.dart';
import '../../data/models/services/owner_service.dart';
import 'daftar_klaim_aktif_page.dart'; // Import halaman daftar klaim

class AdminKeuanganPage extends StatefulWidget {
  const AdminKeuanganPage({super.key});

  @override
  State<AdminKeuanganPage> createState() => _AdminKeuanganPageState();
}

class _AdminKeuanganPageState extends State<AdminKeuanganPage> {
  final KeuanganService _keuanganService = KeuanganService();
  final OwnerService _ownerService = OwnerService(); // Instance of OwnerService
  bool _isLoading = true;
  double _totalPendapatan = 0; // Untuk menyimpan total pendapatan
  double _totalFeePlatform = 0;
  List<TransaksiKeuangan> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Mengambil total pendapatan dari OwnerService
      final revenueData = await _ownerService.getTotalRevenue();
      _totalPendapatan = (revenueData['total_pendapatan_platform'] ?? 0)
          .toDouble();
      _totalFeePlatform = (revenueData['total_fee_platform'] ?? 0).toDouble();

      // Mengambil semua transaksi untuk tampilan admin
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
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
                    'Total Pendapatan',
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
                    icon: Icons.pending_actions,
                    label: 'Klaim Pending',
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
                  'Daftar Klaim Aktif',
                  style: AppTextStyles.poppinsSectionTitle.copyWith(
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DaftarKlaimAktifPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Lihat Semua',
                    style: AppTextStyles.interLink.copyWith(
                      color: AppColors.primary,
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
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: tx.isPemasukan || tx.isHadiah
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        child: Icon(
                          tx.isPemasukan || tx.isHadiah
                              ? Icons.call_received
                              : Icons.call_made,
                          color: tx.isPemasukan || tx.isHadiah
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.deskripsi ??
                                  (tx.isPemasukan
                                      ? 'Pemasukan'
                                      : 'Pengeluaran'),
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
                          color: tx.isPemasukan || tx.isHadiah
                              ? AppColors.success
                              : AppColors.error,
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
    );
  }

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
}
