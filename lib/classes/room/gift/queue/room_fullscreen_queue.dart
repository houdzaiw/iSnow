import '../models/room_gift_effect_task.dart';

/// One active lease, including its asynchronous release, and bounded waiters.
class RoomFullscreenQueue {
  RoomFullscreenQueue({this.capacity = 20}) : assert(capacity > 0);
  final int capacity;
  int? _currentUid;
  int? get currentUid => _currentUid;
  set currentUid(int? value) {
    _currentUid = value;
    _waiting.sort(_compare);
  }

  RoomGiftEffectTask? _active;
  final List<RoomGiftEffectTask> _waiting = [];
  final Map<String, int> _arrival = {};
  final Set<String> _preparing = {};
  int _sequence = 0;
  bool _interrupt = false;

  List<RoomGiftEffectTask> get tasks =>
      List.unmodifiable([if (_active != null) _active!, ..._waiting]);
  String? get stopRequestedKey => _interrupt ? _active?.key : null;
  RoomGiftEffectTask? get active => _active;

  bool add(RoomGiftEffectTask task, DateTime now, {bool ready = true}) {
    if (_expired(task, now) || _active?.identity == task.identity) return false;
    _waiting.removeWhere((item) => _expired(item, now));
    final index = _waiting.indexWhere((item) => item.identity == task.identity);
    if (index >= 0) {
      final old = _waiting[index];
      _waiting[index] = RoomGiftEffectTask(
        key: old.key,
        message: task.message,
        createdAt: old.createdAt,
        kind: task.kind,
        giftIcon: task.giftIcon,
      );
    } else {
      _arrival[task.identity] = _sequence++;
      _waiting.add(task);
      if (!ready) _preparing.add(task.identity);
    }
    _waiting.sort(_compare);
    while (_waiting.length + (_active == null ? 0 : 1) > capacity) {
      final dropped = _waiting.removeLast();
      _arrival.remove(dropped.identity);
    }
    _prune();
    final accepted = _waiting.any((item) => item.identity == task.identity);
    if (!accepted) return false;
    if (_active == null) {
      _promote(now);
    } else if (ready && task.kind == RoomGiftEffectKind.prize) {
      // Keep the old lease until the player acknowledges native destruction.
      _interrupt = true;
    }
    return true;
  }

  /// Download failure never interrupts the current native lease.
  void prepared(String key, DateTime now, {required bool success}) {
    final task = _waiting.where((item) => item.key == key).firstOrNull;
    if (task == null || !_preparing.remove(task.identity)) return;
    if (!success) {
      _waiting.remove(task);
    } else if (_active == null) {
      _promote(now);
    } else if (task.kind == RoomGiftEffectKind.prize) {
      _interrupt = true;
    }
    _prune();
  }

  void complete(String key, DateTime now) {
    if (_active?.key != key) return;
    _arrival.remove(_active!.identity);
    _active = null;
    _interrupt = false;
    _promote(now);
  }

  void clear() {
    _active = null;
    _waiting.clear();
    _arrival.clear();
    _preparing.clear();
    _interrupt = false;
  }

  void cancelWhere(bool Function(RoomGiftEffectTask) test) {
    _waiting.removeWhere(test);
    if (_active != null && test(_active!)) _interrupt = true;
    _prune();
  }

  void _promote(DateTime now) {
    _waiting.removeWhere((item) => _expired(item, now));
    final index = _waiting.indexWhere(
      (task) => !_preparing.contains(task.identity),
    );
    if (index >= 0) _active = _waiting.removeAt(index);
    _prune();
  }

  void _prune() {
    final retained = tasks.map((item) => item.identity).toSet();
    _arrival.removeWhere((key, _) => !retained.contains(key));
    _preparing.removeWhere((key) => !retained.contains(key));
  }

  bool _expired(RoomGiftEffectTask task, DateTime now) =>
      task.kind == RoomGiftEffectKind.entrance &&
      now.difference(task.createdAt) >= const Duration(seconds: 30);

  int _rank(RoomGiftEffectTask task) {
    if (task.kind == RoomGiftEffectKind.prize) return 0;
    if (task.message.uid == currentUid) return 1;
    return task.kind == RoomGiftEffectKind.entrance ? 2 : 3;
  }

  int _compare(RoomGiftEffectTask a, RoomGiftEffectTask b) {
    final rank = _rank(a).compareTo(_rank(b));
    if (rank != 0) return rank;
    if (_rank(a) == 3) {
      final value = b.value.compareTo(a.value);
      if (value != 0) return value;
    }
    return (_arrival[a.identity] ?? 0).compareTo(_arrival[b.identity] ?? 0);
  }
}
