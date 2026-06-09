import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/auth_service.dart';
import '../../data/models/services/notification_service.dart';

import 'user_edit_profile_page.dart';
import 'claim_prize_page.dart';
import 'help_support_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  static const _notifPopupPrefKey = 'notifikasi_popup_aktif';

  String _name = 'Memuat...';
  String _email = 'Memuat...';
  String? _fotoProfil;
  bool _isLoading = true;
  bool _isNotifikasiAktif = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_notifPopupPrefKey) ?? true;
    if (!mounted) return;
    setState(() {
      _isNotifikasiAktif = isActive;
    });
  }

  Future<void> _loadUserProfile() async {
    final authService = AuthService();
    final data = await authService.getCurrentAkunAndProfil();
    
    if (mounted && data != null) {
      final akun = data['akun'];
      final profil = data['profil'];
      
      setState(() {
        _email = akun.email;
        if (profil['foto_profil'] != null && profil['foto_profil'].toString().isNotEmpty) {
          final url = profil['foto_profil'].toString();
          final separator = url.contains('?') ? '&' : '?';
          _fotoProfil = '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
        } else {
          _fotoProfil = null;
        }
        if (data['role'] == 'pengguna') {
          _name = profil['nama_tim'] ?? 'Tim Tanpa Nama';
        } else if (data['role'] == 'admin') {
          _name = profil['nama_lengkap'] ?? 'Admin';
        } else {
          _name = profil['nama_owner'] ?? 'Owner';
        }
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _name = 'Gagal memuat';
        _email = 'Gagal memuat';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profil',
          style: AppTextStyles.poppinsTitle.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Profile Picture
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: _fotoProfil != null && _fotoProfil!.isNotEmpty
                      ? NetworkImage(_fotoProfil!)
                      : null,
                  child: (_fotoProfil == null || _fotoProfil!.isEmpty)
                      ? Text(
                          _name.isNotEmpty ? _name.substring(0, 1).toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                _name,
                style: AppTextStyles.poppinsHeadline.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                _email,
                style: AppTextStyles.interBody.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Section 1: Pengaturan Akun
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PENGATURAN AKUN',
                  style: AppTextStyles.interCaption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildCardMenu(
                icon: Icons.person_outline,
                title: 'Edit Profil',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserEditProfilePage(
                        initialName: _name,
                        initialEmail: _email,
                        initialFotoProfil: _fotoProfil,
                      ),
                    ),
                  );

                  // Reload dari database agar foto profil baru langsung tampil
                  _loadUserProfile();
                },
              ),
              const SizedBox(height: 12),
              _buildCardMenu(
                icon: Icons.card_giftcard,
                title: 'Klaim Hadiah',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ClaimPrizePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildCardMenu(
                icon: Icons.notifications_none,
                title: 'Notifikasi',
                trailing: Switch(
                  value: _isNotifikasiAktif,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFFD4AF37), // Matches the yellowish primary color in screenshot
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: AppColors.surfaceVariant,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(_notifPopupPrefKey, val);
                    if (!mounted) return;
                    setState(() {
                      _isNotifikasiAktif = val;
                    });
                  },
                ),
                onTap: () {},
              ),
              
              const SizedBox(height: 24),
              
              // Section 2: Dukungan dan Hukum
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'DUKUNGAN DAN HUKUM',
                  style: AppTextStyles.interCaption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildCardMenu(
                icon: Icons.help_outline,
                title: 'Bantuan dan Dukungan',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildCardMenu(
                icon: Icons.logout,
                title: 'Logout',
                textColor: AppColors.error,
                iconColor: AppColors.error,
                iconBackgroundColor: AppColors.error.withOpacity(0.1),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: AppColors.backgroundCard,
                        title: Text('Konfirmasi Logout', style: AppTextStyles.poppinsTitle),
                        content: Text('Apakah Anda yakin ingin keluar?', style: AppTextStyles.interBody),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close dialog
                            },
                            child: Text('Tidak', style: AppTextStyles.interBody),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close dialog
                              NotificationService().clear();
                              context.go('/login'); // Navigate to login
                            },
                            child: Text('Ya', style: AppTextStyles.interLink.copyWith(color: AppColors.error)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Member Elit Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEMBER ELIT',
                            style: AppTextStyles.poppinsTitleSmall.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Valid sampai Des 2025',
                            style: AppTextStyles.interCaption.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              'PERBARUI MEMBERSHIP',
                              style: AppTextStyles.interCaption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.workspace_premium, // Similar to the badge icon in the design
                        size: 64,
                        color: Colors.white60,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardMenu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    Color? iconBackgroundColor,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBackgroundColor ?? AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 22),
        ),
        title: Text(
          title,
          style: AppTextStyles.poppinsTitleSmall.copyWith(
            color: textColor ?? AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}