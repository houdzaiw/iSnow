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
    '/calendar',
    '/messages',
    '/profile',
  ];

  int _locationToIndex(String location) {
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      backgroundColor: AppColors.pageBackground,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: Colors.transparent,
        unselectedItemColor: Colors.transparent,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        enableFeedback: false,
        onTap: (index) {
          final target = _tabs[index];
          if (location != target) {
            context.go(target);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: _AssetTabIcon(asset: AppAssets.tabHomeNormal),
            activeIcon: _AssetTabIcon(asset: AppAssets.tabHomeActive),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const _IconTabIcon(
              icon: Icons.calendar_month,
              color: AppColors.tabInactive,
            ),
            activeIcon: const _IconTabIcon(
              icon: Icons.calendar_month,
              color: AppColors.primaryPink,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _AssetTabIcon(asset: AppAssets.tabMessageNormal),
            activeIcon: _AssetTabIcon(asset: AppAssets.tabMessageActive),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _AssetTabIcon(asset: AppAssets.tabProfileNormal),
            activeIcon: _AssetTabIcon(asset: AppAssets.tabProfileActive),
            label: '',
          ),
        ],
      ),
    );
  }
}

class _AssetTabIcon extends StatelessWidget {
  final String asset;

  const _AssetTabIcon({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Image.asset(asset, width: 36, height: 36),
    );
  }
}

class _IconTabIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconTabIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Icon(icon, size: 30, color: color),
    );
  }
}
