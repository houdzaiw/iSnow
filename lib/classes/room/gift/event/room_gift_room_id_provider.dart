import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../room_repository.dart';

/// Tracks the canonical ID without recreating the page's in-flight ViewModel.
final roomGiftRoomIdProvider = Provider.autoDispose.family<String, String>((
  ref,
  routeId,
) {
  final repository = ref.watch(roomRepositoryProvider);
  repository.addListener(ref.invalidateSelf);
  ref.onDispose(() => repository.removeListener(ref.invalidateSelf));
  final roomId = repository.roomState.currentRoomId?.trim();
  return roomId?.isNotEmpty == true ? roomId! : routeId;
});
