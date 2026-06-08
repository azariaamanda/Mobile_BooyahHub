import 'dart:async';
import 'package:booyahhub/presentation/user/user_pesanan.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/notification_service.dart';
import 'user_home_screen.dart';
import 'history_scrim_page.dart';
import 'user_profile_page.dart';

class UserMainNavigator extends StatefulWidget {
  const UserMainNavigator({super.key});

  @override
  State<UserMainNavigator> createState() => _UserMainNavigatorState();
}

class _UserMainNavigatorState extends State<UserMainNavigator> {
  int _currentIndex = 0;
  StreamSubscription<NotifData>? _notifSub;

  final List<Widget> _pages = [
    const UserHomeScreen(),
    const UserPesananPage(),
    const HistoryScrimPage(),
    const UserProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;

    final akun = await Supabase.instance.client
        .from('akun')
        .select('id_akun')
        .eq('email', email)
        .maybeSingle();

    if (akun == null || !mounted) return;

    final akunId = akun['id_akun'] as int;
    await NotificationService().initialize(akunId, 'pengguna');

    _notifSub = NotificationService().newNotifStream.listen((notif) {
      if (!mounted) return;
      _showInAppBanner(notif);
    });
  }

  void _showInAppBanner(NotifData notif) {
    final color = _notifColor(notif.tipe);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.backgroundCard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        content: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Icon(_notifIcon(notif.tipe), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(notif.judul,
                      style: AppTextStyles.poppinsTitleSmall.copyWith(fontSize: 13)),
                  Text(notif.pesan,
                      style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _notifColor(String tipe) {
    switch (tipe) {
      case 'pembayaran_dikonfirmasi': return AppColors.accent;
      case 'pembayaran_ditolak':      return AppColors.error;
      case 'scrim_baru':              return AppColors.info;
      default:                        return AppColors.primary;
    }
  }

  IconData _notifIcon(String tipe) {
    switch (tipe) {
      case 'pembayaran_dikonfirmasi': return Icons.check_circle_outline;
      case 'pembayaran_ditolak':      return Icons.cancel_outlined;
      case 'scrim_baru':              return Icons.sports_esports_outlined;
      default:                        return Icons.notifications_outlined;
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(
            left: AppConstants.paddingM,
            right: AppConstants.paddingM,
            bottom: AppConstants.paddingM,
          ),
          height: 65,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Beranda', 0),
              _buildNavItem(Icons.assignment, 'Pesanan', 1),
              _buildNavItem(Icons.history, 'Riwayat', 2),
              _buildNavItem(Icons.person, 'Profil', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;

    return isSelected
        ? Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: AppConstants.paddingXS),
                Text(label,
                    style: AppTextStyles.interCaption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
          )
        : IconButton(
            icon: Icon(icon, color: AppColors.background),
            onPressed: () => setState(() => _currentIndex = index),
          );
  }
}
