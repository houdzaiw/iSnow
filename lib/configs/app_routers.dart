// dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:project/classes/message/chat_page.dart';
import 'package:project/classes/message/message_page.dart';
import 'package:project/classes/profile/block_list_page.dart';
import 'package:project/classes/profile/my_posts_page.dart';
import 'package:project/classes/profile/setting_profile_page.dart';
import 'package:project/classes/web/web_view_page.dart';

import '../classes/detail/post_detail_page.dart';
import '../classes/home/home_page.dart';
import '../classes/oauth/agree_policy_page.dart';
import '../classes/oauth/login_page.dart';
import '../classes/party/party_page.dart';
import '../classes/profile/about_us_page.dart';
import '../classes/profile/edit_profile_page.dart';
import '../classes/profile/edit_nickname_page.dart';
import '../classes/profile/homepage/profile_homepage_page.dart';
import '../classes/profile/mine/profile_page.dart';
import '../classes/profile/relations/profile_relation_page.dart';
import '../classes/profile/settings_page.dart';
import '../classes/rank/rank_page.dart';
import '../classes/launch_page.dart';
import '../classes/oauth/login_detail_page.dart';
import '../classes/oauth/register_page.dart';
import '../manager/app_navigation.dart';
import '../manager/app_shell.dart';

const String _initialRoute = String.fromEnvironment(
  'INITIAL_ROUTE',
  defaultValue: '/launch',
);

final GoRouter goRouter = GoRouter(
  navigatorKey: appRootNavigatorKey,
  initialLocation: _initialRoute,
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
      builder: (context, state) => LoginDetailPage(
        initialAreaCode: state.uri.queryParameters['areaCode'],
        initialCountryCode: state.uri.queryParameters['countryCode'],
      ),
    ),
    // 注册页（不需要底部导航）
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => RegisterPage(
        initialPhone: state.uri.queryParameters['phone'],
        initialAreaCode: state.uri.queryParameters['areaCode'],
        initialCountryCode: state.uri.queryParameters['countryCode'],
      ),
    ),
    // 编辑资料页（不需要底部导航）
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    // 编辑昵称页（不需要底部导航）
    GoRoute(
      path: '/edit-nickname',
      name: 'edit-nickname',
      builder: (context, state) => const EditNicknamePage(),
    ),
    GoRoute(
      path: '/my-posts',
      name: 'my-posts',
      builder: (context, state) => const MyPostsPage(),
    ),
    GoRoute(
      path: '/web-view',
      name: 'web-view',
      builder: (context, state) {
        final title = state.uri.queryParameters['title'] ?? 'WebView';
        final uri = state.uri.queryParameters['uri'] ?? '';
        return WebViewPage(title: title, uri: uri);
      },
    ),
    GoRoute(
      path: '/about-us',
      name: 'about-us',
      builder: (context, state) => const AboutUsPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/rank',
      name: 'rank',
      builder: (context, state) => const RankPage(),
    ),
    GoRoute(
      path: '/chat-view',
      name: 'chat-view',
      builder: (context, state) => ChatPage(
        targetUID: state.uri.queryParameters['targetUID'] ?? '',
        title: state.uri.queryParameters['title'],
      ),
    ),
    GoRoute(
      path: '/post_detail-view',
      name: 'post_detail-view',
      builder: (context, state) =>
          PostDetailPage(entry: state.extra as dynamic),
    ),
    GoRoute(
      path: '/agree_policy-view',
      name: 'agree_policy-view',
      builder: (context, state) => AgreePolicyPage(),
    ),
    GoRoute(
      path: '/setting-view',
      name: 'setting-view',
      builder: (context, state) => SettingProfilePage(),
    ),
    GoRoute(
      path: '/block-list',
      name: 'block-list',
      builder: (context, state) => BlockListPage(),
    ),
    GoRoute(
      path: '/profile-relations/:type',
      name: 'profile-relations',
      builder: (context, state) => ProfileRelationPage(
        type: ProfileRelationType.fromRoute(
          state.pathParameters['type'] ?? 'followers',
        ),
      ),
    ),
    GoRoute(
      path: '/profile-homepage/:targetUid',
      name: 'profile-homepage',
      builder: (context, state) {
        final targetUid =
            int.tryParse(state.pathParameters['targetUid'] ?? '') ?? 0;
        return ProfileHomepagePage(targetUid: targetUid);
      },
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
          path: '/party',
          name: 'party',
          builder: (context, state) => const PartyPage(),
        ),
        // GoRoute(
        //   path: '/calendar',
        //   name: 'calendar',
        //   builder: (context, state) => const CalendarPage(),
        // ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/messages',
          name: 'messages',
          builder: (context, state) => const MessagePage(),
        ),
      ],
    ),
  ],
);
