import 'package:booyahhub/presentation/user/user_pesanan.dart';
import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import 'user_home_screen.dart'; // Import halaman beranda lu
import 'scrim_page.dart';
import 'history_scrim_page.dart';
import 'user_profile_page.dart';

class UserMainNavigator extends StatefulWidget {
  const UserMainNavigator({super.key});

  @override
  State<UserMainNavigator> createState() => _UserMainNavigatorState();
}

class _UserMainNavigatorState extends State<UserMainNavigator> {
  int _currentIndex = 0;

  // DAFTAR HALAMAN YANG AKAN DIKONTROL OLEH BOTTOM NAV BAR
  final List<Widget> _pages = [
    const UserHomeScreen(),
    const UserPesananPage(),
    const HistoryScrimPage(),
    const UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body otomatis berubah sesuai index menu yang sedang aktif
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      // ================= BOTTOM NAVIGATION BAR (MOCKUP STYLE) =================
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(
            left: AppConstants.paddingM,
            right: AppConstants.paddingM,
            bottom: AppConstants.paddingM,
          ),
          height: 65,
          decoration: BoxDecoration(
            color: AppColors.primary, // Kuning emas tim lu
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
              _buildNavItem(Icons.home, "Beranda", 0),
              _buildNavItem(Icons.assignment, "Pesanan", 1),
              _buildNavItem(Icons.history, "Riwayat", 2),
              _buildNavItem(Icons.person, "Profil", 3),
            ],
          ),
        ),
      ),
    );
  }

  // HELPER WIDGET PIL KAPSUL AKTIF & TIDAK AKTIF
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;

    return isSelected
        ? Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM, 
              vertical: AppConstants.paddingS
            ),
            decoration: BoxDecoration(
              color: AppColors.background, // Background hitam gelap saat aktif
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
            icon: Icon(icon, color: AppColors.background), // Warna gelap saat mati
            onPressed: () {
              setState(() {
                _currentIndex = index; // Pindah halaman otomatis pas diklik
              });
            },
          );
  }
}