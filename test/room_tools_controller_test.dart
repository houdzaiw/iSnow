import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_models.dart';

import 'support/room_tools_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ToolsRoomFake room;
  late ToolsApiFake api;
  late RoomToolsController vm;
  setUp(() async {
    room = ToolsRoomFake();
    api = ToolsApiFake();
    vm = RoomToolsController(roomId: '123', repository: api, room: room)
      ..start();
    await flushTools();
    api.calls.clear();
  });
  tearDown(() {
    vm.dispose();
    room.dispose();
  });

  test('only Chat and configured Nady Win/Treasure modes are enabled', () {
    expect(vm.snapshot.config.moreModes, [0, 1, 2]);
    const config = RoomFunctionConfig([
      {
        'type': 12,
        'list': [
          {'position': 7},
        ],
      },
      {
        'type': 8,
        'list': [
          {'position': 17},
        ],
      },
    ]);
    expect(config.moreModes, [0]);
    expect(config.enabled(8, 17), isTrue);
  });
  test(
    'selected mode restores locally without toggling or requesting again',
    () async {
      expect(await vm.selectMode(1), isTrue);
      vm.foldLobby();
      expect(await vm.selectMode(1), isTrue);
      expect(api.count(HttpApi.lobbyOpen), 1);
      expect(vm.snapshot.lobbyVisible, isTrue);
      expect(await vm.selectMode(0), isTrue);
      expect(
        api.calls.lastWhere((call) => call.path == HttpApi.lobbyOpen).body,
        {'roomId': '123', 'status': 0, 'lobbyType': 1},
      );
    },
  );
  test(
    'manager permission is rechecked at submission and after response',
    () async {
      room.setRole(UserRoomIdentity.audience);
      expect(await vm.setCurrency(2), isFalse);
      expect(api.calls, isEmpty);
      room.setRole(UserRoomIdentity.manager);
      api.heldPath = HttpApi.roomCharmSwitch;
      api.gate = Completer();
      final operation = vm.setCurrency(2);
      await flushTools();
      room.setRole(UserRoomIdentity.audience);
      api.gate!.complete(null);
      expect(await operation, isFalse);
      expect(vm.snapshot.currency, 1);
    },
  );
  test('old response cannot mutate a new session with the same ID', () async {
    api.heldPath = HttpApi.roomCharmSwitch;
    api.gate = Completer();
    final pending = vm.setCurrency(2);
    await flushTools();
    room.generation++;
    room.notifyListeners();
    await flushTools();
    api.gate!.complete(null);
    expect(await pending, isFalse);
    expect(vm.snapshot.currency, 1);
  });
  test('false charm response is valid data, not API failure', () async {
    api.responses[HttpApi.roomCharmUpdate] = false;
    expect(await vm.setCharmEnabled(false), isTrue);
    expect(vm.snapshot.charmEnabled, isFalse);
    expect(vm.snapshot.error, isNull);
  });
  test('duplicate submissions use a single request', () async {
    api.heldPath = HttpApi.roomCharmSwitch;
    api.gate = Completer();
    final pending = vm.setCurrency(2);
    await flushTools();
    expect(await vm.setCurrency(1), isFalse);
    expect(api.count(HttpApi.roomCharmSwitch), 1);
    api.gate!.complete(null);
    expect(await pending, isTrue);
  });
  test(
    'Keep/background preserve the room and continue business events',
    () async {
      room.minimizeRoom();
      vm.didChangeAppLifecycleState(AppLifecycleState.paused);
      room.event('RoomMicCharmUpdate', 2);
      room.event('RoomScreenLuckyBagSendEvent', {
        'msg': 'sent a box',
      }, id: 'lucky');
      expect(vm.snapshot.currency, 2);
      expect(vm.snapshot.luckyMessages.length, 1);
      expect(vm.snapshot.sessionActive, isTrue);
      expect(room.leaves, 0);
      expect(vm.snapshot.worldBanners, isEmpty);
    },
  );
  test(
    'realtime messages deduplicate across room channels and reject wrong room',
    () {
      room.event('RoomPkInfoUpdate', _pk(1));
      room.event('RoomPkInfoUpdate', _pk(2), channel: 'room');
      expect(vm.snapshot.pk.eventType, 1);
      room.event(
        'RoomPkInfoUpdate',
        _pk(4),
        channel: 'room:other',
        id: 'wrong',
      );
      expect(vm.snapshot.pk.active, isTrue);
      room.event('RoomMicCharmUpdate', {'digitalCurrency': 2}, id: 'bad');
      expect(vm.snapshot.currency, 1);
    },
  );
  test(
    'terminal PK cannot be resurrected by replay; failed end stays active',
    () async {
      room.event('RoomPkInfoUpdate', _pk(1));
      api.failingPath = HttpApi.roomPkOver;
      expect(await vm.endPk(), isFalse);
      expect(vm.snapshot.pk.active, isTrue);
      room.event('RoomPkInfoUpdate', _pk(4), id: 'end');
      room.event('RoomPkInfoUpdate', _pk(2), id: 'old');
      await vm.refresh();
      expect(vm.snapshot.pk.eventType, 4);
      expect(vm.snapshot.pk.users.first['pkScore'], 12);
    },
  );
  test(
    'PK participant payload uses live mic indexes and duration minutes',
    () async {
      room.current = room.current.copyWith(
        micList: const [
          RoomMicModel(position: 3, uid: 11, raw: {}),
          RoomMicModel(position: 8, uid: 22, raw: {}),
        ],
      );
      expect(await vm.beginPk([11, 22], 5, oneOnOne: true), isTrue);
      final body = api.calls
          .firstWhere((call) => call.path == HttpApi.roomPkBegin)
          .body;
      expect(body['duration'], 5);
      expect(body['pkUserList'], [
        {'uid': 11, 'identity': 1, 'micIndex': 3},
        {'uid': 22, 'identity': 2, 'micIndex': 8},
      ]);
      expect(await vm.beginPk([11, 99], 5, oneOnOne: true), isFalse);
      expect(api.count(HttpApi.roomPkBegin), 1);
    },
  );
  test(
    'first Lucky Box needs explicit confirmation and exact config',
    () async {
      expect(
        await vm.sendLucky(
          type: 0,
          gold: 100,
          recipients: 1,
          countdown: 0,
          confirmed: false,
        ),
        isFalse,
      );
      expect(api.count(HttpApi.roomLuckyPush), 0);
      expect(api.confirmation, isFalse);
      expect(
        await vm.sendLucky(
          type: 0,
          gold: 100,
          recipients: 1,
          countdown: 0,
          confirmed: true,
        ),
        isTrue,
      );
      expect(api.confirmation, isTrue);
      expect(api.count(HttpApi.roomLuckyPush), 1);
      expect(
        await vm.sendLucky(
          type: 1,
          gold: 100,
          recipients: 1,
          countdown: 0,
          confirmed: true,
        ),
        isFalse,
      );
    },
  );
  test('audience Lucky Box visibility follows server flag', () async {
    room.setRole(UserRoomIdentity.audience);
    expect(vm.canSendLucky, isFalse);
    api.responses[HttpApi.roomLuckyConfig] = {'visible': true};
    await vm.refresh();
    expect(vm.canSendLucky, isTrue);
  });
  test(
    'Lucky Box network failure is not a losing result; retry succeeds once',
    () async {
      api.responses[HttpApi.roomLuckyList] = [
        {'id': 7, 'remainingTime': 0},
      ];
      await vm.refreshBags();
      api.failingPath = HttpApi.roomLuckyGrab;
      expect(await vm.grabLucky('7'), isNull);
      expect(vm.snapshot.bags.length, 1);
      api.failingPath = null;
      api.responses[HttpApi.roomLuckyGrab] = {'count': 0};
      expect(await vm.grabLucky('7'), {'count': 0});
      expect(vm.snapshot.bags, isEmpty);
      expect(await vm.grabLucky('7'), isNull);
      expect(api.count(HttpApi.roomLuckyGrab), 2);
    },
  );
  test('Exit clears runtime data and drops late broadcasts', () async {
    room.event('RoomPkInfoUpdate', _pk(1));
    await room.leaveRoom();
    room.event('RoomPkInfoUpdate', _pk(2), id: 'late');
    expect(vm.snapshot.sessionActive, isFalse);
    expect(vm.snapshot.pk.raw, isEmpty);
    expect(await vm.selectMode(1), isFalse);
  });
  test('effect aggregate derives from all five children', () async {
    expect(await vm.setEffect('gift_effect', false), isTrue);
    expect(vm.snapshot.effects.all, isFalse);
    await vm.setEffect('all_effect', true);
    expect(vm.snapshot.effects.toJson().values, everyElement(true));
  });
  test(
    'vehicle preference gates real entry queue, while wave preference never mutes audio',
    () async {
      final payload = {
        'roomId': '123',
        'userBaseInfo': {
          'uid': 20,
          'vehicle': {'animationUrl': 'https://assets.example/car.pag'},
        },
      };
      room.event(
        'RoomUserPropInfoEvent',
        payload,
        channel: 'global',
        id: 'car',
      );
      expect(vm.snapshot.vehicleEffects.length, 1);
      await vm.setEffect('car_effect', false);
      expect(vm.snapshot.vehicleEffects, isEmpty);
      room.event(
        'RoomUserPropInfoEvent',
        payload,
        channel: 'global',
        id: 'car2',
      );
      expect(vm.snapshot.vehicleEffects, isEmpty);
      await vm.setEffect('sound_effect', false);
      expect(room.speaker, isFalse);
      expect(vm.snapshot.effects.sound, isFalse);
      expect(room.leaves, 0);
    },
  );
  test('Socket mode update wins over a delayed HTTP response', () async {
    api.heldPath = HttpApi.lobbyOpen;
    api.gate = Completer();
    final pending = vm.selectMode(1);
    await flushTools();
    room.event('RoomLobbyStatusEvent', {'status': 0, 'lobbyType': 1});
    api.gate!.complete(null);
    await pending;
    expect(vm.snapshot.lobbyType, 0);
    expect(vm.snapshot.lobbyVisible, isFalse);
  });
}

ToolJson _pk(int type) => {
  'eventType': type,
  'pkInfo': {
    'pkId': 9,
    'countdown': DateTime.now()
        .add(const Duration(minutes: 3))
        .millisecondsSinceEpoch,
    'pkMap': [
      {
        'userInfo': {'uid': 11, 'nick': 'Winner'},
        'pkScore': 12,
      },
    ],
  },
};
