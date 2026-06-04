import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/transaksi_keuangan_model.dart';
import '../../data/models/services/keuangan_service.dart';
import '../../data/models/services/owner_service.dart';
import 'detail_klaim_page.dart';

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
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
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
                      'Rp ${_totalPendapatan.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}',
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
                          '+0% Bulan ini',
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

              // --- AKSI CEPAT ---
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
                    child: _buildKlaimPendingButton(context),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // --- SECTION: RIWAYAT TRANSAKSI ---
              Text(
                'Riwayat Transaksi',
                style: AppTextStyles.poppinsSectionTitle.copyWith(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),

              // LIST RIWAYAT TRANSAKSI
              if (_recentTransactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada transaksi',
                          style: AppTextStyles.interBody.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTransactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tx = _recentTransactions[index];
                    final bool isIncome = tx.isPemasukan || tx.isHadiah;
                    final Color color =
                        isIncome ? AppColors.success : AppColors.error;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Icon(
                              isIncome
                                  ? Icons.call_received
                                  : Icons.call_made,
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
                                  style:
                                      AppTextStyles.interBodyMedium.copyWith(
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
              const SizedBox(height: 28),

              // --- SECTION: DAFTAR KLAIM AKTIF ---
              Text(
                'Daftar Klaim Aktif',
                style: AppTextStyles.poppinsSectionTitle.copyWith(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),

              // Kartu URGENT
              _buildUrgentCard(context),
              const SizedBox(height: 12),

              // Kartu COMPLETED
              _buildCompletedCard(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static const _urgentKlaim = {
    'nama_event': 'Ultimate Pro League - S12',
    'tanggal': '24 Okt 2023',
    'jumlah_pending': 12,
    'jumlah_tim': 12,
    'nominal': 600000,
  };

  static const _completedKlaim = {
    'nama_event': 'Elite Weekly Cup',
    'tanggal': '23 Okt 2023',
    'nominal': 1200000,
  };

  String _formatRupiah(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    int counter = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      counter++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  Widget _buildUrgentCard(BuildContext context) {
    final int pending = _urgentKlaim['jumlah_pending'] as int;
    final int tim = _urgentKlaim['jumlah_tim'] as int;
    final int nominal = _urgentKlaim['nominal'] as int;
    final String namaEvent = _urgentKlaim['nama_event'] as String;
    final String tanggal = _urgentKlaim['tanggal'] as String;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B141C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=600',
          ),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  tanggal,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    namaEvent,
                    style: AppTextStyles.poppinsTitleSmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pending Pending',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text('$tim Tim', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Text(
                  _formatRupiah(nominal),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DetailKlaimPage(),
                    ),
                  );
                },
                child: const Text(
                  'Detail Klaim',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context) {
    final String namaEvent = _completedKlaim['nama_event'] as String;
    final String tanggal = _completedKlaim['tanggal'] as String;
    final int nominal = _completedKlaim['nominal'] as int;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0B141C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(tanggal, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(width: 6),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 6),
                  const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.history, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            namaEvent,
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatRupiah(nominal),
            style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 20),
          ),
          const Divider(color: Colors.white10, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selesai dalam 45 menit',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Lihat Riwayat',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
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
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
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

  Widget _buildKlaimPendingButton(BuildContext context) {
    // Hitung jumlah klaim pending dari _recentTransactions
    final int pendingCount = _recentTransactions
        .where((tx) => tx.status == 'pending')
        .length;
    // Gunakan mock 12 jika data kosong agar UI tetap terlihat
    final int displayCount = pendingCount > 0 ? pendingCount : 12;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DetailKlaimPage()),
      ),
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$displayCount',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Klaim Pending',
              style: AppTextStyles.interBody.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              'Segera Proses',
              style: AppTextStyles.interCaption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
