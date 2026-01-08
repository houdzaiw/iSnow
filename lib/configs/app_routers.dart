// dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../classes/calendar_page.dart';
import '../classes/home_page.dart';
import '../classes/profile_page.dart';
import '../classes/launch_page.dart';
import '../classes/login_page.dart';
import '../classes/login_detail_page.dart';
import '../classes/register_page.dart';
import '../classes/edit_profile_page.dart';
import 'app_shell.dart';

final GoRouter goRouter = GoRouter(
  initialLocation: '/launch',
  routes: [
    // 启动页（不需要底部导航）
    GoRoute(
      path: '/launch',
      name: 'launch',
      builder: (context, state) => const LaunchPage(),
    ),
    // 登录页（不需要底部导航）
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    // 登录详情页（不需要底部导航）
    GoRoute(
      path: '/login-detail',
      name: 'login-detail',
      builder: (context, state) => const LoginDetailPage(),
    ),
    // 注册页（不需要底部导航）
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    // 编辑资料页（不需要底部导航）
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    // 主应用页面（带底部导航）
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AppShell(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          builder: (context, state) => const CalendarPage(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);
