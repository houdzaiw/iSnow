import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project/classes/room/more/room_settings_page.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/server_response.dart';
import 'package:project/theme/app_theme.dart';

import 'support/room_more_settings_fixture.dart';
import 'support/room_tools_fakes.dart';

void main() {
  final counter = find.text('Charm Counter');
  final sheet = find.byKey(const ValueKey('room-more-tools-sheet'));
  Finder image(bool enabled) => find.image(
    AssetImage(
      enabled
          ? AppAssets.lanhuRoomMoreCharmCounter
          : AppAssets.lanhuRoomMoreCharmCounterMuted,
    ),
  );
  bool micValueVisible(WidgetTester tester) => tester
      .widget<Visibility>(
        find.ancestor(of: find.text('7654'), matching: find.byType(Visibility)),
      )
      .visible;

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('counter toggles in More and controls mic values at $width', (
      tester,
    ) async {
      final room = ToolsRoomFake();
      room.current = room.current.copyWith(
        micList: const [
          RoomMicModel(
            position: 0,
            uid: 20,
            raw: {'charmValue': 7654},
            userInfo: {'uid': 20, 'nick': 'Listener'},
          ),
        ],
      );
      final f = await mountRoomMoreSettings(
        tester,
        width: width,
        room: room,
        api: _CounterApi(),
      );
      await f.open(tester);
      expect(image(true), findsOneWidget);
      expect(find.text('7654'), findsOneWidget);
      expect(micValueVisible(tester), isTrue);
      final assets = tester.widgetList<Image>(image(true));
      expect(assets.single.width, AppSpacing.roomMoreToolIconBoxSize.r);
      await tester.tap(counter);
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(find.byType(RoomSettingsPage), findsNothing);
      expect(f.router.state.uri.path, '/room/123');
      expect(f.controller.snapshot.charmEnabled, isFalse);
      expect(image(false), findsOneWidget);
      expect(micValueVisible(tester), isFalse);
      final request = f.api.calls.lastWhere(
        (c) => c.path == HttpApi.roomCharmUpdate,
      );
      expect(request.method, 'GET');
      expect(request.body, {'roomId': '123', 'enable': false});
      await tester.tap(counter);
      await tester.pumpAndSettle();
      expect(image(true), findsOneWidget);
      expect(micValueVisible(tester), isTrue);
      expect(f.room.leaves, 0);
      expect(f.room.speaker, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loading status cannot submit a guessed toggle', (tester) async {
    final api = _CounterApi()
      ..heldPath = HttpApi.roomCharmEnabled
      ..gate = Completer<Object?>();
    final f = await mountRoomMoreSettings(tester, api: api, settle: false);
    await f.open(tester, settle: false);
    expect(f.controller.charmStatusBusy, isTrue);
    expect(await f.controller.toggleCharmCounter(), isFalse);
    expect(api.count(HttpApi.roomCharmUpdate), 0);
    api.gate!.complete(false);
    await tester.pumpAndSettle();
    expect(image(false), findsOneWidget);
    await tester.tap(counter);
    await tester.pumpAndSettle();
    expect(f.controller.snapshot.charmEnabled, isTrue);
    expect(api.calls.last.body, {'roomId': '123', 'enable': true});
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed initial status retries before computing the target', (
    tester,
  ) async {
    final api = _CounterApi()..failingPath = HttpApi.roomCharmEnabled;
    final f = await mountRoomMoreSettings(tester, api: api);
    await f.open(tester);
    expect(f.controller.charmStatusReady, isFalse);
    await tester.tap(counter);
    await tester.pumpAndSettle();
    expect(api.count(HttpApi.roomCharmUpdate), 0);
    api.failingPath = null;
    await tester.tap(counter);
    await tester.pumpAndSettle();
    expect(f.controller.charmStatusReady, isTrue);
    expect(f.controller.snapshot.charmEnabled, isFalse);
    expect(api.calls.last.body['enable'], isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busy toggles deduplicate; newer socket state wins', (
    tester,
  ) async {
    final api = _CounterApi();
    final f = await mountRoomMoreSettings(tester, api: api);
    await f.open(tester);
    api.heldPath = HttpApi.roomCharmUpdate;
    api.gate = Completer<Object?>();
    await tester.tap(counter);
    await tester.pump();
    expect(f.controller.charmStatusBusy, isTrue);
    expect(await f.controller.toggleCharmCounter(), isFalse);
    expect(api.count(HttpApi.roomCharmUpdate), 1);
    f.room.event('RoomMicCharmIsEnableEvent', true);
    api.gate!.complete(false);
    await tester.pumpAndSettle();
    expect(f.controller.snapshot.charmEnabled, isTrue);
    expect(image(true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('write supersedes an older status read', (tester) async {
    final api = _CounterApi();
    final f = await mountRoomMoreSettings(tester, api: api);
    api.heldPath = HttpApi.roomCharmEnabled;
    api.gate = Completer<Object?>();
    final read = f.controller.refreshCharmStatus();
    expect(await f.controller.setCharmEnabled(false), isTrue);
    api.gate!.complete(true);
    await read;
    await tester.pumpAndSettle();
    expect(f.controller.snapshot.charmEnabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failure keeps the icon, displays msg and can retry', (
    tester,
  ) async {
    final api = _CounterApi()
      ..updateError = NadyServerResponse<Object?>.fromJson({
        'code': 1003,
        'message': 'Generic error',
        'msg': 'Counter cannot be changed',
      }, (data) => data).toException();
    final f = await mountRoomMoreSettings(tester, api: api);
    await f.open(tester);
    await tester.tap(counter);
    await tester.pumpAndSettle();
    expect(image(true), findsOneWidget);
    expect(find.text('Counter cannot be changed'), findsOneWidget);
    expect(find.text('Generic error'), findsNothing);
    api.updateError = null;
    await tester.tap(counter);
    await tester.pumpAndSettle();
    expect(image(false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audiences receive status but cannot toggle it', (tester) async {
    final room = ToolsRoomFake()..setRole(UserRoomIdentity.audience);
    final f = await mountRoomMoreSettings(
      tester,
      room: room,
      api: _CounterApi(),
    );
    await f.open(tester);
    expect(counter, findsNothing);
    expect(await f.controller.toggleCharmCounter(), isFalse);
    f.room.event('RoomMicCharmIsEnableEvent', false);
    expect(f.controller.snapshot.charmEnabled, isFalse);
    expect(f.api.count(HttpApi.roomCharmUpdate), 0);
    expect(tester.takeException(), isNull);
  });

  for (final boundary in ['permission', 'session', 'exit', 'sheet']) {
    testWidgets('late counter response is safe after $boundary', (
      tester,
    ) async {
      final api = _CounterApi();
      final f = await mountRoomMoreSettings(tester, api: api);
      await f.open(tester);
      api.heldPath = HttpApi.roomCharmUpdate;
      api.gate = Completer<Object?>();
      await tester.tap(counter);
      await tester.pump();
      switch (boundary) {
        case 'permission':
          f.room.setRole(UserRoomIdentity.audience);
        case 'session':
          f.room.changeAccount(30);
          f.room.generation++;
          f.room.emitState();
        case 'exit':
          await f.room.leaveRoom();
        case 'sheet':
          f.close(tester);
          api.updateError = const NadyApiException(message: 'Late failure');
      }
      api.gate!.complete(false);
      await tester.pumpAndSettle();
      if (boundary == 'exit') {
        expect(f.controller.snapshot.sessionActive, isFalse);
      } else {
        expect(f.controller.snapshot.charmEnabled, isTrue);
      }
      expect(find.text('Late failure'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

class _CounterApi extends RoomSettingsApiFake {
  Object? updateError;
  @override
  Future<Object?> get(String path, [ToolJson? query]) async {
    if (path == HttpApi.roomCharmUpdate) {
      responses[path] = query!['enable'];
    }
    final result = await super.get(path, query);
    if (path == HttpApi.roomCharmUpdate && updateError != null) {
      throw updateError!;
    }
    return result;
  }
}
