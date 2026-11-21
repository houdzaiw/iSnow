import '../models/room_gift_event_models.dart';

class RoomGiftSlot {
  const RoomGiftSlot({
    required this.key,
    required this.message,
    required this.updatedAt,
    this.remaining = const Duration(seconds: 5),
  });
  final String key;
  final RoomScreenGiftMsg message;
  final DateTime updatedAt;
  final Duration remaining;

  DateTime get expiresAt => updatedAt.add(remaining);
}

/// Two visible slots and five paused waiting entries, with self priority.
class RoomGiftSlotQueue {
  final List<RoomGiftSlot?> _slots = [null, null];
  final List<RoomGiftSlot> _waiting = [];
  static const capacity = 5;
  int? _mainIndex;
  int? currentUid;
  List<RoomGiftSlot?> get slots => List.unmodifiable(_slots);
  List<RoomGiftSlot> get waiting => List.unmodifiable(_waiting);

  void add(RoomScreenGiftMsg message, String eventKey, DateTime now) {
    expire(now);
    final key = message.comboId.isEmpty ? eventKey : message.comboKey;
    final incoming = RoomGiftSlot(key: key, message: message, updatedAt: now);
    final same = _slots.indexWhere((item) => item?.key == key);
    final mine = message.uid == currentUid;
    if (same >= 0) {
      _slots[same] = incoming;
      return;
    }
    final queued = _waiting.indexWhere((item) => item.key == key);
    if (queued >= 0) {
      _waiting[queued] = incoming;
      return;
    }
    if (mine && _mainIndex != null) {
      _slots[_mainIndex!] = incoming;
      return;
    }
    final empty = _slots.indexOf(null);
    if (empty >= 0) {
      _slots[empty] = incoming;
      if (mine) _mainIndex = empty;
    } else if (mine) {
      // [A, B] -> [self, A], with B's unused display time paused.
      final interrupted = _slots[1]!;
      _enqueue(
        RoomGiftSlot(
          key: interrupted.key,
          message: interrupted.message,
          updatedAt: now,
          remaining: interrupted.expiresAt.difference(now),
        ),
        first: true,
      );
      _slots[1] = _slots[0];
      _slots[0] = incoming;
      _mainIndex = 0;
    } else {
      _enqueue(incoming);
    }
  }

  void _enqueue(RoomGiftSlot slot, {bool first = false}) {
    if (_waiting.length == capacity) {
      final other = _waiting.indexWhere((s) => s.message.uid != currentUid);
      if (other < 0 && slot.message.uid != currentUid) return;
      _waiting.removeAt(other < 0 ? 0 : other);
    }
    if (first) {
      _waiting.insert(0, slot);
    } else {
      _waiting.add(slot);
    }
  }

  void expire(DateTime now) {
    for (var index = 0; index < _slots.length; index++) {
      final slot = _slots[index];
      if (slot != null && !now.isBefore(slot.expiresAt)) {
        _slots[index] = null;
        if (_mainIndex == index) _mainIndex = null;
      }
    }
    for (var index = 0; index < _slots.length; index++) {
      if (_slots[index] != null || _waiting.isEmpty) continue;
      final own = _waiting.indexWhere((s) => s.message.uid == currentUid);
      final next = _waiting.removeAt(own >= 0 && _mainIndex == null ? own : 0);
      _slots[index] = RoomGiftSlot(
        key: next.key,
        message: next.message,
        updatedAt: now,
        remaining: next.remaining,
      );
      if (next.message.uid == currentUid) _mainIndex = index;
    }
  }

  void clear() {
    _slots.fillRange(0, 2, null);
    _waiting.clear();
    _mainIndex = null;
  }
}
