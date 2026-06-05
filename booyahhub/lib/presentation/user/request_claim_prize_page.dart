import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class RequestClaimPrizePage extends StatefulWidget {
  final String title;
  final String rank;
  final String totalPrize;
  final int? pendaftaranId; // ID Pendaftaran Tim

  const RequestClaimPrizePage({
    super.key,
    required this.title,
    required this.rank,
    required this.totalPrize,
    this.pendaftaranId,
  });

  @override
  State<RequestClaimPrizePage> createState() => _RequestClaimPrizePageState();
}

class _RequestClaimPrizePageState extends State<RequestClaimPrizePage> {
  final _formKey = GlobalKey<FormState>();
  final _bankController = TextEditingController();
  final _rekeningController = TextEditingController();
  final _namaPemilikController = TextEditingController();
  final _ewalletController = TextEditingController();
  final _noHpController = TextEditingController();
  
  bool _isBankSelected = true;
  bool _isLoading = false;

  final List<String> _bankOptions = [
    'BCA',
    'BNI',
    'BRI',
    'Mandiri',
    'BSI',
    'DANA',
    'OVO',
    'GoPay',
    'ShopeePay'
  ];
  String? _selectedBank;

  @override
  void dispose() {
    _rekeningController.dispose();
    _namaPemilikController.dispose();
    _noHpController.dispose();
    super.dispose();
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
          'Ajukan Klaim Hadiah',
          style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Top Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CONGRATULATIONS',
                                style: AppTextStyles.interCaption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.title,
                                style: AppTextStyles.poppinsHeadline.copyWith(
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.rank.toUpperCase(),
                            style: AppTextStyles.interCaption.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, thickness: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Hadiah', style: AppTextStyles.interCaption),
                            const SizedBox(height: 4),
                            Text(
                              widget.totalPrize,
                              style: AppTextStyles.poppinsMoneyLarge.copyWith(
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.emoji_events,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Metode Pencairan',
                style: AppTextStyles.poppinsTitleSmall,
              ),
              const SizedBox(height: 16),
              
              // Toggle Buttons
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info, width: 2), // Blue border for active look as in design
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isBankSelected = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isBankSelected ? AppColors.backgroundInput : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance,
                                color: _isBankSelected ? AppColors.primary : AppColors.textHint,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rekening Bank',
                                style: AppTextStyles.interBodyMedium.copyWith(
                                  color: _isBankSelected ? AppColors.white : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isBankSelected = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_isBankSelected ? AppColors.backgroundInput : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2,
                                color: !_isBankSelected ? AppColors.primary : AppColors.textHint,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'QRIS',
                                style: AppTextStyles.interBodyMedium.copyWith(
                                  color: !_isBankSelected ? AppColors.white : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Form Fields
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isBankSelected) ...[
                      // Dropdown Pilih Bank
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Bank / E-Wallet',
                            style: AppTextStyles.interLabel.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundInput,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: _selectedBank,
                                hint: Text(
                                  'BCA / BNI / DANA / OVO...',
                                  style: AppTextStyles.interHint.copyWith(color: AppColors.textHint),
                                ),
                                dropdownColor: AppColors.backgroundCard,
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint),
                                decoration: const InputDecoration(border: InputBorder.none),
                                style: AppTextStyles.interInput,
                                items: _bankOptions.map((String bank) {
                                  return DropdownMenuItem<String>(
                                    value: bank,
                                    child: Text(bank),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedBank = newValue;
                                  });
                                },
                                validator: (value) => value == null ? 'Wajib dipilih' : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _rekeningController,
                        label: 'Nomor Rekening',
                        hint: '80003289843298',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _namaPemilikController,
                        label: 'Nama Pemilik Rekening',
                        hint: 'Nama Sesuai di Buku Tabungan',
                      ),
                    ] else ...[
                      _buildInputField(
                        controller: _noHpController,
                        label: 'Nomor Handphone Terdaftar',
                        hint: '081234567890',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _namaPemilikController,
                        label: 'Nama Pemilik QRIS',
                        hint: 'Nama Merchant QRIS / Pemilik',
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Warning Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catatan Penting',
                            style: AppTextStyles.interBodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Proses verifikasi klaim membutuhkan waktu maksimal 2 x 24 jam hari kerja. Pastikan data rekening yang anda masukkan sudah benar',
                            style: AppTextStyles.interCaption.copyWith(
                              color: AppColors.textHint,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
                      )
                    : Text(
                        'Kirim Pengajuan',
                        style: AppTextStyles.poppinsButton.copyWith(
                          color: AppColors.black,
                          fontSize: 18,
                        ),
                      ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.pendaftaranId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID Pendaftaran tidak ditemukan'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Membersihkan format Rp
      final double totalPrizeValue = double.tryParse(widget.totalPrize.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      await Supabase.instance.client.from('klaim_hadiah').insert({
        'id_pendaftaran': widget.pendaftaranId,
        'jumlah_klaim': totalPrizeValue,
        'status_klaim': 'diajukan',
        'metode_klaim': _isBankSelected ? 'bank_transfer' : 'qris',
        'nama_bank': _isBankSelected ? _selectedBank : null,
        'nomor_rekening': _isBankSelected ? _rekeningController.text : _noHpController.text,
        'nama_pemilik_rekening': _namaPemilikController.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klaim berhasil diajukan!'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop(); // Tutup page Request
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan klaim: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isDropdown = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.interLabel.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.backgroundInput,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            enabled: !isDropdown, // Asumsi sederhana
            keyboardType: keyboardType,
            style: AppTextStyles.interInput,
            validator: (value) {
              if (!isDropdown && (value == null || value.trim().isEmpty)) {
                return 'Wajib diisi';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.interHint.copyWith(
                color: isDropdown ? AppColors.white : AppColors.textHint,
              ),
              border: InputBorder.none,
              suffixIcon: isDropdown
                  ? const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
