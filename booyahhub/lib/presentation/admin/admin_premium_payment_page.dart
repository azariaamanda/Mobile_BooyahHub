import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/paket_premium_model.dart';

class AdminPremiumPaymentPage extends StatefulWidget {
  final PaketPremiumModel paket;
  const AdminPremiumPaymentPage({super.key, required this.paket});

  @override
  State<AdminPremiumPaymentPage> createState() => _AdminPremiumPaymentPageState();
}

class _AdminPremiumPaymentPageState extends State<AdminPremiumPaymentPage> {
  final _supabase = Supabase.instance.client;
  Uint8List? _buktiBytes;
  bool _isSubmitting = false;

  // 0 = QRIS, 1 = Transfer Bank
  int _selectedMethod = 0;
  int _selectedBankIndex = 0;

  static const _banks = [
    {
      'nama': 'BCA',
      'norek': '0022000A1A26',
      'atas_nama': 'BooyahHub Official',
    },
    {
      'nama': 'BRI',
      'norek': '0022-01-012345-56-7',
      'atas_nama': 'BooyahHub Official',
    },
    {
      'nama': 'BNI',
      'norek': '0123456789',
      'atas_nama': 'BooyahHub Official',
    },
    {
      'nama': 'Mandiri',
      'norek': '1100012345678',
      'atas_nama': 'BooyahHub Official',
    },
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _buktiBytes = bytes);
    }
  }

  Future<void> _kirimPembayaran() async {
    if (_buktiBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan unggah bukti pembayaran terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final email = _supabase.sessionEmail;
      if (email == null) throw Exception('Sesi habis, silakan login ulang.');

      final akun = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', email)
          .single();
      final akunId = akun['id_akun'] as int;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'premium/bukti_${akunId}_$timestamp.jpg';
      await _supabase.storage
          .from('bukti_bayar')
          .uploadBinary(filePath, _buktiBytes!);

      await _supabase.from('transaksi_premium').insert({
        'akun_id': akunId,
        'nama_paket': widget.paket.namaPaket,
        'harga': widget.paket.harga,
        'durasi_hari': widget.paket.durasiHari ?? 30,
        'tier_level': widget.paket.tierLevel,
        'status': 'menunggu',
        'bukti_pembayaran': filePath,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti pembayaran terkirim! Menunggu verifikasi owner.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatRupiah(dynamic val) {
    if (val == null) return 'Rp 0';
    final int v = val is int ? val : (val as num).toInt();
    return 'Rp ${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pembayaran Premium',
          style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ringkasan paket ────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ringkasan Paket', style: AppTextStyles.poppinsTitleSmall),
                  const SizedBox(height: 12),
                  _row('Paket', widget.paket.namaPaket),
                  _row('Tier', widget.paket.tierLabel),
                  _row('Durasi', widget.paket.formattedDurasi),
                  Divider(color: AppColors.divider, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: AppTextStyles.interBody
                              .copyWith(color: AppColors.textSecondary)),
                      Text(
                        _formatRupiah(widget.paket.harga),
                        style: AppTextStyles.poppinsMoneyLarge.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Pilih metode ───────────────────────────────────────────
            Text('Metode Pembayaran', style: AppTextStyles.poppinsTitleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _methodCard(0, Icons.qr_code_2_rounded, 'QRIS')),
                const SizedBox(width: 12),
                Expanded(child: _methodCard(1, Icons.account_balance_rounded, 'Transfer Bank')),
              ],
            ),
            const SizedBox(height: 20),

            // ── Konten metode terpilih ─────────────────────────────────
            if (_selectedMethod == 0) _buildQrisSection(),
            if (_selectedMethod == 1) _buildBankSection(),

            const SizedBox(height: 20),

            // ── Upload bukti ───────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  border: Border.all(
                    color: _buktiBytes != null
                        ? AppColors.success
                        : AppColors.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _buktiBytes != null
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _buktiBytes != null
                            ? Icons.check_circle_rounded
                            : Icons.file_upload_outlined,
                        color: _buktiBytes != null ? AppColors.success : AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _buktiBytes != null
                          ? 'Bukti Terunggah — Ketuk untuk Ganti'
                          : 'Ketuk untuk Unggah Bukti Pembayaran',
                      style: AppTextStyles.interBody.copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    if (_buktiBytes != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        child: Image.memory(
                          _buktiBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Tombol kirim ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _kirimPembayaran,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text('Kirim Bukti Pembayaran', style: AppTextStyles.poppinsButton),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Method selector card ─────────────────────────────────────────────
  Widget _methodCard(int index, IconData icon, String label) {
    final bool selected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.inputBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.interBody.copyWith(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── QRIS section ─────────────────────────────────────────────────────
  Widget _buildQrisSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scan QRIS', style: AppTextStyles.poppinsTitleSmall),
          const SizedBox(height: 4),
          Text(
            'A/N BooyahHub Official',
            style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2_rounded, size: 120, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Scan QR di atas menggunakan\naplikasi mobile banking atau e-wallet',
              style: AppTextStyles.interCaption
                  .copyWith(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Text(
              'Nominal: ${_formatRupiah(widget.paket.harga)}',
              style: AppTextStyles.poppinsTitle.copyWith(
                fontSize: 16,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bank transfer section ─────────────────────────────────────────────
  Widget _buildBankSection() {
    final bank = _banks[_selectedBankIndex];
    final norek = bank['norek']!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pilih bank
        Text('Pilih Bank', style: AppTextStyles.poppinsTitleSmall),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_banks.length, (i) {
            final selected = _selectedBankIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedBankIndex = i),
                child: Container(
                  margin: EdgeInsets.only(right: i < _banks.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.inputBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    _banks[i]['nama']!,
                    style: AppTextStyles.interBody.copyWith(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // Detail rekening
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank ${bank['nama']}',
                style: AppTextStyles.interBody.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'A/N ${bank['atas_nama']}',
                style: AppTextStyles.interCaption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundInput,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        norek,
                        style: AppTextStyles.poppinsTitle.copyWith(
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: norek));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nomor rekening disalin'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Salin',
                          style: AppTextStyles.interCaption.copyWith(
                            color: AppColors.buttonText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transfer tepat sesuai nominal, lalu unggah bukti di bawah.',
                style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: child,
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.interBody
                  .copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.interBody),
        ],
      ),
    );
  }
}
