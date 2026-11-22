import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/pk/room_pk_view_model.dart';
import 'package:project/classes/room/pk/room_pk_repository.dart';
import 'package:project/classes/room/lucky_box/room_lucky_box_repository.dart';
import 'package:project/classes/room/lucky_box/room_lucky_box_view_model.dart';
import 'package:project/classes/room/lucky_box/room_lucky_box_models.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_models.dart';

import 'support/room_tools_fakes.dart';

Map<String, dynamic> pkEvent(
  int event, {
  int id = 9,
  int score = 100,
  int seconds = 180,
}) => {
  'eventType': event,
  'pkInfo': {
    'pkId': id,
    'countdown': DateTime.now()
        .add(Duration(seconds: seconds))
        .millisecondsSinceEpoch,
    'pkMap': [
      for (final uid in [11, 22])
        {
          'userInfo': {'uid': uid, 'nick': 'User $uid'},
          'identity': uid == 11 ? 1 : 2,
          'pkScore': uid == 11 ? score : 0,
          'contributorList': [
            {'uid': 33, 'nick': 'Supporter'},
          ],
        },
    ],
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ToolsRoomFake room;
  late ToolsApiFake api;
  late RoomToolsController tools;
  late RoomPkViewModel pk;
  late RoomLuckyBoxViewModel box;
  setUp(() async {
    room = ToolsRoomFake();
    api = ToolsApiFake();
    room.current = room.current.copyWith(
      micList: const [
        RoomMicModel(position: 1, uid: 11, userInfo: {'nick': 'Red'}, raw: {}),
        RoomMicModel(position: 4, uid: 22, userInfo: {'nick': 'Blue'}, raw: {}),
        RoomMicModel(
          position: 8,
          uid: 33,
          userInfo: {'nick': 'Third'},
          raw: {},
        ),
      ],
    );
    tools = RoomToolsController(roomId: '123', repository: api, room: room)
      ..start();
    await flushTools();
    pk = RoomPkViewModel(tools, room);
    box = RoomLuckyBoxViewModel(tools);
    api.calls.clear();
  });
  tearDown(() {
    pk.dispose();
    box.dispose();
    tools.dispose();
    room.dispose();
  });

  test(
    'PK selection follows UID after seats move or are occupied by another user',
    () {
      pk.select(11);
      pk.select(22);
      pk.select(33);
      pk.mode(true);
      expect(pk.state.selected, [11, 22]);
      room.current = room.current.copyWith(
        micList: const [
          RoomMicModel(position: 1, uid: 33, raw: {}),
          RoomMicModel(position: 8, uid: 22, raw: {}),
        ],
      );
      room.emitState();
      expect(pk.state.selected, [22]);
      expect(pk.state.selected, isNot(contains(33)));
    },
  );
  test(
    'PK modes clear selection; multi all and live indexes match Nady',
    () async {
      pk.select(11);
      pk.mode(false);
      expect(pk.state.selected, isEmpty);
      pk.selectAll();
      pk.duration(60);
      expect(pk.state.selected, [11, 22, 33]);
      await pk.begin();
      final body = api.calls
          .firstWhere((c) => c.path == HttpApi.roomPkBegin)
          .body;
      expect(body['duration'], 60);
      expect((body['pkUserList'] as List)[2], {
        'uid': 33,
        'identity': null,
        'micIndex': 8,
      });
    },
  );
  test(
    'PK start is locked against repeated taps and roles are rechecked',
    () async {
      pk.select(11);
      pk.select(22);
      api.heldPath = HttpApi.roomPkBegin;
      api.gate = Completer<Object?>();
      final first = pk.begin();
      await flushTools();
      expect(await pk.begin(), isFalse);
      room.setRole(UserRoomIdentity.audience);
      api.gate!.complete(null);
      await first;
      expect(api.count(HttpApi.roomPkBegin), 1);
      expect(pk.state.manager, isFalse);
    },
  );
  test(
    'PK empty snapshot clears active; final result retains typed contributors',
    () async {
      room.event('RoomPkInfoUpdate', pkEvent(1), id: 'start');
      expect(pk.state.data.active, isTrue);
      expect(pk.state.data.time(DateTime.now()), startsWith('3:'));
      room.event('RoomPkInfoUpdate', pkEvent(4), id: 'end');
      expect(pk.state.result!.winner!.uid, 11);
      expect(pk.state.result!.users.first.contributors.single.uid, 33);
      pk.closeResult();
      room.event('RoomPkInfoUpdate', pkEvent(4), id: 'duplicate');
      expect(pk.state.result, isNull);
      room.event('RoomPkInfoUpdate', pkEvent(1, id: 10), id: 'new');
      room.event('RoomPkInfoUpdate', {'eventType': 0}, id: 'clear');
      expect(pk.state.data.active, isFalse);
    },
  );
  test('early PK end and background do not manufacture winner effects', () {
    room.event('RoomPkInfoUpdate', pkEvent(3), id: 'early');
    expect(pk.state.result, isNull);
    pk.setVisible(false);
    room.event('RoomPkInfoUpdate', pkEvent(4, id: 10), id: 'background');
    pk.setVisible(true);
    expect(pk.state.result, isNull);
  });
  test(
    'PK zero scores still show result and end failure retains live PK',
    () async {
      room.event('RoomPkInfoUpdate', pkEvent(1), id: 'begin');
      api.failingPath = HttpApi.roomPkOver;
      expect(await pk.end(), isFalse);
      expect(pk.state.data.active, isTrue);
      room.event('RoomPkInfoUpdate', pkEvent(4, score: 0), id: 'done');
      expect(pk.state.result, isNotNull);
      expect(pk.state.winnerPending, isFalse);
    },
  );
  test(
    'PK local fold performs no server start/end; optional result id is preserved',
    () async {
      room.event('RoomPkInfoUpdate', pkEvent(1), id: 'start');
      pk.fold(false);
      expect(pk.state.mini, isFalse);
      pk.fold(true);
      expect(pk.state.mini, isTrue);
      await RoomPkRepository(api).fetch('123', pkId: '9');
      expect(api.calls.single.body, {'roomId': '123', 'pkId': '9'});
    },
  );
  test('PK expiry queries once and never decides the winner locally', () async {
    api.responses[HttpApi.roomPkInfo] = pkEvent(2, seconds: -1);
    room.event('RoomPkInfoUpdate', pkEvent(2, seconds: -1), id: 'expired');
    await flushTools();
    expect(api.count(HttpApi.roomPkInfo), 1);
    expect(pk.state.data.active, isTrue);
    expect(pk.state.result, isNull);
  });
  test(
    'current PK snapshot without eventType restores Nady active state',
    () async {
      final raw = pkEvent(1)..remove('eventType');
      api.responses[HttpApi.roomPkInfo] = raw;
      await tools.refreshPk();
      expect(pk.state.data.active, isTrue);
      expect(pk.state.data.users.length, 2);
    },
  );
  test('recreating room UI does not replay an old terminal PK winner', () {
    room.event('RoomPkInfoUpdate', pkEvent(4), id: 'finished-before-keep');
    final restored = RoomPkViewModel(tools, room);
    expect(restored.state.result, isNull);
    expect(restored.state.winnerPending, isFalse);
    restored.dispose();
  });
  test('configuration failure keeps cached box amounts read-only', () async {
    await box.load();
    api.failingPath = HttpApi.roomLuckyConfig;
    expect(await box.load(), isFalse);
    expect(box.state.canSubmit, isFalse);
    expect(await box.send(confirmed: true), isFalse);
    expect(api.count(HttpApi.roomLuckyPush), 0);
  });
  test(
    'FIFO survives list refresh reordering while a modal blocks presentation',
    () async {
      api.responses[HttpApi.roomLuckyList] = [
        {'id': 'late', 'remainingTime': 60},
        {'id': 'early', 'remainingTime': 0},
      ];
      await tools.refreshBags();
      box.tick(presentable: false);
      api.responses[HttpApi.roomLuckyList] = [
        {'id': 'late', 'remainingTime': 0},
        {'id': 'early', 'remainingTime': 0},
      ];
      await tools.refreshBags();
      box.tick(presentable: true);
      expect(box.state.current!.id, 'early');
      box.close();
      box.tick(presentable: true);
      expect(box.state.current!.id, 'late');
    },
  );
  test(
    'same room reentry resets activity state and drops an old send response',
    () async {
      await box.load();
      api.heldPath = HttpApi.roomLuckyPush;
      api.gate = Completer<Object?>();
      final old = box.send(confirmed: true);
      await flushTools();
      await room.leaveRoom();
      api.heldPath = null;
      room.current = room.current.copyWith(
        status: RoomStatus.ready,
        currentRoomId: '123',
        isInRoom: true,
      );
      room.setRole(UserRoomIdentity.owner);
      room.emitState();
      await flushTools();
      api.gate!.complete({'id': 'old', 'remainingTime': 30});
      await old;
      expect(box.state.active, isTrue);
      expect(box.state.sending, isFalse);
      expect(box.state.reviewRequired, isFalse);
      expect(pk.state.selected, isEmpty);
      expect(await box.load(), isTrue);
      expect(box.state.canSubmit, isTrue);
    },
  );
  test(
    'box modes/amounts reset invalid options; rules reject unsupported schemes',
    () async {
      await box.load();
      expect(box.state.gold, 100);
      expect(box.state.people, 1);
      box.choosePeople(5);
      box.chooseType(1);
      expect(box.state.gold, 200);
      expect(box.state.people, 2);
      expect(box.state.countdown, 60);
      box.chooseType(0);
      expect(box.state.people, 1);
      final config = RoomLuckyBoxConfig.fromJson({
        'rulesUrlEn': 'javascript:alert(1)',
        'rulesUrlAr': 'https://fixture.example/ar',
      });
      expect(config.rules('en'), '');
      expect(config.rules('ar'), 'https://fixture.example/ar');
    },
  );
  test(
    'box sends valid receipt once; first confirmation cancellation never submits',
    () async {
      await box.load();
      expect(await box.send(confirmed: false), isFalse);
      expect(api.count(HttpApi.roomLuckyPush), 0);
      await box.load();
      expect(await box.send(confirmed: true), isTrue);
      expect(api.count(HttpApi.roomLuckyPush), 1);
    },
  );
  test(
    'missing box send receipt requires status review and never auto-retries',
    () async {
      await box.load();
      api.responses[HttpApi.roomLuckyPush] = null;
      expect(await box.send(confirmed: true), isFalse);
      expect(box.state.reviewRequired, isTrue);
      expect(await box.send(confirmed: true), isFalse);
      expect(api.count(HttpApi.roomLuckyPush), 1);
      await box.load();
      expect(box.state.reviewRequired, isFalse);
    },
  );
  test('box send freezes selection and prevents duplicate charges', () async {
    await box.load();
    api.heldPath = HttpApi.roomLuckyPush;
    api.gate = Completer<Object?>();
    final task = box.send(confirmed: true);
    await flushTools();
    box.chooseType(1);
    expect(box.state.type, 0);
    expect(await box.send(confirmed: true), isFalse);
    api.gate!.complete({'id': '7', 'remainingTime': 30});
    expect(await task, isTrue);
    expect(api.count(HttpApi.roomLuckyPush), 1);
  });
  Future<void> bags() async {
    api.responses[HttpApi.roomLuckyList] = [
      {'id': 'a', 'remainingTime': 0},
      {'id': 'b', 'remainingTime': 0},
    ];
    await tools.refreshBags();
  }

  test(
    'box expiry queues presentation only and requires explicit Open to grab',
    () async {
      await bags();
      box.tick(presentable: false);
      expect(box.state.current, isNull);
      box.tick(presentable: true);
      expect(box.state.current!.id, 'a');
      expect(api.count(HttpApi.roomLuckyGrab), 0);
      box.close();
      box.tick(presentable: true);
      expect(box.state.current!.id, 'b');
      box.close();
      box.tick(presentable: true);
      expect(box.state.current, isNull);
      box.open('a');
      expect(box.state.current!.id, 'a');
    },
  );
  test(
    'box grab failure is retryable and zero count is a real losing result',
    () async {
      await bags();
      box.open('a');
      api.failingPath = HttpApi.roomLuckyGrab;
      await box.grab();
      expect(box.state.phase, RoomLuckyBoxPhase.error);
      expect(box.state.result, isNull);
      api.failingPath = null;
      api.responses[HttpApi.roomLuckyGrab] = {'count': 0};
      await box.grab();
      expect(box.state.result!.count, 0);
      expect(box.state.phase, RoomLuckyBoxPhase.result);
      await box.grab();
      expect(api.count(HttpApi.roomLuckyGrab), 2);
    },
  );
  test(
    'box close during request discards old UI result but preserves backend claim',
    () async {
      await bags();
      box.open('a');
      api.heldPath = HttpApi.roomLuckyGrab;
      api.gate = Completer<Object?>();
      final task = box.grab();
      await flushTools();
      box.close();
      api.gate!.complete({'count': 7});
      await task;
      expect(box.state.current, isNull);
      expect(box.state.result, isNull);
      expect(tools.snapshot.bags.any((b) => b.id == 'a'), isFalse);
    },
  );
  test(
    'box background/reentry does not replay paid result; room exit drops tasks',
    () async {
      await bags();
      box.open('a');
      api.responses[HttpApi.roomLuckyGrab] = {'count': 7};
      await box.grab();
      box.suspend();
      box.tick(presentable: true);
      expect(box.state.current!.id, 'b');
      await room.leaveRoom();
      expect(box.state.active, isFalse);
      expect(box.state.current, isNull);
      expect(pk.state.active, isFalse);
    },
  );
  test('account change during send validation prevents the order', () async {
    await box.load();
    api.heldPath = HttpApi.roomLuckyConfig;
    api.gate = Completer<Object?>();
    final task = box.send(confirmed: true);
    await flushTools();
    room.changeAccount(999);
    api.gate!.complete({});
    await task;
    expect(api.count(HttpApi.roomLuckyPush), 0);
    expect(box.state.active, isFalse);
  });
  test(
    'typed grab repository rejects missing count and preserves the exact bag ID',
    () async {
      api.responses[HttpApi.roomLuckyGrab] = {};
      await expectLater(
        RoomLuckyBoxRepository(api).grab('1234567890123456789'),
        throwsException,
      );
      expect(api.calls.single.body, {'luckyBagId': '1234567890123456789'});
    },
  );
}
