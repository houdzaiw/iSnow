import '../models/room_entrance.dart';

/// A separate entrance lane, ordered self then FIFO, with one shared deadline.
class RoomEntranceQueue {
  int? currentUid;
  final _waiting = <RoomEntrance>[];
  final _pending = <String>{};
  RoomEntrance? active;
  DateTime? startedAt;
  bool trackEnded = false, vehicleEnded = false;

  bool add(RoomEntrance entry, DateTime now, {bool ready = true}) {
    if (!now.isBefore(entry.deadline) ||
        active?.key == entry.key ||
        _waiting.any((e) => e.key == entry.key)) {
      return false;
    }
    _waiting.add(entry);
    if (!ready) _pending.add(entry.key);
    _sort();
    while (_waiting.length + (active == null ? 0 : 1) > 20) {
      _pending.remove(_waiting.removeLast().key);
    }
    final accepted = _waiting.any((e) => e.key == entry.key);
    advance(now);
    return accepted;
  }

  void prepared(String key, DateTime now, {required bool success}) {
    if (!_pending.remove(key)) return;
    if (!success) _waiting.removeWhere((e) => e.key == key);
    advance(now);
  }

  void start(DateTime now) {
    if (active != null && startedAt == null && now.isBefore(active!.deadline)) {
      startedAt = now;
    }
  }

  void complete(
    String key,
    DateTime now, {
    bool track = false,
    bool vehicle = false,
  }) {
    if (active?.key != key) return;
    trackEnded |= track;
    vehicleEnded |= vehicle;
    if (trackEnded && vehicleEnded) {
      active = null;
      startedAt = null;
      advance(now);
    }
  }

  void advance(DateTime now) {
    _waiting.removeWhere((e) => !now.isBefore(e.deadline));
    _pending.removeWhere((key) => !_waiting.any((e) => e.key == key));
    if (active != null &&
        startedAt == null &&
        !now.isBefore(active!.deadline)) {
      active = null;
    }
    // A car waiting on the full-screen lane has not started its entrance yet.
    // A ready self arrival may take that waiting place, never a playing track.
    if (active != null &&
        startedAt == null &&
        active!.user.uid != currentUid &&
        _waiting.any(
          (e) => e.user.uid == currentUid && !_pending.contains(e.key),
        )) {
      _waiting.insert(0, active!);
      active = null;
    }
    if (active != null) return;
    _sort();
    final index = _waiting.indexWhere((e) => !_pending.contains(e.key));
    if (index < 0) return;
    active = _waiting.removeAt(index);
    trackEnded = false;
    vehicleEnded = active!.vehicle == null;
  }

  void clear() {
    active = null;
    startedAt = null;
    _waiting.clear();
    _pending.clear();
  }

  void _sort() {
    // stable partition: no sort may reorder equal-priority arrivals.
    final own = _waiting.where((e) => e.user.uid == currentUid).toList();
    final guests = _waiting.where((e) => e.user.uid != currentUid).toList();
    _waiting
      ..clear()
      ..addAll([...own, ...guests]);
  }
}
