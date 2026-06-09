import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/notification_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_scrim_page.dart';
import 'peserta_management_page.dart';
import 'admin_keuangan_page.dart';
import 'admin_profile_page.dart';

class AdminMainNavigator extends StatefulWidget {
  const AdminMainNavigator({super.key});

  @override
  State<AdminMainNavigator> createState() => _AdminMainNavigatorState();
}

class _AdminMainNavigatorState extends State<AdminMainNavigator>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _pendingCount = 0;
  StreamSubscription<NotifData>? _notifSub;
  RealtimeChannel? _pendingChannel;

  late final AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  static const _icons = [
    Icons.dashboard,
    Icons.add_circle_outline,
    Icons.people_outline,
    Icons.account_balance_wallet,
    Icons.settings_outlined,
  ];

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminScrimPage(),
    PesertaManagementPage(),
    AdminKeuanganPage(),
    AdminProfilePage(),
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
    _fetchPendingCount();
    _subscribePending();
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

  Future<void> _fetchPendingCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final akunData = await Supabase.instance.client
          .from('akun')
          .select('id_akun')
          .eq('email', user.email!)
          .maybeSingle();
      if (akunData == null) return;
      final adminId = akunData['id_akun'] as int;

      final scrims = await Supabase.instance.client
          .from('scrim')
          .select('id_scrim')
          .eq('id_admin', adminId);
      if ((scrims as List).isEmpty) {
        if (mounted) setState(() => _pendingCount = 0);
        return;
      }
      final scrimIds = scrims.map((s) => s['id_scrim'] as int).toList();

      final sessions = await Supabase.instance.client
          .from('sesi_scrim')
          .select('id_sesi')
          .inFilter('id_scrim', scrimIds);
      if ((sessions as List).isEmpty) {
        if (mounted) setState(() => _pendingCount = 0);
        return;
      }
      final sesiIds = sessions.map((s) => s['id_sesi'] as int).toList();

      final res = await Supabase.instance.client
          .from('pendaftaran_tim')
          .select('id_pendaftaran')
          .inFilter('id_sesi', sesiIds)
          .eq('status_pembayaran', 'menunggu');
      if (mounted) setState(() => _pendingCount = (res as List).length);
    } catch (_) {}
  }

  void _subscribePending() {
    _pendingChannel = Supabase.instance.client
        .channel('pending_pembayaran')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pendaftaran_tim',
          callback: (_) => _fetchPendingCount(),
        )
        .subscribe();
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
    await NotificationService().initialize(akunId, 'admin');

    _notifSub = NotificationService().newNotifStream.listen((notif) {
      if (!mounted) return;
      _showInAppBanner(notif);
    });
  }

  void _showInAppBanner(NotifData notif) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.backgroundCard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 70),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          side: BorderSide(
              color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: const Icon(Icons.payment_outlined,
                  color: AppColors.warning, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(notif.judul,
                      style: AppTextStyles.poppinsTitleSmall
                          .copyWith(fontSize: 13)),
                  Text(notif.pesan,
                      style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _selectTab(2);
              },
              child: Text('Lihat',
                  style: AppTextStyles.interLink.copyWith(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _notifSub?.cancel();
    _pendingChannel?.unsubscribe();
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
                        // Icons
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
                              final showBadge =
                                  i == 2 && _pendingCount > 0;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTab(i),
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(_icons[i],
                                            color: iconColor, size: 22),
                                        if (showBadge)
                                          Positioned(
                                            top: -4,
                                            right: -6,
                                            child: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: const BoxDecoration(
                                                color: AppColors.error,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _pendingCount > 9
                                                      ? '9+'
                                                      : '$_pendingCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
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
