import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  // accept location from ShellRoute's GoRouterState
  final String location;
  const AppShell({required this.location, required this.child, super.key});

  static const List<String> _tabs = [
    '/home',
    '/party',
    '/messages',
    '/profile',
  ];

  int _locationToIndex(String location) {
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx < 0 ? 1 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      backgroundColor: AppColors.pageBackground,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(left: 22, right: 19, bottom: 28),
        child: SizedBox(
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.cardBackground.withValues(alpha: 0.6),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x1A252525), blurRadius: 4),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                backgroundColor: AppColors.transparent,
                selectedItemColor: AppColors.transparent,
                unselectedItemColor: AppColors.transparent,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                enableFeedback: false,
                onTap: (index) => _goToTab(context, index),
                items: const [
                  BottomNavigationBarItem(
                    icon: _ShellTabIcon(
                      asset: AppAssets.lanhuShellTabHome,
                      width: 27,
                      height: 26,
                    ),
                    activeIcon: _ShellTabIcon(
                      asset: AppAssets.lanhuShellTabHome,
                      width: 27,
                      height: 26,
                      selected: true,
                    ),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _ShellTabIcon(
                      asset: AppAssets.lanhuShellTabParty,
                      width: 26,
                      height: 26,
                    ),
                    activeIcon: _ShellTabIcon(
                      asset: AppAssets.lanhuShellTabParty,
                      width: 26,
                      height: 26,
                      selected: true,
                    ),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _ShellTabIcon(
                      asset: AppAssets.lanhuShellTabMessages,
                      width: 27,
                      height: 27,
                    ),
                    activeIcon: _ShellTabIcon(
                      asset: AppAssets.lanhuShellTabMessages,
                      width: 27,
                      height: 27,
                      selected: true,
                    ),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _ShellTabIcon(
                      asset: AppAssets.lanhuShellTabProfile,
                      width: 22,
                      height: 24,
                    ),
                    activeIcon: _ShellTabIcon(
                      asset: AppAssets.lanhuShellTabProfile,
                      width: 22,
                      height: 24,
                      selected: true,
                    ),
                    label: '',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToTab(BuildContext context, int index) {
    final target = _tabs[index];
    if (location != target) {
      context.go(target);
    }
  }
}

class _ShellTabIcon extends StatelessWidget {
  const _ShellTabIcon({
    required this.asset,
    required this.width,
    required this.height,
    this.selected = false,
  });

  final String asset;
  final double width;
  final double height;
  final bool selected;

  static const _selectedScale = 1.08;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: AnimatedScale(
        scale: selected ? _selectedScale : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Image.asset(
          asset,
          width: width,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
