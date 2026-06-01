import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class RequestClaimPrizePage extends StatefulWidget {
  final String title;
  final String rank;
  final String totalPrize;

  const RequestClaimPrizePage({
    super.key,
    required this.title,
    required this.rank,
    required this.totalPrize,
  });

  @override
  State<RequestClaimPrizePage> createState() => _RequestClaimPrizePageState();
}

class _RequestClaimPrizePageState extends State<RequestClaimPrizePage> {
  bool _isBankSelected = true;

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
                                Icons.account_balance_wallet,
                                color: !_isBankSelected ? AppColors.primary : AppColors.textHint,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'E - Wallet',
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
              if (_isBankSelected) ...[
                _buildInputField(
                  label: 'Pilih Bank',
                  hint: 'BCA - Bank Central Asia',
                  isDropdown: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Nomor Rekening',
                  hint: '80003289843298',
                  hasCheck: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Nama Pemilik Rekening',
                  hint: 'Nama Sesuai di Buku Tabungan',
                ),
              ] else ...[
                _buildInputField(
                  label: 'Pilih E-Wallet',
                  hint: 'OVO / GoPay / DANA',
                  isDropdown: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Nomor HP',
                  hint: '081234567890',
                  hasCheck: true,
                ),
              ],
              
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
                  onPressed: () {
                    // TODO: Handle submission
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
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

  Widget _buildInputField({
    required String label,
    required String hint,
    bool isDropdown = false,
    bool hasCheck = false,
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
            enabled: !isDropdown,
            style: AppTextStyles.interInput,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.interHint.copyWith(
                color: isDropdown || hasCheck ? AppColors.white : AppColors.textHint,
              ),
              border: InputBorder.none,
              suffixIcon: isDropdown
                  ? const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint)
                  : (hasCheck ? const Icon(Icons.check, color: AppColors.success, size: 20) : null),
            ),
          ),
        ),
      ],
    );
  }
}
