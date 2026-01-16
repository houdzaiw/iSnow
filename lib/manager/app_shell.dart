import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  // accept location from ShellRoute's GoRouterState
  final String location;
  const AppShell({required this.location, required this.child, super.key});

  static const List<String> _tabs = ['/home', '/calendar', '/profile'];

  int _locationToIndex(String location) {
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFFF9E707),
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
            icon: Container(
              padding: const EdgeInsets.only(top: 6),
              child: Image.asset(
                'assets/tabbar/home_normal.png',
                width: 36,
                height: 36,
              ),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.only(top: 6),
              child: Image.asset(
                'assets/tabbar/home_select.png',
                width: 36,
                height: 36,
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.only(top: 6),
              child: Image.asset(
                'assets/tabbar/message_normal.png',
                width: 36,
                height: 36,
              ),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.only(top: 6),
              child: Image.asset(
                'assets/tabbar/message_select.png',
                width: 36,
                height: 36,
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.only(top: 6),
              child: Image.asset(
                'assets/tabbar/user_profile_normal.png',
                width: 36,
                height: 36,
              ),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.only(top: 6),
              child: Image.asset(
                'assets/tabbar/user_profile_select.png',
                width: 36,
                height: 36,
              ),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
