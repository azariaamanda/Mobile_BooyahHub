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

class _AdminMainNavigatorState extends State<AdminMainNavigator> {
  int _currentIndex = 0;
  int _pendingCount = 0;
  StreamSubscription<NotifData>? _notifSub;
  RealtimeChannel? _pendingChannel;

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminScrimPage(),
    PesertaManagementPage(),
    AdminKeuanganPage(),
    AdminProfilePage(),
  ];

  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.dashboard, 'label': 'Home'},
    {'icon': Icons.add_circle_outline, 'label': 'Scrim'},
    {'icon': Icons.people_outline, 'label': 'Peserta'},
    {'icon': Icons.account_balance_wallet, 'label': 'Keuangan'},
    {'icon': Icons.settings_outlined, 'label': 'Setting'},
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _fetchPendingCount();
    _subscribePending();
  }

  Future<void> _fetchPendingCount() async {
    try {
      final res = await Supabase.instance.client
          .from('pendaftaran_tim')
          .select('id_pendaftaran')
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
              width: 36, height: 36,
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
                setState(() => _currentIndex = 2); // buka tab Peserta
              },
              child: Text('Lihat', style: AppTextStyles.interLink.copyWith(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _pendingChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(
            left: AppConstants.paddingM,
            right: AppConstants.paddingM,
            bottom: AppConstants.paddingM,
          ),
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: List.generate(_menuItems.length, (i) {
              return Expanded(
                child: _buildNavItem(
                  _menuItems[i]['icon'] as IconData,
                  _menuItems[i]['label'] as String,
                  i,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;
    // Badge merah di tab Peserta (index 2): hanya pembayaran pending
    final bool showBadge = index == 2 && _pendingCount > 0;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      child: Center(
        child: isSelected
            ? Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.interCaption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: AppColors.background, size: 22),
                  if (showBadge)
                    Positioned(
                      top: -4, right: -6,
                      child: Container(
                        width: 14, height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _pendingCount > 9 ? '9+' : '$_pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
