// lib/presentation/admin/participant_detail_page.dart
//
// Layar "Detail Peserta" — admin meninjau bukti pembayaran satu tim,
// lalu menekan Konfirmasi / Tolak Pembayaran.

import 'package:flutter/material.dart';

import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/peserta_verifikasi_model.dart';
import 'validate_payment_page.dart' show StatusBadge;

class ParticipantDetailPage extends StatefulWidget {
  final PesertaVerifikasi peserta;

  const ParticipantDetailPage({super.key, required this.peserta});

  @override
  State<ParticipantDetailPage> createState() => _ParticipantDetailPageState();
}

class _ParticipantDetailPageState extends State<ParticipantDetailPage> {
  late PesertaVerifikasi _peserta = widget.peserta;
  bool _processing = false;

  bool get _sudahDiproses => _peserta.status != StatusPeserta.menunggu;

  // ---- Aksi admin -------------------------------------------------
  Future<void> _ubahStatus(StatusPeserta status) async {
    setState(() => _processing = true);
    // TODO: panggil Supabase update di sini.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _peserta = _peserta.copyWith(status: status);
      _processing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: status == StatusPeserta.dikonfirmasi
            ? AppColors.success
            : AppColors.error,
        content: Text(
          status == StatusPeserta.dikonfirmasi
              ? 'Pembayaran ${_peserta.namaTim} dikonfirmasi'
              : 'Pembayaran ${_peserta.namaTim} ditolak',
        ),
      ),
    );
  }

  void _konfirmasi() => _ubahStatus(StatusPeserta.dikonfirmasi);

  void _tolak() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Tolak Pembayaran?', style: AppTextStyles.poppinsTitleSmall),
        content: Text(
          'Pembayaran ${_peserta.namaTim} akan ditandai ditolak.',
          style: AppTextStyles.interBody,
        ),
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
              _ubahStatus(StatusPeserta.ditolak);
            },
            child: Text('Tolak',
                style: AppTextStyles.interLabel
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _lihatBukti() {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppConstants.paddingM),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: _ReceiptPlaceholder(height: 420),
          ),
        ),
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
                    _sectionLabel('INFORMASI TIM'),
                    _buildTeamCard(),
                    const SizedBox(height: AppConstants.paddingL),
                    _sectionLabel('INFORMASI BOOKING'),
                    _buildBookingGrid(),
                    const SizedBox(height: AppConstants.paddingL),
                    _sectionLabel('BUKTI PEMBAYARAN'),
                    _buildBuktiPembayaran(),
                    const SizedBox(height: AppConstants.paddingL),
                    _sectionLabel('DETAIL TRANSAKSI'),
                    _buildTransaksiCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
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
            onPressed: () =>
                Navigator.of(context).pop<PesertaVerifikasi>(_peserta),
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          Text(
            'Detail Peserta',
            style: AppTextStyles.poppinsTitleSmall
                .copyWith(color: AppColors.primary),
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

  // ===================== KARTU TIM =====================
  Widget _buildTeamCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: const Icon(Icons.groups_rounded,
                    color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_peserta.namaTim,
                        style: AppTextStyles.poppinsTitleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Captain: ${_peserta.namaKapten}',
                      style: AppTextStyles.interCaption,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: _peserta.status),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppConstants.paddingM),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            children: [
              Icon(Icons.phone_outlined,
                  size: 16, color: AppColors.textHint),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Text(
                  _peserta.whatsappKapten,
                  style: AppTextStyles.interBodyMedium
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka WhatsApp...')),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingM, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusXL),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'Hubungi WA',
                        style: AppTextStyles.interStatus
                            .copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== GRID BOOKING =====================
  Widget _buildBookingGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _infoBox('Nama Scrim', _peserta.namaScrim)),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: _infoBox('Slot ID', _peserta.slotId,
                  valueColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          children: [
            Expanded(child: _infoBox('Tanggal', _peserta.tanggal)),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(child: _infoBox('Waktu', _peserta.waktu)),
          ],
        ),
      ],
    );
  }

  Widget _infoBox(String label, String value, {Color? valueColor}) {
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
          Text(label, style: AppTextStyles.interCaption),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.interBodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== BUKTI PEMBAYARAN =====================
  Widget _buildBuktiPembayaran() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: _ReceiptPlaceholder(height: 200),
        ),
        Positioned(
          right: AppConstants.paddingM,
          bottom: AppConstants.paddingM,
          child: GestureDetector(
            onTap: _lihatBukti,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.85),
                borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Perbesar',
                    style: AppTextStyles.interStatus
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== DETAIL TRANSAKSI =====================
  Widget _buildTransaksiCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nominal', style: AppTextStyles.interBody),
              Text(_peserta.nominalFormatted,
                  style: AppTextStyles.poppinsMoney),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppConstants.paddingM),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            children: [
              Expanded(
                child: _txInfo('Bank Pengirim', _peserta.bankPengirim),
              ),
              Expanded(
                child: _txInfo('Nama Pengirim', _peserta.namaPengirim,
                    alignEnd: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _txInfo(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.interCaption),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.interBodyMedium
              .copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  // ===================== TOMBOL AKSI =====================
  Widget _buildActionButtons() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: _sudahDiproses
            ? _statusBanner()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: AppConstants.buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: _processing ? null : _konfirmasi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        disabledBackgroundColor:
                            AppColors.buttonPrimaryDisabled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.radiusM),
                        ),
                      ),
                      icon: _processing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.buttonText,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline,
                              color: AppColors.buttonText, size: 20),
                      label: Text('Konfirmasi Pembayaran',
                          style: AppTextStyles.poppinsButton),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  SizedBox(
                    width: double.infinity,
                    height: AppConstants.buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _tolak,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.radiusM),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_outlined,
                          color: AppColors.error, size: 20),
                      label: Text(
                        'Tolak Pembayaran',
                        style: AppTextStyles.poppinsButton
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statusBanner() {
    final dikonfirmasi = _peserta.status == StatusPeserta.dikonfirmasi;
    final color = dikonfirmasi ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(dikonfirmasi ? Icons.verified : Icons.block,
              color: color, size: 20),
          const SizedBox(width: AppConstants.paddingS),
          Text(
            dikonfirmasi
                ? 'Pembayaran sudah dikonfirmasi'
                : 'Pembayaran ditolak',
            style: AppTextStyles.poppinsButton.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  // ===================== HELPER KARTU =====================
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

// ============================================================
// PLACEHOLDER STRUK — ganti dengan Image.network(buktiPembayaranUrl)
// ============================================================
class _ReceiptPlaceholder extends StatelessWidget {
  final double height;
  const _ReceiptPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long,
              size: height * 0.28, color: AppColors.textDisabled),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            'Bukti Pembayaran',
            style: AppTextStyles.interCaption
                .copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}
