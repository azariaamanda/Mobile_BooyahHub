// lib/presentation/admin/admin_claim_list_page.dart
//
// SATU FILE LENGKAP: layar Keuangan (tab "Klaim") + layar Klaim Hadiah.
// Tidak butuh file model atau file detail terpisah.
// Hanya bergantung pada 3 file config yang sudah ada.

import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

// ============================================================
// KONSTANTA, FORMAT, MODEL & DATA DUMMY  (semua inline)
// ============================================================

/// Warna khusus status "sedang dicairkan" (teal).
const Color _kTeal = Color(0xFF14B8A6);

/// Format "Rp 50.000".
String _rupiah(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}Rp $b';
}

/// Format ringkas: 12400000 -> "Rp 12.4M".
String _rupiahRingkas(int v) {
  if (v >= 1000000000) return 'Rp ${(v / 1000000000).toStringAsFixed(1)}B';
  if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}K';
  return _rupiah(v);
}

enum KlaimCardStatus { urgent, completed }

class KlaimAktif {
  final String namaScrim;
  final String tanggal;
  final int nominal;
  final KlaimCardStatus status;
  final int? jumlahPending;
  final int? jumlahTim;
  final String? catatan;

  const KlaimAktif({
    required this.namaScrim,
    required this.tanggal,
    required this.nominal,
    required this.status,
    this.jumlahPending,
    this.jumlahTim,
    this.catatan,
  });
}

class RingkasanKeuangan {
  final int totalPendapatan;
  final double pertumbuhanPersen;
  final int danaKeluar;
  final int persenTersalurkan;
  final int klaimPending;

  const RingkasanKeuangan({
    required this.totalPendapatan,
    required this.pertumbuhanPersen,
    required this.danaKeluar,
    required this.persenTersalurkan,
    required this.klaimPending,
  });
}

/// Status verifikasi klaim seorang pemenang.
enum WinnerClaimStatus { belumVerifikasi, sudahVerifikasi, ditolak, sedangDicairkan }

extension on WinnerClaimStatus {
  String get label {
    switch (this) {
      case WinnerClaimStatus.belumVerifikasi:
        return 'BELUM VERIFIKASI';
      case WinnerClaimStatus.sudahVerifikasi:
        return 'SUDAH VERIFIKASI';
      case WinnerClaimStatus.ditolak:
        return 'DITOLAK';
      case WinnerClaimStatus.sedangDicairkan:
        return 'SEDANG DICAIRKAN';
    }
  }

  Color get color {
    switch (this) {
      case WinnerClaimStatus.belumVerifikasi:
        return AppColors.warning;
      case WinnerClaimStatus.sudahVerifikasi:
        return AppColors.success;
      case WinnerClaimStatus.ditolak:
        return AppColors.error;
      case WinnerClaimStatus.sedangDicairkan:
        return _kTeal;
    }
  }
}

class TimelineEntry {
  final String label;
  final String? waktu;
  final bool done;
  final bool pending;
  const TimelineEntry(
      {required this.label, this.waktu, this.done = false, this.pending = false});
}

class WinnerClaim {
  final int rank;
  final String namaTim;
  final int nominal;
  final String metode;
  final String nomorRekening;
  final String namaPemilik;
  WinnerClaimStatus status;

  WinnerClaim({
    required this.rank,
    required this.namaTim,
    required this.nominal,
    required this.metode,
    required this.nomorRekening,
    required this.namaPemilik,
    this.status = WinnerClaimStatus.belumVerifikasi,
  });

  List<TimelineEntry> get timeline {
    switch (status) {
      case WinnerClaimStatus.belumVerifikasi:
        return const [
          TimelineEntry(label: 'Klaim Diajukan', waktu: '12 Okt, 14:20', done: true),
          TimelineEntry(label: 'Menunggu Verifikasi Admin', pending: true),
        ];
      case WinnerClaimStatus.sudahVerifikasi:
        return const [
          TimelineEntry(label: 'Klaim Diajukan', waktu: '12 Okt, 14:20', done: true),
          TimelineEntry(label: 'Disetujui Admin', waktu: '12 Okt, 14:45', done: true),
        ];
      case WinnerClaimStatus.ditolak:
        return const [
          TimelineEntry(label: 'Klaim Diajukan', waktu: '12 Okt, 14:20', done: true),
          TimelineEntry(label: 'Ditolak Admin', waktu: '12 Okt, 14:45', done: true),
        ];
      case WinnerClaimStatus.sedangDicairkan:
        return const [
          TimelineEntry(label: 'Klaim Diajukan', waktu: '12 Okt, 14:20', done: true),
          TimelineEntry(label: 'Disetujui Admin', waktu: '12 Okt, 14:45', done: true),
          TimelineEntry(label: 'Diteruskan ke Owner', waktu: '13 Okt, 08:15', done: true),
        ];
    }
  }
}

// ---- Data dummy (ganti dengan query Supabase saat integrasi) ----
const _mockRingkasan = RingkasanKeuangan(
  totalPendapatan: 12400000,
  pertumbuhanPersen: 4.2,
  danaKeluar: 10200000,
  persenTersalurkan: 80,
  klaimPending: 12,
);

const _mockKlaimAktif = [
  KlaimAktif(
    namaScrim: 'Ultimate Pro League - S12',
    tanggal: '24 Okt 2023',
    nominal: 600000,
    status: KlaimCardStatus.urgent,
    jumlahPending: 12,
    jumlahTim: 8,
  ),
  KlaimAktif(
    namaScrim: 'Elite Weekly Cup',
    tanggal: '25 Okt 2023',
    nominal: 1200000,
    status: KlaimCardStatus.completed,
    catatan: 'Selesai dalam 45 menit',
  ),
];

const _mockSesiList = [
  'Sesi 1: 08.00 - 09.00',
  'Sesi 2: 10.00 - 11.00',
  'Sesi 3: 13.00 - 14.00',
];

List<WinnerClaim> _buildMockWinners() => [
      WinnerClaim(
        rank: 1,
        namaTim: 'Evos Glory',
        nominal: 255000,
        metode: 'BCA',
        nomorRekening: '8821 0941 12',
        namaPemilik: 'MUHAMMAD RIDWAN',
      ),
      WinnerClaim(
        rank: 2,
        namaTim: 'RRQ Hoshi',
        nominal: 153000,
        metode: 'DANA',
        nomorRekening: '0812 9342 123',
        namaPemilik: 'ANDIKA PRATAMA',
      ),
      WinnerClaim(
        rank: 3,
        namaTim: 'Bigetron Alpha',
        nominal: 102000,
        metode: 'GoPay',
        nomorRekening: '8857 1123 661',
        namaPemilik: 'RIZKY FAUZI',
      ),
    ];

// ============================================================
// LAYAR KEUANGAN — isi tab "Klaim" pada AdminMainNavigator
// (TANPA Scaffold & TANPA bottomNavigationBar)
// ============================================================
class AdminClaimListPage extends StatelessWidget {
  const AdminClaimListPage({super.key});

  @override
  Widget build(BuildContext context) {
    const ringkasan = _mockRingkasan;
    const klaimList = _mockKlaimAktif;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingM, AppConstants.paddingS, AppConstants.paddingM, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _TotalPendapatanCard(ringkasan: ringkasan),
                const SizedBox(height: AppConstants.paddingM),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        label: 'DANA KELUAR',
                        value: _rupiahRingkas(ringkasan.danaKeluar),
                        caption: '${ringkasan.persenTersalurkan}% Tersalurkan',
                        captionColor: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingM),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'KLAIM PENDING',
                        value: '${ringkasan.klaimPending}',
                        caption: 'Segera Proses',
                        captionColor: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingL),
                Text('Daftar Klaim Aktif', style: AppTextStyles.poppinsSectionTitle),
                const SizedBox(height: AppConstants.paddingM),
                ...klaimList.map(
                  (k) => Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
                    child: _KlaimAktifCard(
                      klaim: k,
                      onDetail: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClaimDetailPage(namaScrim: k.namaScrim),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingM, AppConstants.paddingL, AppConstants.paddingM, AppConstants.paddingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Keuangan', style: AppTextStyles.poppinsHeadline),
          const SizedBox(height: AppConstants.paddingXS),
          Text('Ringkasan pendapatan & klaim hadiah', style: AppTextStyles.interBody),
        ],
      ),
    );
  }
}

class _TotalPendapatanCard extends StatelessWidget {
  final RingkasanKeuangan ringkasan;
  const _TotalPendapatanCard({required this.ringkasan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
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
          Text('TOTAL PENDAPATAN',
              style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: AppConstants.paddingS),
          Text(_rupiahRingkas(ringkasan.totalPendapatan),
              style: AppTextStyles.poppinsMoneyLarge),
          const SizedBox(height: AppConstants.paddingXS),
          Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text('+${ringkasan.pertumbuhanPersen}% bln ini',
                  style: AppTextStyles.percentageUp),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label, value, caption;
  final Color captionColor;
  const _MiniStatCard(
      {required this.label,
      required this.value,
      required this.caption,
      required this.captionColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: AppConstants.paddingS),
          Text(value,
              style: AppTextStyles.poppinsTitle
                  .copyWith(color: AppColors.textPrimary, fontSize: 22)),
          const SizedBox(height: 2),
          Text(caption,
              style: AppTextStyles.interCaption.copyWith(color: captionColor)),
        ],
      ),
    );
  }
}

class _KlaimAktifCard extends StatelessWidget {
  final KlaimAktif klaim;
  final VoidCallback onDetail;
  const _KlaimAktifCard({required this.klaim, required this.onDetail});

  bool get _urgent => klaim.status == KlaimCardStatus.urgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
            color: _urgent
                ? AppColors.primary.withOpacity(0.35)
                : AppColors.divider),
      ),
      child: _urgent ? _urgentBody() : _completedBody(),
    );
  }

  Widget _urgentBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS)),
              child: Text('URGENT',
                  style: AppTextStyles.interStatus.copyWith(
                      color: AppColors.buttonText, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Text(klaim.tanggal,
                style: AppTextStyles.interCaption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          children: [
            Expanded(
                child: Text(klaim.namaScrim,
                    style: AppTextStyles.poppinsTitleSmall)),
            const SizedBox(width: AppConstants.paddingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS)),
              child: Text('${klaim.jumlahPending} Pending',
                  style: AppTextStyles.interStatus
                      .copyWith(color: AppColors.warning)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.groups_outlined, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text('${klaim.jumlahTim} Tim', style: AppTextStyles.interCaption),
            Text('   •   ',
                style: AppTextStyles.interCaption
                    .copyWith(color: AppColors.textDisabled)),
            Text(_rupiah(klaim.nominal), style: AppTextStyles.goldHighlight),
          ],
        ),
        const SizedBox(height: AppConstants.paddingM),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusS)),
            ),
            icon: const Icon(Icons.receipt_long,
                size: 18, color: AppColors.buttonText),
            label: Text('Detail Klaim',
                style: AppTextStyles.poppinsButton.copyWith(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _completedBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(klaim.tanggal, style: AppTextStyles.interCaption),
            Text('  •  ',
                style: AppTextStyles.interCaption
                    .copyWith(color: AppColors.textDisabled)),
            Icon(Icons.check_circle, size: 12, color: AppColors.success),
            const SizedBox(width: 4),
            Text('COMPLETED',
                style: AppTextStyles.interStatus
                    .copyWith(color: AppColors.success)),
          ],
        ),
        const SizedBox(height: AppConstants.paddingS),
        Text(klaim.namaScrim, style: AppTextStyles.poppinsTitleSmall),
        const SizedBox(height: 4),
        Text(_rupiah(klaim.nominal), style: AppTextStyles.poppinsMoney),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppConstants.paddingM),
          child: Divider(height: 1, color: AppColors.divider),
        ),
        Row(
          children: [
            Expanded(
                child: Text(klaim.catatan ?? '',
                    style: AppTextStyles.interCaption)),
            OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingM, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusS)),
              ),
              icon: const Icon(Icons.history,
                  size: 14, color: AppColors.textSecondary),
              label: Text('Lihat Riwayat',
                  style: AppTextStyles.interLabel
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// LAYAR KLAIM HADIAH — dibuka penuh lewat Navigator.push
// Menangani 2 kondisi: sebelum & sesudah diteruskan ke Owner.
// ============================================================
class ClaimDetailPage extends StatefulWidget {
  final String namaScrim;
  const ClaimDetailPage({super.key, this.namaScrim = 'Ultimate Pro League'});

  @override
  State<ClaimDetailPage> createState() => _ClaimDetailPageState();
}

class _ClaimDetailPageState extends State<ClaimDetailPage> {
  String _sesi = _mockSesiList.first;
  late List<WinnerClaim> _winners = _buildMockWinners();
  bool _diteruskan = false;

  // Rincian keuangan dihitung dari total pendapatan sesi.
  static const int _total = 600000;
  static const int _jumlahTim = 12;
  int get _feePlatform => (_total * 0.05).round();
  int get _feeAdmin => (_total * 0.10).round();
  int get _sisaHadiah => _total - _feePlatform - _feeAdmin;
  int get _juara1 => (_sisaHadiah * 0.50).round();
  int get _juara2 => (_sisaHadiah * 0.30).round();
  int get _juara3 => (_sisaHadiah * 0.20).round();

  int get _jumlahTerverifikasi =>
      _winners.where((w) => w.status == WinnerClaimStatus.sudahVerifikasi).length;
  bool get _semuaTerverifikasi =>
      _winners.every((w) => w.status == WinnerClaimStatus.sudahVerifikasi);

  void _setujui(WinnerClaim w) =>
      setState(() => w.status = WinnerClaimStatus.sudahVerifikasi);

  void _tolak(WinnerClaim w) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Tolak Klaim?', style: AppTextStyles.poppinsTitleSmall),
        content: Text('Klaim hadiah ${w.namaTim} akan ditandai ditolak.',
            style: AppTextStyles.interBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: AppTextStyles.interLabel
                    .copyWith(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => w.status = WinnerClaimStatus.ditolak);
            },
            child: Text('Tolak',
                style: AppTextStyles.interLabel
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _teruskanKeOwner() {
    setState(() {
      _diteruskan = true;
      for (final w in _winners) {
        w.status = WinnerClaimStatus.sedangDicairkan;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          backgroundColor: _kTeal, content: Text('Klaim diteruskan ke Owner')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _appBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppConstants.paddingM,
                    AppConstants.paddingS, AppConstants.paddingM, AppConstants.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoBiaya(),
                    const SizedBox(height: AppConstants.paddingL),
                    _label('PILIH SESI SCRIM'),
                    _sesiDropdown(),
                    const SizedBox(height: AppConstants.paddingL),
                    _rincianKeuangan(),
                    const SizedBox(height: AppConstants.paddingL),
                    _label('STATUS KLAIM PEMENANG'),
                    ..._winners.map(
                      (w) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppConstants.paddingM),
                        child: _WinnerCard(
                          winner: w,
                          locked: _diteruskan,
                          onSetuju: () => _setujui(w),
                          onTolak: () => _tolak(w),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _forwardButton(),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.paddingS,
          AppConstants.paddingS, AppConstants.paddingM, AppConstants.paddingS),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          Text('Klaim Hadiah',
              style: AppTextStyles.poppinsTitleSmall
                  .copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
        child: Text(t,
            style: AppTextStyles.interCaption.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
      );

  Widget _infoBiaya() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingM),
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
              Text('INFORMASI BIAYA',
                  style: AppTextStyles.interCaption.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: AppConstants.paddingS),
          _bullet('Fee Platform: 5% dari total pendaftaran'),
          _bullet('Fee Admin: 10% dari total pendaftaran'),
          _bullet('Hadiah: Juara 1 = 50%, Juara 2 = 30%, Juara 3 = 20%'),
          const SizedBox(height: 6),
          Text('Total Hadiah = Total Pendaftaran − Fee Platform − Fee Admin',
              style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic)),
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
                      color: AppColors.textHint, shape: BoxShape.circle)),
            ),
            Expanded(child: Text(t, style: AppTextStyles.interCaption)),
          ],
        ),
      );

  Widget _sesiDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
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
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          style: AppTextStyles.interInput,
          items: _mockSesiList
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: AppTextStyles.interInput)))
              .toList(),
          onChanged: _diteruskan
              ? null
              : (val) {
                  if (val != null) setState(() => _sesi = val);
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
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusM)),
            ),
            child: Row(
              children: [
                Icon(Icons.calculate_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('RINCIAN KEUANGAN SESI',
                    style: AppTextStyles.interCaption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusS)),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 16, color: AppColors.textHint),
                      const SizedBox(width: AppConstants.paddingS),
                      Expanded(
                        child: Text('Total Pendapatan ($_jumlahTim tim)',
                            style: AppTextStyles.interBodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                      Text(_rupiah(_total),
                          style: AppTextStyles.goldHighlight),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                _feeRow('Fee Platform (5%)', '- ${_rupiah(_feePlatform)}'),
                const SizedBox(height: 8),
                _feeRow('Fee Admin (10%)', '- ${_rupiah(_feeAdmin)}'),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: AppConstants.paddingM),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sisa untuk Hadiah',
                        style: AppTextStyles.interBodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    Text(_rupiah(_sisaHadiah),
                        style: AppTextStyles.poppinsTitleSmall),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingM),
                _alokasiHadiah(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.remove_circle_outline,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.interBody),
            ],
          ),
          Text(value,
              style: AppTextStyles.interBodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      );

  Widget _alokasiHadiah() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ALOKASI HADIAH (85%)',
              style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: AppConstants.paddingS),
          _juaraRow('Juara 1 (50%)', _juara1, AppColors.primary),
          const SizedBox(height: 8),
          _juaraRow('Juara 2 (30%)', _juara2, AppColors.textPrimary),
          const SizedBox(height: 8),
          _juaraRow('Juara 3 (20%)', _juara3, AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _juaraRow(String label, int nominal, Color c) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.interBody),
          Text(_rupiah(nominal),
              style: AppTextStyles.interBodyMedium
                  .copyWith(color: c, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _forwardButton() {
    final bool aktif = _semuaTerverifikasi && !_diteruskan;
    final String caption = _diteruskan
        ? 'MENUNGGU KONFIRMASI PEMBAYARAN DARI OWNER'
        : 'MENUNGGU VERIFIKASI SEMUA PEMENANG $_jumlahTerverifikasi/${_winners.length}';
    final String label =
        _diteruskan ? 'Sudah Diteruskan ke Owner' : 'Teruskan ke Owner';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
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
                onPressed: aktif ? _teruskanKeOwner : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM)),
                ),
                icon: Icon(
                  _diteruskan ? Icons.check_circle : Icons.send_rounded,
                  size: 20,
                  color:
                      aktif ? AppColors.buttonText : AppColors.textDisabled,
                ),
                label: Text(label,
                    style: AppTextStyles.poppinsButton.copyWith(
                        color: aktif
                            ? AppColors.buttonText
                            : AppColors.textDisabled)),
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(caption,
                textAlign: TextAlign.center,
                style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textDisabled, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ---- Kartu pemenang ----
class _WinnerCard extends StatelessWidget {
  final WinnerClaim winner;
  final bool locked;
  final VoidCallback onSetuju, onTolak;
  const _WinnerCard(
      {required this.winner,
      required this.locked,
      required this.onSetuju,
      required this.onTolak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _head(),
          const SizedBox(height: AppConstants.paddingM),
          _RiwayatStatus(entries: winner.timeline),
          const SizedBox(height: AppConstants.paddingM),
          _action(),
        ],
      ),
    );
  }

  Widget _head() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          ),
          child: Text('${winner.rank}',
              style: AppTextStyles.poppinsTitleSmall
                  .copyWith(color: AppColors.primary)),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(winner.namaTim,
                          style: AppTextStyles.poppinsTitleSmall)),
                  Text(_rupiah(winner.nominal),
                      style: AppTextStyles.goldHighlight),
                ],
              ),
              const SizedBox(height: 4),
              Text('${winner.metode} • ${winner.nomorRekening}',
                  style: AppTextStyles.interCaption
                      .copyWith(color: AppColors.textSecondary)),
              Text('A/N: ${winner.namaPemilik}',
                  style: AppTextStyles.interCaption),
              const SizedBox(height: 6),
              _StatusChip(status: winner.status),
            ],
          ),
        ),
      ],
    );
  }

  Widget _action() {
    switch (winner.status) {
      case WinnerClaimStatus.belumVerifikasi:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: locked ? null : onTolak,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusS)),
                ),
                child: Text('TOLAK',
                    style: AppTextStyles.interStatus.copyWith(
                        color: locked
                            ? AppColors.textDisabled
                            : AppColors.error,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: AppConstants.paddingS),
            Expanded(
              child: ElevatedButton(
                onPressed: locked ? null : onSetuju,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusS)),
                ),
                child: Text('SETUJUI',
                    style: AppTextStyles.interStatus.copyWith(
                        color: locked
                            ? AppColors.textDisabled
                            : AppColors.buttonText,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      case WinnerClaimStatus.sudahVerifikasi:
        return _doneBar(
            Icons.verified, 'DATA TERVALIDASI', AppColors.success);
      case WinnerClaimStatus.ditolak:
        return _doneBar(Icons.block, 'KLAIM DITOLAK', AppColors.error);
      case WinnerClaimStatus.sedangDicairkan:
        return _doneBar(Icons.payments_outlined,
            'SEDANG DICAIRKAN OLEH OWNER', _kTeal);
    }
  }

  Widget _doneBar(IconData icon, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: AppTextStyles.interStatus
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final WinnerClaimStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(status.label,
          style: AppTextStyles.interStatus.copyWith(color: color)),
    );
  }
}

class _RiwayatStatus extends StatelessWidget {
  final List<TimelineEntry> entries;
  const _RiwayatStatus({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingS),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 4, bottom: AppConstants.paddingS),
            child: Text('RIWAYAT STATUS',
                style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
          ),
          for (int i = 0; i < entries.length; i++)
            _row(entries[i], i == entries.length - 1),
        ],
      ),
    );
  }

  Widget _row(TimelineEntry e, bool isLast) {
    final Color dot = e.pending
        ? AppColors.warning
        : (e.done ? AppColors.success : AppColors.textDisabled);
    return IntrinsicHeight(
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
                  color: dot,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.background, width: 1.5),
                ),
              ),
              if (!isLast)
                Expanded(
                    child: Container(width: 1.5, color: AppColors.divider)),
            ],
          ),
          const SizedBox(width: AppConstants.paddingS),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 2 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.label,
                      style: AppTextStyles.interCaption.copyWith(
                          color: e.pending
                              ? AppColors.warning
                              : AppColors.textSecondary,
                          fontWeight: e.pending
                              ? FontWeight.w600
                              : FontWeight.w500)),
                  if (e.waktu != null)
                    Text(e.waktu!,
                        style: AppTextStyles.interCaption.copyWith(
                            color: AppColors.textDisabled, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}