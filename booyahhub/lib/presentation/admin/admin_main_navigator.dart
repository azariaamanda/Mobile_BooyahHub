import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'admin_dashboard_screen.dart';
import 'create_scrim_page.dart';
import 'peserta_management_page.dart';
import '../../data/models/services/admin_keuangan_page.dart';
import 'setting_page.dart';

class AdminMainNavigator extends StatefulWidget {
  const AdminMainNavigator({super.key});

  @override
  State<AdminMainNavigator> createState() => _AdminMainNavigatorState();
}

class _AdminMainNavigatorState extends State<AdminMainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboardScreen(), // 0: Dashboard
    CreateScrimPage(), // 1: Buat Scrim
    PesertaManagementPage(), // 2: Peserta
    AdminKeuanganPage(), // 3: Keuangan
    PaymentConfigPage(), // 4: Pengaturan
  ];

  // Label DIPENDEKKAN supaya muat di nav 5 item.
  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.dashboard, 'label': 'Home'},
    {'icon': Icons.add_circle_outline, 'label': 'Scrim'},
    {'icon': Icons.people_outline, 'label': 'Peserta'},
    {'icon': Icons.account_balance_wallet, 'label': 'Keuangan'},
    {'icon': Icons.settings_outlined, 'label': 'Setting'},
  ];

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
            // Tiap item dapat slot lebar SAMA — anti-overflow.
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
            : Icon(icon, color: AppColors.background, size: 22),
      ),
    );
  }
}
