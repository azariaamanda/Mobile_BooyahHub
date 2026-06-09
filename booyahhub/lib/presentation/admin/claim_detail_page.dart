import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

const Color _kTeal = Color(0xFF14B8A6);

String _rp(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp $b';
}

String _rpShort(int v) {
  if (v >= 1000000000) return 'Rp ${(v / 1000000000).toStringAsFixed(1)}B';
  if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}K';
  return _rp(v);
}

enum _WinStatus { belum, sudah, ditolak, dicairkan }

class _Winner {
  final int rank;
  final String tim, metode, rek, atas;
  final int nominal;
  _WinStatus status;
  _Winner(this.rank, this.tim, this.nominal, this.metode, this.rek, this.atas)
    : status = _WinStatus.belum;
}

// ============================================================
// TAB "KLAIM" — layar Keuangan
// Pakai Scaffold + ListView supaya RENDER STABIL di IndexedStack.
// ============================================================
class AdminClaimListPage extends StatelessWidget {
  const AdminClaimListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 110),
        children: [
          Text('Keuangan', style: AppTextStyles.poppinsHeadline),
          const SizedBox(height: 4),
          Text(
            'Ringkasan pendapatan & klaim hadiah',
            style: AppTextStyles.interBody,
          ),
          const SizedBox(height: 20),
          _totalPendapatanCard(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'DANA KELUAR',
                  _rpShort(10200000),
                  '80% Tersalurkan',
                  AppColors.textHint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  'KLAIM PENDING',
                  '12',
                  'Segera Proses',
                  AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Daftar Klaim Aktif', style: AppTextStyles.poppinsSectionTitle),
          const SizedBox(height: 12),
          _kartuUrgent(
            context,
            tanggal: '24 Okt 2023',
            namaScrim: 'Ultimate Pro League - S12',
            jumlahPending: 12,
            jumlahTim: 8,
            nominal: 600000,
          ),
          const SizedBox(height: 12),
          _kartuCompleted(
            tanggal: '25 Okt 2023',
            namaScrim: 'Elite Weekly Cup',
            nominal: 1200000,
            catatan: 'Selesai dalam 45 menit',
          ),
        ],
      ),
    );
  }

  Widget _totalPendapatanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.backgroundCard],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL PENDAPATAN',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textHint,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(_rpShort(12400000), style: AppTextStyles.poppinsMoneyLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text('+4.2% bln ini', style: AppTextStyles.percentageUp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, String caption, Color cc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textHint,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.poppinsTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(caption, style: AppTextStyles.interCaption.copyWith(color: cc)),
        ],
      ),
    );
  }

  Widget _kartuUrgent(
    BuildContext context, {
    required String tanggal,
    required String namaScrim,
    required int jumlahPending,
    required int jumlahTim,
    required int nominal,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'URGENT',
                  style: AppTextStyles.interStatus.copyWith(
                    color: AppColors.buttonText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                tanggal,
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(namaScrim, style: AppTextStyles.poppinsTitleSmall),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$jumlahPending Pending',
                  style: AppTextStyles.interStatus.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.groups_outlined, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('$jumlahTim Tim', style: AppTextStyles.interCaption),
              Text(
                '   •   ',
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
              Text(_rp(nominal), style: AppTextStyles.goldHighlight),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ClaimDetailPage(namaScrim: namaScrim),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              icon: const Icon(
                Icons.receipt_long,
                size: 18,
                color: AppColors.buttonText,
              ),
              label: Text(
                'Detail Klaim',
                style: AppTextStyles.poppinsButton.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuCompleted({
    required String tanggal,
    required String namaScrim,
    required int nominal,
    required String catatan,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tanggal, style: AppTextStyles.interCaption),
              Text(
                '  •  ',
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
              Icon(Icons.check_circle, size: 12, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                'COMPLETED',
                style: AppTextStyles.interStatus.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(namaScrim, style: AppTextStyles.poppinsTitleSmall),
          const SizedBox(height: 4),
          Text(_rp(nominal), style: AppTextStyles.poppinsMoney),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            children: [
              Expanded(child: Text(catatan, style: AppTextStyles.interCaption)),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(
                  Icons.history,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  'Lihat Riwayat',
                  style: AppTextStyles.interLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LAYAR KLAIM HADIAH (full screen, dibuka via Navigator.push)
// Menangani 2 kondisi: sebelum & sesudah diteruskan ke Owner.
// ============================================================
class ClaimDetailPage extends StatefulWidget {
  final String namaScrim;
  const ClaimDetailPage({super.key, this.namaScrim = 'Ultimate Pro League'});

  @override
  State<ClaimDetailPage> createState() => _ClaimDetailPageState();
}

class _ClaimDetailPageState extends State<ClaimDetailPage> {
  String _sesi = 'Sesi 1: 08.00 - 09.00';
  bool _diteruskan = false;
  late final List<_Winner> _winners = [
    _Winner(1, 'Evos Glory', 255000, 'BCA', '8821 0941 12', 'MUHAMMAD RIDWAN'),
    _Winner(2, 'RRQ Hoshi', 153000, 'DANA', '0812 9342 123', 'ANDIKA PRATAMA'),
    _Winner(
      3,
      'Bigetron Alpha',
      102000,
      'GoPay',
      '8857 1123 661',
      'RIZKY FAUZI',
    ),
  ];

  static const int _total = 600000;
  static const int _jmlTim = 12;

  // Fee settings from database
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
    int fee = (_total * _feePlatformPersen ~/ 100);
    return fee < _nominalMinimumPlatform ? _nominalMinimumPlatform : fee;
  }
  
  int get _feeAdmin {
    return _isPersentaseAdmin 
        ? (_total * _feeAdminPersen ~/ 100)
        : _feeAdminTetap;
  }
  
  int get _sisa => _total - _feePlatform - _feeAdmin;
  int get _juara1 => (_sisa * 0.50).round();
  int get _juara2 => (_sisa * 0.30).round();
  int get _juara3 => (_sisa * 0.20).round();

  int get _verified =>
      _winners.where((w) => w.status == _WinStatus.sudah).length;
  bool get _allVerified => _winners.every((w) => w.status == _WinStatus.sudah);

  void _setujui(_Winner w) => setState(() => w.status = _WinStatus.sudah);

  void _tolak(_Winner w) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Tolak Klaim?', style: AppTextStyles.poppinsTitleSmall),
        content: Text(
          'Klaim hadiah ${w.tim} akan ditandai ditolak.',
          style: AppTextStyles.interBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppTextStyles.interLabel.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => w.status = _WinStatus.ditolak);
            },
            child: Text(
              'Tolak',
              style: AppTextStyles.interLabel.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _teruskan() {
    setState(() {
      _diteruskan = true;
      for (final w in _winners) {
        w.status = _WinStatus.dicairkan;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          'Klaim Hadiah',
          style: AppTextStyles.poppinsTitleSmall.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _infoBiaya(),
          const SizedBox(height: 20),
          _label('PILIH SESI SCRIM'),
          _sesiDropdown(),
          const SizedBox(height: 20),
          _rincianKeuangan(),
          const SizedBox(height: 20),
          _label('STATUS KLAIM PEMENANG'),
          for (final w in _winners) ...[
            _winnerCard(w),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomNavigationBar: _forwardButton(),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: AppTextStyles.interCaption.copyWith(
        color: AppColors.textHint,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _infoBiaya() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 6),
              Text(
                'INFORMASI BIAYA',
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _bullet('Fee Platform: ${_feePlatform == _nominalMinimumPlatform ? "Min. Rp${_nominalMinimumPlatform ~/ 1000}K" : "$_feePlatformPersen%"} dari total pendaftaran'),
          _bullet('Fee Admin: ${_isPersentaseAdmin ? "$_feeAdminPersen%" : "Tetap Rp${_feeAdminTetap ~/ 1000}K"} dari total pendaftaran'),
          _bullet('Hadiah: Juara 1 = 50%, Juara 2 = 30%, Juara 3 = 20%'),
          const SizedBox(height: 6),
          Text(
            'Total Hadiah = Total Pendaftaran − Fee Platform − Fee Admin',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.textHint,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(child: Text(t, style: AppTextStyles.interCaption)),
      ],
    ),
  );

  Widget _sesiDropdown() {
    const sesi = [
      'Sesi 1: 08.00 - 09.00',
      'Sesi 2: 10.00 - 11.00',
      'Sesi 3: 13.00 - 14.00',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundInput,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sesi,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          style: AppTextStyles.interInput,
          items: sesi
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: _diteruskan
              ? null
              : (v) {
                  if (v != null) setState(() => _sesi = v);
                },
        ),
      ),
    );
  }

  Widget _rincianKeuangan() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusM),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'RINCIAN KEUANGAN SESI',
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total Pendapatan ($_jmlTim tim)',
                          style: AppTextStyles.interBodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(_rp(_total), style: AppTextStyles.goldHighlight),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _feeRow(
                  _feePlatform == _nominalMinimumPlatform 
                      ? 'Fee Platform (Min. Rp${_nominalMinimumPlatform ~/ 1000}K)' 
                      : 'Fee Platform ($_feePlatformPersen%)', 
                  '- ${_rp(_feePlatform)}'
                ),
                const SizedBox(height: 8),
                _feeRow(
                  _isPersentaseAdmin ? 'Fee Admin ($_feeAdminPersen%)' : 'Fee Admin (Tetap)', 
                  '- ${_rp(_feeAdmin)}'
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sisa untuk Hadiah',
                      style: AppTextStyles.interBodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(_rp(_sisa), style: AppTextStyles.poppinsTitleSmall),
                  ],
                ),
                const SizedBox(height: 12),
                _alokasiBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String l, String v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(
            Icons.remove_circle_outline,
            size: 13,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 6),
          Text(l, style: AppTextStyles.interBody),
        ],
      ),
      Text(
        v,
        style: AppTextStyles.interBodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );

  Widget _alokasiBox() {
    Widget row(String l, int n, Color c) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: AppTextStyles.interBody),
        Text(
          _rp(n),
          style: AppTextStyles.interBodyMedium.copyWith(
            color: c,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALOKASI HADIAH (85%)',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          row('Juara 1 (50%)', _juara1, AppColors.primary),
          const SizedBox(height: 8),
          row('Juara 2 (30%)', _juara2, AppColors.textPrimary),
          const SizedBox(height: 8),
          row('Juara 3 (20%)', _juara3, AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _winnerCard(_Winner w) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Text(
                  '${w.rank}',
                  style: AppTextStyles.poppinsTitleSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            w.tim,
                            style: AppTextStyles.poppinsTitleSmall,
                          ),
                        ),
                        Text(
                          _rp(w.nominal),
                          style: AppTextStyles.goldHighlight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${w.metode} • ${w.rek}',
                      style: AppTextStyles.interCaption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text('A/N: ${w.atas}', style: AppTextStyles.interCaption),
                    const SizedBox(height: 6),
                    _statusChip(w.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _timeline(w),
          const SizedBox(height: 12),
          _winnerAction(w),
        ],
      ),
    );
  }

  Widget _statusChip(_WinStatus s) {
    late final String label;
    late final Color c;
    switch (s) {
      case _WinStatus.belum:
        label = 'BELUM VERIFIKASI';
        c = AppColors.warning;
        break;
      case _WinStatus.sudah:
        label = 'SUDAH VERIFIKASI';
        c = AppColors.success;
        break;
      case _WinStatus.ditolak:
        label = 'DITOLAK';
        c = AppColors.error;
        break;
      case _WinStatus.dicairkan:
        label = 'SEDANG DICAIRKAN';
        c = _kTeal;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Text(label, style: AppTextStyles.interStatus.copyWith(color: c)),
    );
  }

  Widget _timeline(_Winner w) {
    final List<List<dynamic>> rows;
    switch (w.status) {
      case _WinStatus.belum:
        rows = [
          ['Klaim Diajukan', '12 Okt, 14:20', AppColors.success],
          ['Menunggu Verifikasi Admin', null, AppColors.warning],
        ];
        break;
      case _WinStatus.sudah:
        rows = [
          ['Klaim Diajukan', '12 Okt, 14:20', AppColors.success],
          ['Disetujui Admin', '12 Okt, 14:45', AppColors.success],
        ];
        break;
      case _WinStatus.ditolak:
        rows = [
          ['Klaim Diajukan', '12 Okt, 14:20', AppColors.success],
          ['Ditolak Admin', '12 Okt, 14:45', AppColors.error],
        ];
        break;
      case _WinStatus.dicairkan:
        rows = [
          ['Klaim Diajukan', '12 Okt, 14:20', AppColors.success],
          ['Disetujui Admin', '12 Okt, 14:45', AppColors.success],
          ['Diteruskan ke Owner', '13 Okt, 08:15', AppColors.success],
        ];
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'RIWAYAT STATUS',
              style: AppTextStyles.interCaption.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (int i = 0; i < rows.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 2),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: rows[i][2] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 1.5,
                          ),
                        ),
                      ),
                      if (i != rows.length - 1)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: AppColors.divider,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i == rows.length - 1 ? 2 : 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rows[i][0] as String,
                            style: AppTextStyles.interCaption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (rows[i][1] != null)
                            Text(
                              rows[i][1] as String,
                              style: AppTextStyles.interCaption.copyWith(
                                color: AppColors.textDisabled,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _winnerAction(_Winner w) {
    Widget bar(IconData ic, String t, Color c) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ic, size: 15, color: c),
          const SizedBox(width: 6),
          Text(
            t,
            style: AppTextStyles.interStatus.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    switch (w.status) {
      case _WinStatus.belum:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _diteruskan ? null : () => _tolak(w),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'TOLAK',
                  style: AppTextStyles.interStatus.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _diteruskan ? null : () => _setujui(w),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'SETUJUI',
                  style: AppTextStyles.interStatus.copyWith(
                    color: AppColors.buttonText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      case _WinStatus.sudah:
        return bar(Icons.verified, 'DATA TERVALIDASI', AppColors.success);
      case _WinStatus.ditolak:
        return bar(Icons.block, 'KLAIM DITOLAK', AppColors.error);
      case _WinStatus.dicairkan:
        return bar(
          Icons.payments_outlined,
          'SEDANG DICAIRKAN OLEH OWNER',
          _kTeal,
        );
    }
  }

  Widget _forwardButton() {
    final bool aktif = _allVerified && !_diteruskan;
    final caption = _diteruskan
        ? 'MENUNGGU KONFIRMASI PEMBAYARAN DARI OWNER'
        : 'MENUNGGU VERIFIKASI SEMUA PEMENANG $_verified/${_winners.length}';
    final label = _diteruskan
        ? 'Sudah Diteruskan ke Owner'
        : 'Teruskan ke Owner';
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: aktif ? _teruskan : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                icon: Icon(
                  _diteruskan ? Icons.check_circle : Icons.send_rounded,
                  size: 20,
                  color: aktif ? AppColors.buttonText : AppColors.textDisabled,
                ),
                label: Text(
                  label,
                  style: AppTextStyles.poppinsButton.copyWith(
                    color: aktif
                        ? AppColors.buttonText
                        : AppColors.textDisabled,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: AppTextStyles.interCaption.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
