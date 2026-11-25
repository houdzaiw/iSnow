import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/profile/about_us_page.dart';
import 'package:project/classes/profile/block_list_page.dart';
import 'package:project/classes/profile/binding/account_binding_page.dart';
import 'package:project/classes/profile/honor/honor_page.dart';
import 'package:project/classes/profile/mine/profile_models.dart';
import 'package:project/classes/profile/mine/profile_page.dart';
import 'package:project/classes/profile/membership/membership_view_model.dart';
import 'package:project/classes/profile/membership/membership_state.dart';
import 'package:project/classes/profile/tools/profile_menu_repository.dart';
import 'package:project/classes/profile/mine/profile_repository.dart';
import 'package:project/classes/profile/settings/account_security_page.dart';
import 'package:project/classes/profile/settings/about_view_model.dart';
import 'package:project/classes/profile/settings_page.dart';
import 'package:project/classes/profile/store/backpack_page.dart';
import 'package:project/classes/profile/tools/profile_feature_repository.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/user_profile.dart';
import 'package:project/theme/app_theme.dart';
import 'profile_menu_completion_test.dart' show TestAppManager, me, badge;
import 'support/profile_tools_fakes.dart';

class MenuMembershipModel extends MembershipViewModel {
  @override
  MembershipState build() =>
      const MembershipState(loadingVip: false, loadingNoble: false);
  @override
  Future<void> load({bool force = false}) async {}
}

class ViewProfileRepository implements ProfileRepository {
  int submits = 0;
  @override
  Future<ProfileAccountSummary?> cachedProfile() async =>
      ProfileAccountSummary.cached(const UserData(uid: 10));
  @override
  Future<ProfileAccountSummary> fetchProfile() async =>
      ProfileAccountSummary.cached(const UserData(uid: 10));
  @override
  Future<void> logout() async {
    submits++;
  }

  @override
  Future<void> deleteAccount() async {
    submits++;
  }
}

Future<void> settleView(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late ProfileToolsFake f;
  late ViewProfileRepository profile;
  final boundaryKey = GlobalKey();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    f = ProfileToolsFake();
    profile = ViewProfileRepository();
    f.data[HttpApi.myUserInfo] = me();
    f.data[HttpApi.medalWearingNum] = {'wearingNum': 3};
    f.data[HttpApi.medalShowList] = [
      {
        ...badge('a'),
        'medalNameEn': 'A long medal title that should wrap gracefully',
        'medalStages': [
          {
            'stage': 1,
            'icon': AppAssets.profileAvatar,
            'descEn': 'Detailed description\nSecond paragraph',
          },
        ],
      },
      badge('b'),
      badge('c', current: 0),
    ];
    f.data[HttpApi.medalAchieved] = [];
    f.data[HttpApi.backpackGifts] = [
      {
        'giftId': 600,
        'giftName': 'Gift with a long descriptive name',
        'icon': AppAssets.profileAvatar,
        'amount': 3,
      },
    ];
    f.data[HttpApi.backpackUserProps] = [
      {'goodsId': 900, 'name': 'Prop', 'amount': 2},
    ];
    f.data[HttpApi.userBlacklist] = {
      'list': [
        {
          'targetUserInfo': {
            'uid': 88,
            'userNo': 10088,
            'nick': 'A very long nickname to fit on a small phone screen',
            'avatar': AppAssets.profileAvatar,
          },
        },
      ],
    };
    f.data[HttpApi.profileAccountBindings] = [
      {'bandingType': 5, 'isBanding': false},
      {'bandingType': 0, 'isBanding': true, 'accountId': 'user@example.org'},
      {'bandingType': 1, 'isBanding': false},
    ];
  });
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(
        File(
          'test/fixtures/fonts/Roboto-Regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await font.load();
  });
  Future<void> mount(
    WidgetTester tester,
    Widget page,
    double width, {
    GoRouter? router,
  }) async {
    tester.view.physicalSize = Size(width, width == 320 ? 640 : 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = router == null
        ? MaterialApp(
            home: page,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light.copyWith(
              textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
              appBarTheme: AppTheme.light.appBarTheme.copyWith(
                titleTextStyle: AppTextStyles.navTitle.copyWith(
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            localizationsDelegates: const [AppLocalizations.delegate],
            supportedLocales: const [Locale('en'), Locale('zh')],
          )
        : MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light,
            localizationsDelegates: const [AppLocalizations.delegate],
            supportedLocales: const [Locale('en'), Locale('zh')],
          );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileFeatureRepositoryProvider.overrideWithValue(f.features),
          membershipViewModelProvider.overrideWith(MenuMembershipModel.new),
          profileMenuProvider.overrideWith(
            (ref) async => const ProfileMenuResult([]),
          ),
          profileRepositoryProvider.overrideWithValue(profile),
          profileAppInfoManagerProvider.overrideWithValue(TestAppManager()),
        ],
        child: RepaintBoundary(key: boundaryKey, child: app),
      ),
    );
    await settleView(tester);
    await tester.runAsync(() async {
      final context = boundaryKey.currentContext!;
      for (final asset in [
        AppAssets.profileAvatar,
        AppAssets.iconMissing,
        AppAssets.backButton,
        AppAssets.appLogo,
        AppAssets.profileMenuSettings,
        AppAssets.membershipVipBadge,
        AppAssets.profileMenuBlockList,
        AppAssets.roomProfileChevron,
        AppAssets.lanhuProfileMenuAbout,
        AppAssets.lanhuProfileMenuTerms,
        AppAssets.lanhuProfileMenuPrivacy,
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await settleView(tester);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull);
    const dir = String.fromEnvironment('PROFILE_MENU_CAPTURE_DIR');
    if (dir.isNotEmpty) {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$dir/$name').create(recursive: true);
        await File('$dir/$name').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    } else {
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/profile_menu_v1/$name'),
      );
    }
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('Honor edit preview and cancel at $width', (tester) async {
      await mount(tester, const HonorPage(), width);
      expect(find.text('Achievement'), findsOneWidget);
      await capture(tester, 'honor_${width.toInt()}.png');
      await tester.tap(
        find.text('A long medal title that should wrap gracefully'),
      );
      await settleView(tester);
      expect(
        find.text('Detailed description\nSecond paragraph'),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await settleView(tester);
      await tester.tap(find.text('Edit'));
      await settleView(tester);
      await tester.tap(find.text('English').first);
      await settleView(tester);
      await tester.tap(find.text('Cancel'));
      await settleView(tester);
      expect(f.count(HttpApi.medalWear), 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Backpack Gifts default and all eight tabs at $width', (
      tester,
    ) async {
      await mount(tester, const BackpackPage(initialGifts: true), width);
      expect(find.text('×3'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(8));
      await capture(tester, 'backpack_gifts_${width.toInt()}.png');
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Settings scroll and destructive cancel at $width', (
      tester,
    ) async {
      await mount(tester, const SettingsPage(), width);
      expect(find.text('Account Security'), findsOneWidget);
      expect(find.text('VIP Settings'), findsOneWidget);
      await capture(tester, 'settings_${width.toInt()}.png');
      await tester.ensureVisible(find.text('Log Out'));
      await tester.tap(find.text('Log Out'));
      await settleView(tester);
      await tester.tap(find.text('Cancel'));
      await settleView(tester);
      expect(profile.submits, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Server blacklist long name and cancel at $width', (
      tester,
    ) async {
      await mount(tester, const BlockListPage(), width);
      expect(find.text('ID: 10088'), findsOneWidget);
      await capture(tester, 'blacklist_${width.toInt()}.png');
      await tester.tap(find.text('Unblock'));
      await settleView(tester);
      await tester.tap(find.text('Cancel'));
      await settleView(tester);
      expect(f.count(HttpApi.userBlacklistUpdate), 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('About actual version and update errors at $width', (
      tester,
    ) async {
      await mount(tester, const AboutUsPage(), width);
      expect(find.text('iSnow'), findsOneWidget);
      expect(find.text('3.2.1+123'), findsOneWidget);
      expect(f.count(HttpApi.appVersion), 0);
      await capture(tester, 'about_${width.toInt()}.png');
      f.envelopes[HttpApi.appVersion] = {
        'code': 1003,
        'msg':
            'A very long error message returned by the server. Please try again later.',
      };
      await tester.tap(find.text('Check for updates'));
      await settleView(tester);
      expect(find.text('You are using the latest version.'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'Account overview opens phone binding without sending SMS; social is read-only',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/account',
        routes: [
          GoRoute(
            path: '/account',
            builder: (_, _) => const AccountSecurityPage(),
          ),
          GoRoute(
            path: '/account-binding',
            builder: (_, _) => const AccountBindingPage(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await mount(tester, const SizedBox(), 375, router: router);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Facebook'), findsNothing);
      await tester.tap(find.text('Bind'));
      await settleView(tester);
      expect(find.byType(AccountBindingPage), findsOneWidget);
      expect(f.count(HttpApi.sendSms), 0);
      expect(f.count(HttpApi.profileBindPhone), 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('medal limit error disables Edit and retry loads safely', (
    tester,
  ) async {
    f.envelopes[HttpApi.medalWearingNum] = {
      'code': 1003,
      'msg': 'limit failed',
    };
    await mount(tester, const HonorPage(), 375);
    expect(find.text('limit failed'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await settleView(tester);
    expect(find.text('Save'), findsNothing);
    f.envelopes.clear();
    await tester.tap(find.text('Retry'));
    await settleView(tester);
    await tester.tap(find.text('Edit'));
    await settleView(tester);
    expect(find.text('Save'), findsOneWidget);
    expect(f.count(HttpApi.medalWear), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('all seven Profile menu actions route to real destinations', (
    tester,
  ) async {
    Uri? opened;
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
        for (final path in [
          '/honor',
          '/backpack',
          '/settings',
          '/about-us',
          '/web-view',
        ])
          GoRoute(
            path: path,
            builder: (_, state) {
              opened = state.uri;
              return const Scaffold(body: Text('destination'));
            },
          ),
      ],
    );
    addTearDown(router.dispose);
    await mount(tester, const SizedBox(), 375, router: router);
    for (final entry in {
      'Level': '/web-view',
      'Backpack': '/backpack',
      'Honor (0)': '/honor',
      'Settings': '/settings',
      'About us': '/about-us',
      'Privacy Policy': '/web-view',
      'Terms of use': '/web-view',
    }.entries) {
      final target = find.text(entry.key);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await settleView(tester);
      expect(opened?.path, entry.value, reason: entry.key);
      if (entry.key == 'Level') {
        expect(opened!.queryParameters['hiddenAppBar'], 'true');
        expect(
          Uri.parse(opened!.queryParameters['uri']!).path,
          '/h5/userlevel/index.html',
        );
      }
      if (entry.key == 'Privacy Policy') {
        expect(opened!.queryParameters['hiddenAppBar'], isNull);
        expect(
          opened!.queryParameters['uri'],
          'https://www.simisoul.com/policy.html',
        );
      }
      if (entry.key == 'Terms of use') {
        expect(opened!.queryParameters['hiddenAppBar'], isNull);
        expect(
          opened!.queryParameters['uri'],
          'https://www.simisoul.com/protocol.html',
        );
      }
      router.pop();
      await settleView(tester);
    }
    expect(find.text('Coming soon'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'VIP transfer freezes item and recipient; cancelling never submits',
    (tester) async {
      await mount(tester, const BackpackPage(), 375);
      await tester.tap(find.text('Transfer (VIP 5+)'));
      await settleView(tester);
      await tester.enterText(
        find.byKey(const ValueKey('store-recipient-input')),
        '10088',
      );
      await tester.tap(find.text('Search'));
      await settleView(tester);
      await tester.tap(find.text('Confirm'));
      await settleView(tester);
      expect(
        find.text(
          'Transfer Owned frame to Receiver (88)? No purchase will be made.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await settleView(tester);
      expect(f.count(HttpApi.backpackTransfer), 0);
      expect(f.count(HttpApi.storePurchase), 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
