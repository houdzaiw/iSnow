import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/activities/room_activity_widgets.dart';
import 'package:project/classes/room/activities/room_activity_host.dart';
import 'package:project/classes/room/gift/effects/room_gift_asset_resolver.dart';
import 'package:project/classes/room/lucky_box/room_lucky_box_sheet.dart';
import 'package:project/classes/room/lucky_box/room_lucky_box_view_model.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/pk/room_pk_board.dart';
import 'package:project/classes/room/pk/room_pk_models.dart';
import 'package:project/classes/room/pk/room_pk_result_card.dart';
import 'package:project/classes/room/pk/room_pk_sheet.dart';
import 'package:project/classes/room/pk/room_pk_view_model.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_models.dart';
import 'package:project/theme/app_theme.dart';

import 'room_pk_lucky_complete_test.dart' show pkEvent;
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
  late ToolsRoomFake room;
  late ToolsApiFake api;
  late ProviderContainer container;
  Future<void> mount(
    WidgetTester tester,
    double width,
    Widget child, {
    bool short = false,
  }) async {
    tester.view.physicalSize = Size(width, short ? 568 : 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    room = ToolsRoomFake();
    api = ToolsApiFake();
    room.current = room.current.copyWith(
      micList: [
        for (final uid in [11, 22, 33])
          RoomMicModel(
            position: uid,
            uid: uid,
            userInfo: {'nick': 'Long nickname for selected user $uid'},
            raw: const {},
          ),
      ],
    );
    container = ProviderContainer(
      overrides: [
        roomRepositoryProvider.overrideWithValue(room),
        roomToolsRepositoryProvider.overrideWithValue(api),
        roomActivityResourceProvider.overrideWith(
          (ref, source) => Completer<RoomGiftAnimationResource>().future,
        ),
      ],
    );
    container.read(roomToolsControllerProvider('123'));
    await tester.runAsync(flushTools);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [AppLocalizations.delegate],
            home: Scaffold(
              backgroundColor: RoomActivityTheme.surface,
              body: RepaintBoundary(
                key: const ValueKey('activity-golden'),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      room.dispose();
    });
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump();
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('PK and Lucky Box panels at $width', (tester) async {
      await mount(
        tester,
        width,
        const RoomPkPage(roomId: '123'),
        short: width == 320,
      );
      final pk = container.read(roomPkProvider('123').notifier);
      await precacheRoomAssets(tester, tester.element(find.byType(RoomPkPage)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('activity-golden')),
        matchesGoldenFile(
          'goldens/room_pk_lucky_v1/pk_settings_${width.toInt()}.png',
        ),
      );
      pk.mode(false);
      pk.selectAll();
      await tester.pumpAndSettle();
      expect(pk.state.selected.length, 3);
      await tester.tap(find.text('Multi-player'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Reuse the same real providers and selection lifecycle for the editor.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: const [AppLocalizations.delegate],
              home: const Scaffold(
                body: RepaintBoundary(
                  key: ValueKey('activity-golden'),
                  child: RoomLuckyBoxPage(roomId: '123'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(flushTools);
      await tester.pumpAndSettle();
      await precacheRoomAssets(
        tester,
        tester.element(find.byType(RoomLuckyBoxPage)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('activity-golden')),
        matchesGoldenFile(
          'goldens/room_pk_lucky_v1/lucky_editor_${width.toInt()}.png',
        ),
      );
      final box = container.read(roomLuckyBoxProvider('123').notifier);
      expect(box.state.canSubmit, isTrue);
      await tester.tap(find.byType(RoomActivityImageButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(api.count(HttpApi.roomLuckyPush), 0);
      expect(api.confirmation, isFalse);
      await finish(tester);
    });
    testWidgets('active PK layout/results at $width do not overflow', (
      tester,
    ) async {
      await mount(
        tester,
        width,
        Column(
          children: [RoomPkBoard(roomId: '123', onUser: (_) {})],
        ),
      );
      room.event(
        'RoomPkInfoUpdate',
        pkEvent(1, score: 999999999999),
        id: 'start',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pk-gift-11')), findsOneWidget);
      expect(tester.takeException(), isNull);
      room.event('RoomPkInfoUpdate', pkEvent(4), id: 'end');
      await tester.pumpAndSettle();
      final data = container.read(roomPkProvider('123')).result!;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: const [AppLocalizations.delegate],
              home: Scaffold(
                backgroundColor: RoomActivityTheme.scrim,
                body: RepaintBoundary(
                  key: const ValueKey('activity-golden'),
                  child: RoomPkResultCard(
                    roomId: '123',
                    data: data,
                    onUser: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await precacheRoomAssets(
        tester,
        tester.element(find.byType(RoomPkResultCard)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('activity-golden')),
        matchesGoldenFile(
          'goldens/room_pk_lucky_v1/pk_result_${width.toInt()}.png',
        ),
      );
      await finish(tester);
    });
  }
  testWidgets('Lucky Box open requires a user click and close never grabs', (
    tester,
  ) async {
    await mount(tester, 375, const RoomLuckyBoxOpenLayer(roomId: '123'));
    api.responses[HttpApi.roomLuckyList] = [
      {'id': 'a', 'remainingTime': 0, 'nickName': 'Sender'},
    ];
    final tools = container.read(roomToolsControllerProvider('123').notifier);
    await tester.runAsync(tools.refreshBags);
    final box = container.read(roomLuckyBoxProvider('123').notifier);
    box.open('a');
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(api.count(HttpApi.roomLuckyGrab), 0);
    await tester.tap(find.byType(RoomActivityClose));
    await tester.pumpAndSettle();
    expect(api.count(HttpApi.roomLuckyGrab), 0);
    await finish(tester);
  });
  testWidgets(
    'multi PK drag stays in bounds and folding never ends the server PK',
    (tester) async {
      await mount(
        tester,
        320,
        Stack(
          children: [RoomMultiPkOverlay(roomId: '123', onUser: (_) {})],
        ),
      );
      final event = pkEvent(1);
      ((event['pkInfo'] as Map)['pkMap'] as List).add({
        'userInfo': {'uid': 33, 'nick': 'Third'},
        'pkScore': 0,
      });
      room.event('RoomPkInfoUpdate', event, id: 'multi');
      await tester.pumpAndSettle();
      final panel = find.byKey(const ValueKey('room-multi-pk-panel'));
      await tester.drag(panel, const Offset(-10000, -10000));
      await tester.pumpAndSettle();
      final rect = tester.getRect(panel);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
      await tester.tap(panel);
      await tester.pumpAndSettle();
      expect(container.read(roomPkProvider('123')).mini, isFalse);
      await tester.tap(
        find.image(const AssetImage(AppAssets.roomActivityPkMinimizeBtnIcon)),
      );
      await tester.pumpAndSettle();
      expect(container.read(roomPkProvider('123')).mini, isTrue);
      expect(api.count(HttpApi.roomPkOver), 0);
      expect(api.count(HttpApi.roomPkBegin), 0);
      await finish(tester);
    },
  );

  for (final count in [0, 7]) {
    testWidgets(
      'box result $count reveals once and closes without another claim',
      (tester) async {
        await mount(tester, 375, const RoomLuckyBoxOpenLayer(roomId: '123'));
        api.responses[HttpApi.roomLuckyList] = [
          {'id': 'result-box', 'remainingTime': 0, 'nickName': 'Sender'},
        ];
        api.responses[HttpApi.roomLuckyGrab] = {'count': count};
        final tools = container.read(
          roomToolsControllerProvider('123').notifier,
        );
        await tester.runAsync(tools.refreshBags);
        final box = container.read(roomLuckyBoxProvider('123').notifier);
        box.open('result-box');
        await tester.pump();
        await tester.tap(find.byType(RoomActivityImageButton));
        await tester.pump();
        final resultText = count > 0 ? '+$count' : 'Better luck next time';
        expect(find.text(resultText), findsNothing);
        await tester.pump(const Duration(milliseconds: 1750));
        await tester.pump();
        expect(find.text(resultText), findsOneWidget);
        expect(api.count(HttpApi.roomLuckyGrab), 1);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(box.state.current, isNull);
        expect(find.text(resultText), findsNothing);
        expect(api.count(HttpApi.roomLuckyGrab), 1);
        expect(api.count(HttpApi.roomLuckyPush), 0);
        expect(tester.takeException(), isNull);
        await finish(tester);
      },
    );
  }
  testWidgets(
    'box error keeps Open retryable without displaying a losing result',
    (tester) async {
      await mount(tester, 375, const RoomLuckyBoxOpenLayer(roomId: '123'));
      api.responses[HttpApi.roomLuckyList] = [
        {'id': 'retry-box', 'remainingTime': 0},
      ];
      final tools = container.read(roomToolsControllerProvider('123').notifier);
      await tester.runAsync(tools.refreshBags);
      final box = container.read(roomLuckyBoxProvider('123').notifier);
      box.open('retry-box');
      await tester.pump();
      api.failingPath = HttpApi.roomLuckyGrab;
      await tester.tap(find.byType(RoomActivityImageButton));
      await tester.pumpAndSettle();
      expect(find.byType(RoomActivityError), findsOneWidget);
      expect(find.text('Better luck next time'), findsNothing);
      expect(box.state.result, isNull);
      api.failingPath = null;
      api.responses[HttpApi.roomLuckyGrab] = {'count': 7};
      await tester.tap(find.byType(RoomActivityImageButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1750));
      await tester.pump();
      expect(find.text('+7'), findsOneWidget);
      expect(api.count(HttpApi.roomLuckyGrab), 2);
      await tester.tap(find.byType(RoomActivityClose));
      await tester.pumpAndSettle();
      expect(box.state.current, isNull);
      await finish(tester);
    },
  );
  testWidgets(
    'PK contributors open the selected profile callback without gift requests',
    (tester) async {
      final opened = <int>[];
      await mount(
        tester,
        375,
        RoomPkResultCard(
          roomId: '123',
          data: RoomPkData.fromJson(pkEvent(4)),
          onUser: opened.add,
        ),
      );
      await tester.tap(find.text('Contributors').first);
      await tester.pumpAndSettle();
      expect(find.text('Supporter'), findsOneWidget);
      await tester.tap(find.text('Supporter'));
      await tester.pumpAndSettle();
      expect(opened, [33]);
      expect(find.byType(AlertDialog), findsNothing);
      expect(api.count(HttpApi.giftSend), 0);
      expect(api.count(HttpApi.roomPkBegin), 0);
      expect(api.count(HttpApi.roomPkOver), 0);
      await finish(tester);
    },
  );
  testWidgets('account invalidation closes only the owned lucky editor route', (
    tester,
  ) async {
    await mount(
      tester,
      375,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showRoomLuckyBoxSheet(context, '123'),
          child: const Text('Open editor'),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomLuckyBoxPage), findsOneWidget);
    room.changeAccount(99);
    await tester.pumpAndSettle();
    expect(find.byType(RoomLuckyBoxPage), findsNothing);
    expect(find.text('Open editor'), findsOneWidget);
    expect(api.count(HttpApi.roomLuckyPush), 0);
    expect(api.count(HttpApi.roomLuckyGrab), 0);
    await finish(tester);
  });
  testWidgets('contributor dialog rebuild uses its own active context', (
    tester,
  ) async {
    var showCard = true;
    late StateSetter update;
    await mount(
      tester,
      375,
      StatefulBuilder(
        builder: (_, setState) {
          update = setState;
          return showCard
              ? RoomPkResultCard(
                  roomId: '123',
                  data: RoomPkData.fromJson(pkEvent(4)),
                  onUser: (_) {},
                )
              : const SizedBox.shrink();
        },
      ),
    );
    await tester.tap(find.text('Contributors').first);
    await tester.pumpAndSettle();
    update(() => showCard = false);
    await tester.pumpAndSettle();
    tester
        .element(
          find
              .ancestor(
                of: find.byType(AlertDialog),
                matching: find.byType(Builder),
              )
              .first,
        )
        .markNeedsBuild();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Supporter'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(api.count(HttpApi.roomPkBegin), 0);
    expect(api.count(HttpApi.giftSend), 0);
    await finish(tester);
  });
  testWidgets(
    'missing result close image stays bounded and remains clickable',
    (tester) async {
      var closed = 0;
      await mount(
        tester,
        320,
        DefaultAssetBundle(
          bundle: _MissingActivityCloseBundle(),
          child: Row(
            children: [
              const Expanded(child: Text('PK result')),
              RoomActivityClose(onTap: () => closed++),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final close = find.byType(RoomActivityClose);
      expect(
        tester.getSize(close).width,
        closeTo(
          (RoomActivityTheme.icon + RoomActivityTheme.gap * 2) * 320 / 375,
          1,
        ),
      );
      await tester.tap(close);
      expect(closed, 1);
      await finish(tester);
    },
  );
}

class _MissingActivityCloseBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == AppAssets.roomActivityIcPkResultClose) {
      throw FlutterError('Simulated missing close asset');
    }
    return rootBundle.load(key);
  }
}
