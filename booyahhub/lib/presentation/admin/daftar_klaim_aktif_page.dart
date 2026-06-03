import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class DaftarKlaimAktifPage extends StatefulWidget {
  const DaftarKlaimAktifPage({super.key});

  @override
  State<DaftarKlaimAktifPage> createState() => _DaftarKlaimAktifPageState();
}

class _DaftarKlaimAktifPageState extends State<DaftarKlaimAktifPage> {
  final List<Map<String, dynamic>> _daftarKlaim = [
    {
      'nama_user': 'Top Up Saldo User',
      'keterangan': 'Ahmad Fauzi • Jaminan Lapangan',
      'tanggal': '03 Juni 2026 • 14:30 WIB',
      'nominal': 250000,
      'is_income': true,
    },
    {
      'nama_user': 'Penarikan Dana',
      'keterangan': 'Rian Hidayat • Refund Pembatalan',
      'tanggal': '03 Juni 2026 • 12:15 WIB',
      'nominal': 100000,
      'is_income': false,
    },
    {
      'nama_user': 'Top Up Saldo User',
      'keterangan': 'Siti Aminah • Kendala Transfer',
      'tanggal': '02 Juni 2026 • 09:45 WIB',
      'nominal': 150000,
      'is_income': true,
    },
    {
      'nama_user': 'Penarikan Dana',
      'keterangan': 'Budi Santoso • Cashback Event',
      'tanggal': '01 Juni 2026 • 18:20 WIB',
      'nominal': 50000,
      'is_income': false,
    },
  ];
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
      body: _daftarKlaim.isEmpty
          ? _buildStateKosong()
          : ListView.separated(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemCount: _daftarKlaim.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _daftarKlaim[index];
                return _buildItemKlaim(item);
              },
            ),
    );
  }

  Widget _buildItemKlaim(Map<String, dynamic> item) {
    bool isIncome = item['is_income'] ?? true;
    Color color = isIncome ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider.withOpacity(0.1)),
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
                  item['nama_user'] ?? '',
                  style: AppTextStyles.interBodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['keterangan'] ?? '',
                  style: AppTextStyles.interBody.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  item['tanggal'] ?? '',
                  style: AppTextStyles.interCaption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            isIncome ? '+Rp ${item['nominal']}' : '-Rp ${item['nominal']}',
            style: AppTextStyles.poppinsMoneySmall.copyWith(
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateKosong() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Klaim Aktif',
              style: AppTextStyles.poppinsTitleSmall.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Semua berkas klaim baru yang diajukan oleh pengguna akan terdaftar di halaman ini.',
              textAlign: TextAlign.center,
              style: AppTextStyles.interBody,
            ),
          ],
        ),
      ),
    );
  }
}
