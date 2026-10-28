import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/models/room_more_tools_models.dart';
import 'package:project/classes/room/more/room_lucky_box_page.dart';
import 'package:project/classes/room/more/room_pk_page.dart';
import 'package:project/classes/room/more/room_report_page.dart';
import 'package:project/classes/room/more/room_settings_page.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_widgets.dart';
import 'package:project/classes/room/more/room_mic_wave.dart';
import 'package:project/classes/room/more/room_game_page.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_models.dart';
import 'package:project/classes/room/room_more_tools_repository.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_more_tools_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/theme/app_theme.dart';

import 'support/room_tools_fakes.dart';
import 'support/precache_room_assets.dart';

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
  testWidgets(
    'terminating a hidden game page preserves the newer wallet page',
    (tester) async {
      late BuildContext gameContext;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          GoRoute(
            path: '/room-tool',
            builder: (_, state) => state.extra! as Widget,
          ),
          GoRoute(
            path: '/wallet',
            builder: (_, _) => const Scaffold(body: Text('wallet')),
          ),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        router.dispose();
      });
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final game = router.push<void>(
        '/room-tool',
        extra: Builder(
          builder: (context) {
            gameContext = context;
            return const Scaffold(body: Text('game'));
          },
        ),
      );
      await tester.pumpAndSettle();
      router.push<void>('/wallet');
      await tester.pumpAndSettle();
      dismissOwnedRoomTool(gameContext);
      await tester.pumpAndSettle();
      await game;
      expect(find.text('wallet'), findsOneWidget);
      expect(router.state.uri.path, '/wallet');
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(find.text('game'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'unconfigured game shows an error without creating a native WebView',
    (tester) async {
      final room = ToolsRoomFake();
      final api = ToolsApiFake();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        room.dispose();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomRepositoryProvider.overrideWithValue(room),
            roomToolsRepositoryProvider.overrideWithValue(api),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const RoomGamePage(
              roomId: '123',
              url: 'https://unconfigured.example/game',
              title: 'Game',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Game host is not configured'),
        findsOneWidget,
      );
      expect(api.count(HttpApi.gameToken), 0);
      expect(room.leaves, 0);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'More preserves its grid and opens complete secondary pages at $width',
      (tester) async {
        final room = ToolsRoomFake();
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
        tester.view.physicalSize = Size(width, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          room.dispose();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roomRepositoryProvider.overrideWithValue(room),
              roomToolsRepositoryProvider.overrideWithValue(ToolsApiFake()),
              roomGiftRepositoryProvider.overrideWithValue(_Gifts()),
              roomMoreToolsRepositoryProvider.overrideWithValue(_Banners()),
            ],
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, _) => MaterialApp.router(
                routerConfig: router,
                builder: (_, child) => RepaintBoundary(
                  key: const ValueKey('room-more-snapshot'),
                  child: child!,
                ),
                theme: AppTheme.light.copyWith(
                  appBarTheme: AppTheme.light.appBarTheme.copyWith(
                    titleTextStyle: AppTextStyles.navTitle.copyWith(
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en')],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> openMore() async {
          final image = find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName ==
                    AppAssets.lanhuRoomBottomMore,
          );
          await tester.tap(image);
          await tester.pumpAndSettle();
          await precacheRoomAssets(
            tester,
            tester.element(find.byKey(const ValueKey('room-more-tools-sheet'))),
          );
          expect(find.text('Basic Tools'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('room-more-tools-sheet')),
              matching: find.text('Chat'),
            ),
            findsOneWidget,
          );
          expect(find.text('Map Social'), findsNothing);
          expect(
            find.image(const AssetImage(AppAssets.lanhuRoomMoreMusic)),
            findsOneWidget,
          );
          final voiceFrames = tester.widgetList<DecoratedBox>(
            find.ancestor(
              of: find.image(const AssetImage(AppAssets.lanhuRoomMoreVoice)),
              matching: find.byType(DecoratedBox),
            ),
          );
          expect(
            voiceFrames.any(
              (frame) =>
                  frame.decoration is BoxDecoration &&
                  (frame.decoration as BoxDecoration).border ==
                      Border.all(color: AppColors.roomMoreSelectedBorder),
            ),
            isTrue,
            reason: 'An enabled Voice control must retain its selected outline',
          );
        }

        for (final (label, type) in <(String, Type)>[
          ('Report', RoomReportPage),
          ('PK', RoomPkPage),
          ('Lucky Box', RoomLuckyBoxPage),
        ]) {
          await openMore();
          if (label == 'Report') {
            await expectLater(
              find.byKey(const ValueKey('room-more-snapshot')),
              matchesGoldenFile(
                'goldens/room_more_basic_v2_${width.toInt()}.png',
              ),
            );
          }
          await tester.ensureVisible(find.text(label));
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(find.byType(type), findsOneWidget);
          await precacheRoomAssets(tester, tester.element(find.byType(type)));
          expect(room.leaves, 0);
          expect(router.state.uri.path, '/room-tool');
          router.pop();
          await tester.pumpAndSettle();
          expect(find.byType(RoomPage), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await openMore();
        await tester.ensureVisible(find.text('Effect Settings'));
        await tester.tap(find.text('Effect Settings'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('room-more-tools-sheet')),
          findsOneWidget,
        );
        expect(find.byType(RoomSettingsPage), findsNothing);
        expect(router.state.uri.path, '/room/123');
        expect(find.byType(Switch), findsNWidgets(6));
        await expectLater(
          find.byKey(const ValueKey('room-more-snapshot')),
          matchesGoldenFile(
            'goldens/room_more_setting_v2_${width.toInt()}.png',
          ),
        );
        Navigator.of(
          tester.element(find.byKey(const ValueKey('room-more-tools-sheet'))),
        ).pop();
        await tester.pumpAndSettle();
        room.current = room.current.copyWith(
          micList: const [RoomMicModel(position: 0, uid: 10, raw: {})],
        );
        room.volumes = {10: 80};
        room.emitState();
        await tester.pump();
        expect(find.byType(RoomMicWave), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(RoomPage)),
        );
        await container
            .read(roomToolsControllerProvider('123').notifier)
            .setEffect('sound_effect', false);
        await tester.pump();
        expect(find.byType(RoomMicWave), findsNothing);
        expect(room.speaker, isFalse);
      },
    );
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
