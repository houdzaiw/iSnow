import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/room/barrage/room_barrage_host.dart';
import 'package:project/classes/room/barrage/room_barrage_provider.dart';
import 'package:project/classes/room/barrage/room_barrage_view_model.dart';
import 'package:project/classes/room/more/room_entry_flow.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/localization/app_localizations.dart';
import 'support/precache_room_assets.dart';
import 'room_barrage_view_model_test.dart'
    show BarrageTestRepository, BarrageTestNavigator;
import 'room_barrage_parser_test.dart'
    show barrageMessage, giftBanner, barrageNow;

void main() {
  setUpAll(() async {
    await (FontLoader('Roboto')..addFont(
          File(
            'test/fixtures/fonts/Roboto-Regular.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'account banner text and click fit $width without blocking room',
      (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = BarrageTestRepository()..current = const RoomState();
        final vm =
            RoomBarrageViewModel(repo, now: () => barrageNow, startTimer: false)
              ..syncRoom()
              ..bindIdentity(10);
        final navigation = BarrageTestNavigator();
        var roomTaps = 0;
        final router = GoRouter(
          initialLocation: '/party',
          routes: [
            GoRoute(
              path: '/party',
              builder: (_, __) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => roomTaps++,
                    child: const Text('Room remains available'),
                  ),
                ),
              ),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [roomBarrageProvider.overrideWith((ref) => vm)],
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, __) => MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                theme: AppTheme.light,
                localizationsDelegates: const [AppLocalizations.delegate],
                builder: (_, child) => RepaintBoundary(
                  key: const ValueKey('barrage-canvas'),
                  child: RoomBarrageHost(
                    router: router,
                    navigator: navigation,
                    child: child!,
                  ),
                ),
              ),
            ),
          ),
        );
        vm.receive(
          barrageMessage('RoomGiftSendBannerEvent', {
            ...giftBanner(room: '999'),
            'giftPic': AppAssets.lanhuRoomGiftCoin,
            'bannerContentObj': {
              'en': 'Sender sent a very long gift title ×9999 to the room',
            },
          }),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        final banner = find.byKey(const ValueKey('room-account-barrage'));
        expect(banner, findsOneWidget);
        final rect = tester.getRect(banner);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
        await precacheRoomAssets(
          tester,
          tester.element(find.byType(Scaffold).first),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<RawImage>(find.byType(RawImage))
              .any((image) => image.image != null),
          isTrue,
        );
        await expectLater(
          find.byKey(const ValueKey('barrage-canvas')),
          matchesGoldenFile(
            'goldens/room_barrage_v1/banner_${width.toInt()}.png',
          ),
        );
        await tester.tap(find.text('Room remains available'));
        expect(roomTaps, 1);
        await tester.pump();
        await tester.tap(banner);
        await tester.pump();
        expect(navigation.calls, ['enter:999']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        router.dispose();
        await repo.events.close();
      },
    );
  }
  testWidgets('local prize shows actual amount and closes on account change', (
    tester,
  ) async {
    final repo = BarrageTestRepository()..current = const RoomState();
    final vm =
        RoomBarrageViewModel(repo, now: () => barrageNow, startTimer: false)
          ..syncRoom()
          ..bindIdentity(10);
    final router = GoRouter(
      initialLocation: '/party',
      routes: [
        GoRoute(
          path: '/party',
          builder: (_, __) => const Scaffold(body: Center(child: Text('Room'))),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [roomBarrageProvider.overrideWith((ref) => vm)],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: AppTheme.light,
            localizationsDelegates: const [AppLocalizations.delegate],
            builder: (_, child) =>
                RoomBarrageHost(router: router, child: child!),
          ),
        ),
      ),
    );
    vm.receive(
      barrageMessage('RoomLobbyBigWinPrizeEvent', {
        'userWinCoins': 88,
        'gameName': 'Game',
      }, channel: 'global:10'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('room-account-barrage')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    vm.bindIdentity(20);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Room'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    router.dispose();
    await repo.events.close();
  });

  testWidgets(
    'locked-room password dialog is owned and cancelled on account change',
    (tester) async {
      final repo = BarrageTestRepository();
      final vm =
          RoomBarrageViewModel(repo, now: () => barrageNow, startTimer: false)
            ..syncRoom()
            ..bindIdentity(10);
      final router = GoRouter(
        initialLocation: '/party',
        routes: [
          GoRoute(
            path: '/party',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('Room'))),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomBarrageProvider.overrideWith((ref) => vm),
            roomEntryInfoProvider(
              '999',
            ).overrideWith((ref) async => {'roomLock': true}),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: const [AppLocalizations.delegate],
              builder: (_, child) =>
                  RoomBarrageHost(router: router, child: child!),
            ),
          ),
        ),
      );
      vm.receive(
        barrageMessage('RoomGiftSendBannerEvent', giftBanner(room: '999')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('room-account-barrage')));
      await tester.pumpAndSettle();
      expect(find.text('Room password'), findsOneWidget);
      await tester.showKeyboard(find.byType(TextField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      expect(tester.takeException(), isNull);
      vm.bindIdentity(20);
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pump(kThemeAnimationDuration);
      expect(find.byType(AlertDialog), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/party');
      expect(RoomManager.instance.state.status, RoomStatus.idle);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      router.dispose();
      await repo.events.close();
    },
  );
}
