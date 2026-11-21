import '../models/room_gift_effect_task.dart';

/// One burst in flight and at most five waiting tasks, never an image cap.
class RoomFlightQueue {
  int? currentUid;
  RoomGiftEffectTask? _active;
  final List<RoomGiftEffectTask> _waiting = [];
  List<RoomGiftEffectTask> get tasks =>
      List.unmodifiable([if (_active != null) _active!, ..._waiting]);

  void add(RoomGiftEffectTask task) {
    if (tasks.any((item) => item.key == task.key)) return;
    if (_active == null) {
      _active = task;
      return;
    }
    _waiting.add(task);
    if (_waiting.length > 5) _waiting.removeAt(0);
  }

  void complete(String key) {
    if (_active?.key != key) return;
    _active = null;
    _promote();
  }

  void cancelCombo(String comboId, {int? uid}) {
    bool matches(RoomGiftEffectTask task) =>
        task.message.comboId == comboId &&
        (uid == null || task.message.uid == uid);
    _waiting.removeWhere(matches);
    if (_active != null && matches(_active!)) _active = null;
    _promote();
  }

  void clear() {
    _active = null;
    _waiting.clear();
  }

  void _promote() {
    if (_active != null || _waiting.isEmpty) return;
    final self = _waiting.indexWhere((item) => item.message.uid == currentUid);
    _active = _waiting.removeAt(self < 0 ? 0 : self);
  }
}
