// dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../classes/calendar_page.dart';
import '../classes/home_page.dart';
import '../classes/profile_page.dart';
import 'app_shell.dart';

final GoRouter goRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AppShell(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => HomePage(),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          builder: (context, state) => CalendarPage(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => ProfilePage(),
        ),
      ],
    ),
  ],
);
