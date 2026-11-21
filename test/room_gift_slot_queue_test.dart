import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/queue/room_gift_slot_queue.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';

import 'room_gift_events_test.dart' show payload, socket;

void main() {
  final start = DateTime(2026, 11, 14);
  late RoomGiftSlotQueue queue;
  setUp(() => queue = RoomGiftSlotQueue()..currentUid = 10);

  void add(int uid, String id, DateTime time, {int count = 1}) => queue.add(
    RoomScreenGiftMsg.fromJson(payload(uid: uid, combo: id, count: count)),
    id,
    time,
  );

  test('self interrupts B, keeps A and resumes B with unused time', () {
    add(20, 'A', start);
    add(30, 'B', start);
    final arrival = start.add(const Duration(seconds: 2));
    add(10, 'self', arrival);
    expect(queue.slots.map((s) => s!.message.uid), [10, 20]);
    expect(queue.waiting.single.message.uid, 30);
    expect(queue.waiting.single.remaining, const Duration(seconds: 3));
    queue.expire(start.add(const Duration(seconds: 5)));
    expect(queue.slots.map((s) => s!.message.uid), [10, 30]);
    queue.expire(start.add(const Duration(seconds: 7)));
    expect(queue.slots[1]!.message.uid, 30);
    queue.expire(start.add(const Duration(seconds: 8)));
    expect(queue.slots, [null, null]);
  });

  test(
    'queued combo updates in place and restores its latest cumulative value',
    () {
      add(20, 'A', start);
      add(30, 'B', start);
      add(40, 'C', start);
      add(40, 'C', start.add(const Duration(seconds: 1)), count: 8);
      expect(queue.waiting, hasLength(1));
      queue.expire(start.add(const Duration(seconds: 5)));
      expect(queue.slots[0]!.message.displayCount, 8);
      expect(queue.slots[0]!.remaining, const Duration(seconds: 5));
    },
  );

  test('waiting capacity is bounded without replacing active guests', () {
    for (var uid = 20; uid < 32; uid++) {
      add(uid, '$uid', start);
    }
    expect(queue.slots.map((s) => s!.message.uid), [20, 21]);
    expect(queue.waiting.map((s) => s.message.uid), [27, 28, 29, 30, 31]);
  });

  test('updating an active combo resets its own dwell only', () {
    add(20, 'A', start);
    add(30, 'B', start);
    add(40, 'C', start);
    add(20, 'A', start.add(const Duration(seconds: 4)), count: 2);
    queue.expire(start.add(const Duration(seconds: 5)));
    expect(queue.slots.map((s) => s!.message.uid), [20, 40]);
    expect(queue.slots[0]!.expiresAt, start.add(const Duration(seconds: 9)));
  });

  test('clear discards paused entries and self slot ownership', () {
    add(20, 'A', start);
    add(30, 'B', start);
    add(10, 'self', start);
    queue.clear();
    queue.expire(start.add(const Duration(seconds: 20)));
    expect(queue.slots, [null, null]);
    expect(queue.waiting, isEmpty);
    add(40, 'fresh', start.add(const Duration(seconds: 20)));
    expect(queue.slots[0]!.message.uid, 40);
  });

  testWidgets(
    'manager restores and expires paused time at its actual deadline',
    (tester) async {
      final manager = RoomGiftEventManager(
        roomId: '123',
        now: tester.binding.clock.now,
      )..currentUid = 10;
      addTearDown(() {
        if (manager.isAlive) manager.dispose();
      });
      manager.receive(socket(payload(uid: 20, combo: 'A'), id: 'A'));
      manager.receive(socket(payload(uid: 30, combo: 'B'), id: 'B'));
      await tester.pump(const Duration(milliseconds: 1250));
      manager.receive(socket(payload(combo: 'self'), id: 'self'));
      await tester.pump(const Duration(milliseconds: 3750));
      expect(manager.snapshot.slots[1]!.message.uid, 30);
      await tester.pump(const Duration(milliseconds: 3749));
      expect(manager.snapshot.slots[1]!.message.uid, 30);
      await tester.pump(const Duration(milliseconds: 1));
      expect(manager.snapshot.slots, [null, null]);
      manager.dispose();
    },
  );
}
