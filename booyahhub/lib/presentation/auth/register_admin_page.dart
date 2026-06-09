import 'dart:convert';
import 'package:crypto/crypto.dart';
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

  String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
  
  // Metode Pembayaran - BANK
  final _bankAccountController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  
  // Daftar Bank dari enum nama_bank_enum (BCA, BNI, BRI, Mandiri, BSI)
  final List<String> _bankList = [
    'BCA', 'BNI', 'BRI', 'Mandiri', 'BSI'
  ];
  String? _selectedBank;
  
  // Metode Pembayaran - QRIS
  Uint8List? _qrisBytes;

  // State
  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;
  bool _isLoading = false;
  bool _setujuiSyarat = false;
  
  // Payment method selection (bisa milih lebih dari satu)
  bool _pilihBank = false;
  bool _pilihQris = false;

  // Image bytes
  Uint8List? _logoBytes;
  Uint8List? _ktpBytes;

  // Untuk rollback
  String? _uploadedKtpPath;
  String? _uploadedLogoPath;
  String? _uploadedQrisPath;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _passwordController.dispose();
    _konfirmasiPasswordController.dispose();
    _bankAccountController.dispose();
    _bankAccountNameController.dispose();
    super.dispose();
  }

  // ============================================================
  // UPLOAD FILE KE SUPABASE STORAGE
  // ============================================================
  Future<String?> _uploadFileToStorage(Uint8List bytes, String bucket, String path) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Tentukan contentType berdasarkan ekstensi file
      String contentType = 'image/jpeg';
      if (path.endsWith('.png')) {
        contentType = 'image/png';
      } else if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (path.endsWith('.pdf')) {
        contentType = 'application/pdf';
      }
      
      await supabase.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );
      
      if (bucket == 'foto_profil' || bucket == 'posters') {
        return supabase.storage.from(bucket).getPublicUrl(path);
      } else {
        return path;
      }
    } catch (e) {
      debugPrint('Upload error to $bucket: $e');
      return null;
    }
  }

  // ============================================================
  // ROLLBACK: HAPUS FILE YANG SUDAH DIUPLOAD
  // ============================================================
  Future<void> _rollbackUploads() async {
    final supabase = Supabase.instance.client;
    
    if (_uploadedKtpPath != null) {
      try {
        await supabase.storage.from('ktp').remove([_uploadedKtpPath!]);
      } catch (_) {}
    }
    
    if (_uploadedLogoPath != null) {
      try {
        await supabase.storage.from('foto_profil').remove([_uploadedLogoPath!]);
      } catch (_) {}
    }
    
    if (_uploadedQrisPath != null) {
      try {
        await supabase.storage.from('qr_qris').remove([_uploadedQrisPath!]);
      } catch (_) {}
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

  Future<void> _pickQRIS() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _qrisBytes = bytes);
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

    if (!_pilihBank && !_pilihQris) {
      _showSnackBar('Pilih minimal 1 metode pembayaran (Bank atau QRIS)', isError: true);
      return;
    }

    if (_pilihBank) {
      if (_selectedBank == null ||
          _bankAccountController.text.trim().isEmpty ||
          _bankAccountNameController.text.trim().isEmpty) {
        _showSnackBar('Data rekening bank wajib diisi', isError: true);
        return;
      }
    }

    if (_pilihQris && _qrisBytes == null) {
      _showSnackBar('Gambar QRIS wajib diunggah', isError: true);
      return;
    }

    if (!_setujuiSyarat) {
      _showSnackBar('Anda harus menyetujui syarat & ketentuan', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Reset upload paths
    _uploadedKtpPath = null;
    _uploadedLogoPath = null;
    _uploadedQrisPath = null;

    try {
      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // ============================================================
      // STEP 1: CEK EMAIL SUDAH TERDAFTAR
      // ============================================================
      final existingAkun = await supabase
          .from('akun')
          .select('id_akun')
          .eq('email', email)
          .maybeSingle();
      
      if (existingAkun != null) {
        _showSnackBar('Email sudah terdaftar, silakan login', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      
      // ============================================================
      // STEP 2: REGISTER KE SUPABASE AUTH
      // ============================================================
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: _passwordController.text,
      );
      
      if (authResponse.user == null) {
        throw Exception('Gagal registrasi akun');
      }

      // ============================================================
      // STEP 3: UPLOAD KTP (PALING KRITIS)
      // ============================================================
      final ktpFileName = 'admin_${timestamp}_ktp.jpg';
      final ktpPath = 'admin/$ktpFileName';
      final fotoKtpPath = await _uploadFileToStorage(_ktpBytes!, 'ktp', ktpPath);
      
      if (fotoKtpPath == null) {
        throw Exception('Gagal upload foto KTP. Pastikan file gambar valid.');
      }
      _uploadedKtpPath = ktpPath;
      
      // ============================================================
      // STEP 4: UPLOAD LOGO (JIKA ADA)
      // ============================================================
      String? fotoProfilUrl;
      if (_logoBytes != null) {
        final logoFileName = 'admin_${timestamp}_logo.jpg';
        final logoPath = 'admin/$logoFileName';
        fotoProfilUrl = await _uploadFileToStorage(_logoBytes!, 'foto_profil', logoPath);
        if (fotoProfilUrl != null) {
          _uploadedLogoPath = logoPath;
        }
      }
      
      // ============================================================
      // STEP 5: UPLOAD QRIS (JIKA DIPILIH)
      // ============================================================
      String? qrisImagePath;
      if (_pilihQris && _qrisBytes != null) {
        final qrisFileName = 'admin/qris_${timestamp}.jpg';
        qrisImagePath = await _uploadFileToStorage(_qrisBytes!, 'qr_qris', qrisFileName);
        if (qrisImagePath != null) {
          _uploadedQrisPath = qrisFileName;
        }
      }
      
      // ============================================================
      // STEP 6: INSERT KE TABEL AKUN
      // ============================================================
      final hashedPassword = _hashPassword(_passwordController.text);

      final akunResponse = await supabase
          .from('akun')
          .insert({
            'email': email,
            'kata_sandi': hashedPassword, // Ganti _passwordController.text dengan hashedPassword
            'role': 'admin',
            'status_akun': 'pending',
            'status_metode_pembayaran': 'pending',
          })
          .select('id_akun')
          .single();
      
      final int akunId = akunResponse['id_akun'];
      
      // ============================================================
      // STEP 7: INSERT METODE PEMBAYARAN BANK
      // ============================================================
      int? primaryMetodeId;

      if (_pilihBank) {
        final bankRes = await supabase.from('metode_pembayaran_penyelenggara').insert({
          'akun_id': akunId,
          'role': 'admin',
          'jenis_metode': 'bank_transfer',
          'nama_bank': _selectedBank,
          'nomor_rekening': _bankAccountController.text.trim(),
          'nama_pemilik': _bankAccountNameController.text.trim(),
          'is_active': true,
        }).select('id_metode').single();
        primaryMetodeId = bankRes['id_metode'];
      }
      
      // ============================================================
      // STEP 8: INSERT METODE PEMBAYARAN QRIS
      // ============================================================
      if (_pilihQris && qrisImagePath != null) {
        final qrisRes = await supabase.from('metode_pembayaran_penyelenggara').insert({
          'akun_id': akunId,
          'role': 'admin',
          'jenis_metode': 'qris',
          'qris_image': qrisImagePath,
          'is_active': true,
        }).select('id_metode').single();
        
        // Jika bank tidak dipilih, jadikan QRIS sebagai metode utama
        primaryMetodeId ??= qrisRes['id_metode'];
      }

      // ============================================================
      // STEP 9: INSERT KE TABEL PROFIL_ADMIN
      // ============================================================
      await supabase.from('profil_admin').insert({
        'akun_id': akunId,
        'nama_lengkap': _namaController.text.trim(),
        'no_handphone': _noHpController.text.trim(),
        'foto_profil': fotoProfilUrl,
        'foto_ktp': ktpPath,
        'status_verifikasi_ktp': 'pending',
        if (primaryMetodeId != null) 'metode_pembayaran_id': primaryMetodeId,
      });
      
      _showSnackBar('Pendaftaran admin berhasil! Menunggu verifikasi owner.');
      
      await Future.delayed(const Duration(seconds: 2));
      await supabase.auth.signOut();
      
      if (mounted) context.go('/login');
      
    } catch (e) {
      debugPrint('Error: $e');
      
      // ROLLBACK: Hapus file yang sudah diupload
      await _rollbackUploads();
      
      _showSnackBar('Gagal mendaftar: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
  InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
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
                    Text(
                      'NAMA LENGKAP',
                      style: AppTextStyles.interLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaController,
                      style: AppTextStyles.interInput,
                      decoration: _inputDecoration(hint: 'Masukkan nama'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: AppConstants.paddingM),

                    Text(
                      'EMAIL',
                      style: AppTextStyles.interLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      style: AppTextStyles.interInput,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(hint: 'contoh@email.com'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!v.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingM),

                    Text(
                      'NO HANDPHONE',
                      style: AppTextStyles.interLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _noHpController,
                      style: AppTextStyles.interInput,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(hint: '081234567890'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'No. HP wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: AppConstants.paddingM),

                    Text(
                      'PASSWORD',
                      style: AppTextStyles.interLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
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

                    Text(
                      'KONFIRMASI PASSWORD',
                      style: AppTextStyles.interLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
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

                    Text(
                      'LOGO',
                      style: AppTextStyles.interLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundInput,
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          border: Border.all(
                            color: _logoBytes != null ? AppColors.primary : AppColors.inputBorder,
                            width: _logoBytes != null ? 1.5 : 1,
                          ),
                        ),
                        child: _logoBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOTO KTP',
                      style: AppTextStyles.interLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickKTP,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingL),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundInput,
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          border: Border.all(
                            color: _ktpBytes != null ? AppColors.primary : AppColors.inputBorder,
                            width: _ktpBytes != null ? 1.5 : 1,
                          ),
                        ),
                        child: _ktpBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                child: Image.memory(
                                  _ktpBytes!,
                                  fit: BoxFit.cover,
                                  height: 180,
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
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pastikan seluruh bagian KTP terlihat jelas',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.interCaption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: AppConstants.paddingM),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppConstants.paddingL,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                    ),
                                    child: Text(
                                      'PILIH FILE',
                                      style: AppTextStyles.poppinsButton.copyWith(
                                        fontSize: 12,
                                        color: AppColors.background,
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

              const SizedBox(height: AppConstants.paddingM),

              // Seksi 3: Metode Pembayaran
              _sectionCard(
                title: 'Metode Pembayaran',
                icon: Icons.payment_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih metode pembayaran untuk menerima pembayaran dari pengguna',
                      style: AppTextStyles.interCaption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    
                    // Horizontal Payment Method Cards
                    Row(
                      children: [
                        _buildPaymentMethodCard(
                          selected: _pilihBank,
                          onTap: () => setState(() {
                            _pilihBank = !_pilihBank;
                            if (!_pilihBank) {
                              _selectedBank = null;
                              _bankAccountController.clear();
                              _bankAccountNameController.clear();
                            }
                          }),
                          title: 'Bank Transfer',
                          icon: Icons.account_balance_outlined,
                        ),
                        const SizedBox(width: AppConstants.paddingM),
                        _buildPaymentMethodCard(
                          selected: _pilihQris,
                          onTap: () => setState(() {
                            _pilihQris = !_pilihQris;
                            if (!_pilihQris) {
                              _qrisBytes = null;
                            }
                          }),
                          title: 'QRIS',
                          icon: Icons.qr_code_outlined,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.paddingM),
                    
                    // Form Bank (muncul jika _pilihBank true)
                    if (_pilihBank) ...[
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundInput,
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NAMA BANK',
                              style: AppTextStyles.interLabel.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedBank,
                              hint: Text(
                                'Pilih Bank',
                                style: AppTextStyles.interHint,
                              ),
                              decoration: _inputDecoration(),
                              items: _bankList.map((bank) {
                                return DropdownMenuItem(
                                  value: bank,
                                  child: Text(bank, style: AppTextStyles.interInput),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedBank = value);
                              },
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                            
                            Text(
                              'NOMOR REKENING',
                              style: AppTextStyles.interLabel.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _bankAccountController,
                              style: AppTextStyles.interInput,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(hint: 'Masukkan nomor rekening'),
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                            
                            Text(
                              'NAMA PEMILIK',
                              style: AppTextStyles.interLabel.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _bankAccountNameController,
                              style: AppTextStyles.interInput,
                              decoration: _inputDecoration(hint: 'Sesuai nama di rekening'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Form QRIS (muncul jika _pilihQris true)
                    if (_pilihQris) ...[
                      const SizedBox(height: AppConstants.paddingM),
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundInput,
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QRIS',
                              style: AppTextStyles.interLabel.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _pickQRIS,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppConstants.paddingL),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundInput,
                                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                  border: Border.all(
                                    color: _qrisBytes != null ? AppColors.primary : AppColors.inputBorder,
                                    width: _qrisBytes != null ? 1.5 : 1,
                                  ),
                                ),
                                child: _qrisBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                        child: Image.memory(
                                          _qrisBytes!,
                                          fit: BoxFit.contain,
                                          height: 120,
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          Icon(
                                            Icons.qr_code_scanner_outlined,
                                            color: AppColors.primary,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'UPLOAD QRIS',
                                            style: AppTextStyles.interLabel.copyWith(
                                              color: AppColors.primary,
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
                    ],
                  ],
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
                      onChanged: (v) => setState(() => _setujuiSyarat = v ?? false),
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

  // ============================================================
  // PAYMENT METHOD CARD (HORIZONTAL)
  // ============================================================
  Widget _buildPaymentMethodCard({
    required bool selected,
    required VoidCallback onTap,
    required String title,
    required IconData icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.backgroundInput,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.inputBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Icon(
                    icon,
                    color: selected ? AppColors.primary : AppColors.textHint,
                    size: 28,
                  ),
                  if (selected)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.poppinsTitleSmall.copyWith(
                  fontSize: 12,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}