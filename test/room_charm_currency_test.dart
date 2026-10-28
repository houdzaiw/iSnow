import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/server_response.dart';

import 'support/room_more_settings_fixture.dart';
import 'support/room_tools_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (label, raw, parsed, initial)
      in <(String, Map<String, dynamic>, int?, int)>[
        ('missing', {}, null, 1),
        ('null', {'digitalCurrency': null}, null, 1),
        ('zero', {'digitalCurrency': 0}, 0, 0),
        ('coins', {'digitalCurrency': 1}, 1, 1),
        ('diamonds', {'digitalCurrency': 2}, 2, 2),
        ('numeric string', {'digitalCurrency': '2'}, 2, 2),
        ('unsupported', {'digitalCurrency': 99}, 99, 0),
        ('malformed', {'digitalCurrency': 'unknown'}, null, 0),
      ]) {
    test('entry $label preserves the Nady currency contract', () async {
      final response = EnterRoomResp.fromJson({'roomId': '123', ...raw});
      expect(response.digitalCurrency, parsed);
      expect(response.initialCharmCurrency, initial);
      final room = _CurrencyRoom(raw);
      final api = ToolsApiFake();
      final vm = RoomToolsController(
        roomId: '123',
        repository: api,
        room: room,
      );
      addTearDown(() {
        vm.dispose();
        room.dispose();
      });
      vm.start();
      await flushTools();
      expect(vm.snapshot.currency, initial);
      expect(api.count(HttpApi.roomCharmSwitch), 0);
      // Nady reads entry/socket state, not a currency field in room/get/info.
      expect(room.refreshes, 0);
    });
  }

  test(
    'socket currency wins over a pending first selection and refresh',
    () async {
      final room = _CurrencyRoom({'digitalCurrency': 0});
      final api = ToolsApiFake();
      final vm = RoomToolsController(
        roomId: '123',
        repository: api,
        room: room,
      );
      addTearDown(() {
        vm.dispose();
        room.dispose();
      });
      vm.start();
      await flushTools();
      api.heldPath = HttpApi.roomCharmSwitch;
      api.gate = Completer<Object?>();
      final pending = vm.setCurrency(1);
      await flushTools();
      room.event('RoomMicCharmUpdate', 2);
      api.gate!.complete(null);
      expect(await pending, isTrue);
      await vm.refresh();
      expect(vm.snapshot.currency, 2);
      expect(room.current.enterResponse!.digitalCurrency, 0);
    },
  );

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('zero entry is selectable without a fake default at $width', (
      tester,
    ) async {
      final room = _CurrencyRoom({'digitalCurrency': 0});
      final f = await mountRoomMoreSettings(tester, room: room, width: width);
      await f.open(tester);
      await tester.tap(find.text('Setting'));
      await tester.pumpAndSettle();
      expect(find.text('Currency not available yet'), findsNothing);
      expect(
        find.text('Select a currency to calculate charm.'),
        findsOneWidget,
      );
      expect(
        tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>)).groupValue,
        0,
      );
      expect(
        tester
            .widgetList<Radio<int>>(find.byType(Radio<int>))
            .every((radio) => radio.enabled == true),
        isTrue,
      );
      expect(f.api.count(HttpApi.roomCharmSwitch), 0);
      expect(room.refreshes, 0);
      await tester.tap(find.byKey(const ValueKey('room-currency-2')));
      await tester.pumpAndSettle();
      expect(f.controller.snapshot.currency, 2);
      expect(find.text('Select a currency to calculate charm.'), findsNothing);
      expect(
        f.api.calls.lastWhere((c) => c.path == HttpApi.roomCharmSwitch).body,
        {'roomId': '123', 'digitalCurrency': 2},
      );
      expect(room.refreshes, 1);
      f.close(tester);
      await tester.pumpAndSettle();
      await f.open(tester);
      await tester.tap(find.text('Setting'));
      await tester.pumpAndSettle();
      expect(f.controller.snapshot.currency, 2);
      expect(f.api.count(HttpApi.roomCharmSwitch), 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('first selection preserves zero on failure, then retries', (
    tester,
  ) async {
    final api = _CurrencyApi()
      ..currencyError = NadyServerResponse<Object?>.fromJson({
        'code': 1003,
        'message': 'Generic failure',
        'msg': 'Currency cannot be changed',
      }, (value) => value).toException();
    final f = await mountRoomMoreSettings(
      tester,
      room: _CurrencyRoom({'digitalCurrency': 0}),
      api: api,
    );
    await f.open(tester);
    await tester.tap(find.text('Setting'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room-currency-1')));
    await tester.pumpAndSettle();
    expect(f.controller.snapshot.currency, 0);
    expect(find.text('Currency cannot be changed'), findsOneWidget);
    expect(find.text('Generic failure'), findsNothing);
    api.currencyError = null;
    api.heldPath = HttpApi.roomCharmSwitch;
    api.gate = Completer<Object?>();
    await tester.tap(find.byKey(const ValueKey('room-currency-1')));
    await tester.pump();
    expect(f.controller.snapshot.currency, 0);
    expect(
      tester
          .widgetList<Radio<int>>(find.byType(Radio<int>))
          .every((radio) => radio.enabled == false),
      isTrue,
    );
    expect(await f.controller.setCurrency(2), isFalse);
    api.gate!.complete(null);
    await tester.pumpAndSettle();
    expect(f.controller.snapshot.currency, 1);
    expect(api.count(HttpApi.roomCharmSwitch), 2);
    expect(tester.takeException(), isNull);
  });
}

class _CurrencyRoom extends ToolsRoomFake {
  _CurrencyRoom(Map<String, dynamic> entry) {
    current = current.copyWith(
      enterResponse: EnterRoomResp.fromJson({
        'roomId': '123',
        'identity': 'ROOM_OWNER',
        ...entry,
      }),
    );
  }

  int refreshes = 0;
  @override
  Future<void> refreshRoomData() async {
    refreshes++;
  }
}

class _CurrencyApi extends RoomSettingsApiFake {
  Object? currencyError;
  @override
  Future<Object?> post(String path, ToolJson body) async {
    final result = await super.post(path, body);
    if (path == HttpApi.roomCharmSwitch && currencyError != null) {
      throw currencyError!;
    }
    return result;
  }
}
