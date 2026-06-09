// lib/presentation/auth/register_user_page.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/auth_service.dart';

class RegisterUserPage extends StatefulWidget {
  const RegisterUserPage({super.key});

  @override
  State<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaTimController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;
  bool _setujuiSyarat = false;

  @override
  void dispose() {
    _namaTimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_setujuiSyarat) {
      _showSnackBar('Anda harus menyetujui syarat & ketentuan', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().registerPengguna(
        namaTim: _namaTimController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success']) {
        _showSnackBar(result['message'], isError: false);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
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
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingL),
              Text(
                'Daftar\nSebagai Tim',
                style: AppTextStyles.poppinsHeadline.copyWith(
                  fontSize: 28,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bergabunglah dan ikuti berbagai turnamen seru!',
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              Text(
                'NAMA TIM',
                style: AppTextStyles.interLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _namaTimController,
                style: AppTextStyles.interInput,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama tim',
                  hintStyle: AppTextStyles.interHint,
                  filled: true,
                  fillColor: AppColors.backgroundInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama tim wajib diisi'
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
                decoration: InputDecoration(
                  hintText: 'contoh@email.com',
                  hintStyle: AppTextStyles.interHint,
                  filled: true,
                  fillColor: AppColors.backgroundInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Format email tidak valid';
                  return null;
                },
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
                decoration: InputDecoration(
                  hintText: 'Minimal 6 karakter',
                  hintStyle: AppTextStyles.interHint,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.inputIcon,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password wajib diisi';
                  if (v.length < 6) return 'Minimal 6 karakter';
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
                decoration: InputDecoration(
                  hintText: 'Ulangi password',
                  hintStyle: AppTextStyles.interHint,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKonfirmasi
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.inputIcon,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                  if (v != _passwordController.text) return 'Password tidak cocok';
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingL),

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
                      side: BorderSide(color: AppColors.inputBorder, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi BooyahHub',
                      style: AppTextStyles.interCaption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingL),

              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
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
                      : Text(
                          'Daftar',
                          style: AppTextStyles.poppinsButton.copyWith(
                            color: AppColors.background,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
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
                      'Masuk',
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
      ),
    );
  }
}