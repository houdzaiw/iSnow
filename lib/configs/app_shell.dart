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
        onTap: (index) {
          final target = _tabs[index];
          if (location != target) {
            context.go(target);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '日历'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '个人'),
        ],
      ),
    );
  }
}
