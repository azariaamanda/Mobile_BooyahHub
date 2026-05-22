import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/auth_service.dart';

class RegisterAdminPage extends StatefulWidget {
  const RegisterAdminPage({super.key});

  @override
  State<RegisterAdminPage> createState() => _RegisterAdminPageState();
}

class _RegisterAdminPageState extends State<RegisterAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiPasswordController = TextEditingController();
  final _namaBankController = TextEditingController();
  final _namaPemilikController = TextEditingController();
  final _noRekeningController = TextEditingController();

  // State
  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;
  bool _isLoading = false;
  bool _setujuiSyarat = false;

  // File paths
  String? _logoPath;
  String? _ktpPath;

  // Metode pembayaran
  final List<String> _metodeTersedia = ['Bank Transfer', 'QRIS'];
  final Set<String> _metodeSelected = {'Bank Transfer'};

  String? _qrisPath;

  // Tambahkan fungsi pick QRIS
  Future<void> _pickQRIS() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _qrisPath = image.path);
    }
  }

  // Bank dropdown
  final List<String> _daftarBank = [
    'BCA',
    'BRI',
    'BNI',
    'Mandiri',
    'CIMB Niaga',
    'Danamon',
    'Permata',
    'BTN',
    'BSI',
    'Lainnya',
  ];
  String _selectedBank = 'BCA';

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _passwordController.dispose();
    _konfirmasiPasswordController.dispose();
    _namaBankController.dispose();
    _namaPemilikController.dispose();
    _noRekeningController.dispose();
    super.dispose();
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
      setState(() => _logoPath = image.path);
    }
  }

  Future<void> _pickKTP() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _ktpPath = image.path);
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ktpPath == null) {
      _showSnackBar('Foto KTP wajib diunggah', isError: true);
      return;
    }

    if (!_setujuiSyarat) {
      _showSnackBar('Anda harus menyetujui syarat & ketentuan', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.registerAdmin(
      namaLengkap: _namaController.text.trim(),
      email: _emailController.text.trim(),
      noHandphone: _noHpController.text.trim(),
      password: _passwordController.text,
      fotoProfilPath: _logoPath,
      fotoKtpPath: _ktpPath!,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      _showSnackBar(result['message'] ?? 'Pendaftaran berhasil!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/login');
    } else {
      _showSnackBar(result['message'] ?? 'Terjadi kesalahan', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.interBody.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS UI
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
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.interHint,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
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

              // Judul
              Text(
                'Pendaftaran\nPenyelenggara',
                style: AppTextStyles.poppinsHeadline.copyWith(
                  fontSize: 28,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bergabunglah dengan ekosistem e-sports profesional terbesar. Mulai kelola turnamen dan clan Anda hari ini.',
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
                    _fieldLabel('NAMA LENGKAP/KELOMPOK'),
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
                        if (v == null || v.trim().isEmpty)
                          return 'Email wajib diisi';
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
                        if (v == null || v.isEmpty)
                          return 'Password wajib diisi';
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
                        if (v == null || v.isEmpty)
                          return 'Konfirmasi password wajib diisi';
                        if (v != _passwordController.text)
                          return 'Password tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingM),

                    // Upload Logo (FIXED)
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
                            color: _logoPath != null
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _logoPath != null
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.image_outlined,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _logoPath != null
                                  ? 'Logo diunggah'
                                  : 'UPLOAD LOGO',
                              style: AppTextStyles.interLabel.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
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

              // Seksi 2: Verifikasi Identitas (FIXED)
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
                        color: _ktpPath != null
                            ? AppColors.primary
                            : AppColors.inputBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _ktpPath != null
                                ? Icons.check_circle_rounded
                                : Icons.insert_drive_file_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          _ktpPath != null
                              ? 'Foto KTP diunggah'
                              : 'Unggah Foto KTP',
                          style: AppTextStyles.poppinsTitleSmall.copyWith(
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pastikan seluruh bagian KTP terlihat jelas\ndan tidak buram. Format: JPG, PNG (Max. 5MB)',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.interCaption.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
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
                            _ktpPath != null ? 'GANTI FILE' : 'PILIH FILE',
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

              // Seksi 3: Pengaturan Pembayaran
              _sectionCard(
                title: 'Pengaturan Pembayaran',
                icon: Icons.account_balance_wallet_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('METODE PEMBAYARAN YANG DITERIMA'),
                    const SizedBox(height: 4),

                    // Grid 2x2 metode pembayaran (BANK TRANSFER & QRIS)
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 3.2,
                      children: _metodeTersedia.map((metode) {
                        final selected = _metodeSelected.contains(metode);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _metodeSelected.remove(metode);
                              } else {
                                _metodeSelected.add(metode);
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.backgroundInput,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusS,
                              ),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.inputBorder,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.inputBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: selected
                                      ? Icon(
                                          Icons.check,
                                          size: 11,
                                          color: AppColors.background,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    metode,
                                    style: AppTextStyles.interBody.copyWith(
                                      color: selected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppConstants.paddingM),

                    // FORM BANK TRANSFER (hanya muncul jika Bank Transfer dipilih)
                    if (_metodeSelected.contains('Bank Transfer')) ...[
                      _fieldLabel('NAMA BANK'),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBank,
                        dropdownColor: AppColors.backgroundCard,
                        style: AppTextStyles.interInput,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                        decoration: _inputDecoration(),
                        items: _daftarBank.map((bank) {
                          return DropdownMenuItem(
                            value: bank,
                            child: Text(bank, style: AppTextStyles.interInput),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedBank = v!),
                      ),
                      const SizedBox(height: AppConstants.paddingM),

                      _fieldLabel('NAMA PEMILIK REKENING'),
                      TextFormField(
                        controller: _namaPemilikController,
                        style: AppTextStyles.interInput,
                        decoration: _inputDecoration(
                          hint: 'Sesuai buku tabungan',
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingM),

                      _fieldLabel('NO. REKENING'),
                      TextFormField(
                        controller: _noRekeningController,
                        style: AppTextStyles.interInput,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(hint: '0000000000'),
                      ),
                    ],

                    // FORM QRIS (hanya muncul jika QRIS dipilih)
                    if (_metodeSelected.contains('QRIS')) ...[
                      _fieldLabel('UPLOAD QRIS'),
                      GestureDetector(
                        onTap: _pickQRIS,
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusM,
                            ),
                            border: Border.all(
                              color: _qrisPath != null
                                  ? AppColors.primary
                                  : AppColors.inputBorder,
                              width: _qrisPath != null ? 1.5 : 1,
                            ),
                          ),
                          child: _qrisPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusM,
                                  ),
                                  child: Image.file(
                                    File(_qrisPath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 120,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'UPLOAD QRIS',
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
                                      style: AppTextStyles.interCaption
                                          .copyWith(
                                            color: AppColors.textHint,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ),
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
                              decorationColor: AppColors.primary,
                            ),
                          ),
                          const TextSpan(text: ' serta '),
                          TextSpan(
                            text: 'Kebijakan Privasi',
                            style: AppTextStyles.interLink.copyWith(
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
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

      // Tombol Daftar (fixed bottom)
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
                      decorationColor: AppColors.primary,
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
