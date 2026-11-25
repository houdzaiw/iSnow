import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/profile/binding/account_binding_page.dart';
import 'package:project/classes/profile/binding/account_binding_repository.dart';
import 'package:project/classes/profile/rewards/daily_reward_page.dart';
import 'package:project/classes/profile/rewards/daily_reward_repository.dart';
import 'package:project/classes/profile/rewards/daily_reward_view_model.dart';
import 'package:project/classes/profile/store/backpack_page.dart';
import 'package:project/classes/profile/store/store_page.dart';
import 'package:project/classes/profile/store/store_repository.dart';
import 'package:project/classes/profile/store/store_recipient_sheet.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/theme/app_theme.dart';
import 'support/profile_tools_fakes.dart';
import 'package:project/classes/profile/tools/profile_feature_repository.dart';
import 'package:project/classes/profile/views/profile_content_view.dart';
import 'package:project/classes/profile/mine/profile_state.dart';
import 'package:project/classes/profile/mine/profile_menu_item.dart';
import 'package:project/classes/profile/membership/membership_state.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  final key = GlobalKey();
  late ProfileToolsFake f;
  setUp(() {
    f = ProfileToolsFake();
    f.data[HttpApi.backpackGifts] = [];
    f.data[HttpApi.backpackUserProps] = [];
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
  Future<void> mount(WidgetTester tester, Widget page, double width) async {
    tester.view.physicalSize = Size(width, width == 320 ? 640 : 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileFeatureRepositoryProvider.overrideWithValue(f.features),
          storeRepositoryProvider.overrideWithValue(
            StoreRepository(f.features),
          ),
          dailyRewardProvider.overrideWith(
            (ref) => DailyRewardViewModel(DailyRewardRepository(f.features)),
          ),
          accountBindingRepositoryProvider.overrideWithValue(
            AccountBindingRepository(
              f.features,
              encrypt: (s) async => 'fixture-encrypted',
            ),
          ),
        ],
        child: RepaintBoundary(
          key: key,
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
    await tester.runAsync(() async {
      final context = key.currentContext!;
      await Future.wait([
        precacheImage(const AssetImage(AppAssets.profileAvatar), context),
        precacheImage(const AssetImage(AppAssets.iconMissing), context),
        precacheImage(const AssetImage(AppAssets.backButton), context),
      ]);
    });
    await settle(tester);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    const dir = String.fromEnvironment('PROFILE_TOOLS_CAPTURE_DIR');
    if (dir.isNotEmpty) {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final img = await boundary.toImage();
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$dir/$name');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        img.dispose();
      });
    } else {
      await expectLater(find.byKey(key), matchesGoldenFile('goldens/$name'));
    }
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'Store many plans and long product name at $width; cancel buys nothing',
      (tester) async {
        f.data[HttpApi.storeProducts] = {
          'totalPage': 1,
          'shopPropList': [
            {
              ...ProfileToolsFake.product(),
              'name':
                  'A long product name which must wrap without hiding controls',
              'icon': AppAssets.profileAvatar,
              'priceList': [
                for (final day in [1, 7, 14, 30, 90, 365])
                  {'day': day, 'currencyType': 1, 'price': 50},
              ],
            },
          ],
        };
        await mount(tester, const StorePage(), width);
        expect(tester.takeException(), isNull);
        await capture(tester, 'profile_tools_v1_store_${width.toInt()}.png');
        await tester.tap(find.text('Buy'));
        await settle(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await settle(tester);
        expect(f.count(HttpApi.storePurchase), 0);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    testWidgets('Backpack at $width', (tester) async {
      f.data[HttpApi.profileProps] = [
        {...ProfileToolsFake.prop(), 'icon': AppAssets.profileAvatar},
      ];
      await mount(tester, const BackpackPage(), width);
      expect(tester.takeException(), isNull);
      await capture(tester, 'profile_tools_v2_backpack_${width.toInt()}.png');
      expect(f.count(HttpApi.profileUseProp), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Daily rewards at $width', (tester) async {
      await mount(tester, const DailyRewardPage(), width);
      expect(tester.takeException(), isNull);
      await capture(tester, 'profile_tools_v1_daily_${width.toInt()}.png');
      expect(f.count(HttpApi.dailySign), 0);
      expect(f.count(HttpApi.dailyClaim), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Binding at $width keeps submit reachable with keyboard', (
      tester,
    ) async {
      await mount(tester, const AccountBindingPage(), width);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '55555555');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.ensureVisible(fields.last);
      await tester.tap(fields.last);
      await settle(tester);
      await tester.ensureVisible(find.text('Confirm'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      await capture(
        tester,
        'profile_tools_v1_binding_keyboard_${width.toInt()}.png',
      );
      expect(f.count(HttpApi.sendSms), 0);
      expect(f.count(HttpApi.profileBindPhone), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'recipient clears old selected user and cannot confirm unknown ID',
    (tester) async {
      await mount(tester, const Scaffold(body: StoreRecipientSheet()), 375);
      await tester.enterText(find.byType(TextField), '10088');
      await tester.tap(find.text('Search'));
      await settle(tester);
      expect(find.text('Receiver · 10088'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '999');
      await tester.pump();
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.text('Receiver · 10088'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'both white cards expose all available entries without clipping',
    (tester) async {
      final actions = <String>[];
      final badges = [
        for (var i = 0; i < 9; i++)
          ProfileBadgeItem(
            iconAsset: AppAssets.lanhuProfileBadge06,
            titleKey: '',
            title: 'Tool $i',
            webPath: '',
            destination: const ProfileDestination(
              ProfileDestinationKind.dailyReward,
              '/daily-reward',
            ),
          ),
      ];
      await mount(
        tester,
        Scaffold(
          body: ProfileContentView(
            state: ProfileState.initial().copyWith(badgeItems: badges),
            membership: const MembershipState(),
            onRefresh: () async {},
            onEditProfile: () {},
            onAvatarAction: () {},
            onMetricAction: (_) {},
            onVipTap: () {},
            onNobleTap: () {},
            onMenuAction: (item) => actions.add(item.action),
            onBadgeAction: (item) => actions.add(item.title),
          ),
        ),
        320,
      );
      for (final label in ['Wallet', 'Invite friends', 'Store']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
      }
      for (var i = 0; i < 9; i++) {
        await tester.ensureVisible(find.text('Tool $i'));
        await tester.tap(find.text('Tool $i'));
      }
      expect(actions, [
        'wallet',
        'invite-friends',
        'store',
        for (var i = 0; i < 9; i++) 'Tool $i',
      ]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Store failed balance and long error fit narrow screen and retry does not buy',
    (tester) async {
      f.errors[HttpApi.walletPurse] = StateError(
        List.filled(20, 'Long network error').join(' '),
      );
      await mount(tester, const StorePage(), 320);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Retry'));
      await settle(tester);
      expect(f.count(HttpApi.storePurchase), 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
