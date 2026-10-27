import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/manager/http_api.dart';

import 'support/room_tools_fakes.dart';

const _enabled = RoomFunctionConfig([
  {
    'type': 8,
    'list': [
      {'position': 17},
    ],
  },
]);

ToolJson _activity(int status, {String? id = '42'}) => {
  'status': status,
  'gameBigWinInfoVO': {
    if (id != null) 'gameBigWinId': id,
    'gameId': 'game-1',
    'gameName': 'Game',
    'bigWinTotalCoins': 1000000,
    'winRoundCount': 3,
    'curRound': 1,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final status in [0, 1, 2, 3, 4, -1, 5]) {
    test('room pendant follows Nady status $status', () {
      final state = RoomToolsState(
        sessionActive: true,
        config: _enabled,
        bigWin: _activity(status),
      );
      expect(state.showBigWinPendant, status >= 0 && status < 4);
      expect(state.bigWinSnapshot.poolLabel, '1M');
    });
  }

  test(
    'configuration alone, missing identity, and inactive session stay hidden',
    () {
      expect(
        const RoomToolsState(
          sessionActive: true,
          config: _enabled,
        ).showBigWinPendant,
        isFalse,
      );
      expect(
        RoomToolsState(
          sessionActive: true,
          config: _enabled,
          bigWin: _activity(1, id: null),
        ).showBigWinPendant,
        isFalse,
      );
      expect(
        RoomToolsState(
          sessionActive: true,
          bigWin: _activity(1),
        ).showBigWinPendant,
        isFalse,
      );
      expect(
        RoomToolsState(
          config: _enabled,
          bigWin: _activity(1),
        ).showBigWinPendant,
        isFalse,
      );
    },
  );

  test('status updates retain metadata only for the same activity', () {
    final snapshot = RoomBigWinSnapshot(_activity(1));
    final same = snapshot.applyStatus({'gameBigWinId': '42', 'status': 2});
    expect(same.status, 2);
    expect(same.info['gameName'], 'Game');
    final replacement = snapshot.applyStatus({
      'gameBigWinId': '43',
      'status': 1,
    });
    expect(replacement.id, '43');
    expect(replacement.info.containsKey('gameName'), isFalse);
    expect(snapshot.applyStatus({'status': 1}).hasPendant, isFalse);
  });

  test('missing prize pool is not rendered as a fabricated zero', () {
    expect(const RoomBigWinSnapshot({}).poolLabel, '');
    expect(
      const RoomBigWinSnapshot({
        'gameBigWinInfoVO': {'bigWinTotalCoins': 0},
      }).poolLabel,
      '0',
    );
    expect(
      const RoomBigWinSnapshot({
        'gameBigWinInfoVO': {'bigWinTotalCoins': 'NaN'},
      }).poolLabel,
      '',
    );
  });

  group('realtime activity lifecycle', () {
    late ToolsRoomFake room;
    late ToolsApiFake api;
    late RoomToolsController vm;
    setUp(() async {
      room = ToolsRoomFake();
      api = ToolsApiFake();
      api.responses[HttpApi.roomFunctions] = _enabled.items;
      api.responses[HttpApi.gameBigWinShow] = _activity(1);
      vm = RoomToolsController(roomId: '123', repository: api, room: room)
        ..start();
      await flushTools();
    });
    tearDown(() {
      vm.dispose();
      room.dispose();
    });

    void statusEvent(int status, {bool showScreen = false}) =>
        room.event('RoomLobbyBigWinStatusEvent', {
          'gameBigWinId': '42',
          'gameId': 'game-1',
          'status': status,
          'showScreen': showScreen,
        }, channel: 'global_lobby');

    test('showScreen only controls the broadcast, not the pendant', () async {
      api.responses[HttpApi.gameBigWinShow] = _activity(2);
      statusEvent(2);
      expect(vm.snapshot.showBigWinPendant, isTrue);
      expect(vm.snapshot.bigWinSnapshot.status, 2);
      expect(vm.snapshot.prize, isEmpty);
      await flushTools();
      expect(vm.snapshot.showBigWinPendant, isTrue);
    });

    test(
      'end event hides immediately even if the detail refresh fails',
      () async {
        api.failingPath = HttpApi.gameBigWinShow;
        statusEvent(4);
        expect(vm.snapshot.showBigWinPendant, isFalse);
        await flushTools();
        expect(vm.snapshot.bigWinSnapshot.status, 4);
        expect(vm.snapshot.showBigWinPendant, isFalse);
      },
    );

    test(
      'a delayed old HTTP snapshot cannot resurrect an ended pendant',
      () async {
        api.heldPath = HttpApi.gameBigWinShow;
        api.gate = Completer<Object?>();
        final loading = vm.refreshBigWin();
        await flushTools();
        statusEvent(4);
        expect(vm.snapshot.showBigWinPendant, isFalse);
        api.heldPath = null;
        api.responses[HttpApi.gameBigWinShow] = _activity(4);
        api.gate!.complete(_activity(1));
        await loading;
        await flushTools();
        expect(vm.snapshot.bigWinSnapshot.status, 4);
        expect(vm.snapshot.showBigWinPendant, isFalse);
      },
    );

    test('leaving drops pending refreshes and activity entries', () async {
      api.heldPath = HttpApi.gameBigWinShow;
      api.gate = Completer<Object?>();
      final pending = vm.refreshBigWin();
      await room.leaveRoom();
      api.gate!.complete(_activity(1));
      await pending;
      expect(vm.snapshot.showBigWinPendant, isFalse);
      expect(vm.snapshot.bigWin, isEmpty);
    });
  });
}
