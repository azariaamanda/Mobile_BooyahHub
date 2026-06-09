import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Password tidak cocok', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      final newPassword = _newPasswordController.text;
      final hashedNewPassword = _hashPassword(newPassword);

      final user = await supabase
          .from('akun')
          .select('id_akun, kata_sandi')
          .eq('email', email)
          .maybeSingle();

      if (user == null) {
        _showSnackBar('Email tidak terdaftar', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final currentPasswordHash = user['kata_sandi'];
      if (currentPasswordHash == hashedNewPassword) {
        _showSnackBar('Password baru tidak boleh sama dengan password lama', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      await supabase
          .from('akun')
          .update({'kata_sandi': hashedNewPassword})
          .eq('email', email);

      _showSnackBar('Password berhasil direset! Silakan login.', isError: false);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');

    } catch (e) {
      _showSnackBar('Gagal reset password: $e', isError: true);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reset Password',
          style: AppTextStyles.poppinsTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 20),

                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),

                Center(
                  child: Text(
                    'Lupa Password?',
                    style: AppTextStyles.poppinsHeadline.copyWith(
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Masukkan email dan password baru Anda',
                    style: AppTextStyles.interBody.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

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
                    hintText: 'Masukkan email Anda',
                    hintStyle: AppTextStyles.interHint,
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.backgroundInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                    if (!v.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),

                const SizedBox(height: AppConstants.paddingL),

                Text(
                  'PASSWORD BARU',
                  style: AppTextStyles.interLabel.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _newPasswordController,
                  style: AppTextStyles.interInput,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    hintStyle: AppTextStyles.interHint,
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.textHint),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
                  controller: _confirmPasswordController,
                  style: AppTextStyles.interInput,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Ulangi password baru',
                    hintStyle: AppTextStyles.interHint,
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.textHint),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            'Reset Password',
                            style: AppTextStyles.poppinsButton,
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ingat password? ',
                      style: AppTextStyles.interBody.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
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

                const SizedBox(height: AppConstants.paddingL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}