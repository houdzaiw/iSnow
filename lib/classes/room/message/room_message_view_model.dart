import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/room_manager.dart';
import '../../message/chat_view_model.dart';
import '../../message/message_view_model.dart';
import '../room_repository.dart';

final roomMessageViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomMessageViewModel, RoomMessageState, String>(
      (ref, id) => RoomMessageViewModel(ref.watch(roomRepositoryProvider), id),
    );

typedef RoomPrivateChatKey = ({String roomId, int generation, String uid});
final roomPrivateChatProvider = StateNotifierProvider.autoDispose
    .family<ChatViewModel, ChatState, RoomPrivateChatKey>((ref, key) {
      final room = ref.watch(roomRepositoryProvider);
      final owner = ref.watch(
        roomMessageViewModelProvider(key.roomId).notifier,
      );
      return ChatViewModel(
        targetUID: key.uid,
        repository: ref.watch(imRepositoryProvider),
        isCurrent: () => owner.valid && room.roomGeneration == key.generation,
      );
    });

class RoomMessageState {
  const RoomMessageState({this.active = true, this.ready = false});
  final bool active, ready;
}

class RoomMessageViewModel extends StateNotifier<RoomMessageState> {
  RoomMessageViewModel(this.room, this.roomId)
    : generation = room.roomGeneration,
      super(const RoomMessageState()) {
    room.addListener(_sync);
    room.addAuthListener(_invalidate);
    ready = _readIdentity();
  }
  final RoomRepository room;
  final String roomId;
  final int generation;
  late final Future<bool> ready;
  bool _opened = false, _openingChat = false;
  bool get valid =>
      mounted &&
      state.active &&
      room.roomGeneration == generation &&
      room.roomState.currentRoomId == roomId &&
      room.roomState.isInRoom &&
      room.roomState.status == RoomStatus.ready;

  Future<bool> _readIdentity() async {
    int? uid;
    try {
      uid = await room.currentUid();
    } catch (_) {
      _invalidate();
      return false;
    }
    if (!valid || uid == null) {
      _invalidate();
      return false;
    }
    state = const RoomMessageState(ready: true);
    return true;
  }

  void _sync() {
    if (!valid) _invalidate();
  }

  void _invalidate() {
    if (mounted && state.active) state = const RoomMessageState(active: false);
  }

  bool beginOpen() {
    if (!valid || !state.ready || _opened) return false;
    _opened = true;
    return true;
  }

  void finishOpen() {
    _opened = false;
  }

  bool beginChat() {
    if (!valid || _openingChat) return false;
    _openingChat = true;
    return true;
  }

  void finishChat() {
    _openingChat = false;
  }

  @override
  void dispose() {
    room.removeListener(_sync);
    room.removeAuthListener(_invalidate);
    super.dispose();
  }
}
