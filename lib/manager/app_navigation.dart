import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>();

class AppNavigation {
  const AppNavigation._();

  static void goLogin() {
    final context = appRootNavigatorKey.currentContext;
    if (context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentContext = appRootNavigatorKey.currentContext;
      if (currentContext == null) return;
      currentContext.go('/login');
    });
  }
}
