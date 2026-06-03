import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/app_color.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';
import '../transaksi_keuangan_model.dart';
import '../saldo_pengguna_model.dart';
import 'keuangan_service.dart';

class AdminKeuanganPage extends StatefulWidget {
  const AdminKeuanganPage({super.key});

  @override
  State<AdminKeuanganPage> createState() => _AdminKeuanganPageState();
}

class _AdminKeuanganPageState extends State<AdminKeuanganPage> {
  final KeuanganService _keuanganService = KeuanganService();
  bool _isLoading = true;
  SaldoPengguna? _saldo;
  int _currentIndex = 3;
  List<TransaksiKeuangan> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        // Mengambil id_akun numerik berdasarkan email auth
        final akunData = await Supabase.instance.client
            .from('akun')
            .select('id_akun')
            .eq('email', currentUser.email!)
            .single();

        final int idAkun = akunData['id_akun'];
        final saldoData = await _keuanganService.fetchSaldoPengguna(idAkun);
        final transactions = await _keuanganService.fetchTransaksiPengguna(
          idAkun,
          limit: 5,
        );

        setState(() {
          _saldo = saldoData;
          _recentTransactions = transactions;
        });
      }
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
                    'Total Saldo Keuangan',
                    style: AppTextStyles.interLabel.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _saldo?.displaySaldoTotal ?? 'Rp 0',
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

            // --- AKSI CEPAT / TOMBOL NAVIGASI ---
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add_card,
                    label: 'Isi Saldo',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.outbox,
                    label: 'Tarik Tunai',
                    onTap: () {},
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
                TextButton(
                  onPressed: () {},
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

  Widget _buildBottomNavItem(IconData icon, int index) => IconButton(
    icon: Icon(icon, color: Colors.black87),
    onPressed: () => setState(() => _currentIndex = index),
  );
  Widget _buildBottomNavActiveItem(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
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
