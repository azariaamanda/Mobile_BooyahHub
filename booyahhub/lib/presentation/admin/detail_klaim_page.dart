import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'klaim_hadiah_detail_page.dart';

class DetailKlaimPage extends StatefulWidget {
  const DetailKlaimPage({super.key});

  @override
  State<DetailKlaimPage> createState() => _DetailKlaimPageState();
}

class _DetailKlaimPageState extends State<DetailKlaimPage> {
  String _selectedSesi = 'Sesi 1: 08:00 - 09:00';
  final List<String> _sesiOptions = [
    'Sesi 1: 08:00 - 09:00',
    'Sesi 2: 10:00 - 11:00',
    'Sesi 3: 13:00 - 14:00',
  ];

  // 'belum' | 'verified' | 'ditolak'
  late List<String> _statusPemenang;

  static const List<Map<String, dynamic>> _pemenang = [
    {
      'rank': 1,
      'nama_tim': 'Evos Glory',
      'hadiah': 255000,
      'kode': 'ECK',
      'id_game': '4821 4941 32',
      'nama_akun': 'MUHAMAD NOVAN',
      'klaim_submitted': true,
    },
    {
      'rank': 2,
      'nama_tim': 'RRQ Hoshi',
      'hadiah': 153000,
      'kode': 'NAK',
      'id_game': '4812 8983 123',
      'nama_akun': 'PRESTASI',
      'klaim_submitted': true,
    },
    {
      'rank': 3,
      'nama_tim': 'Bigetron Alpha',
      'hadiah': 102000,
      'kode': '31',
      'id_game': '4423 4431',
      'nama_akun': 'REKY PACO',
      'klaim_submitted': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    // RRQ Hoshi sudah terverifikasi, dua lainnya belum
    _statusPemenang = ['belum', 'verified', 'belum'];
  }

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

  void _setujui(int index) {
    setState(() => _statusPemenang[index] = 'verified');
  }

  void _tolak(int index) {
    setState(() => _statusPemenang[index] = 'ditolak');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Klaim Hadiah',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBiaya(),
                  const SizedBox(height: 16),
                  _buildPilihSesi(),
                  const SizedBox(height: 16),
                  _buildRincianKeuangan(),
                  const SizedBox(height: 24),
                  Text(
                    'STATUS KLAIM PEMENANG',
                    style: AppTextStyles.interLabel.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_pemenang.length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPemenangCard(i),
                      )),
                ],
              ),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildInfoBiaya() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'INFORMASI BIAYA',
                style: AppTextStyles.interLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoItem('Fee Platform: 5% dari total pendaftaran'),
          _buildInfoItem('Fee Admin: 10% dari total pendaftaran'),
          _buildInfoItem('Hadiah: Juara 1 = 50%, Juara 2 = 30%, Juara 3 = 20%'),
          const SizedBox(height: 8),
          Text(
            'Total Hadiah = Total Pendapatan - Fee Platform - Fee Admin',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.interCaption.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPilihSesi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PILIH SESI SCRIM',
          style: AppTextStyles.interLabel.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSesi,
              dropdownColor: AppColors.backgroundCard,
              style: AppTextStyles.interBody.copyWith(fontSize: 14),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
              isExpanded: true,
              items: _sesiOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSesi = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRincianKeuangan() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'RINCIAN KEUANGAN SESI',
                style: AppTextStyles.interLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _financeRow('Total Pendapatan (12 tim)', 'Rp 600.000', AppColors.primary, bold: true),
          const Divider(color: Colors.white10, height: 20),
          _financeRow('Fee Platform (5%)', '- Rp 30.000', AppColors.textSecondary),
          const SizedBox(height: 8),
          _financeRow('Fee Admin (10%)', '- Rp 60.000', AppColors.textSecondary),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sisa untuk Hadiah',
                  style: AppTextStyles.interBodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Rp 510.000',
                  style: AppTextStyles.poppinsMoneySmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ALOKASI HADIAH (Sisa)',
            style: AppTextStyles.interLabel.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _financeRow('Juara 1 (50%)', 'Rp 255.000', AppColors.primary),
          const SizedBox(height: 6),
          _financeRow('Juara 2 (30%)', 'Rp 153.000', AppColors.primary),
          const SizedBox(height: 6),
          _financeRow('Juara 3 (20%)', 'Rp 102.000', AppColors.primary),
        ],
      ),
    );
  }

  Widget _financeRow(String label, String value, Color valueColor, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.interBody.copyWith(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.poppinsMoneySmall.copyWith(
            color: valueColor,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPemenangCard(int index) {
    final p = _pemenang[index];
    final int rank = p['rank'] as int;
    final String status = _statusPemenang[index];

    final Color rankColor = rank == 1
        ? AppColors.primary
        : rank == 2
            ? const Color(0xFFB0BEC5)
            : const Color(0xFFCD7F32);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama + hadiah
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p['nama_tim'] as String,
                        style: AppTextStyles.poppinsTitleSmall.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatRupiah(p['hadiah'] as int),
                      style: AppTextStyles.poppinsMoneySmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Status badge
                _buildStatusBadge(status),
                const SizedBox(height: 10),

                // ID Game & akun
                Text(
                  '${p['kode']} • ${p['id_game']}',
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p['nama_akun'] as String,
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),

                // Riwayat status
                Text(
                  'RIWAYAT STATUS',
                  style: AppTextStyles.interLabel.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTimeline(status),
                const SizedBox(height: 14),

                // Action buttons
                _buildActionButtons(index, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    late String label;
    late Color bg;
    late Color fg;

    switch (status) {
      case 'verified':
        label = 'SUDAH VERIFIKASI';
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case 'ditolak':
        label = 'DITOLAK';
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
      default:
        label = 'BELUM VERIFIKASI';
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTimeline(String status) {
    final bool verified = status == 'verified';
    final steps = [
      {'label': 'Klaim Diajukan', 'done': true},
      {'label': verified ? 'Diteruskan ke Admin' : 'Menunggu Verifikasi Admin', 'done': verified},
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final bool done = steps[i]['done'] as bool;
        final bool isLast = i == steps.length - 1;
        final Color dotColor = done ? AppColors.success : Colors.white24;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 1.5,
                            color: done
                                ? AppColors.success.withValues(alpha: 0.4)
                                : Colors.white10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[i]['label'] as String,
                      style: AppTextStyles.interBody.copyWith(
                        fontSize: 12,
                        color: done ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (done)
                      Text(
                        '12 Okt 2023',
                        style: AppTextStyles.interCaption.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons(int index, String status) {
    if (status == 'verified') {
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success.withValues(alpha: 0.15),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
            ),
          ),
          onPressed: null,
          child: Text(
            'DATA TERVALIDASI',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (status == 'ditolak') {
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: null,
          child: Text(
            'DITOLAK',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    // BELUM VERIFIKASI → TOLAK + SETUJUI
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _tolak(index),
              child: Text(
                'TOLAK',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _setujui(index),
              child: const Text(
                'SETUJUI',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            elevation: 0,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KlaimHadiahDetailPage()),
            );
          },
          child: const Text(
            'TERUSKAN KE OWNER',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
