import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/interaction/room_interaction_repository.dart';
import 'package:project/classes/room/models/room_more_tools_models.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/room_more_tools_repository.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_more_tools_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_models.dart';
import 'package:project/theme/app_theme.dart';

import 'precache_room_assets.dart';
import 'room_tools_fakes.dart';

class RoomLobbyHarness {
  final room = ToolsRoomFake();
  final api = ToolsApiFake();
  late ProviderContainer container;
  late GoRouter router;
  RoomToolsController get vm =>
      container.read(roomToolsControllerProvider('123').notifier);

  Future<void> mount(
    WidgetTester tester, {
    int type = 1,
    UserRoomIdentity role = UserRoomIdentity.owner,
    List<int> positions = const [1, 2, 7],
    bool bigWin = false,
    double width = 375,
    double height = 812,
    RoomInteractionRepository? interaction,
  }) async {
    room.current = room.current.copyWith(
      enterResponse: EnterRoomResp(
        roomId: '123',
        identity: role,
        status: type == 0 ? 0 : 1,
        lobbyType: type,
        raw: const {},
      ),
    );
    api.responses[HttpApi.roomFunctions] = [
      for (final mode in [1, 2])
        {
          'type': mode,
          'list': [
            for (final position in positions) {'position': position},
          ],
        },
      if (bigWin)
        {
          'type': 8,
          'list': [
            {'position': 17},
          ],
        },
    ];
    if (bigWin) {
      api.responses[HttpApi.gameBigWinShow] = {
        'status': 1,
        'gameBigWinInfoVO': {'gameBigWinId': '42', 'bigWinTotalCoins': 1000000},
      };
    }
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    router = GoRouter(
      initialLocation: '/room/123',
      routes: [
        GoRoute(
          path: '/room/:id',
          builder: (_, __) => const RoomPage(roomId: '123'),
        ),
        GoRoute(path: '/room-tool', builder: (_, s) => s.extra! as Widget),
        GoRoute(
          path: '/wallet',
          builder: (_, __) => const Scaffold(body: Text('Wallet sentinel')),
        ),
        GoRoute(
          path: '/party',
          builder: (_, __) => const Scaffold(body: Text('Party sentinel')),
        ),
      ],
    );
    final overrides = [
      roomRepositoryProvider.overrideWithValue(room),
      roomToolsRepositoryProvider.overrideWithValue(api),
      roomGiftRepositoryProvider.overrideWithValue(_Gifts()),
      roomMoreToolsRepositoryProvider.overrideWithValue(_Banners()),
      if (interaction != null)
        roomInteractionRepositoryProvider.overrideWithValue(interaction),
    ];
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      room.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: const [AppLocalizations.delegate],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(RoomPage)),
    );
    await precacheRoomAssets(tester, tester.element(find.byType(RoomPage)));
    await tester.pumpAndSettle();
  }
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
