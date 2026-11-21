import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/effects/room_gift_playback_barrier.dart';
import 'package:project/classes/room/gift/models/room_gift_effect_task.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/queue/room_fullscreen_queue.dart';

void main() {
  final now = DateTime(2026, 11, 15);
  RoomGiftEffectTask task(
    String key, {
    int uid = 2,
    int price = 1,
    RoomGiftEffectKind kind = RoomGiftEffectKind.gift,
    DateTime? at,
  }) => RoomGiftEffectTask(
    key: key,
    createdAt: at ?? now,
    kind: kind,
    message: RoomScreenGiftMsg(
      uid: uid,
      userInfo: RoomGiftUser(uid: uid),
      giftCount: 1,
      gift: RoomGift(
        id: 1,
        name: '',
        icon: '',
        price: price,
        isCombo: 0,
        tabId: 1,
      ),
    ),
  );

  test(
    'normal arrivals never interrupt, waiters sort by self, entry, value',
    () {
      final queue = RoomFullscreenQueue()..currentUid = 1;
      queue.add(task('active'), now);
      queue.add(task('cheap'), now);
      queue.add(task('valuable', price: 100), now);
      queue.add(task('entry', kind: RoomGiftEffectKind.entrance), now);
      queue.add(task('self', uid: 1), now);
      expect(queue.tasks.map((e) => e.key), [
        'active',
        'self',
        'entry',
        'valuable',
        'cheap',
      ]);
      expect(queue.stopRequestedKey, isNull);
    },
  );

  test('prize requests destruction and promotes only after matching ack', () {
    final queue = RoomFullscreenQueue();
    queue.add(task('active'), now);
    queue.add(task('prize', kind: RoomGiftEffectKind.prize), now);
    expect(queue.tasks.first.key, 'active');
    expect(queue.stopRequestedKey, 'active');
    queue.complete('late-old-player', now);
    expect(queue.tasks.first.key, 'active');
    queue.complete('active', now);
    expect(queue.tasks.single.key, 'prize');
    expect(queue.stopRequestedKey, isNull);
  });

  test(
    'unprepared prize does not interrupt; failed preparation is discarded',
    () {
      final queue = RoomFullscreenQueue();
      queue.add(task('active'), now);
      queue.add(
        task('prize', kind: RoomGiftEffectKind.prize),
        now,
        ready: false,
      );
      expect(queue.active!.key, 'active');
      expect(queue.stopRequestedKey, isNull);
      queue.prepared('prize', now, success: false);
      expect(queue.tasks.map((e) => e.key), ['active']);
      expect(queue.stopRequestedKey, isNull);
    },
  );

  test(
    'prepared prize waits for ack; late completion after clear is ignored',
    () {
      final queue = RoomFullscreenQueue();
      queue.add(task('active'), now);
      queue.add(
        task('prize', kind: RoomGiftEffectKind.prize),
        now,
        ready: false,
      );
      queue.prepared('prize', now, success: true);
      expect(queue.stopRequestedKey, 'active');
      queue.complete('active', now);
      expect(queue.active!.key, 'prize');
      queue.clear();
      queue.add(task('new-room'), now);
      queue.prepared('prize', now, success: true);
      expect(queue.active!.key, 'new-room');
      expect(queue.stopRequestedKey, isNull);
    },
  );

  test(
    'preparing prize alone cannot start a native player or block ready gifts',
    () {
      final queue = RoomFullscreenQueue();
      queue.add(
        task('prize', kind: RoomGiftEffectKind.prize),
        now,
        ready: false,
      );
      expect(queue.active, isNull);
      queue.add(task('gift'), now);
      expect(queue.active!.key, 'gift');
      queue.prepared('prize', now, success: true);
      expect(queue.stopRequestedKey, 'gift');
    },
  );

  test('capacity includes active and preserves high priority waiters', () {
    final queue = RoomFullscreenQueue()..currentUid = 1;
    queue.add(task('active'), now);
    for (var i = 0; i < 40; i++) {
      queue.add(task('guest$i', price: i), now);
    }
    queue.add(task('self', uid: 1), now);
    expect(queue.tasks, hasLength(20));
    expect(queue.tasks.first.key, 'active');
    expect(queue.tasks[1].key, 'self');
    expect(queue.tasks.any((e) => e.key == 'guest0'), isFalse);
  });

  test('entrance expires from enqueue time, not playback time', () {
    final queue = RoomFullscreenQueue();
    queue.add(task('active'), now);
    queue.add(task('entry', kind: RoomGiftEffectKind.entrance), now);
    queue.add(task('gift'), now);
    queue.complete('active', now.add(const Duration(seconds: 30)));
    expect(queue.tasks.single.key, 'gift');
  });

  test('cancel waits for release, clear discards old completion', () {
    final queue = RoomFullscreenQueue();
    queue.add(task('a'), now);
    queue.add(task('entry', kind: RoomGiftEffectKind.entrance), now);
    queue.cancelWhere((e) => e.kind == RoomGiftEffectKind.gift);
    expect(queue.tasks.first.key, 'a');
    expect(queue.stopRequestedKey, 'a');
    queue.complete('a', now);
    expect(queue.tasks.single.key, 'entry');
    queue.clear();
    queue.add(task('new'), now);
    queue.complete('entry', now);
    expect(queue.tasks.single.key, 'new');
  });

  test(
    'native release barrier also observes releases registered mid-acquire',
    () async {
      final barrier = RoomGiftPlaybackBarrier();
      final release = Completer<void>();
      var acquired = false;
      final acquiring = barrier.ready.then((_) => acquired = true);
      final releasing = barrier.release(() => release.future);
      await Future<void>.delayed(Duration.zero);
      expect(acquired, isFalse);
      release.complete();
      await releasing;
      await acquiring;
      expect(acquired, isTrue);
    },
  );

  test('failed destruction prevents next native acquisition', () async {
    final barrier = RoomGiftPlaybackBarrier();
    await expectLater(
      barrier.release(() async => throw StateError('decoder alive')),
      throwsStateError,
    );
    await expectLater(barrier.ready, throwsStateError);
  });

  test(
    'simultaneous native acquirers serialize until destruction completes',
    () async {
      final barrier = RoomGiftPlaybackBarrier();
      final first = await barrier.acquire();
      final release = Completer<void>();
      var secondReady = false, thirdReady = false;
      final second = barrier.acquire().then((lease) {
        secondReady = true;
        return lease;
      });
      final third = barrier.acquire().then((lease) {
        thirdReady = true;
        return lease;
      });
      final stopping = first.release(() => release.future);
      await Future<void>.delayed(Duration.zero);
      expect(secondReady, isFalse);
      expect(thirdReady, isFalse);
      release.complete();
      await stopping;
      final next = await second;
      expect(thirdReady, isFalse);
      await next.release(() async {});
      await (await third).release(() async {});
      expect(thirdReady, isTrue);
    },
  );
}
