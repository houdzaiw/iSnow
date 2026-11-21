import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/models/room_entrance.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/queue/room_entrance_queue.dart';

void main() {
  final now = DateTime(2026, 11, 16);
  RoomEntrance item(String id, int uid, {bool car = false, DateTime? at}) =>
      RoomEntrance(
        key: id,
        createdAt: at ?? now,
        user: RoomGiftUser(uid: uid),
        vehicle: car
            ? const RoomGift(
                id: 1,
                name: '',
                icon: '',
                price: 0,
                tabId: 0,
                isCombo: 0,
                animationUrl: 'car.pag',
              )
            : null,
      );
  test('self may replace a guest still waiting for vehicle start', () {
    final queue = RoomEntranceQueue()..currentUid = 10;
    queue.add(item('guest', 20, car: true), now);
    queue.add(item('self', 10), now);
    expect(queue.active!.key, 'self');
    queue.start(now);
    queue.complete('self', now, track: true);
    expect(queue.active!.key, 'guest');
  });
  test(
    'independent track FIFO, own arrival first among waiters, no active interruption',
    () {
      final queue = RoomEntranceQueue()..currentUid = 10;
      queue.add(item('a', 20), now);
      queue.start(now);
      queue.add(item('b', 30), now);
      queue.add(item('self', 10), now);
      expect(queue.active!.key, 'a');
      queue.complete('a', now, track: true);
      expect(queue.active!.key, 'self');
      queue.complete('stale-a', now, track: true);
      expect(queue.active!.key, 'self');
      queue.complete('self', now, track: true);
      expect(queue.active!.key, 'b');
    },
  );
  test('track and car must both finish; one shared 30s start budget', () {
    final queue = RoomEntranceQueue();
    queue.add(item('car', 1, car: true), now);
    queue.start(now.add(const Duration(seconds: 29)));
    queue.complete('car', now.add(const Duration(seconds: 35)), track: true);
    expect(queue.active!.key, 'car');
    queue.add(item('late', 2), now.add(const Duration(seconds: 35)));
    queue.complete('car', now.add(const Duration(seconds: 35)), vehicle: true);
    expect(queue.active, isNull);
    expect(
      queue.add(item('expired', 3), now.add(const Duration(seconds: 30))),
      isFalse,
    );
  });
  test(
    'loading time uses the same deadline; old preparation cannot revive cleared entry',
    () {
      final queue = RoomEntranceQueue();
      queue.add(item('loading', 1), now, ready: false);
      expect(queue.active, isNull);
      queue.prepared(
        'loading',
        now.add(const Duration(seconds: 30)),
        success: true,
      );
      expect(queue.active, isNull);
      queue.add(item('new', 2), now, ready: false);
      queue.clear();
      queue.prepared('new', now, success: true);
      expect(queue.active, isNull);
    },
  );
}
