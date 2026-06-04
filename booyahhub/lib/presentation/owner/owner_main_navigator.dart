import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import 'owner_dashboard_screen.dart';

class OwnerMainNavigator extends StatefulWidget {
  const OwnerMainNavigator({super.key});

  @override
  State<OwnerMainNavigator> createState() => _OwnerMainNavigatorState();
}

class _OwnerMainNavigatorState extends State<OwnerMainNavigator> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const OwnerDashboardScreen(),
    _buildPlaceholder('Halaman Admin'),
    _buildPlaceholder('Halaman Tagihan'),
    _buildPlaceholder('Halaman Banner/Premium'),
    _buildPlaceholder('Halaman Profil'),
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
      extendBody: true, // Allows body to scroll behind the floating navbar
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700), // Yellow from design
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.grid_view_rounded, 0),
              _buildNavItem(Icons.people_alt_outlined, 1),
              _buildNavItem(Icons.receipt_long_rounded, 2),
              _buildNavItem(Icons.stars_rounded, 3),
              _buildNavItem(Icons.person_outline_rounded, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: isSelected
            ? const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFFFFD700) : Colors.black,
          size: 24,
        ),
      ),
    );
  }
}
