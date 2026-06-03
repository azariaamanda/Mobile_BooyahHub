import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'validate_payment_page.dart';

class DaftarKlaimAktifPage extends StatelessWidget {
  const DaftarKlaimAktifPage({super.key});

  // Mock data simulasi — ganti dengan data Supabase saat sudah siap
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Daftar Klaim Aktif',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.primary,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUrgentCard(context),
            const SizedBox(height: 12),
            _buildCompletedCard(context),
          ],
        ),
      ),
    );
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
            // Badge URGENT + tanggal
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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

            // Nama event + badge jumlah pending
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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

            // Tim & nominal
            Row(
              children: [
                const Icon(Icons.people, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$tim Tim',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
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

            // Tombol Detail Klaim
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
                      builder: (_) => const ValidatePaymentPage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Detail Klaim',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.black,
                      size: 16,
                    ),
                  ],
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
                  Text(
                    tanggal,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ValidatePaymentPage(),
                    ),
                  );
                },
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
}
