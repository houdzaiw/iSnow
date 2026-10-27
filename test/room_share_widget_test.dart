import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/message/message_view_model.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/models/room_more_tools_models.dart';
import 'package:project/classes/room/more/room_share_page.dart';
import 'package:project/classes/room/more/room_share_repository.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/classes/room/room_more_tools_repository.dart';
import 'package:project/classes/room/viewmodel/room_more_tools_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_share_manager.dart';
import 'package:project/model/room_share_models.dart';
import 'package:project/model/server_response.dart';
import 'package:project/theme/app_theme.dart';

import 'support/precache_room_assets.dart';
import 'support/room_share_fakes.dart';
import 'support/room_tools_fakes.dart';

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

  Future<
    ({
      ToolsRoomFake room,
      ToolsApiFake api,
      SharePlatformFake platform,
      GoRouter router,
    })
  >
  open(
    WidgetTester tester, {
    double width = 375,
    ToolsApiFake? api,
    bool fromMore = false,
    bool waitForMaterials = true,
  }) async {
    final room = ToolsRoomFake();
    final requests = api ?? shareApiFake();
    final platform = SharePlatformFake();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            bottomNavigationBar: const SizedBox(
              height: 56,
              child: Text('bottom-navigation'),
            ),
            body: fromMore
                ? const RoomPage(roomId: '123')
                : Navigator(
                    onGenerateRoute: (_) => MaterialPageRoute<void>(
                      builder: (context) => Center(
                        child: TextButton(
                          onPressed: () => showRoomShareSheet(context, '123'),
                          child: const Text('Open share'),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        GoRoute(
          path: '/chat-view',
          builder: (_, state) => Scaffold(
            body: Text('chat-${state.uri.queryParameters['targetUID']}'),
          ),
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
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomRepositoryProvider.overrideWithValue(room),
          roomToolsRepositoryProvider.overrideWithValue(requests),
          roomShareRepositoryProvider.overrideWithValue(
            RoomShareRepository(requests, config: ShareConfigFake()),
          ),
          roomShareManagerProvider.overrideWithValue(platform),
          imRepositoryProvider.overrideWithValue(ShareImFake()),
          roomGiftRepositoryProvider.overrideWithValue(_Gifts()),
          roomMoreToolsRepositoryProvider.overrideWithValue(_Banners()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light.copyWith(
              textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            builder: (_, child) => RepaintBoundary(
              key: const ValueKey('share-snapshot'),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (fromMore) {
      await tester.tap(
        find.image(const AssetImage(AppAssets.lanhuRoomBottomMore)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
    } else {
      await tester.tap(find.text('Open share'));
    }
    if (waitForMaterials) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await precacheRoomAssets(
      tester,
      tester.element(find.byType(RoomSharePage)),
    );
    return (room: room, api: requests, platform: platform, router: router);
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'root share sheet, poster switching, keyboard and long text at $width',
      (tester) async {
        final api = shareApiFake();
        api.responses[HttpApi.roomShareMaterials] = [
          {
            ...shareMaterialJson(1),
            'copyText': List.filled(
              25,
              'A long invitation with details',
            ).join(' '),
          },
          shareMaterialJson(2),
        ];
        final setup = await open(tester, width: width, api: api);
        expect(find.byKey(const ValueKey('room-share-system')), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);
        final channelGrid = tester.widget<GridView>(
          find.byKey(const ValueKey('room-share-channels')),
        );
        expect(
          (channelGrid.gridDelegate
                  as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount,
          5,
        );
        final channelItems = RoomShareAction.values
            .where((action) => action != RoomShareAction.copy)
            .toList();
        for (final (index, action) in channelItems.indexed) {
          final rect = tester.getRect(
            find.byKey(ValueKey('room-share-${action.name}')),
          );
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
          expect(rect.bottom, lessThanOrEqualTo(812));
          final first = tester.getRect(
            find.byKey(
              ValueKey('room-share-${channelItems[index < 5 ? 0 : 5].name}'),
            ),
          );
          expect(rect.top, first.top);
        }
        expect(
          tester.getSize(find.byKey(const ValueKey('room-share-copy'))),
          const Size(60, 32),
        );
        expect(find.byType(Icon), findsNothing);
        expect(
          tester
              .getBottomRight(find.byKey(const ValueKey('room-share-sheet')))
              .dy,
          closeTo(812, 1),
        );
        await expectLater(
          find.byKey(const ValueKey('share-snapshot')),
          matchesGoldenFile(
            'goldens/room_share_channels_v2_${width.toInt()}.png',
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('room-share-poster-previous')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Join Tester 2'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('room-share-poster-next')));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(const ValueKey('room-share-posters')),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text('Join Tester 2'), findsOneWidget);
        expect(
          tester
              .widget<PageView>(
                find.byKey(const ValueKey('room-share-posters')),
              )
              .controller!
              .page,
          1,
        );
        await tester.tap(find.byKey(const ValueKey('room-share-copy')));
        await tester.pumpAndSettle();
        expect(setup.platform.copied.single, startsWith('Join Tester 2'));
        expect(find.text('Link copied'), findsOneWidget);
        await tester.tap(find.text('Friends'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('room-share-contact-20')).hitTestable(),
          findsOneWidget,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final search = find.byType(TextField).hitTestable();
        await tester.enterText(search, 'Friend');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('room-share-close')));
        await tester.pumpAndSettle();
        expect(find.byType(RoomSharePage), findsNothing);
        expect(setup.room.leaves, 0);
        expect(setup.room.authListeners, isEmpty);
      },
    );
  }

  testWidgets('cancelled system share does not display a success toast', (
    tester,
  ) async {
    final setup = await open(tester);
    setup.platform.outcome = RoomShareOutcome.cancelled;
    await tester.tap(find.byKey(const ValueKey('room-share-system')));
    await tester.pumpAndSettle();
    expect(setup.platform.shares, hasLength(1));
    expect(setup.platform.shares.single.origin.isEmpty, isFalse);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(RoomSharePage), findsOneWidget);
  });

  testWidgets(
    'actual More entry opens a root share sheet without replacing or exiting the room',
    (tester) async {
      final setup = await open(tester, fromMore: true);
      expect(find.byKey(const ValueKey('room-more-tools-sheet')), findsNothing);
      expect(find.byType(RoomSharePage), findsOneWidget);
      expect(setup.router.state.uri.path, '/');
      await tester.tap(find.byKey(const ValueKey('room-share-close')));
      await tester.pumpAndSettle();
      expect(find.byType(RoomPage), findsOneWidget);
      expect(find.byType(RoomSharePage), findsNothing);
      expect(setup.room.leaves, 0);
      expect(setup.room.roomState.isInRoom, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'share errors are visible above the root sheet and preserve the server msg',
    (tester) async {
      final setup = await open(tester);
      setup.platform.failure = const NadyApiException(
        code: 1003,
        message: 'Please retry sharing',
      );
      await tester.tap(find.byKey(const ValueKey('room-share-system')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Please retry sharing'), findsOneWidget);
      final message = tester.getRect(find.text('Please retry sharing'));
      final sheet = tester.getRect(
        find.byKey(const ValueKey('room-share-sheet')),
      );
      expect(sheet.contains(message.center), isTrue);
      expect(find.byType(RoomSharePage), findsOneWidget);
    },
  );

  testWidgets(
    'reopening shares cached public materials but reloads personal invitation data',
    (tester) async {
      final setup = await open(tester);
      await tester.tap(find.byKey(const ValueKey('room-share-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open share'));
      await tester.pumpAndSettle();
      expect(setup.api.count(HttpApi.roomShareMaterials), 1);
      expect(setup.api.count(HttpApi.roomInviteInfo), 2);
      expect(find.byKey(const ValueKey('room-share-system')), findsOneWidget);
    },
  );

  testWidgets(
    'empty materials retain three tabs and retry within Share without reloading contacts',
    (tester) async {
      final api = shareApiFake()..responses[HttpApi.roomShareMaterials] = [];
      await open(tester, api: api);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Recent Chats'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
      expect(find.text('No share materials available'), findsOneWidget);
      expect(find.byKey(const ValueKey('room-share-posters')), findsNothing);
      expect(find.byKey(const ValueKey('room-share-copy')), findsNothing);
      expect(find.byKey(const ValueKey('room-share-system')), findsNothing);
      final calls = api.count(HttpApi.userFriends);
      api.responses[HttpApi.roomShareMaterials] = [shareMaterialJson(1)];
      await tester.tap(
        find.byKey(const ValueKey('room-share-materials-retry')),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
      expect(api.count(HttpApi.userFriends), calls);
      expect(
        find.byKey(const ValueKey('room-share-poster-next')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('room-share-poster-previous')),
        findsNothing,
      );
      await tester.tap(find.text('Recent Chats'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('room-share-contact-20')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('room-share-materials-retry')).hitTestable(),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('loading and server msg preserve tabs and retry at $width', (
      tester,
    ) async {
      final api = shareApiFake()
        ..heldPath = HttpApi.roomShareMaterials
        ..gate = Completer<Object?>();
      addTearDown(() {
        if (!api.gate!.isCompleted) api.gate!.complete([]);
      });
      await open(tester, width: width, api: api, waitForMaterials: false);
      expect(tester.widget<TabBar>(find.byType(TabBar)).tabs, hasLength(3));
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Friends'));
      await tester.pump(const Duration(milliseconds: 350));
      final message = List.filled(12, 'Share materials unavailable.').join(' ');
      api.gate!.completeError(
        NadyServerResponse<Object?>.fromJson({
          'code': 1003,
          'msg': message,
          'message': 'Generic error',
        }, null).toException(),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 2);
      expect(
        find.byKey(const ValueKey('room-share-contact-20')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('room-share-materials-retry')).hitTestable(),
        findsNothing,
      );
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(find.text('Generic error'), findsNothing);
      expect(find.byKey(const ValueKey('room-share-channels')), findsNothing);
      final friendsCalls = api.count(HttpApi.userFriends);
      api.heldPath = null;
      await tester.ensureVisible(
        find.byKey(const ValueKey('room-share-materials-retry')),
      );
      await tester.tap(
        find.byKey(const ValueKey('room-share-materials-retry')),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
      expect(find.byKey(const ValueKey('room-share-system')), findsOneWidget);
      expect(api.count(HttpApi.userFriends), friendsCalls);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a failed direct launch shows an error and keeps the panel', (
    tester,
  ) async {
    final setup = await open(tester);
    setup.platform.opens = false;
    await tester.tap(find.byKey(const ValueKey('room-share-whatsapp')));
    await tester.pumpAndSettle();
    expect(find.text('Unable to open WhatsApp'), findsOneWidget);
    expect(find.byType(RoomSharePage), findsOneWidget);
    expect(setup.platform.opened, hasLength(1));
    expect(setup.platform.shares, isEmpty);
    expect(setup.room.leaves, 0);
  });

  testWidgets('a direct launch does not show a sent or copied success notice', (
    tester,
  ) async {
    final setup = await open(tester);
    await tester.tap(find.byKey(const ValueKey('room-share-whatsapp')));
    await tester.pumpAndSettle();
    expect(setup.platform.opened, hasLength(1));
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(RoomSharePage), findsOneWidget);
  });

  testWidgets(
    'invitation confirmation preserves the sheet on cancel and opens chat after IM success',
    (tester) async {
      final setup = await open(tester);
      await tester.tap(find.text('Recent Chats'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('room-share-contact-20')).hitTestable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(RoomSharePage), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('room-share-contact-20')).hitTestable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.byType(RoomSharePage), findsNothing);
      expect(find.text('chat-20'), findsOneWidget);
      expect(setup.room.leaves, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dismissing the sheet immediately cancels pending shortening work',
    (tester) async {
      final setup = await open(tester);
      setup.api.heldPath = HttpApi.roomShareShortLinks;
      setup.api.gate = Completer<Object?>();
      await tester.tap(find.byKey(const ValueKey('room-share-system')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('room-share-close')));
      await tester.pump();
      setup.api.gate!.complete([
        {'shortUrl': 'https://share.example/s/late'},
      ]);
      await tester.pumpAndSettle();
      expect(setup.platform.shares, isEmpty);
      expect(setup.room.leaves, 0);
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
