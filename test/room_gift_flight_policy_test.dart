import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/queue/room_flight_queue.dart';
import 'package:project/classes/room/gift/trajectory/room_gift_seat_registry.dart';
import 'package:project/classes/room/gift/trajectory/room_gift_trajectory_task.dart';
import 'package:project/manager/room_animation_performance_manager.dart';

import 'room_gift_events_test.dart' show payload, socket;

void main() {
  RoomGiftEffectTask task(
    String key, {
    int uid = 2,
    int count = 50,
    String? combo,
    List<int> targets = const [10, 20],
  }) => RoomGiftEffectTask(
    key: key,
    createdAt: DateTime(2026, 11, 15),
    message: RoomScreenGiftMsg(
      uid: uid,
      comboId: combo ?? key,
      userInfo: RoomGiftUser(uid: uid),
      giftCount: count,
      uids: targets,
      gift: const RoomGift(
        id: 1,
        name: '',
        icon: '',
        price: 1,
        isCombo: 1,
        tabId: 1,
      ),
    ),
  );
  RoomGiftSeatCoordinate coordinate(int uid) => RoomGiftSeatCoordinate(
    uid: uid,
    position: uid,
    offset: Offset(uid.toDouble(), 30),
  );

  test(
    'one active plus five waiters; oldest waiter evicted, self promoted first',
    () {
      final queue = RoomFlightQueue()..currentUid = 1;
      queue.add(task('active'));
      for (var i = 0; i < 6; i++) {
        queue.add(task('guest$i'));
      }
      queue.add(task('self', uid: 1));
      expect(queue.tasks, hasLength(6));
      expect(
        queue.tasks.any((task) => task.key == 'guest0' || task.key == 'guest1'),
        isFalse,
      );
      queue.complete('active');
      expect(queue.tasks.first.key, 'self');
      queue.complete('self');
      expect(queue.tasks.first.key, 'guest2');
    },
  );

  test('combo cancellation leaves other senders and other combos intact', () {
    final queue = RoomFlightQueue();
    queue.add(task('a', uid: 1));
    queue.add(task('other-event', uid: 2, combo: 'a'));
    // Event identities normally differ even when combo IDs happen to match.
    queue.add(task('b', uid: 1));
    queue.cancelCombo('a', uid: 1);
    expect(queue.tasks.map((task) => task.key), ['other-event', 'b']);
  });

  test(
    'each target survives quality limits and server zero normalizes to one',
    () {
      for (final (quality, expected) in [
        (RoomAnimationQuality.full, 7),
        (RoomAnimationQuality.reduced, 3),
        (RoomAnimationQuality.minimum, 1),
      ]) {
        final tasks = RoomGiftTrajectoryTask.fromEvent(
          task('a'),
          coordinate,
          viewport: const Size(375, 812),
          quality: quality,
          maxPerTarget: 7,
        );
        expect(tasks.length, expected * 2);
        expect(tasks.map((task) => task.target.uid).toSet(), {10, 20});
        expect(tasks.last.delay.inMilliseconds, (expected - 1) * 100);
      }
      final many = RoomGiftTrajectoryTask.fromEvent(
        task('many', targets: List.generate(40, (index) => index + 1)),
        coordinate,
        viewport: const Size(375, 812),
        maxPerTarget: 0,
      );
      expect(many, hasLength(40));
      expect(many.map((task) => task.target.uid).toSet(), hasLength(40));
    },
  );

  test(
    'quality degrades immediately, recovers with hysteresis over three samples',
    () {
      final monitor = RoomAnimationPerformanceManager(listen: false);
      addTearDown(monitor.dispose);
      monitor.sampleFps(20);
      expect(monitor.state, RoomAnimationQuality.reduced);
      monitor.sampleFps(12);
      expect(monitor.state, RoomAnimationQuality.minimum);
      monitor.sampleFps(19);
      monitor.sampleFps(19);
      monitor.sampleFps(19);
      expect(monitor.state, RoomAnimationQuality.minimum);
      for (var i = 0; i < 3; i++) {
        monitor.sampleFps(22);
      }
      expect(monitor.state, RoomAnimationQuality.reduced);
      for (var i = 0; i < 3; i++) {
        monitor.sampleFps(30);
      }
      expect(monitor.state, RoomAnimationQuality.full);
    },
  );

  test(
    'late paid echo updates public count without reviving expired own flight',
    () {
      final manager = RoomGiftEventManager(roomId: '123', startTimer: false)
        ..currentUid = 10;
      addTearDown(manager.dispose);
      manager.receive(socket(payload(), id: 'one'));
      manager.cancelComboFlights('combo', uid: 10);
      manager.receive(socket(payload(count: 2), id: 'late'));
      expect(manager.snapshot.flights, isEmpty);
      expect(manager.snapshot.publicMessages.single.count, 2);
      manager.receive(socket(payload(uid: 20, combo: 'other'), id: 'other'));
      expect(manager.snapshot.flights.single.message.uid, 20);
    },
  );
}
