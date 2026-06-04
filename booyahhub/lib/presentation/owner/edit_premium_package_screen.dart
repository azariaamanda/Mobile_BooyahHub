import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class EditPremiumPackageScreen extends StatelessWidget {
  const EditPremiumPackageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFD700)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Paket Premium',
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: const Color(0xFFFFD700),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarningAlert(),
            const SizedBox(height: 24),
            _buildLabel('NAMA PAKET PREMIUM'),
            _buildTextField('Elite Commander'),
            const SizedBox(height: 24),
            _buildLabel('FITUR PAKET'),
            _buildFeatureItem(title: 'Dukungan Support', isChecked: true),
            const SizedBox(height: 12),
            _buildFeatureItem(title: 'Sorotan Spanduk', isChecked: true),
            const SizedBox(height: 12),
            _buildFeatureItem(title: 'Analitik Tingkat Lanjut', isChecked: true),
            const SizedBox(height: 12),
            _buildFeatureItem(title: 'Lencana Eksklusif', isChecked: false),
            const SizedBox(height: 24),
            _buildLabel('HARGA (RP)'),
            _buildPriceField(),
            const SizedBox(height: 24),
            _buildLabel('DURASI PAKET'),
            _buildDropdownField('3 bulan'),
            const SizedBox(height: 24),
            _buildStatusSwitch(),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A191B), // Dark reddish brown
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF8B4747),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.priority_high_rounded, color: Color(0xFF2A191B), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peringatan Transaksi',
                  style: AppTextStyles.interBody.copyWith(
                    color: const Color(0xFFD67777),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mohon lengkapi semua field yang diperlukan sebelum menyimpan perubahan',
                  style: AppTextStyles.interCaption.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: AppTextStyles.interCaption.copyWith(
          color: const Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField(String initialValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        initialValue,
        style: AppTextStyles.interBody.copyWith(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required String title, required bool isChecked}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isChecked ? const Color(0xFFFFD700) : Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.interBody.copyWith(
                color: isChecked ? Colors.white : Colors.white54,
                fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
          if (isChecked)
            const Icon(Icons.check_rounded, color: Color(0xFFFFD700), size: 18),
        ],
      ),
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF131F2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Text(
                'Rp',
                style: AppTextStyles.interBody.copyWith(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '99.000',
                  style: AppTextStyles.interBody.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PER PERIODE',
                  style: AppTextStyles.interCaption.copyWith(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
            const SizedBox(width: 6),
            Text(
              'harga tidak valid',
              style: AppTextStyles.interCaption.copyWith(
                color: Colors.redAccent,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: AppTextStyles.interBody.copyWith(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFFD700)),
        ],
      ),
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Paket',
                  style: AppTextStyles.interBody.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'tentukan visibilitas paket di beranda',
                  style: AppTextStyles.interCaption.copyWith(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 24,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F1722),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AKTIF',
                style: AppTextStyles.interCaption.copyWith(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'SIMPAN PAKET',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F1722),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'BATAL',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
