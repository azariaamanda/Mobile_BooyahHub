import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = true;
  Map<String, dynamic>? _akun;
  Map<String, dynamic>? _profil;
  Uint8List? _selectedFotoFile;

  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final userEmail = _supabase.sessionEmail;
      if (userEmail == null) throw Exception('Sesi habis');

      final akunData = await _supabase
          .from('akun')
          .select()
          .eq('email', userEmail)
          .single();
      _akun = akunData;

      final profilData = await _supabase
          .from('profil_admin')
          .select()
          .eq('akun_id', akunData['id_akun'])
          .maybeSingle();

      if (profilData != null) {
        _profil = profilData;
        _namaController.text = profilData['nama_lengkap'] ?? '';
        _emailController.text = akunData['email'] ?? '';
        _noHpController.text = profilData['no_handphone'] ?? '';
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadFotoProfil(Uint8List imageBytes, int akunId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'admin/${akunId}_avatar_$timestamp.jpg';

      await _supabase.storage.from('foto_profil').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(upsert: true),
      );
      
      final publicUrl = _supabase.storage.from('foto_profil').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _pickFoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _selectedFotoFile = bytes);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      // Upload foto profil jika ada perubahan
      if (_selectedFotoFile != null && _akun != null) {
        final fotoUrl = await _uploadFotoProfil(_selectedFotoFile!, _akun!['id_akun']);
        if (fotoUrl != null) {
          await _supabase
              .from('profil_admin')
              .update({'foto_profil': fotoUrl})
              .eq('akun_id', _akun!['id_akun']);
        }
      }
      
      // Update email di tabel akun
      await _supabase
          .from('akun')
          .update({'email': _emailController.text})
          .eq('id_akun', _akun!['id_akun']);

      // Update profil admin
      await _supabase
          .from('profil_admin')
          .update({
            'nama_lengkap': _namaController.text,
            'no_handphone': _noHpController.text,
          })
          .eq('akun_id', _akun!['id_akun']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(child: Text('Logout')),
        content: const Center(child: Text('Yakin ingin logout?')),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Batal', style: AppTextStyles.interLabel),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Logout', style: AppTextStyles.poppinsButton.copyWith(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.auth.signOut();
      if (mounted) context.go('/login');
    }
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final namaLengkap = _profil?['nama_lengkap'] ?? 'Admin';
    final initial = namaLengkap.isNotEmpty ? namaLengkap[0].toUpperCase() : 'A';
    final fotoUrl = _profil?['foto_profil'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profil', style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.primary)),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          children: [
            // Header Profile dengan GestureDetector untuk ganti foto
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickFoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          backgroundImage: _selectedFotoFile != null
                              ? MemoryImage(_selectedFotoFile!)
                              : (_isValidImageUrl(fotoUrl) ? NetworkImage(fotoUrl) : null),
                          child: _selectedFotoFile == null && !_isValidImageUrl(fotoUrl)
                              ? Text(
                                  initial,
                                  style: AppTextStyles.poppinsHeadline.copyWith(
                                    fontSize: 40,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    namaLengkap,
                    style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ADMIN',
                      style: AppTextStyles.interLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Form Edit Profile
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full Name', style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _namaController,
                    style: AppTextStyles.interInput,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama lengkap',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Email Address', style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    style: AppTextStyles.interInput,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Masukkan email',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('No Handphone', style: AppTextStyles.interLabel.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noHpController,
                    style: AppTextStyles.interInput,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nomor handphone',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('SIMPAN PERUBAHAN', style: AppTextStyles.poppinsButton),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ubah Password Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ubah Password', style: AppTextStyles.poppinsTitleSmall),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigasi ke halaman ubah password
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('UBAH PASSWORD', style: AppTextStyles.poppinsButton.copyWith(color: AppColors.primary)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Logout Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error, width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text('Logout', style: AppTextStyles.poppinsButton.copyWith(color: AppColors.error, fontSize: 15)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}