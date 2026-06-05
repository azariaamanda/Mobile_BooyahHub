import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../../config/app_text_styles.dart';
import '../../data/models/services/admin_utang_service.dart';
import '../../presentation/admin/admin_bayar_tagihan_page.dart';

class AdminSuspensionGuard extends StatefulWidget {
  final Widget child;
  final bool redirectIfSuspended;

  const AdminSuspensionGuard({
    super.key,
    required this.child,
    this.redirectIfSuspended = true,
  });

  @override
  State<AdminSuspensionGuard> createState() => _AdminSuspensionGuardState();
}

class _AdminSuspensionGuardState extends State<AdminSuspensionGuard> {
  final _supabase = Supabase.instance.client;
  final _adminUtangService = AdminUtangService();
  
  bool _isLoading = true;
  bool _isSuspended = false;
  double? _totalUtang;
  double? _limitUtang;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _isSuspended = false;
        });
        return;
      }

      final akunData = await _supabase
          .from('akun')
          .select('id_akun')
          .eq('email', currentUser.email!)
          .maybeSingle();

      if (akunData == null) {
        setState(() {
          _isLoading = false;
          _isSuspended = false;
        });
        return;
      }

      final result = await _adminUtangService.cekStatusAdmin(akunData['id_akun']);
      
      if (result['total_utang'] >= result['limit_utang'] && result['status_akun'] != 'suspended') {
        await _supabase
            .from('akun')
            .update({'status_akun': 'suspended'})
            .eq('id_akun', akunData['id_akun']);
        
        // Refresh result
        final newResult = await _adminUtangService.cekStatusAdmin(akunData['id_akun']);
        setState(() {
          _isSuspended = newResult['status_akun'] == 'suspended';
          _totalUtang = newResult['total_utang'];
          _limitUtang = newResult['limit_utang'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isSuspended = result['status_akun'] == 'suspended';
          _totalUtang = result['total_utang'];
          _limitUtang = result['limit_utang'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuspended = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_isSuspended && widget.redirectIfSuspended) {
      return _buildSuspendedScreen();
    }

    return widget.child;
  }

  Widget _buildSuspendedScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Akun Ditangguhkan',
                style: AppTextStyles.poppinsHeadline.copyWith(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Akun Anda telah mencapai batas limit utang. Silakan lunasi tagihan untuk mengaktifkan kembali akun Anda.',
                style: AppTextStyles.interBody.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_totalUtang != null && _limitUtang != null)
                Text(
                  'Total Utang: ${_adminUtangService.formatRupiah(_totalUtang!)} / ${_adminUtangService.formatRupiah(_limitUtang!)}',
                  style: AppTextStyles.interBodyMedium.copyWith(color: Colors.orange),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminBayarTagihanPage(),
                    ),
                  ).then((_) => _checkStatus());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Bayar Tagihan Sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}