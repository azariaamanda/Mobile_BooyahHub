import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_constants.dart';
import 'owner_dashboard_screen.dart';
import 'admin_verification_page.dart';
import 'premium_management_screen.dart';
import 'owner_profile_screen.dart';

class OwnerMainNavigator extends StatefulWidget {
  const OwnerMainNavigator({super.key});

  @override
  State<OwnerMainNavigator> createState() => _OwnerMainNavigatorState();
}

class _OwnerMainNavigatorState extends State<OwnerMainNavigator>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late final AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  static const _icons = [
    Icons.grid_view_rounded,
    Icons.people_alt_outlined,
    Icons.stars_rounded,
    Icons.person_outline_rounded,
  ];

  late final List<Widget> _pages = [
    const OwnerDashboardScreen(),
    const AdminVerificationPage(),
    const PremiumManagementScreen(),
    OwnerProfileScreen(
      onNavigateTab: (index) => _selectTab(index),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = AlwaysStoppedAnimation(0.0);
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    final from = _slideAnim.value;
    _slideAnim = Tween<double>(begin: from, end: index.toDouble()).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOut),
    );
    _slideCtrl.forward(from: 0);
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedIndex, children: _pages),
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
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTab(i),
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: Icon(_icons[i],
                                        color: iconColor, size: 22),
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
