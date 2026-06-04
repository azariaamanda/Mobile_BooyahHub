import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 40),
            _buildPersonalDetailsSection(),
            const SizedBox(height: 32),
            _buildSecuritySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 3),
                image: const DecorationImage(
                  image: NetworkImage('https://i.pravatar.cc/300'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: Colors.black, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'AKU OWNER',
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'LEAD CLAN HOLDER',
          style: AppTextStyles.interCaption.copyWith(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Details',
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: const Color(0xFFFFD700),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF131F2D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildDetailItem(
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                value: 'Alok',
              ),
              const SizedBox(height: 24),
              _buildDetailItem(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: 'Alok@gmail.com',
              ),
              const SizedBox(height: 24),
              _buildDetailItem(
                icon: Icons.phone_rounded,
                label: 'Telepon',
                value: '+62 81283231731',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white54, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.interCaption.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.interBody.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security',
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: const Color(0xFFFFD700),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField('Password'),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.update_rounded, color: Color(0xFFFFD700), size: 12),
            ),
            const SizedBox(width: 8),
            Text(
              'Update security password',
              style: AppTextStyles.interCaption.copyWith(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField('New Password'),
      ],
    );
  }

  Widget _buildTextField(String hint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1722),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        hint,
        style: AppTextStyles.interBody.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
