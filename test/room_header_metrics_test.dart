import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_header_metrics_view_model.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/server_response.dart';

import 'support/room_lifecycle_fakes.dart';
import 'support/room_tools_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('heat uses scalar endpoint and real room ID; zero is valid', () async {
    final fixture = RoomLifecycleFixture();
    final http = _HeatHttp(fixture);
    final repository = RoomRepository(httpManager: http);
    addTearDown(fixture.dispose);
    for (final data in [0, '12345']) {
      http.response = {'code': 200, 'data': data};
      expect(await repository.fetchRoomHeat('internal-id'), int.parse('$data'));
      expect(http.path, HttpApi.roomHotScore);
      expect(http.query, {'roomId': 'internal-id'});
    }
    for (final invalid in [null, -1, {}, 'broken']) {
      http.response = {'code': 200, 'data': invalid};
      await expectLater(
        repository.fetchRoomHeat('id'),
        throwsA(isA<NadyApiException>()),
      );
    }
    http.response = {'code': 1003, 'message': 'fallback', 'msg': 'Real error'};
    await expectLater(
      repository.fetchRoomHeat('id'),
      throwsA(
        isA<NadyApiException>().having(
          (e) => e.message,
          'msg first',
          'Real error',
        ),
      ),
    );
  });

  test(
    'details and live contribution are separate from audience/mics',
    () async {
      final room = _HeaderRoom();
      room.current = room.current.copyWith(
        roomInfo: RoomInfo.fromJson({
          'roomInfoDTO': {'roomGiftWeekVal': 12345, 'roomGiftIncomeVal': 987},
        }),
      );
      final vm = RoomHeaderMetricsViewModel(room, (
        roomId: '123',
        generation: 1,
      ));
      addTearDown(() {
        vm.dispose();
        room.dispose();
      });
      await flushTools();
      expect(vm.state.heat, 7654);
      expect(vm.state.contribution, 12345);
      expect(vm.state.profit, 987);
      room.current = room.current.copyWith(roomWeekVal: 0);
      room.emitState();
      expect(vm.state.contribution, 0);
      room.failure = const NadyApiException(message: 'Heat unavailable');
      await vm.refreshHeat();
      expect(vm.state.heat, 7654);
      expect(vm.state.heatError, 'Heat unavailable');
    },
  );

  test(
    'coalesces heat requests; Keep discards stale result without clearing new task',
    () async {
      final room = _HeaderRoom()..gate = Completer<int>();
      final old = room.gate!;
      final vm = RoomHeaderMetricsViewModel(room, (
        roomId: '123',
        generation: 1,
      ));
      addTearDown(() {
        vm.dispose();
        room.dispose();
      });
      await flushTools();
      final pending = vm.refreshHeat();
      expect(room.calls, 1);
      room.minimizeRoom();
      room.gate = Completer<int>();
      room.restoreRoom();
      expect(room.calls, 2);
      old.complete(99);
      await pending;
      final newer = vm.refreshHeat();
      expect(room.calls, 2);
      room.gate!.complete(0);
      await newer;
      expect(vm.state.heat, 0);
    },
  );

  for (final reason in [
    'account',
    'generation',
    'leave',
    'dispose',
    'background',
  ]) {
    test('$reason discards late heat results', () async {
      final room = _HeaderRoom()..gate = Completer<int>();
      final vm = RoomHeaderMetricsViewModel(room, (
        roomId: '123',
        generation: 1,
      ));
      await flushTools();
      final pending = vm.refreshHeat();
      switch (reason) {
        case 'account':
          room.changeAccount(99);
        case 'generation':
          room.generation++;
          room.emitState();
        case 'leave':
          await room.leaveRoom();
        case 'dispose':
          vm.dispose();
        case 'background':
          vm.didChangeAppLifecycleState(AppLifecycleState.paused);
      }
      room.gate!.complete(9999);
      await pending;
      if (vm.mounted) {
        expect(vm.state.heat, isNull);
        expect(vm.state.active, isFalse);
        vm.dispose();
      }
      room.dispose();
    });
  }

  testWidgets('heat polls every 100 seconds only while active', (tester) async {
    final room = _HeaderRoom();
    final vm = RoomHeaderMetricsViewModel(room, (roomId: '123', generation: 1));
    await tester.pump();
    expect(room.calls, 1);
    await tester.pump(const Duration(seconds: 100));
    expect(room.calls, 2);
    room.minimizeRoom();
    await tester.pump(const Duration(seconds: 100));
    expect(room.calls, 2);
    vm.dispose();
    room.dispose();
  });

  test(
    'Socket contribution survives stale detail and resets after re-entry',
    () async {
      final fixture = RoomLifecycleFixture();
      addTearDown(fixture.dispose);
      fixture.http.roomInfoExtras = {
        'roomGiftWeekVal': 100,
        'roomGiftIncomeVal': 50,
      };
      await fixture.enter();
      final manager = fixture.manager;
      expect(manager.state.roomInfo!.roomGiftWeekVal, 100);
      expect(manager.state.roomInfo!.roomGiftIncomeVal, 50);
      fixture.http.infoGate = Completer<void>();
      final refresh = manager.refreshRoomInfo();
      fixture.socket.controller.add(
        const RoomSocketMessage(
          channel: 'room:first',
          event: 'RoomGiftStreamUpdateEvent',
          payload: {'roomWeekVal': 200},
          raw: {},
        ),
      );
      fixture.http.infoGate!.complete();
      await refresh;
      expect(manager.state.roomWeekVal, 200);
      for (final message in [
        const RoomSocketMessage(
          channel: 'room:other',
          event: 'RoomGiftStreamUpdateEvent',
          payload: {'roomWeekVal': 999},
          raw: {},
        ),
        const RoomSocketMessage(
          channel: 'room',
          event: 'RoomGiftStreamUpdateEvent',
          payload: {'roomId': 'other', 'roomWeekVal': 999},
          raw: {},
        ),
        const RoomSocketMessage(
          channel: 'room:first',
          event: 'RoomGiftStreamUpdateEvent',
          payload: {'roomWeekVal': -1},
          raw: {},
        ),
      ]) {
        fixture.socket.controller.add(message);
      }
      expect(manager.state.roomWeekVal, 200);
      fixture.socket.controller.add(
        const RoomSocketMessage(
          channel: 'room:first',
          event: 'RoomGiftStreamUpdateEvent',
          payload: {'roomWeekVal': 0},
          raw: {},
        ),
      );
      expect(manager.state.roomWeekVal, 0);
      await manager.refreshRoomInfo();
      expect(manager.state.roomWeekVal, isNull);
      expect(manager.state.roomInfo!.roomGiftWeekVal, 100);
      await manager.leaveRoom();
      await fixture.enter('second');
      expect(manager.state.roomWeekVal, isNull);
    },
  );
}

class _HeaderRoom extends ToolsRoomFake {
  int calls = 0;
  Completer<int>? gate;
  Object? failure;
  @override
  Future<int> fetchRoomHeat(String roomId) async {
    calls++;
    if (failure != null) throw failure!;
    return gate == null ? 7654 : gate!.future;
  }
}

class _HeatHttp extends FakeRoomHttp {
  _HeatHttp(RoomLifecycleFixture f) : super(f.actions, f.auth);
  Object? response;
  String? path;
  Map<String, dynamic>? query;
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.path = path;
    query = queryParameters;
    return response;
  }
}
