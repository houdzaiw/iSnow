import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/room_manager.dart';
import '../room_repository.dart';

final roomAudienceViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomAudienceViewModel, RoomState, String>((ref, roomId) {
      return RoomAudienceViewModel(
        repository: ref.read(roomRepositoryProvider),
        roomId: roomId,
      );
    });

class RoomAudienceViewModel extends StateNotifier<RoomState> {
  RoomAudienceViewModel({
    required RoomRepository repository,
    required String roomId,
  }) : _repository = repository,
       _roomId = roomId,
       super(const RoomState()) {
    _repository.addListener(_sync);
    _sync();
    unawaited(Future<void>.microtask(refresh));
  }

  final RoomRepository _repository;
  final String _roomId;

  void _sync() {
    if (!mounted) return;
    final room = _repository.roomState;
    state = room.currentRoomId == _roomId && room.isInRoom
        ? room
        : const RoomState();
  }

  Future<void> refresh() async {
    if (!mounted ||
        state.currentRoomId != _roomId ||
        state.status != RoomStatus.ready ||
        !state.isInRoom) {
      return;
    }
    await _repository.refreshAudience();
  }

  @override
  void dispose() {
    _repository.removeListener(_sync);
    super.dispose();
  }
}
