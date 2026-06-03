import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_image_helper.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _akun;
  Map<String, dynamic>? _profil;

  // State untuk toggle notifikasi
  bool _notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final userEmail = _supabase.auth.currentUser?.email;
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
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 300),
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.only(top: 16, bottom: 4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.only(bottom: 16),
        title: Center(child: Text('Logout', style: AppTextStyles.poppinsTitle)),
        content: Center(
          child: Text(
            'Yakin ingin logout?',
            style: AppTextStyles.interBody,
            textAlign: TextAlign.center,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.divider, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  minimumSize: const Size(100, 40),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Batal',
                  style: AppTextStyles.interLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  minimumSize: const Size(100, 40),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Logout',
                  style: AppTextStyles.poppinsButton.copyWith(
                    color: Colors.white,
                  ),
                ),
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

  void _navigateTo(String route) {
    context.push(route);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Profil',
          style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.primary),
        ),
        backgroundColor: AppColors.background,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.primary,
                ),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildProfileHeader()),
            const SizedBox(height: 32),

            _buildSectionTitle('PENGATURAN AKUN'),
            const SizedBox(height: 8),

            // Edit Profil (dengan chevron)
            _buildMenuItem(
              icon: Icons.edit_outlined,
              title: 'Edit Profil',
              onTap: () => _navigateTo('/admin/profile/edit'),
              showSwitch: false,
            ),
            const SizedBox(height: 8),

            // Notifikasi (dengan Switch toggle)
            _buildMenuItemWithSwitch(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              value: _notificationEnabled,
              onChanged: (val) => setState(() => _notificationEnabled = val),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle('PUSAT KONTROL'),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.star_outline,
              title: 'Layanan Premium',
              onTap: () => _navigateTo('/admin/premium'),
              showSwitch: false,
            ),

            const SizedBox(height: 24),

            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final fotoUrl = AppImageHelper.fotoProfil(_profil?['foto_profil']);
    final namaLengkap = _profil?['nama_lengkap'] ?? 'Admin';
    final initial = namaLengkap.isNotEmpty ? namaLengkap[0].toUpperCase() : 'A';

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: fotoUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    fotoUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Text(
                      initial,
                      style: AppTextStyles.poppinsHeadline.copyWith(
                        fontSize: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : Text(
                  initial,
                  style: AppTextStyles.poppinsHeadline.copyWith(
                    fontSize: 36,
                    color: AppColors.primary,
                  ),
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.interLabel.copyWith(
        color: AppColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

  // Menu item biasa (dengan chevron)
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool showSwitch,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.interBody.copyWith(fontSize: 15),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Menu item dengan Switch (khusus notifikasi)
  Widget _buildMenuItemWithSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.interBody.copyWith(fontSize: 15),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
              inactiveThumbColor: AppColors.textSecondary,
              inactiveTrackColor: AppColors.surfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error, width: 1),
      ),
      child: GestureDetector(
        onTap: _logout,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              'Logout',
              style: AppTextStyles.poppinsButton.copyWith(
                color: AppColors.error,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
