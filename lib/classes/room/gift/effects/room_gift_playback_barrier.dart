import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

final roomGiftPlaybackBarrierProvider = Provider(
  (ref) => RoomGiftPlaybackBarrier(),
);

/// Carries pending native destruction across room/route widget replacement.
class RoomGiftPlaybackBarrier {
  Future<void> _pending = Future.value();
  RoomGiftPlaybackLease? _active;

  Future<RoomGiftPlaybackLease> acquire() async {
    while (true) {
      await ready;
      final active = _active;
      if (active == null) {
        return _active = RoomGiftPlaybackLease._(this);
      }
      await active._released.future;
    }
  }

  Future<void> get ready async {
    while (true) {
      final pending = _pending;
      await pending;
      if (identical(pending, _pending)) return;
    }
  }

  Future<void> release(Future<void> Function() release) {
    final previous = _pending;
    final current = release();
    _pending = Future.wait<void>([previous, current]).then((_) {});
    // The failure remains observable by the next acquirer without an unhandled
    // asynchronous error when there is currently no room view.
    _pending.ignore();
    return _pending;
  }
}

class RoomGiftPlaybackLease {
  RoomGiftPlaybackLease._(this._barrier) {
    _released.future.ignore();
  }
  final RoomGiftPlaybackBarrier _barrier;
  final _released = Completer<void>();
  Future<void>? _releaseTask;
  Future<void> release(Future<void> Function() release) =>
      _releaseTask ??= _finish(release);

  Future<void> _finish(Future<void> Function() release) async {
    try {
      await _barrier.release(release);
      if (identical(_barrier._active, this)) _barrier._active = null;
      _released.complete();
    } catch (error, stack) {
      _released.completeError(error, stack);
      rethrow;
    }
  }
}
