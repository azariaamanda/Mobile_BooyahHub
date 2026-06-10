import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_session.dart';
import 'manage_banner_page.dart';
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

  bool _notificationEnabled = true;
  bool _isPremium = false;
  List<String> _fiturAktif = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
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

      // Baca is_premium dan fitur_premium dari akun
      _isPremium = (akunData['is_premium'] ?? false) as bool;
      final rawFitur = akunData['fitur_premium'];
      _fiturAktif = rawFitur is List ? List<String>.from(rawFitur) : [];

      final profilData = await _supabase
          .from('profil_admin')
          .select()
          .eq('akun_id', akunData['id_akun'])
          .maybeSingle();

      if (profilData != null) {
        _profil = profilData;
        // Baca notifikasi_aktif (default true jika kolom belum ada)
        _notificationEnabled = (profilData['notifikasi_aktif'] ?? true) as bool;
      }

    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotifikasi(bool val) async {
    setState(() => _notificationEnabled = val);
    try {
      final akunId = _akun?['id_akun'];
      if (akunId == null) return;
      await _supabase
          .from('profil_admin')
          .update({'notifikasi_aktif': val})
          .eq('akun_id', akunId);
    } catch (e) {
      // Kolom notifikasi_aktif mungkin belum ada di tabel
      debugPrint('Gagal simpan notifikasi: $e');
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  minimumSize: const Size(100, 40),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Logout',
                  style: AppTextStyles.poppinsButton.copyWith(color: Colors.white),
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
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildProfileHeader()),
            const SizedBox(height: 32),

            // ── PENGATURAN AKUN ──
            _buildSectionTitle('PENGATURAN AKUN'),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.edit_outlined,
              title: 'Edit Profil',
              onTap: () => context.push('/admin/profile/edit'),
            ),
            const SizedBox(height: 8),
            _buildMenuItemWithSwitch(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              subtitle: _notificationEnabled ? 'Aktif' : 'Nonaktif',
              value: _notificationEnabled,
              onChanged: _updateNotifikasi,
            ),
            const SizedBox(height: 8),

            // Layanan Premium — status dari Supabase
            _buildMenuItemWithStatus(
              icon: Icons.star_outline,
              title: 'Layanan Premium',
              isActive: _isPremium,
              onTap: () => context.push('/admin/premium'),
            ),
            const SizedBox(height: 8),
            _buildMenuItemLockable(
              icon: Icons.campaign_rounded,
              title: 'Kelola Banner',
              isLocked: !_fiturAktif.contains('Kelola Banner Promosi'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageBannerPage()),
              ),
            ),
            const SizedBox(height: 8),
            _buildMenuItemLockable(
              icon: Icons.support_agent_rounded,
              title: 'Prioritas Support 24/7',
              isLocked: !_fiturAktif.contains('Prioritas Support 24/7'),
              onTap: _showSupportSheet,
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
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
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
            if (_isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                ),
                child: Text(
                  'PREMIUM',
                  style: AppTextStyles.interLabel.copyWith(
                    color: const Color(0xFFFFD700),
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
                child: Text(title, style: AppTextStyles.interBody.copyWith(fontSize: 15)),
              ),
              Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemLockable({
    required IconData icon,
    required String title,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: GestureDetector(
        onTap: isLocked
            ? () => _showPremiumRequiredDialog(title)
            : onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isLocked ? AppColors.textSecondary : AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.interBody.copyWith(
                    fontSize: 15,
                    color: isLocked ? AppColors.textSecondary : null,
                  ),
                ),
              ),
              if (isLocked)
                const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary)
              else
                const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showPremiumRequiredDialog(String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Fitur Premium', style: AppTextStyles.poppinsTitle),
            const SizedBox(height: 8),
            Text(
              '$featureName hanya tersedia untuk admin Premium. Upgrade sekarang untuk mengakses fitur ini.',
              style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/admin/premium');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.stars_rounded, size: 18),
                label: Text('Upgrade ke Premium', style: AppTextStyles.poppinsButton),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Nanti saja', style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prioritas Support 24/7', style: AppTextStyles.poppinsTitle.copyWith(fontSize: 16)),
                    Text(
                      'Respons dalam < 1 jam',
                      style: AppTextStyles.interCaption.copyWith(color: AppColors.success, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSupportRow(Icons.chat_rounded, 'WhatsApp', '+62 812-3456-7890'),
            const SizedBox(height: 12),
            _buildSupportRow(Icons.email_rounded, 'Email', 'support@booyahhub.id'),
            const SizedBox(height: 12),
            _buildSupportRow(Icons.access_time_rounded, 'Jam Operasional', '24 jam / 7 hari'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text('Mengerti', style: AppTextStyles.poppinsButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.interCaption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
            Text(value, style: AppTextStyles.interBody.copyWith(fontSize: 14)),
          ],
        ),
      ],
    );
  }


  Widget _buildMenuItemWithSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.interBody.copyWith(fontSize: 15)),
                  Text(
                    subtitle,
                    style: AppTextStyles.interCaption.copyWith(
                      color: value ? AppColors.success : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
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


  Widget _buildMenuItemWithStatus({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.interBody.copyWith(fontSize: 15)),
                    Text(
                      isActive ? 'Aktif' : 'Tidak Aktif',
                      style: AppTextStyles.interCaption.copyWith(
                        color: isActive ? AppColors.success : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'AKTIF' : 'NONAKTIF',
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
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
