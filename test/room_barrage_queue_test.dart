import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/barrage/room_barrage_models.dart';
import 'package:project/classes/room/barrage/room_barrage_queue.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';

void main() {
  final now = DateTime(2026, 11, 20);
  RoomBarrageTask task(
    String id,
    RoomBarrageKind kind, {
    int uid = 20,
    int value = 0,
  }) => RoomBarrageTask(
    key: id,
    kind: kind,
    createdAt: now,
    sender: RoomGiftUser(uid: uid),
    value: value,
  );
  test(
    'priority, gift value and stable arrivals do not interrupt current banner',
    () {
      final queue = RoomBarrageQueue()..currentUid = 10;
      void add(RoomBarrageTask task) {
        queue.add(task, now);
        queue.prepared(task.key, now, success: true);
      }

      add(task('active', RoomBarrageKind.gift));
      add(task('cheap', RoomBarrageKind.gift, value: 1));
      add(task('expensive', RoomBarrageKind.gift, value: 100));
      add(task('lucky', RoomBarrageKind.lucky));
      add(task('game', RoomBarrageKind.gameWin));
      add(task('noble', RoomBarrageKind.nobleUpgrade));
      add(task('resource', RoomBarrageKind.resource));
      add(task('self', RoomBarrageKind.gift, uid: 10));
      add(task('prize', RoomBarrageKind.rocket));
      expect(queue.active!.key, 'active');
      final order = <String>[];
      while (queue.active != null) {
        order.add(queue.active!.key);
        queue.complete(queue.active!.key, now);
      }
      expect(order, [
        'active',
        'prize',
        'self',
        'resource',
        'noble',
        'game',
        'lucky',
        'expensive',
        'cheap',
      ]);
    },
  );
  test(
    'capacity includes active; failed/expired preparations do not block ready items',
    () {
      final queue = RoomBarrageQueue(capacity: 3);
      queue.add(task('active', RoomBarrageKind.gift), now);
      queue.prepared('active', now, success: true);
      for (final id in ['a', 'b', 'c']) {
        queue.add(task(id, RoomBarrageKind.gift), now);
      }
      expect(queue.tasks.length, 3);
      expect(queue.tasks.map((t) => t.key), ['active', 'a', 'b']);
      queue.prepared('a', now, success: false);
      queue.prepared('b', now, success: true);
      queue.complete('unrelated', now);
      expect(queue.active!.key, 'active');
      queue.complete('active', now.add(const Duration(seconds: 30)));
      expect(queue.active, isNull);
    },
  );
}
