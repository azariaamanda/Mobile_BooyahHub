import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploading = false;
  
  Map<String, dynamic>? _akunData;
  Map<String, dynamic>? _profilData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final data = await _authService.getCurrentAkunAndProfil();
    if (data != null && mounted) {
      setState(() {
        _akunData = data['akun'].toJson(); // Assume it has toJson()
        _profilData = data['profil'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadFoto() async {
    if (_akunData == null) return;
    final String akunId = _akunData!['id_akun'].toString();

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$akunId.jpg';

      // 1. Upload ke Storage
      await _supabase.storage.from('foto_profil').uploadBinary('owner/$fileName', bytes);
      
      // 2. Dapatkan Public URL
      final publicUrl = _supabase.storage.from('foto_profil').getPublicUrl('owner/$fileName');

      // 3. Update profil_owner table
      await _supabase
          .from('profil_owner')
          .update({'foto_profil': publicUrl})
          .eq('akun_id', int.parse(akunId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }

      // Reload profile
      await _loadProfile();

    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengupload foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : SingleChildScrollView(
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
    final fotoUrl = _profilData?['foto_profil'] as String?;
    final name = _profilData?['nama_lengkap'] ?? 'Loading...';

    return Column(
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUploadFoto,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD700), width: 3),
                  color: AppColors.backgroundInput,
                  image: fotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(fotoUrl),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: NetworkImage('https://i.pravatar.cc/300'),
                          fit: BoxFit.cover,
                        ),
                ),
                child: _isUploading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                  : null,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.black, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name.toUpperCase(),
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
    final name = _profilData?['nama_lengkap'] ?? '-';
    final phone = _profilData?['no_handphone'] ?? '-';
    final email = _akunData?['email'] ?? '-';

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
                value: name,
              ),
              const SizedBox(height: 24),
              _buildDetailItem(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: email,
              ),
              const SizedBox(height: 24),
              _buildDetailItem(
                icon: Icons.phone_rounded,
                label: 'Telepon',
                value: phone,
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
