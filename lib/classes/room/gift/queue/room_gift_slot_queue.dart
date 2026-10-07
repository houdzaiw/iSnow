import '../models/room_gift_event_models.dart';

class RoomGiftSlot {
  const RoomGiftSlot({
    required this.key,
    required this.message,
    required this.updatedAt,
  });
  final String key;
  final RoomScreenGiftMsg message;
  final DateTime updatedAt;
}

/// Two visible slots; the first slot occupied by the current user stays pinned.
class RoomGiftSlotQueue {
  final List<RoomGiftSlot?> _slots = [null, null];
  final List<int> _order = [0, 0];
  int _sequence = 0;
  int? _mainIndex;
  int? currentUid;
  List<RoomGiftSlot?> get slots => List.unmodifiable(_slots);

  void add(RoomScreenGiftMsg message, String eventKey, DateTime now) {
    expire(now);
    final key = message.comboId.isEmpty ? eventKey : message.comboKey;
    final same = _slots.indexWhere((item) => item?.key == key);
    final mine = message.uid == currentUid;
    int index;
    if (same >= 0) {
      index = same;
    } else if (mine && _mainIndex != null) {
      index = _mainIndex!;
    } else if (!mine && _mainIndex != null) {
      index = 1 - _mainIndex!;
    } else {
      final empty = _slots.indexOf(null);
      index = empty >= 0 ? empty : (_order[0] < _order[1] ? 0 : 1);
    }
    if (mine) _mainIndex = index;
    _order[index] = ++_sequence;
    _slots[index] = RoomGiftSlot(key: key, message: message, updatedAt: now);
  }

  void expire(DateTime now) {
    for (var index = 0; index < _slots.length; index++) {
      final slot = _slots[index];
      if (slot != null &&
          now.difference(slot.updatedAt) >= const Duration(seconds: 5)) {
        _slots[index] = null;
        if (_mainIndex == index) _mainIndex = null;
      }
    }
  }

  void clear() {
    _slots.fillRange(0, 2, null);
    _order.fillRange(0, 2, 0);
    _sequence = 0;
    _mainIndex = null;
  }
}
