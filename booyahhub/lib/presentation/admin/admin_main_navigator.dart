import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'admin_dashboard_screen.dart';
import 'create_scrim_page.dart';
import 'admin_claim_list_page.dart';
import 'setting_page.dart';
// TODO: buat halaman peserta
import 'peserta_management_page.dart';  // <-- BUAT NANTI

class AdminMainNavigator extends StatefulWidget {
  const AdminMainNavigator({super.key});

  @override
  State<AdminMainNavigator> createState() => _AdminMainNavigatorState();
}

class _AdminMainNavigatorState extends State<AdminMainNavigator> {
  int _currentIndex = 0;

  // DAFTAR HALAMAN UNTUK ADMIN (5 HALAMAN)
  final List<Widget> _pages = [
    const AdminDashboardScreen(),     // Index 0: Dashboard
    const CreateScrimPage(),          // Index 1: Buat Scrim
    const PesertaManagementPage(),    // Index 2: Peserta (baru)
    const AdminClaimListPage(),       // Index 3: Klaim
    const PaymentConfigPage(),        // Index 4: Pengaturan
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.add_circle_outline, 'label': 'Buat Scrim'},
    {'icon': Icons.people_outline, 'label': 'Peserta'},        // <-- TAMBAH INI
    {'icon': Icons.assignment_turned_in, 'label': 'Klaim'},
    {'icon': Icons.settings_outlined, 'label': 'Pengaturan'},
  ];

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
              _buildNavItem(_menuItems[0]['icon'], _menuItems[0]['label'], 0),
              _buildNavItem(_menuItems[1]['icon'], _menuItems[1]['label'], 1),
              _buildNavItem(_menuItems[2]['icon'], _menuItems[2]['label'], 2),
              _buildNavItem(_menuItems[3]['icon'], _menuItems[3]['label'], 3),
              _buildNavItem(_menuItems[4]['icon'], _menuItems[4]['label'], 4),
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
              vertical: AppConstants.paddingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: AppConstants.paddingXS),
                Text(
                  label,
                  style: AppTextStyles.interCaption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        : IconButton(
            icon: Icon(icon, color: AppColors.background),
            onPressed: () {
              setState(() {
                _currentIndex = index;
              });
            },
          );
  }
}