import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/oauth/provider/login_provider.dart';
import 'package:project/manager/app_socket_manager.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_socket_message.dart';

import 'support/room_lifecycle_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomLifecycleFixture fixture;
  setUp(() => fixture = RoomLifecycleFixture());
  tearDown(() => fixture.dispose());

  test(
    'Keep and restore retain data, Agora and socket without any calls',
    () async {
      await fixture.enter();
      final room = fixture.manager.state;
      final agora = fixture.agora.state;
      final socket = fixture.socket.state;
      fixture.actions.clear();
      fixture.manager.minimizeRoom();
      expect(fixture.manager.state.isMinimized, isTrue);
      expect(fixture.manager.state.isInRoom, isTrue);
      expect(fixture.manager.state.roomInfo, same(room.roomInfo));
      expect(fixture.manager.state.micList, same(room.micList));
      expect(fixture.manager.state.enterResponse, same(room.enterResponse));
      await fixture.manager.enterRoom(roomId: 'first');
      expect(fixture.manager.state.isMinimized, isFalse);
      expect(fixture.agora.state, same(agora));
      expect(fixture.socket.state, same(socket));
      expect(fixture.actions, isEmpty);
    },
  );

  for (final failure in ['none', 'http', 'agora', 'socket', 'all']) {
    test('Exit always reaches idle despite $failure failure', () async {
      await fixture.enter();
      fixture.http.failExit = failure == 'http' || failure == 'all';
      fixture.agora.failLeave = failure == 'agora' || failure == 'all';
      fixture.socket.failLeave = failure == 'socket' || failure == 'all';
      fixture.socket.failDisconnect = failure == 'all';
      fixture.actions.clear();
      await fixture.manager.leaveRoom();
      expect(fixture.actions, [
        'exit:first:test-token',
        'agora-leave',
        'socket-leave:first',
        'socket-disconnect',
      ]);
      final state = fixture.manager.state;
      expect(state.status, RoomStatus.idle);
      expect(state.isInRoom, isFalse);
      expect(state.isMinimized, isFalse);
      expect(state.currentRoomId, isNull);
      expect(state.roomInfo, isNull);
      expect(state.enterResponse, isNull);
      expect(state.micList, isEmpty);
      expect(state.errorMessage, isNull);
      await fixture.manager.leaveRoom();
      expect(fixture.actions, hasLength(4));
    });
  }

  test(
    'duplicate Exit shares one task and Keep/restore cannot revive leaving',
    () async {
      await fixture.enter();
      fixture.manager.minimizeRoom();
      fixture.http.exitGate = Completer<void>();
      final first = fixture.manager.leaveRoom();
      final second = fixture.manager.leaveRoom();
      expect(second, same(first));
      fixture.manager.restoreRoom();
      fixture.manager.minimizeRoom();
      expect(fixture.manager.state.status, RoomStatus.leaving);
      expect(fixture.manager.state.isMinimized, isFalse);
      fixture.http.exitGate!.complete();
      await first;
      expect(
        fixture.actions.where((item) => item.startsWith('exit:')),
        hasLength(1),
      );
    },
  );

  test(
    'Exit drains a pending enter and exits the late canonical room',
    () async {
      fixture.http.enterGate = Completer<void>();
      fixture.http.canonicalRoomId = 'canonical';
      final entering = fixture.manager.enterRoom(roomId: 'alias');
      final leaving = fixture.manager.leaveRoom();
      fixture.http.enterGate!.complete();
      await entering;
      await leaving;
      expect(fixture.actions, [
        'enter:alias',
        'exit:canonical:test-token',
        'agora-leave',
        'socket-leave:canonical',
        'socket-disconnect',
      ]);
      expect(fixture.manager.state.status, RoomStatus.idle);
    },
  );

  test(
    'late SDK joins settle before cleanup and cannot reconnect after Exit',
    () async {
      fixture.socket.joinGate = Completer<void>();
      fixture.agora.joinGate = Completer<void>();
      await fixture.enter();
      final leaving = fixture.manager.leaveRoom();
      fixture.socket.joinGate!.complete();
      fixture.agora.joinGate!.complete();
      await leaving;
      expect(fixture.agora.state.joined, isFalse);
      expect(fixture.socket.state.roomId, isNull);
      expect(fixture.manager.state.status, RoomStatus.idle);
    },
  );

  test('late room details cannot repopulate an exited session', () async {
    await fixture.enter();
    fixture.http.infoGate = Completer<void>();
    final refresh = fixture.manager.refreshRoomInfo();
    await fixture.manager.leaveRoom();
    fixture.http.infoGate!.complete();
    await refresh;
    expect(fixture.manager.state.roomInfo, isNull);
    expect(fixture.manager.state.status, RoomStatus.idle);
  });

  test('switching rooms exits the old room before entering the next', () async {
    await fixture.enter();
    fixture.actions.clear();
    await fixture.enter('second');
    expect(fixture.actions.take(5), [
      'exit:first:test-token',
      'agora-leave',
      'socket-leave:first',
      'socket-disconnect',
      'enter:second',
    ]);
    expect(fixture.manager.state.currentRoomId, 'second');
    expect(fixture.manager.state.isInRoom, isTrue);
  });

  test(
    'transient reconnect keeps the room; permanent socket termination exits',
    () async {
      await fixture.enter();
      fixture.socket.setState(
        const AppSocketState(
          status: AppSocketStatus.connecting,
          roomId: 'first',
        ),
      );
      expect(fixture.manager.state.isInRoom, isTrue);
      fixture.socket.setState(
        const AppSocketState(
          status: AppSocketStatus.disconnected,
          roomId: 'first',
          isTerminal: true,
        ),
      );
      await fixture.manager.leaveRoom();
      expect(fixture.manager.state.status, RoomStatus.idle);
    },
  );

  test('fatal Agora event exits a kept room', () async {
    await fixture.enter();
    fixture.manager.minimizeRoom();
    fixture.agora.setState(
      const RoomAgoraState(roomId: 'first', isTerminal: true),
    );
    await fixture.manager.leaveRoom();
    expect(fixture.manager.state.status, RoomStatus.idle);
  });

  test(
    'Nady kick payload exits only the matching room and current user',
    () async {
      await fixture.enter();
      void kick(String roomId, int uid) => fixture.socket.controller.add(
        RoomSocketMessage(
          channel: 'room',
          event: 'RoomKickOutEvent',
          raw: const {},
          payload: {
            'roomId': roomId,
            'from': {'uid': uid},
          },
        ),
      );
      kick('first', 99);
      kick('other', 10);
      await fixture.flush();
      expect(fixture.manager.state.isInRoom, isTrue);
      fixture.manager.minimizeRoom();
      kick('first', 10);
      await fixture.flush();
      expect(fixture.manager.state.status, RoomStatus.idle);
    },
  );

  for (final failedLogout in [false, true]) {
    test(
      'logout exits room before clearing token even with logout failure=$failedLogout',
      () async {
        await fixture.enter();
        fixture.manager.minimizeRoom();
        fixture.actions.clear();
        fixture.http.failExit = true;
        fixture.http.failLogout = failedLogout;
        await LoginProvider(
          httpManager: fixture.http,
          authSession: fixture.auth,
          roomManager: fixture.manager,
        ).logout();
        expect(fixture.actions, [
          'exit:first:test-token',
          'agora-leave',
          'socket-leave:first',
          'socket-disconnect',
          'logout:test-token',
        ]);
        expect(await fixture.auth.isLoggedIn(), isFalse);
        expect(fixture.manager.state.status, RoomStatus.idle);
      },
    );
  }
}
