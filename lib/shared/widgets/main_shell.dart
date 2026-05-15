import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: _BottomNav(location: location),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String location;
  const _BottomNav({required this.location});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F0).withValues(alpha: 0.88),
            border: const Border(top: BorderSide(color: AppColors.line2, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 5 slots; middle slot is empty (filled by FAB)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(child: _NavItem(
                          icon: Icons.home_rounded, label: 'Home',
                          isActive: location == AppRoutes.home,
                          onTap: () => context.go(AppRoutes.home),
                        )),
                        Expanded(child: _NavItem(
                          icon: Icons.folder_outlined, label: 'Records',
                          isActive: false,
                          onTap: () {},
                        )),
                        const Expanded(child: SizedBox()), // FAB slot
                        Expanded(child: _NavItem(
                          icon: Icons.calendar_month_rounded, label: 'Care',
                          isActive: location == AppRoutes.careCalendar,
                          onTap: () => context.go(AppRoutes.careCalendar),
                        )),
                        Expanded(child: _NavItem(
                          icon: Icons.person_outline_rounded, label: 'Profile',
                          isActive: false,
                          onTap: () {},
                        )),
                      ],
                    ),
                  ),

                  // Center FAB — AI assistant
                  Positioned(
                    top: -12, left: 0, right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => context.go(AppRoutes.aiAssistant),
                        child: Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.25),
                                blurRadius: 16, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppColors.bone, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: isActive ? AppColors.ink : AppColors.stone2),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.notoSans(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.ink : AppColors.stone2,
              )),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 4 : 0, height: isActive ? 4 : 0,
            decoration: const BoxDecoration(
              color: AppColors.clay500, shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
