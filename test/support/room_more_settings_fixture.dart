import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/models/room_more_tools_models.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/room_more_tools_repository.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_more_tools_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/theme/app_theme.dart';

import 'room_tools_fakes.dart';

class RoomSettingsApiFake extends ToolsApiFake {
  int loads = 0, saves = 0;
  Completer<RoomEffectPreferences>? loadGate;
  Completer<void>? saveGate;
  Object? loadError, saveError;
  @override
  Future<RoomEffectPreferences> effects(int uid) async {
    loads++;
    if (loadError != null) throw loadError!;
    return loadGate?.future ?? stored;
  }

  @override
  Future<void> saveEffects(int uid, RoomEffectPreferences effects) async {
    saves++;
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    stored = effects;
  }
}

class RoomMoreSettingsFixture {
  RoomMoreSettingsFixture(
    this.room,
    this.api,
    this.router,
    this.container,
    this.banners,
  );
  final ToolsRoomFake room;
  final RoomSettingsApiFake api;
  final GoRouter router;
  final ProviderContainer container;
  final RoomSettingsBannersFake banners;
  RoomToolsController get controller =>
      container.read(roomToolsControllerProvider('123').notifier);
  Future<void> open(WidgetTester tester, {bool settle = true}) async {
    ScaffoldMessenger.of(
      tester.element(find.byType(RoomPage)),
    ).hideCurrentSnackBar();
    await tester.pump();
    await tester.pump(kThemeAnimationDuration);
    await tester.tap(
      find.image(const AssetImage(AppAssets.lanhuRoomBottomMore)),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }
  }

  void close(WidgetTester tester) => Navigator.of(
    tester.element(find.byKey(const ValueKey('room-more-tools-sheet'))),
  ).pop();
}

Future<RoomMoreSettingsFixture> mountRoomMoreSettings(
  WidgetTester tester, {
  double width = 375,
  double height = 812,
  double inset = 0,
  double bottom = 0,
  double textScale = 1,
  int games = 0,
  RoomSettingsApiFake? api,
  ToolsRoomFake? room,
  bool settle = true,
}) async {
  final activeRoom = room ?? ToolsRoomFake();
  api ??= RoomSettingsApiFake();
  final banners = RoomSettingsBannersFake(games);
  final router = GoRouter(
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
    ],
  );
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    activeRoom.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        roomRepositoryProvider.overrideWithValue(activeRoom),
        roomToolsRepositoryProvider.overrideWithValue(api),
        roomGiftRepositoryProvider.overrideWithValue(_Gifts()),
        roomMoreToolsRepositoryProvider.overrideWithValue(banners),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('en')],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewInsets: EdgeInsets.only(bottom: inset),
              padding: EdgeInsets.only(bottom: bottom),
              viewPadding: EdgeInsets.only(bottom: bottom),
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 350));
  }
  return RoomMoreSettingsFixture(
    activeRoom,
    api,
    router,
    ProviderScope.containerOf(tester.element(find.byType(RoomPage))),
    banners,
  );
}

class RoomSettingsBannersFake extends RoomMoreToolsRepository {
  RoomSettingsBannersFake(this.games);
  final int games;
  int loads = 0;
  @override
  Future<List<RoomToolBanner>> fetchBanners({
    required RoomMoreBannerPosition position,
    required String roomId,
  }) async {
    loads++;
    return position == RoomMoreBannerPosition.game
        ? [
            for (var i = 0; i < games; i++)
              RoomToolBanner(name: 'Game $i', raw: const {}),
          ]
        : [];
  }
}

class _Gifts extends RoomGiftRepository {
  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async =>
      throw StateError('No gift send is expected in settings tests');
  @override
  Future<RoomGiftCatalog> fetchCatalog() async =>
      const RoomGiftCatalog(tabs: [], balance: 1000, canSendSelf: false);
  @override
  Future<int> fetchBalance() async => 1000;
}
