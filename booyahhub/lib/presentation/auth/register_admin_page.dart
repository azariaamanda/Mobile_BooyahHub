import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class RegisterAdminPage extends StatefulWidget {
  const RegisterAdminPage({super.key});

  @override
  State<RegisterAdminPage> createState() => _RegisterAdminPageState();
}

class _RegisterAdminPageState extends State<RegisterAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiPasswordController = TextEditingController();

  // State
  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;
  bool _isLoading = false;
  bool _setujuiSyarat = false;

  // Image bytes (cross-platform, works on web)
  Uint8List? _logoBytes;
  Uint8List? _ktpBytes;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _passwordController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // UPLOAD FILE KE SUPABASE STORAGE
  // ============================================================
  Future<String?> _uploadFileToStorage(Uint8List bytes, String folder, String fileName) async {
    try {
      final supabase = Supabase.instance.client;
      final path = '$folder/$fileName';

      await supabase.storage.from('foto_profil').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      
      final publicUrl = supabase.storage.from('foto_profil').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================
  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _logoBytes = bytes);
    }
  }

  Future<void> _pickKTP() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _ktpBytes = bytes);
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ktpBytes == null) {
      _showSnackBar('Foto KTP wajib diunggah', isError: true);
      return;
    }

    if (!_setujuiSyarat) {
      _showSnackBar('Anda harus menyetujui syarat & ketentuan', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      
      // 1. Register ke Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (authResponse.user == null) {
        throw Exception('Gagal registrasi akun');
      }
      
      // 2. Insert ke tabel akun
      final akunResponse = await supabase
          .from('akun')
          .insert({
            'email': _emailController.text.trim(),
            'role': 'admin',
            'status_akun': 'pending',
          })
          .select('id_akun')
          .single();
      
      final int akunId = akunResponse['id_akun'];
      
      // 3. Upload foto profil (logo) ke Supabase Storage
      String? fotoProfilUrl;
      if (_logoBytes != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'admin_${akunId}_logo_$timestamp.jpg';
        fotoProfilUrl = await _uploadFileToStorage(_logoBytes!, 'admin', fileName);
      }
      
      // 4. Upload foto KTP ke Supabase Storage
      final ktpTimestamp = DateTime.now().millisecondsSinceEpoch;
      final ktpFileName = 'admin_${akunId}_ktp_$ktpTimestamp.jpg';
      final fotoKtpUrl = await _uploadFileToStorage(_ktpBytes!, 'admin', ktpFileName);
      
      if (fotoKtpUrl == null) {
        throw Exception('Gagal upload foto KTP');
      }
      
      // 5. Insert ke tabel profil_admin
      await supabase.from('profil_admin').insert({
        'akun_id': akunId,
        'nama_lengkap': _namaController.text.trim(),
        'no_handphone': _noHpController.text.trim(),
        'foto_profil': fotoProfilUrl,
        'foto_ktp': fotoKtpUrl,
        'status_verifikasi_ktp': 'pending',
      });
      
      _showSnackBar('Pendaftaran admin berhasil! Menunggu verifikasi owner.');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');
      
    } catch (e) {
      _showSnackBar('Gagal mendaftar: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // UI HELPERS
  // ============================================================
  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AppTextStyles.interLabel.copyWith(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.interHint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.backgroundInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: 14,
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.poppinsTitleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'BOOYAHHUB',
          style: AppTextStyles.poppinsTitle.copyWith(
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.primary.withOpacity(0.4),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingM),

              Text(
                'Pendaftaran\nPenyelenggara',
                style: AppTextStyles.poppinsHeadline.copyWith(
                  fontSize: 28,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bergabunglah dengan ekosistem e-sports profesional terbesar.',
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Seksi 1: Informasi Akun
              _sectionCard(
                title: 'Informasi Akun',
                icon: Icons.person_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('NAMA LENGKAP'),
                    TextFormField(
                      controller: _namaController,
                      style: AppTextStyles.interInput,
                      decoration: _inputDecoration(hint: 'Masukkan nama'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: AppConstants.paddingM),

                    _fieldLabel('EMAIL'),
                    TextFormField(
                      controller: _emailController,
                      style: AppTextStyles.interInput,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(hint: '@gmail.com'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!v.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingM),

                    _fieldLabel('NO HANDPHONE'),
                    TextFormField(
                      controller: _noHpController,
                      style: AppTextStyles.interInput,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(hint: '+62 812...'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'No. HP wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: AppConstants.paddingM),

                    _fieldLabel('PASSWORD'),
                    TextFormField(
                      controller: _passwordController,
                      style: AppTextStyles.interInput,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.inputIcon,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password wajib diisi';
                        }
                        if (v.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingM),

                    _fieldLabel('KONFIRMASI PASSWORD'),
                    TextFormField(
                      controller: _konfirmasiPasswordController,
                      style: AppTextStyles.interInput,
                      obscureText: _obscureKonfirmasi,
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureKonfirmasi
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.inputIcon,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureKonfirmasi = !_obscureKonfirmasi,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Konfirmasi password wajib diisi';
                        }
                        if (v != _passwordController.text) {
                          return 'Password tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingM),

                    // Upload Logo
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundInput,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusM,
                          ),
                          border: Border.all(
                            color: _logoBytes != null
                                ? AppColors.primary
                                : AppColors.inputBorder,
                            width: 1.5,
                          ),
                        ),
                        child: _logoBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusM,
                                ),
                                child: Image.memory(
                                  _logoBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 100,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'UPLOAD LOGO',
                                    style: AppTextStyles.interLabel.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Format: JPG, PNG (Max. 2MB)',
                                    style: AppTextStyles.interCaption.copyWith(
                                      color: AppColors.textHint,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingM),

              // Seksi 2: Verifikasi Identitas
              _sectionCard(
                title: 'Verifikasi Identitas',
                icon: Icons.verified_user_outlined,
                child: GestureDetector(
                  onTap: _pickKTP,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingL,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundInput,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(
                        color: _ktpBytes != null
                            ? AppColors.primary
                            : AppColors.inputBorder,
                        width: 1,
                      ),
                    ),
                    child: _ktpBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusM,
                            ),
                            child: Image.memory(
                              _ktpBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                            ),
                          )
                        : Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.insert_drive_file_outlined,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: AppConstants.paddingM),
                              Text(
                                'Unggah Foto KTP',
                                style: AppTextStyles.poppinsTitleSmall.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pastikan seluruh bagian KTP terlihat jelas',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.interCaption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppConstants.paddingM),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.paddingL,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusM,
                                  ),
                                ),
                                child: Text(
                                  'PILIH FILE',
                                  style: AppTextStyles.poppinsButton.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingM),

              // Checkbox Syarat & Ketentuan
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _setujuiSyarat,
                      onChanged: (v) => setState(() => _setujuiSyarat = v!),
                      activeColor: AppColors.primary,
                      checkColor: AppColors.background,
                      side: BorderSide(
                        color: AppColors.inputBorder,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.interBody.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Saya menyetujui '),
                          TextSpan(
                            text: 'Syarat & Ketentuan',
                            style: AppTextStyles.interLink.copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' serta '),
                          TextSpan(
                            text: 'Kebijakan Privasi',
                            style: AppTextStyles.interLink.copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(
                            text: ' BooyahHub sebagai Penyelenggara resmi.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingXL),
            ],
          ),
        ),
      ),

      // Tombol Daftar
      bottomNavigationBar: Container(
        color: AppColors.background,
        padding: EdgeInsets.fromLTRB(
          AppConstants.paddingM,
          AppConstants.paddingM,
          AppConstants.paddingM,
          MediaQuery.of(context).padding.bottom + AppConstants.paddingM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.background,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Daftar',
                            style: AppTextStyles.poppinsButton.copyWith(
                              color: AppColors.background,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: AppColors.background,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sudah punya akun? ',
                  style: AppTextStyles.interBody.copyWith(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    'Login',
                    style: AppTextStyles.interLink.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}