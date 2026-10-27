import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/models/room_more_tools_models.dart';
import 'package:project/classes/room/more/room_big_win_page.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/more/room_tools_strip.dart';
import 'package:project/classes/room/room_more_tools_repository.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_more_tools_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/theme/app_theme.dart';

import 'support/precache_room_assets.dart';
import 'support/room_tools_fakes.dart';

ToolJson _activity(int status) => {
  'status': status,
  'gameBigWinInfoVO': {
    'gameBigWinId': '42',
    'gameId': 'game-1',
    'gameName': 'Game',
    'bigWinTotalCoins': 1000000,
    'winRoundCount': 3,
    'curRound': 1,
  },
};

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(
        File(
          'test/fixtures/fonts/Roboto-Regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await font.load();
  });
  late ToolsRoomFake room;
  late ToolsApiFake api;
  late ProviderContainer container;
  late GoRouter router;
  setUp(() {
    room = ToolsRoomFake();
    api = ToolsApiFake();
    api.responses[HttpApi.roomFunctions] = [
      {
        'type': 8,
        'list': [
          {'position': 17},
        ],
      },
    ];
    api.responses[HttpApi.gameBigWinRank] = {'winUserList': []};
  });
  tearDown(() => room.dispose());
  final pendant = find.byKey(const ValueKey('room-big-win-pendant'));

  Future<void> mount(WidgetTester tester, {double width = 375}) async {
    tester.view.physicalSize = Size(width, 812);
    tester.view.devicePixelRatio = 1;
    router = GoRouter(
      initialLocation: '/room/123',
      routes: [
        GoRoute(
          path: '/room/:id',
          builder: (_, _) => const RoomPage(roomId: '123'),
        ),
        GoRoute(
          path: '/room-tool',
          builder: (_, state) => state.extra! as Widget,
        ),
        GoRoute(
          path: '/party',
          builder: (_, _) => const Scaffold(body: Text('Party')),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomRepositoryProvider.overrideWithValue(room),
          roomToolsRepositoryProvider.overrideWithValue(api),
          roomGiftRepositoryProvider.overrideWithValue(_Gifts()),
          roomMoreToolsRepositoryProvider.overrideWithValue(_Banners()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: const [AppLocalizations.delegate],
            builder: (_, child) => RepaintBoundary(
              key: const ValueKey('big-win-room-snapshot'),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(RoomPage)),
    );
  }

  Future<void> refresh(WidgetTester tester, Object? data) async {
    api.responses[HttpApi.gameBigWinShow] = data;
    await container
        .read(roomToolsControllerProvider('123').notifier)
        .refreshBigWin();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'enabled configuration does not create an unconditional text entry',
    (tester) async {
      await mount(tester);
      expect(pendant, findsNothing);
      expect(find.text('Big Win'), findsNothing);
      expect(tester.getSize(find.byType(RoomToolsStrip)).height, 0);
      await refresh(tester, _activity(4));
      expect(pendant, findsNothing);
      await refresh(tester, {
        'status': 1,
        'gameBigWinInfoVO': {'bigWinTotalCoins': 1000000},
      });
      expect(pendant, findsNothing);
      expect(tester.getSize(find.byType(RoomToolsStrip)).height, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'activity floats above the bottom bar without shrinking chat at $width',
      (tester) async {
        await mount(tester, width: width);
        final chatTop = tester.getTopLeft(find.text('All')).dy;
        await refresh(tester, _activity(1));
        final rect = tester.getRect(pendant);
        expect(rect.right, closeTo(width - AppSpacing.lg.w, .01));
        expect(
          rect.bottom,
          closeTo(
            812 - AppSpacing.roomBottomBarHeight.h - AppSpacing.sm.h,
            .01,
          ),
        );
        expect(
          rect.bottom,
          lessThan(
            tester
                .getTopLeft(
                  find.image(const AssetImage(AppAssets.lanhuRoomBottomMore)),
                )
                .dy,
          ),
        );
        expect(tester.getTopLeft(find.text('All')).dy, chatTop);
        expect(tester.getSize(find.byType(RoomToolsStrip)).height, 0);
        expect(
          find.image(const AssetImage(AppAssets.lanhuRoomBigWinBanner)),
          findsOneWidget,
        );
        expect(find.text('1M'), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
        await tester.tapAt(Offset(24, rect.center.dy));
        await tester.pumpAndSettle();
        expect(find.byType(RoomBigWinPage), findsNothing);
        await precacheRoomAssets(tester, tester.element(pendant));
        await expectLater(
          find.byKey(const ValueKey('big-win-room-snapshot')),
          matchesGoldenFile(
            'goldens/room_big_win_pendant_${width.toInt()}.png',
          ),
        );
        await refresh(tester, _activity(4));
        expect(pendant, findsNothing);
        expect(tester.getTopLeft(find.text('All')).dy, chatTop);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('tap refreshes activity and keeps preview/results APIs', (
    tester,
  ) async {
    api.responses[HttpApi.gameBigWinShow] = _activity(1);
    await mount(tester);
    final before = api.count(HttpApi.gameBigWinShow);
    await tester.tap(pendant);
    await tester.pumpAndSettle();
    expect(find.byType(RoomBigWinPage), findsOneWidget);
    expect(api.count(HttpApi.gameBigWinShow), before + 1);
    expect(api.count(HttpApi.gameBigWinRank), 0);
    router.pop();
    await tester.pumpAndSettle();
    await refresh(tester, _activity(2));
    await tester.tap(pendant);
    await tester.pumpAndSettle();
    expect(find.byType(RoomBigWinPage), findsOneWidget);
    expect(
      api.calls.lastWhere((call) => call.path == HttpApi.gameBigWinRank).body,
      {'gameBigWinId': 42, 'round': 1},
    );
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('personal prize remains separate when the activity has ended', (
    tester,
  ) async {
    api.responses[HttpApi.gameBigWinShow] = _activity(4);
    await mount(tester);
    room.event('RoomLobbyBigWinPrizeEvent', {
      'gameBigWinId': '42',
      'userWinCoins': 88,
    }, channel: 'global:10');
    await tester.pumpAndSettle();
    expect(pendant, findsNothing);
    expect(find.text('Big Win: 88'), findsOneWidget);
    container.read(roomToolsControllerProvider('123').notifier).dismissPrize();
    await tester.pumpAndSettle();
    expect(find.text('Big Win: 88'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keyboard and Keep hide the floating entry; restore retains activity',
    (tester) async {
      api.responses[HttpApi.gameBigWinShow] = _activity(1);
      await mount(tester);
      expect(pendant, findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(pendant, findsNothing);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(pendant, findsOneWidget);
      room.minimizeRoom();
      await tester.pumpAndSettle();
      expect(pendant, findsNothing);
      room.restoreRoom();
      router.go('/room/123');
      await tester.pumpAndSettle();
      expect(pendant, findsOneWidget);
      await room.leaveRoom();
      await tester.pumpAndSettle();
      expect(pendant, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Banners extends RoomMoreToolsRepository {
  @override
  Future<List<RoomToolBanner>> fetchBanners({
    required RoomMoreBannerPosition position,
    required String roomId,
  }) async => [];
}

class _Gifts extends RoomGiftRepository {
  @override
  Future<RoomGiftCatalog> fetchCatalog() async =>
      const RoomGiftCatalog(tabs: [], balance: 1000, canSendSelf: false);
  @override
  Future<int> fetchBalance() async => 1000;
  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async =>
      const RoomGiftSendResult();
}
