import 'room_barrage_models.dart';

/// One visible banner. Prepared waiters use category priority then arrival.
class RoomBarrageQueue {
  RoomBarrageQueue({this.capacity = 20, int Function(RoomBarrageTask)? valueOf})
    : _valueOf = valueOf ?? ((task) => task.value);
  final int capacity;
  final int Function(RoomBarrageTask) _valueOf;
  int? currentUid;
  RoomBarrageTask? active;
  final _waiting = <RoomBarrageTask>[];
  final _ready = <String>{};
  final _arrival = <String, int>{};
  int _sequence = 0;
  List<RoomBarrageTask> get tasks => [if (active != null) active!, ..._waiting];
  bool add(RoomBarrageTask task, DateTime now) {
    if (_expired(task, now) || tasks.any((t) => t.key == task.key)) {
      return false;
    }
    _arrival[task.key] = _sequence++;
    _waiting.add(task);
    _sort();
    while (_waiting.length + (active == null ? 0 : 1) > capacity) {
      final removed = _waiting.removeLast();
      _arrival.remove(removed.key);
      _ready.remove(removed.key);
    }
    return tasks.any((t) => t.key == task.key);
  }

  void prepared(String key, DateTime now, {required bool success}) {
    if (!_waiting.any((t) => t.key == key)) return;
    if (success) {
      _ready.add(key);
    } else {
      _waiting.removeWhere((t) => t.key == key);
    }
    advance(now);
  }

  void complete(String key, DateTime now) {
    if (active?.key != key) return;
    _arrival.remove(key);
    _ready.remove(key);
    active = null;
    advance(now);
  }

  void advance(DateTime now) {
    _waiting.removeWhere((t) => _expired(t, now));
    final retained = tasks.map((t) => t.key).toSet();
    _arrival.removeWhere((key, _) => !retained.contains(key));
    _ready.removeWhere((key) => !retained.contains(key));
    _sort();
    if (active != null) return;
    final index = _waiting.indexWhere((t) => _ready.contains(t.key));
    if (index >= 0) active = _waiting.removeAt(index);
  }

  void clear() {
    active = null;
    _waiting.clear();
    _ready.clear();
    _arrival.clear();
  }

  bool _expired(RoomBarrageTask task, DateTime now) =>
      now.difference(task.createdAt) >= const Duration(seconds: 30);
  void _sort() => _waiting.sort((a, b) {
    final category = a.priority(currentUid).compareTo(b.priority(currentUid));
    if (category != 0) return category;
    if (a.kind == RoomBarrageKind.gift && b.kind == RoomBarrageKind.gift) {
      final value = _valueOf(b).compareTo(_valueOf(a));
      if (value != 0) return value;
    }
    return _arrival[a.key]!.compareTo(_arrival[b.key]!);
  });
}
