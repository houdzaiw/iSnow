import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/model/room_socket_message.dart';
import 'room_gift_events_test.dart' show payload, socket;

void main() {
  late DateTime now;
  setUp(() => now = DateTime(2026, 11, 16));
  RoomSocketMessage entry(
    String id, {
    bool car = false,
    int uid = 20,
    String room = '123',
  }) => RoomSocketMessage(
    channel: 'global',
    event: 'RoomUserPropInfoEvent',
    raw: const {},
    receivedAt: now,
    msgId: id,
    payload: {
      'roomId': room,
      'userBaseInfo': {
        'uid': uid,
        'nick': 'Guest',
        'specialEffects': {'animationUrl': 'https://cdn.example/entry.svga'},
        if (car) 'vehicle': {'animationUrl': 'https://cdn.example/car.pag'},
      },
    },
  );
  test(
    'no-car entrance has its own track, allows gift/numeric lanes, and deduplicates',
    () {
      final manager = RoomGiftEventManager(
        roomId: '123',
        now: () => now,
        startTimer: false,
      );
      addTearDown(manager.dispose);
      manager.receive(entry('one'));
      manager.receive(entry('one'));
      expect(manager.snapshot.entrance!.key, 'entrance:one');
      expect(manager.snapshot.effects, isEmpty);
      manager.receive(entry('wrong', room: '999'));
      manager.completeEntranceTrack('entrance:one');
      expect(manager.snapshot.entrance, isNull);
    },
  );
  test(
    'vehicle-linked track waits for full-screen release and shares original deadline',
    () {
      final manager = RoomGiftEventManager(
        roomId: '123',
        now: () => now,
        startTimer: false,
      );
      addTearDown(manager.dispose);
      manager.receive(socket(payload(), id: 'full', time: now));
      manager.receive(entry('car', car: true));
      expect(manager.snapshot.entrance, isNull);
      now = now.add(const Duration(seconds: 29));
      manager.completeEffect('full');
      expect(manager.snapshot.entrance, isNull);
      manager.startEntranceVehicle('entrance:car:vehicle');
      expect(manager.snapshot.entrance!.key, 'entrance:car');
      manager.completeEntranceTrack('entrance:car');
      expect(manager.snapshot.entrance, isNotNull);
      manager.completeEffect('entrance:car:vehicle');
      expect(manager.snapshot.entrance, isNull);
    },
  );
  test('loaded-after-30s and after-Keep entrances are not replayed', () async {
    final ready = Completer<void>();
    final manager = RoomGiftEventManager(
      roomId: '123',
      now: () => now,
      startTimer: false,
      prepareEntrance: (_) => ready.future,
    );
    addTearDown(manager.dispose);
    manager.receive(entry('slow', car: true));
    expect(manager.snapshot.entrance, isNull);
    now = now.add(const Duration(seconds: 30));
    ready.complete();
    await Future<void>.delayed(Duration.zero);
    expect(manager.snapshot.effects, isEmpty);
    expect(manager.snapshot.entrance, isNull);
    manager.setVisible(false);
    manager.receive(entry('hidden'));
    manager.setVisible(true);
    expect(manager.snapshot.entrance, isNull);
  });
  test(
    'closed session rejects prepared old result without changing the new session',
    () async {
      final ready = Completer<void>();
      final manager = RoomGiftEventManager(
        roomId: '123',
        now: () => now,
        startTimer: false,
        prepareEntrance: (_) => ready.future,
      );
      addTearDown(manager.dispose);
      manager.receive(entry('old', car: true));
      manager.setSessionActive(false);
      manager.setSessionActive(true);
      manager.setVisible(true);
      ready.complete();
      await Future<void>.delayed(Duration.zero);
      expect(manager.snapshot.effects, isEmpty);
      expect(manager.snapshot.entrance, isNull);
    },
  );
}
