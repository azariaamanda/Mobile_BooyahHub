import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'owner_dashboard_screen.dart';
import 'admin_verification_page.dart';
import 'manage_banner_page.dart';
import 'premium_management_screen.dart';
import 'owner_profile_screen.dart';

class OwnerMainNavigator extends StatefulWidget {
  const OwnerMainNavigator({super.key});

  @override
  State<OwnerMainNavigator> createState() => _OwnerMainNavigatorState();
}

class _OwnerMainNavigatorState extends State<OwnerMainNavigator> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const OwnerDashboardScreen(),
    const AdminVerificationPage(),
    const ManageBannerPage(),
    const PremiumManagementScreen(),
    OwnerProfileScreen(
      onNavigateTab: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    ),
  ];

  static Widget _buildPlaceholder(String title) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          title,
          style: AppTextStyles.poppinsHeadline.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      extendBody: false,
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.grid_view_rounded, 'Dashboard', 0),
                _buildNavItem(Icons.people_alt_outlined, 'Admin', 1),
                _buildNavItem(Icons.campaign_rounded, 'Banner', 2),
                _buildNavItem(Icons.stars_rounded, 'Layanan', 3),
                _buildNavItem(Icons.person_outline_rounded, 'Profil', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return isSelected
        ? Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM, 
              vertical: AppConstants.paddingS
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
                _selectedIndex = index;
              });
            },
          );
  }
}