// lib/presentation/admin/claim_detail_page.dart
//
// Layar "Klaim Hadiah" — admin memverifikasi klaim hadiah tiap pemenang
// lalu meneruskannya ke Owner.
//
// Layar ini menangani DUA kondisi dalam satu halaman:
//  - "Klaim Hadiah"  : sebelum diteruskan — tiap pemenang punya tombol
//                      Tolak / Setujui, badge BELUM/SUDAH VERIFIKASI.
//  - "Sesudah Klaim" : setelah diteruskan — badge SEDANG DICAIRKAN,
//                      tombol bawah berubah jadi non-aktif.

import 'package:flutter/material.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/keuangan_admin_model.dart';

/// Warna khusus status "sedang dicairkan" (teal) — tidak ada di AppColors.
const Color _kTeal = Color(0xFF14B8A6);

class ClaimDetailPage extends StatefulWidget {
  final String namaScrim;

  const ClaimDetailPage({super.key, this.namaScrim = 'Ultimate Pro League'});

  @override
  State<ClaimDetailPage> createState() => _ClaimDetailPageState();
}

class _ClaimDetailPageState extends State<ClaimDetailPage> {
  late SesiOption _sesi = mockSesiList.first;
  late final List<WinnerClaim> _winners = buildMockWinners();
  bool _diteruskan = false;

  // Rincian keuangan dihitung dari total pendapatan sesi.
  RincianKeuanganSesi get _rincian => RincianKeuanganSesi.hitung(600000, 12);

  int get _jumlahTerverifikasi => _winners
      .where((w) => w.status == WinnerClaimStatus.sudahVerifikasi)
      .length;

  bool get _semuaTerverifikasi =>
      _winners.every((w) => w.status == WinnerClaimStatus.sudahVerifikasi);

  // ---- Aksi admin -------------------------------------------------
  void _setujui(WinnerClaim w) {
    setState(() => w.status = WinnerClaimStatus.sudahVerifikasi);
  }

  void _tolak(WinnerClaim w) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Tolak Klaim?', style: AppTextStyles.poppinsTitleSmall),
        content: Text(
          'Klaim hadiah ${w.namaTim} akan ditandai ditolak.',
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
              setState(() => w.status = WinnerClaimStatus.ditolak);
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

  void _teruskanKeOwner() {
    setState(() {
      _diteruskan = true;
      for (final w in _winners) {
        w.status = WinnerClaimStatus.sedangDicairkan;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: _kTeal,
        content: Text('Klaim diteruskan ke Owner'),
      ),
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
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingM,
                  AppConstants.paddingS,
                  AppConstants.paddingM,
                  AppConstants.paddingL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBiaya(),
                    const SizedBox(height: AppConstants.paddingL),
                    _sectionLabel('PILIH SESI SCRIM'),
                    _buildSesiDropdown(),
                    const SizedBox(height: AppConstants.paddingL),
                    _buildRincianKeuangan(),
                    const SizedBox(height: AppConstants.paddingL),
                    _sectionLabel('STATUS KLAIM PEMENANG'),
                    ..._winners.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.paddingM,
                        ),
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
      bottomNavigationBar: _buildForwardButton(),
    );
  }

  // ===================== APP BAR =====================
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingS,
        AppConstants.paddingS,
        AppConstants.paddingM,
        AppConstants.paddingS,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          Text(
            'Klaim Hadiah',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
      child: Text(
        text,
        style: AppTextStyles.interCaption.copyWith(
          color: AppColors.textHint,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ===================== INFORMASI BIAYA =====================
  Widget _buildInfoBiaya() {
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
          const SizedBox(height: AppConstants.paddingS),
          _bullet('Fee Platform: 5% dari total pendaftaran'),
          _bullet('Fee Admin: 10% dari total pendaftaran'),
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

  Widget _bullet(String text) {
    return Padding(
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
          Expanded(child: Text(text, style: AppTextStyles.interCaption)),
        ],
      ),
    );
  }

  // ===================== DROPDOWN SESI =====================
  Widget _buildSesiDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundInput,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SesiOption>(
          value: _sesi,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          style: AppTextStyles.interInput,
          items: mockSesiList
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.label, style: AppTextStyles.interInput),
                ),
              )
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

  // ===================== RINCIAN KEUANGAN =====================
  Widget _buildRincianKeuangan() {
    final r = _rincian;
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
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingM),
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
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              children: [
                // Total pendapatan
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      Expanded(
                        child: Text(
                          'Total Pendapatan (${r.jumlahTim} tim)',
                          style: AppTextStyles.interBodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        formatRupiah(r.totalPendapatan),
                        style: AppTextStyles.goldHighlight,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                _feeRow(
                  'Fee Platform (5%)',
                  '- ${formatRupiah(r.feePlatform)}',
                ),
                const SizedBox(height: 8),
                _feeRow('Fee Admin (10%)', '- ${formatRupiah(r.feeAdmin)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppConstants.paddingM,
                  ),
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
                    Text(
                      formatRupiah(r.sisaHadiah),
                      style: AppTextStyles.poppinsTitleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingM),
                _buildAlokasiHadiah(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String label, String value) {
    return Row(
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
            Text(label, style: AppTextStyles.interBody),
          ],
        ),
        Text(
          value,
          style: AppTextStyles.interBodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAlokasiHadiah(RincianKeuanganSesi r) {
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
          Text(
            'ALOKASI HADIAH (85%)',
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          _juaraRow('Juara 1 (50%)', r.juara1, AppColors.primary),
          const SizedBox(height: 8),
          _juaraRow('Juara 2 (30%)', r.juara2, AppColors.textPrimary),
          const SizedBox(height: 8),
          _juaraRow('Juara 3 (20%)', r.juara3, AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _juaraRow(String label, int nominal, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.interBody),
        Text(
          formatRupiah(nominal),
          style: AppTextStyles.interBodyMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ===================== TOMBOL TERUSKAN =====================
  Widget _buildForwardButton() {
    final bool aktif = _semuaTerverifikasi && !_diteruskan;

    final String caption = _diteruskan
        ? 'MENUNGGU KONFIRMASI PEMBAYARAN DARI OWNER'
        : 'MENUNGGU VERIFIKASI SEMUA PEMENANG '
              '$_jumlahTerverifikasi/${_winners.length}';

    final String label = _diteruskan
        ? 'Sudah Diteruskan ke Owner'
        : 'Teruskan ke Owner';

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
            const SizedBox(height: AppConstants.paddingS),
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

// ============================================================
// KARTU PEMENANG
// ============================================================
class _WinnerCard extends StatelessWidget {
  final WinnerClaim winner;
  final bool locked; // true bila klaim sudah diteruskan ke owner
  final VoidCallback onSetuju;
  final VoidCallback onTolak;

  const _WinnerCard({
    required this.winner,
    required this.locked,
    required this.onSetuju,
    required this.onTolak,
  });

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
          _buildHeader(),
          const SizedBox(height: AppConstants.paddingM),
          _RiwayatStatus(entries: winner.timeline),
          const SizedBox(height: AppConstants.paddingM),
          _buildActionArea(),
        ],
      ),
    );
  }

  // ---- Header: peringkat, tim, rekening, badge ----
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lencana peringkat
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          ),
          child: Text(
            '${winner.rank}',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      winner.namaTim,
                      style: AppTextStyles.poppinsTitleSmall,
                    ),
                  ),
                  Text(
                    formatRupiah(winner.nominal),
                    style: AppTextStyles.goldHighlight,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${winner.metode} • ${winner.nomorRekening}',
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'A/N: ${winner.namaPemilik}',
                style: AppTextStyles.interCaption,
              ),
              const SizedBox(height: 6),
              _StatusChip(status: winner.status),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Area aksi sesuai status ----
  Widget _buildActionArea() {
    switch (winner.status) {
      case WinnerClaimStatus.belumVerifikasi:
        // Sebelum diteruskan: tombol Tolak / Setujui.
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: locked ? null : onTolak,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                ),
                child: Text(
                  'TOLAK',
                  style: AppTextStyles.interStatus.copyWith(
                    color: locked ? AppColors.textDisabled : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                ),
                child: Text(
                  'SETUJUI',
                  style: AppTextStyles.interStatus.copyWith(
                    color: locked
                        ? AppColors.textDisabled
                        : AppColors.buttonText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );

      case WinnerClaimStatus.sudahVerifikasi:
        // Sudah diverifikasi admin: tombol non-aktif "Data Tervalidasi".
        return _doneBar(
          icon: Icons.verified,
          text: 'DATA TERVALIDASI',
          color: AppColors.success,
        );

      case WinnerClaimStatus.ditolak:
        return _doneBar(
          icon: Icons.block,
          text: 'KLAIM DITOLAK',
          color: AppColors.error,
        );

      case WinnerClaimStatus.sedangDicairkan:
        // Sudah diteruskan ke owner.
        return _doneBar(
          icon: Icons.payments_outlined,
          text: 'SEDANG DICAIRKAN OLEH OWNER',
          color: _kTeal,
        );
    }
  }

  Widget _doneBar({
    required IconData icon,
    required String text,
    required Color color,
  }) {
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
          Text(
            text,
            style: AppTextStyles.interStatus.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHIP STATUS PEMENANG
// ============================================================
class _StatusChip extends StatelessWidget {
  final WinnerClaimStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    switch (status) {
      case WinnerClaimStatus.belumVerifikasi:
        color = AppColors.warning;
        break;
      case WinnerClaimStatus.sudahVerifikasi:
        color = AppColors.success;
        break;
      case WinnerClaimStatus.ditolak:
        color = AppColors.error;
        break;
      case WinnerClaimStatus.sedangDicairkan:
        color = _kTeal;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.interStatus.copyWith(color: color),
      ),
    );
  }
}

// ============================================================
// TIMELINE "RIWAYAT STATUS"
// ============================================================
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
            padding: const EdgeInsets.only(
              left: 4,
              bottom: AppConstants.paddingS,
            ),
            child: Text(
              'RIWAYAT STATUS',
              style: AppTextStyles.interCaption.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (int i = 0; i < entries.length; i++)
            _buildRow(entries[i], isLast: i == entries.length - 1),
        ],
      ),
    );
  }

  Widget _buildRow(TimelineEntry e, {required bool isLast}) {
    final Color dotColor = e.pending
        ? AppColors.warning
        : (e.done ? AppColors.success : AppColors.textDisabled);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garis + titik
          Column(
            children: [
              const SizedBox(height: 2),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1.5, color: AppColors.divider),
                ),
            ],
          ),
          const SizedBox(width: AppConstants.paddingS),
          // Teks
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 2 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.label,
                    style: AppTextStyles.interCaption.copyWith(
                      color: e.pending
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      fontWeight: e.pending ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (e.waktu != null)
                    Text(
                      e.waktu!,
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
    );
  }
}
