import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/profile/membership/membership_models.dart';
import 'package:project/classes/profile/membership/membership_repository.dart';
import 'package:project/classes/profile/membership/membership_view_model.dart';
import 'package:project/classes/profile/membership/views/membership_page.dart';
import 'package:project/classes/profile/membership/views/membership_settings_page.dart';
import 'package:project/classes/profile/membership/views/membership_titles_page.dart';
import 'package:project/classes/profile/mine/profile_models.dart';
import 'package:project/classes/profile/mine/profile_state.dart';
import 'package:project/classes/profile/views/profile_content_view.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/user_profile.dart';
import 'package:project/theme/app_theme.dart';

import 'support/membership_fakes.dart';

void main() {
  late MembershipFixture f;
  final captureKey = GlobalKey();
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(
        File(
          'test/fixtures/fonts/Roboto-Regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await font.load();
  });
  setUp(() => f = MembershipFixture());
  Future<void> mount(
    WidgetTester tester,
    Widget page, {
    double width = 375,
    double height = 812,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membershipRepositoryProvider.overrideWithValue(f.repository),
          membershipClockProvider.overrideWithValue(() => membershipNow),
        ],
        child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            theme: AppTheme.light.copyWith(
              textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
              appBarTheme: AppTheme.light.appBarTheme.copyWith(
                titleTextStyle: AppTextStyles.navTitle.copyWith(
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [AppLocalizations.delegate],
            supportedLocales: const [Locale('en'), Locale('zh')],
            home: page,
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    const directory = String.fromEnvironment('MEMBERSHIP_CAPTURE_DIR');
    if (directory.isNotEmpty) {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$directory/$name');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    } else {
      await expectLater(
        find.byKey(captureKey),
        matchesGoldenFile('goldens/$name'),
      );
    }
  }

  for (final width in [320.0, 375.0, 430.0]) {
    for (final kind in MembershipKind.values) {
      testWidgets('${kind.name} Nady layout at $width', (tester) async {
        await mount(
          tester,
          MembershipPage(kind: kind),
          width: width,
          height: width == 320 ? 640 : 812,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.text(kind == MembershipKind.vip ? 'VIP Center' : 'Aristocracy'),
          findsOneWidget,
        );
        await screenshot(
          tester,
          'profile_membership_v1_${kind.name}_${width.toInt()}.png',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets(
    'profile cards show actual status and each forwards its own tap',
    (tester) async {
      var vipTaps = 0, nobleTaps = 0;
      final profile = ProfileState.initial().copyWith(
        profile: ProfileAccountSummary.cached(
          UserData.fromJson({...membershipUser(), 'avatar': ''}),
        ),
      );
      await mount(
        tester,
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ProfileContentView(
              state: profile,
              membership: ref.watch(membershipViewModelProvider),
              onRefresh: () async {},
              onVipTap: () {
                vipTaps++;
              },
              onNobleTap: () {
                nobleTaps++;
              },
              onEditProfile: () {},
              onAvatarAction: () {},
              onMetricAction: (_) {},
              onBadgeAction: (_) {},
              onMenuAction: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('VIP 6'), findsOneWidget);
      expect(find.textContaining("It's been open"), findsNothing);
      await tester.tap(find.text('VIP 6'));
      await tester.tap(find.text('Aristocracy'));
      expect(vipTaps, 1);
      expect(nobleTaps, 1);
      expect(tester.takeException(), isNull);
      if (const String.fromEnvironment('MEMBERSHIP_CAPTURE_DIR').isNotEmpty) {
        await screenshot(tester, 'profile_membership_home_preview.png');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('purchase confirm may be cancelled without submitting', (
    tester,
  ) async {
    await mount(tester, const MembershipPage(kind: MembershipKind.vip));
    await tester.tap(find.text('Renew'));
    await settle(tester);
    expect(find.text('Please Confirm'), findsOneWidget);
    expect(find.textContaining('Spend 100 coins'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(f.api.count(HttpApi.membershipVipBuy), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'recipient sheet accommodates keyboard, failed search and close',
    (tester) async {
      await mount(
        tester,
        const MembershipPage(kind: MembershipKind.vip),
        width: 320,
        height: 640,
      );
      await tester.tap(find.text('Send'));
      await settle(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('membership-recipient-input')),
        'bad',
      );
      await tester.tap(find.text('Search'));
      await settle(tester);
      expect(find.text('Please enter a valid user ID'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('VIP Center'), findsOneWidget);
      expect(f.api.count(HttpApi.membershipVipBuy), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'settings exposes exactly two Nady switches and retains failed state',
    (tester) async {
      await mount(tester, const MembershipSettingsPage());
      expect(find.byType(Switch), findsNWidgets(2));
      expect(find.text('Do not disturb'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'gift flow confirms the resolved internal UID and sends one simulated request',
    (tester) async {
      await mount(
        tester,
        const MembershipPage(kind: MembershipKind.vip),
        width: 320,
        height: 640,
      );
      await tester.tap(find.text('Send'));
      await settle(tester);
      await tester.enterText(
        find.byKey(const ValueKey('membership-recipient-input')),
        '10020',
      );
      await tester.tap(find.text('Search'));
      await settle(tester);
      await tester.tap(find.text('Confirm'));
      await settle(tester);
      expect(find.text('Please Confirm'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await settle(tester);
      final call = f.api.calls.singleWhere(
        (c) => c.path == HttpApi.membershipVipBuy,
      );
      expect(call.arguments, {'gradeId': 1, 'targetUid': 20});
      expect(find.text('Successful'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('account replacement closes only membership owned overlays', (
    tester,
  ) async {
    await mount(tester, const MembershipPage(kind: MembershipKind.vip));
    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(
      find.byKey(const ValueKey('membership-recipient-input')),
      findsOneWidget,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MembershipPage)),
    );
    final replacement = MembershipFixture();
    replacement.account = (uid: 11, token: 'other', generation: 2);
    container.updateOverrides([
      membershipRepositoryProvider.overrideWithValue(replacement.repository),
      membershipClockProvider.overrideWithValue(() => membershipNow),
    ]);
    await settle(tester);
    expect(
      find.byKey(const ValueKey('membership-recipient-input')),
      findsNothing,
    );
    expect(find.text('VIP Center'), findsOneWidget);
    expect(f.api.count(HttpApi.membershipVipBuy), 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('title listing displays server artwork without claiming', (
    tester,
  ) async {
    await mount(tester, const MembershipTitlesPage());
    expect(find.text('King of stars'), findsOneWidget);
    expect(f.api.count(HttpApi.membershipNobleTitleClaim), 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  await tester.pumpAndSettle();
}
