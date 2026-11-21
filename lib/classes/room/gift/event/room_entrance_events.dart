part of 'room_gift_event_manager.dart';

extension RoomEntranceEvents on RoomGiftEventManager {
  /// The native player's start callback, rather than queue admission, starts the
  /// linked track. Initialization and lease handover consume the same budget.
  void startEntranceVehicle(String key) {
    final entry = _entrances.active;
    if (!mounted ||
        entry == null ||
        key != '${entry.key}:vehicle' ||
        _fullscreenQueue.active?.key != key ||
        _activeLucky != null) {
      return;
    }
    _entrances.start(_now());
    _emit();
  }

  void _receiveEntrance(RoomSocketMessage message) {
    if (!snapshot.isVisible || !_effects.car) return;
    try {
      final entry = RoomEntranceParser().parse(message, roomId, _now());
      if (entry == null ||
          _seen.containsKey(entry.key) ||
          _acceptAfter != null && entry.createdAt.isBefore(_acceptAfter!)) {
        return;
      }
      _seen[entry.key] = _now();
      while (_seen.length > 300) {
        _seen.remove(_seen.keys.first);
      }
      final accepted = _entrances.add(
        entry,
        _now(),
        ready: prepareEntrance == null,
      );
      if (accepted && prepareEntrance != null) {
        unawaited(_prepareEntrance(entry, _visualGeneration));
      }
      _emit();
    } catch (error) {
      _log('Discard entrance: $error');
    }
  }

  Future<void> _prepareEntrance(RoomEntrance entry, int generation) async {
    var success = false;
    try {
      await prepareEntrance!(entry);
      success = true;
    } catch (error) {
      _log('Entrance resource unavailable: $error');
    }
    if (!mounted || generation != _visualGeneration || !snapshot.isVisible) {
      return;
    }
    _entrances.prepared(entry.key, _now(), success: success);
    _emit();
  }

  void completeEntranceTrack(String key) {
    if (!mounted) return;
    _entrances.complete(key, _now(), track: true);
    _emit();
  }

  void _syncEntrance() {
    final previous = _entrances.active;
    _entrances.advance(_now());
    if (previous != null && previous != _entrances.active) {
      _fullscreenQueue.cancelWhere(
        (task) => task.key == '${previous.key}:vehicle',
      );
    }
    final active = _entrances.active;
    if (active == null || active.key == _enqueuedEntrance) return;
    if (active.vehicle case final vehicle?) {
      final accepted = _fullscreenQueue.add(
        RoomGiftEffectTask(
          key: '${active.key}:vehicle',
          createdAt: active.createdAt,
          kind: RoomGiftEffectKind.entrance,
          message: RoomScreenGiftMsg(
            gift: vehicle,
            uid: active.user.uid,
            userInfo: active.user,
            roomId: roomId,
            giftCount: 1,
          ),
        ),
        _now(),
      );
      if (accepted) _enqueuedEntrance = active.key;
    } else {
      _enqueuedEntrance = active.key;
    }
  }
}
