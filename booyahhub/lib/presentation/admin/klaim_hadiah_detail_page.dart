import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class KlaimHadiahDetailPage extends StatefulWidget {
  const KlaimHadiahDetailPage({super.key});

  @override
  State<KlaimHadiahDetailPage> createState() => _KlaimHadiahDetailPageState();
}

class _KlaimHadiahDetailPageState extends State<KlaimHadiahDetailPage> {
  static const int _totalPendapatan = 600000;
  static const int _jumlahTim = 12;

  // Fee settings
  int _feePlatformPersen = 25;
  int _nominalMinimumPlatform = 5000;
  int _feeAdminPersen = 10;
  int _feeAdminTetap = 10000;
  bool _isPersentaseAdmin = true;

  @override
  void initState() {
    super.initState();
    _fetchFeeSettings();
  }

  Future<void> _fetchFeeSettings() async {
    try {
      final feeSetting = await Supabase.instance.client
          .from('pengaturan_fee')
          .select()
          .maybeSingle();
      
      if (feeSetting != null && mounted) {
        setState(() {
          _feePlatformPersen = feeSetting['fee_platform_persen'] ?? 25;
          _nominalMinimumPlatform = feeSetting['nominal_minimum_platform'] ?? 5000;
          _feeAdminPersen = feeSetting['fee_admin_persen'] ?? 10;
          _feeAdminTetap = feeSetting['fee_admin_tetap'] ?? 10000;
          _isPersentaseAdmin = feeSetting['is_persentase_admin'] ?? true;
        });
      }
    } catch (e) {
      print('Error fetch fee settings: $e');
    }
  }

  int get _feePlatform {
    int fee = (_totalPendapatan * _feePlatformPersen ~/ 100);
    return fee < _nominalMinimumPlatform ? _nominalMinimumPlatform : fee;
  }
  
  int get _feeAdmin {
    return _isPersentaseAdmin 
        ? (_totalPendapatan * _feeAdminPersen ~/ 100)
        : _feeAdminTetap;
  }
  
  int get _sisaHadiah => _totalPendapatan - _feePlatform - _feeAdmin;

  static const List<Map<String, dynamic>> _pemenang = [
    {
      'rank': 1,
      'nama_tim': 'Evos Glory',
      'hadiah': 255000,
      'status': 'dicairkan',
      'rank_game': 1,
      'kill': '1903',
      'points': '32',
      'apk': 'ANIKEL PRADO',
      'timeline_step': 3,
    },
    {
      'rank': 2,
      'nama_tim': 'RRQ Hoshi',
      'hadiah': 153000,
      'status': 'diproses',
      'rank_game': 2,
      'kill': '1803',
      'points': '123',
      'apk': 'ANIKEL PRADO',
      'timeline_step': 2,
    },
    {
      'rank': 3,
      'nama_tim': 'Bigetron Alpha',
      'hadiah': 102000,
      'status': 'pending',
      'rank_game': 3,
      'kill': '1642',
      'points': '87',
      'apk': 'REKY PACO',
      'timeline_step': 1,
    },
  ];

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
                  ..._pemenang.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPemenangCard(p),
                      )),
                ],
              ),
            ),
          ),
          _buildBottomSection(),
        ],
      ),
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
          // Header
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: AppColors.primary,
                size: 18,
              ),
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

          // Total pendapatan
          _buildFinanceRow(
            label: 'Total Pendapatan ($_jumlahTim tim)',
            value: _formatRupiah(_totalPendapatan),
            valueColor: AppColors.primary,
            bold: true,
          ),
          const Divider(color: Colors.white10, height: 20),

          // Fee platform
          _buildFinanceRow(
            label: _feePlatform == _nominalMinimumPlatform 
                ? 'Fee Platform (Min. Rp${_nominalMinimumPlatform ~/ 1000}K)' 
                : 'Fee Platform ($_feePlatformPersen%)',
            value: '-${_formatRupiah(_feePlatform)}',
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),

          // Fee admin
          _buildFinanceRow(
            label: _isPersentaseAdmin ? 'Fee Admin ($_feeAdminPersen%)' : 'Fee Admin (Tetap)',
            value: '-${_formatRupiah(_feeAdmin)}',
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),

          // Sisa untuk hadiah
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
                  style: AppTextStyles.interBodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatRupiah(_sisaHadiah),
                  style: AppTextStyles.poppinsMoneySmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Alokasi hadiah header
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

          _buildAlokasiRow('Juara 1 (50%)', _sisaHadiah * 50 ~/ 100),
          const SizedBox(height: 6),
          _buildAlokasiRow('Juara 2 (30%)', _sisaHadiah * 30 ~/ 100),
          const SizedBox(height: 6),
          _buildAlokasiRow('Juara 3 (20%)', _sisaHadiah * 20 ~/ 100),
        ],
      ),
    );
  }

  Widget _buildFinanceRow({
    required String label,
    required String value,
    required Color valueColor,
    bool bold = false,
  }) {
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

  Widget _buildAlokasiRow(String label, int nominal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.interBody.copyWith(fontSize: 13),
        ),
        Text(
          _formatRupiah(nominal),
          style: AppTextStyles.poppinsMoneySmall.copyWith(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPemenangCard(Map<String, dynamic> p) {
    final int rank = p['rank'] as int;
    final String status = p['status'] as String;
    final int timelineStep = p['timeline_step'] as int;

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

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama tim + hadiah
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

                // Stats
                Text(
                  'RANK: ${p['rank_game']}  •  KILL: ${p['kill']}  •  POINTS: ${p['points']}',
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'APK: ${p['apk']}',
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
                _buildTimeline(timelineStep),
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
      case 'dicairkan':
        label = 'SUDAH DICAIRKAN';
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case 'diproses':
        label = 'SEDANG DIPROSES';
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.primary;
        break;
      default:
        label = 'MENUNGGU KLAIM';
        bg = Colors.white10;
        fg = AppColors.textSecondary;
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

  Widget _buildTimeline(int doneStep) {
    final steps = [
      'Klaim Diajukan',
      'Diteruskan ke Admin',
      'Diteruskan ke Owner',
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final bool done = i < doneStep;
        final bool current = i == doneStep - 1;
        final bool isLast = i == steps.length - 1;
        final Color dotColor = done
            ? (current && doneStep < steps.length
                ? AppColors.primary
                : AppColors.success)
            : Colors.white24;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dot + line column
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
                            color: done ? AppColors.success.withValues(alpha: 0.4) : Colors.white10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Label + date
              Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[i],
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

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                elevation: 0,
              ),
              onPressed: null,
              child: const Text(
                'SUDAH DITERUSKAN KE OWNER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'MENUNGGU KONFIRMASI PEMBAYARAN DARI OWNER',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
