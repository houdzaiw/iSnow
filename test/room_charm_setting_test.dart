import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project/classes/room/more/room_settings_page.dart';
import 'package:project/classes/room/more/room_charm_settings_sheet.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/server_response.dart';

import 'support/room_more_settings_fixture.dart';
import 'support/room_tools_fakes.dart';

void main() {
  final sheet = find.byKey(const ValueKey('room-more-tools-sheet'));
  Finder choice(int value) => find.byKey(ValueKey('room-currency-$value'));
  int? selected(WidgetTester tester) =>
      tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>)).groupValue;

  Future<void> openSetting(
    WidgetTester tester,
    RoomMoreSettingsFixture f,
  ) async {
    await f.openCharm(tester);
    expect(sheet, findsNothing);
    expect(find.byType(RoomCharmSettingsSheet), findsOneWidget);
    expect(find.byKey(const ValueKey('room-more-tabs')), findsNothing);
    expect(find.byType(Radio<int>), findsNWidgets(2));
    expect(find.byType(Switch), findsNothing);
    expect(
      find.text(
        'Charm value is calculated based on the number of gold coins received as gifts.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Charm value is calculated based on the number of diamonds received as gifts.',
      ),
      findsOneWidget,
    );
    expect(find.byType(RoomSettingsPage), findsNothing);
    expect(f.router.state.uri.path, '/room/123');
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('Charm Set saves both currencies and retains them at $width', (
      tester,
    ) async {
      final f = await mountRoomMoreSettings(tester, width: width);
      await openSetting(tester, f);
      expect(selected(tester), 1);
      expect(tester.getSize(find.byType(RoomCharmSettingsSheet)).width, width);
      await tester.tap(choice(1));
      await tester.pumpAndSettle();
      expect(f.api.count(HttpApi.roomCharmSwitch), 0);
      await tester.tap(choice(2));
      await tester.pumpAndSettle();
      expect(selected(tester), 2);
      expect(
        f.api.calls.lastWhere((c) => c.path == HttpApi.roomCharmSwitch).body,
        {'roomId': '123', 'digitalCurrency': 2},
      );
      f.close(tester);
      await tester.pumpAndSettle();
      await openSetting(tester, f);
      expect(selected(tester), 2);
      await tester.tap(choice(1));
      await tester.pumpAndSettle();
      expect(selected(tester), 1);
      expect(f.api.count(HttpApi.roomCharmSwitch), 2);
      expect(f.room.leaves, 0);
      expect(f.room.speaker, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('back and barrier dismiss only the standalone charm sheet', (
    tester,
  ) async {
    final f = await mountRoomMoreSettings(tester);
    await openSetting(tester, f);
    await tester.tap(find.byKey(const ValueKey('room-charm-settings-back')));
    await tester.pumpAndSettle();
    expect(find.byType(RoomCharmSettingsSheet), findsNothing);
    expect(f.router.state.uri.path, '/room/123');
    await openSetting(tester, f);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(RoomCharmSettingsSheet), findsNothing);
    expect(f.api.count(HttpApi.roomCharmSwitch), 0);
    expect(f.room.leaves, 0);
    expect(tester.takeException(), isNull);
  });

  for (final boundary in ['permission', 'session', 'exit']) {
    testWidgets(
      'More closing transition cannot open stale charm after $boundary',
      (tester) async {
        final f = await mountRoomMoreSettings(tester);
        await f.open(tester);
        await tester.tap(find.text('Charm Set'));
        await tester.pump();
        switch (boundary) {
          case 'permission':
            f.room.setRole(UserRoomIdentity.audience);
          case 'session':
            f.room.generation++;
            f.room.changeAccount(30);
            f.room.emitState();
          case 'exit':
            await f.room.leaveRoom();
        }
        await tester.pumpAndSettle();
        expect(find.byType(RoomCharmSettingsSheet), findsNothing);
        expect(f.api.count(HttpApi.roomCharmSwitch), 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('charm options remain readable above keyboard on small screens', (
    tester,
  ) async {
    final f = await mountRoomMoreSettings(
      tester,
      width: 320,
      height: 568,
      inset: 200,
      bottom: 24,
    );
    await openSetting(tester, f);
    final bounds = tester.getRect(
      find.byKey(const ValueKey('room-charm-settings-sheet')),
    );
    expect(bounds.width, 320);
    expect(bounds.bottom, lessThanOrEqualTo(368));
    await tester.ensureVisible(choice(2));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(choice(2)).bottom,
      lessThanOrEqualTo(bounds.bottom - 24),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving shows progress and prevents duplicate submissions', (
    tester,
  ) async {
    final f = await mountRoomMoreSettings(tester);
    await openSetting(tester, f);
    f.api.heldPath = HttpApi.roomCharmSwitch;
    f.api.gate = Completer<Object?>();
    await tester.tap(choice(2));
    await tester.pump();
    expect(find.byKey(const ValueKey('room-currency-saving')), findsOneWidget);
    expect(selected(tester), 1);
    expect(
      tester
          .widgetList<Radio<int>>(find.byType(Radio<int>))
          .every((r) => r.enabled == false),
      isTrue,
    );
    expect(await f.controller.setCurrency(1), isFalse);
    expect(f.api.count(HttpApi.roomCharmSwitch), 1);
    f.api.gate!.complete(null);
    await tester.pumpAndSettle();
    expect(selected(tester), 2);
    expect(find.byKey(const ValueKey('room-currency-saving')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('current panel shows the server msg once and keeps selection', (
    tester,
  ) async {
    final api = _SettingApi()..currencyError = _failure;
    final f = await mountRoomMoreSettings(tester, api: api);
    await openSetting(tester, f);
    await tester.tap(choice(2));
    await tester.pumpAndSettle();
    expect(selected(tester), 1);
    expect(find.text('Currency save rejected'), findsOneWidget);
    expect(find.text('Generic failure'), findsNothing);
    api.currencyError = null;
    await tester.tap(choice(2));
    await tester.pumpAndSettle();
    expect(selected(tester), 2);
    expect(tester.takeException(), isNull);
  });

  for (final boundary in [
    'closing',
    'disposed',
    'permission',
    'session',
    'exit',
  ]) {
    testWidgets('late currency failure is ignored after $boundary', (
      tester,
    ) async {
      final api = _SettingApi()..currencyError = _failure;
      final f = await mountRoomMoreSettings(tester, api: api);
      await openSetting(tester, f);
      api.heldPath = HttpApi.roomCharmSwitch;
      api.gate = Completer<Object?>();
      await tester.tap(choice(2));
      await tester.pump();
      switch (boundary) {
        case 'closing':
        case 'disposed':
          f.close(tester);
          if (boundary == 'disposed') await tester.pumpAndSettle();
        case 'permission':
          f.room.setRole(UserRoomIdentity.audience);
        case 'session':
          f.room.changeAccount(30);
          f.room.generation++;
          f.room.emitState();
        case 'exit':
          await f.room.leaveRoom();
      }
      api.gate!.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('Currency save rejected'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'currency invalidates contributor data and receives room events',
    (tester) async {
      final f = await mountRoomMoreSettings(tester);
      final rank = roomCharmRankProvider(('123', 20));
      final subscription = f.container.listen(rank, (_, _) {});
      addTearDown(subscription.close);
      await f.container.read(rank.future);
      expect(f.api.count(HttpApi.roomCharmRank), 1);
      expect(await f.controller.setCurrency(2), isTrue);
      await f.container.read(rank.future);
      expect(f.api.count(HttpApi.roomCharmRank), 2);
      await openSetting(tester, f);
      expect(selected(tester), 2);
      f.room.event('RoomMicCharmUpdate', 1);
      await tester.pumpAndSettle();
      expect(selected(tester), 1);
      expect(f.api.count(HttpApi.roomCharmSwitch), 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('zero is not a successful no-op currency update', (tester) async {
    final room = ToolsRoomFake();
    room.current = room.current.copyWith(
      enterResponse: const EnterRoomResp(
        roomId: '123',
        identity: UserRoomIdentity.owner,
        raw: {'digitalCurrency': 0},
      ),
    );
    final f = await mountRoomMoreSettings(tester, room: room);
    for (final invalid in [0, -1, 3]) {
      expect(await f.controller.setCurrency(invalid), isFalse);
    }
    expect(f.controller.snapshot.currency, 0);
    expect(f.api.count(HttpApi.roomCharmSwitch), 0);
  });
}

final _failure = NadyServerResponse<Object?>.fromJson({
  'code': 1003,
  'message': 'Generic failure',
  'msg': 'Currency save rejected',
}, (value) => value).toException();

class _SettingApi extends RoomSettingsApiFake {
  Object? currencyError;
  @override
  Future<Object?> post(String path, ToolJson body) async {
    final response = await super.post(path, body);
    if (path == HttpApi.roomCharmSwitch && currencyError != null) {
      throw currencyError!;
    }
    return response;
  }
}
