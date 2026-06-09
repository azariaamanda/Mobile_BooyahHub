import 'dart:async';
import 'package:booyahhub/presentation/user/user_pesanan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../data/models/services/notification_service.dart';
import '../../widgets/top_notification_banner.dart';
import 'user_home_screen.dart';
import 'history_scrim_page.dart';
import 'user_profile_page.dart';

class UserMainNavigator extends StatefulWidget {
  const UserMainNavigator({super.key});

  @override
  State<UserMainNavigator> createState() => _UserMainNavigatorState();
}

class _UserMainNavigatorState extends State<UserMainNavigator>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  StreamSubscription<NotifData>? _notifSub;

  late final AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  static const _icons = [
    Icons.home_rounded,
    Icons.assignment_rounded,
    Icons.history_rounded,
    Icons.person_rounded,
  ];

  final List<Widget> _pages = const [
    UserHomeScreen(),
    UserPesananPage(),
    HistoryScrimPage(),
    UserProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = AlwaysStoppedAnimation(0.0);
    _initNotifications();
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    final from = _slideAnim.value;
    _slideAnim = Tween<double>(begin: from, end: index.toDouble()).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOut),
    );
    _slideCtrl.forward(from: 0);
    setState(() => _currentIndex = index);
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

  Future<void> _showInAppBanner(NotifData notif) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifikasi_popup_aktif') ?? true;
    if (!enabled || !mounted) return;

    TopNotificationBanner.show(
      context,
      title: notif.judul,
      message: notif.pesan,
      icon: _notifIcon(notif.tipe),
      color: _notifColor(notif.tipe),
    );
  }

  Color _notifColor(String tipe) {
    switch (tipe) {
      case 'pembayaran_dikonfirmasi':
        return AppColors.accent;
      case 'pembayaran_ditolak':
        return AppColors.error;
      case 'scrim_baru':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  IconData _notifIcon(String tipe) {
    switch (tipe) {
      case 'pembayaran_dikonfirmasi':
        return Icons.check_circle_outline;
      case 'pembayaran_ditolak':
        return Icons.cancel_outlined;
      case 'scrim_baru':
        return Icons.sports_esports_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingM,
            0,
            AppConstants.paddingM,
            AppConstants.paddingM,
          ),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemW = constraints.maxWidth / _icons.length;
                const circleSize = 46.0;
                const circleTop = (64 - circleSize) / 2;

                return AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (context, _) {
                    final pos = _slideAnim.value;
                    final circleLeft =
                        pos * itemW + (itemW - circleSize) / 2;

                    return Stack(
                      children: [
                        // Sliding circle
                        Positioned(
                          left: circleLeft,
                          top: circleTop,
                          width: circleSize,
                          height: circleSize,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Icons — warna mengikuti posisi circle agar tidak kedip
                        Positioned.fill(
                          child: Row(
                            children: List.generate(_icons.length, (i) {
                              final t =
                                  (1.0 - (pos - i).abs()).clamp(0.0, 1.0);
                              final iconColor = Color.lerp(
                                AppColors.background,
                                AppColors.primary,
                                t,
                              )!;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTab(i),
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: Icon(
                                      _icons[i],
                                      color: iconColor,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
