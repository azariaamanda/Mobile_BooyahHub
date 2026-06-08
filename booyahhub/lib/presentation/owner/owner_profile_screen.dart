import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/auth_service.dart';

class OwnerProfileScreen extends StatefulWidget {
  final void Function(int index)? onNavigateTab;
  const OwnerProfileScreen({super.key, this.onNavigateTab});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _akunData;
  Map<String, dynamic>? _profilData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _authService.getCurrentAkunAndProfil();
    if (data != null && mounted) {
      setState(() {
        _akunData = data['akun'].toJson();
        _profilData = data['profil'] as Map<String, dynamic>?;
        
        if (_profilData != null && _profilData!['foto_profil'] != null && _profilData!['foto_profil'].toString().isNotEmpty) {
          final url = _profilData!['foto_profil'].toString();
          final separator = url.contains('?') ? '&' : '?';
          _profilData!['foto_profil'] = '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
        }
        
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 32),
                  _buildProfileInfo(),
                  const SizedBox(height: 32),
                  _buildStatCard(
                    icon: Icons.account_balance_wallet_rounded,
                    iconBgColor: const Color(0xFF3B331A), // Dark yellowish
                    iconColor: const Color(0xFFFFD700),
                    badgeText: '+12.5% Today',
                    badgeBgColor: const Color(0xFF3B331A),
                    badgeTextColor: const Color(0xFFFFD700),
                    title: 'Total Revenue',
                    value: 'Rp 45.500.000',
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    icon: Icons.videogame_asset_rounded,
                    iconBgColor: Colors.white10,
                    iconColor: Colors.white70,
                    badgeText: 'All-Time',
                    badgeBgColor: Colors.white10,
                    badgeTextColor: Colors.white70,
                    title: 'Total Revenue',
                    value: 'Rp 45.500.000',
                  ),
                  const SizedBox(height: 32),
                  _buildMenuSection(context),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'BOOYAHHUB',
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: const Color(0xFFFFD700),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 24), // Balance the back button
      ],
    );
  }

  Widget _buildProfileInfo() {
    final name = _profilData?['nama_lengkap'] ?? 'Unknown';
    final email = _akunData?['email'] ?? 'Unknown Email';
    final fotoUrl = _profilData?['foto_profil'] as String?;

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF131F2D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700), width: 3),
            image: fotoUrl != null
                ? DecorationImage(
                    image: NetworkImage(fotoUrl),
                    fit: BoxFit.cover,
                  )
                : const DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/300'),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppTextStyles.interCaption.copyWith(
            color: const Color(0xFFFFD700).withValues(alpha: 0.8),
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.interCaption.copyWith(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.interCaption.copyWith(
              color: const Color(0xFFFFD700),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.poppinsHeadline.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.person_rounded, 
          title: 'Edit Profil & Password',
          onTap: () async {
            await context.push('/owner/edit-profile');
            _loadProfile(); // Refresh data after returning
          },
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.account_balance_wallet_rounded, 
          title: 'Kelola Fee',
          onTap: () => context.push('/owner/manage-fee'),
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.stars_rounded, 
          title: 'Layanan Premium',
          onTap: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(3);
            } else {
              context.push('/owner/premium-management');
            }
          },
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.campaign_rounded, 
          title: 'Kelola Banner',
          onTap: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(2);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildMenuItem(icon: Icons.notifications_rounded, title: 'Notifikasi Owner'),
        const SizedBox(height: 8),
        _buildMenuItem(icon: Icons.settings_rounded, title: 'Pengaturan'),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.logout_rounded,
          title: 'Logout',
          isDestructive: true,
          onTap: () {
            _authService.logout();
            context.go('/login');
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final Color itemColor = isDestructive ? Colors.redAccent : Colors.white;
    final Color iconBgColor = isDestructive ? Colors.redAccent.withValues(alpha: 0.1) : Colors.white10;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white70, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.interBody.copyWith(
            color: itemColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDestructive ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white54,
          size: 20,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }
}
