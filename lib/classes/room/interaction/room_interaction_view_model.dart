import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/room_manager.dart';
import '../../../model/room_user_info.dart';
import '../room_repository.dart';
import 'room_interaction_repository.dart';
import 'room_moderation.dart';

typedef RoomInteractionKey = ({
  String roomId,
  int generation,
  Object viewToken,
});

final roomInteractionProvider = StateNotifierProvider.autoDispose
    .family<RoomInteractionViewModel, bool, RoomInteractionKey>(
      (ref, key) => RoomInteractionViewModel(
        ref.watch(roomRepositoryProvider),
        ref.watch(roomInteractionRepositoryProvider),
        key,
      ),
    );

class RoomInteractionViewModel extends StateNotifier<bool> {
  RoomInteractionViewModel(this.room, this.api, this.key) : super(true) {
    state = _matches;
    room.addListener(_sync);
    room.addAuthListener(_invalidate);
  }

  final RoomRepository room;
  final RoomInteractionRepository api;
  final RoomInteractionKey key;
  bool _showing = false;

  bool get _matches =>
      room.roomGeneration == key.generation &&
      room.roomState.currentRoomId == key.roomId &&
      room.roomState.status == RoomStatus.ready &&
      room.roomState.isInRoom &&
      !room.roomState.isMinimized;

  bool get active => mounted && state && _matches;

  bool begin() {
    if (!active || _showing) return false;
    _showing = true;
    return true;
  }

  void finish() => _showing = false;

  void _sync() {
    if (!_matches) _invalidate();
  }

  void _invalidate() {
    if (mounted && state) state = false;
  }

  @override
  void dispose() {
    room.removeListener(_sync);
    room.removeAuthListener(_invalidate);
    super.dispose();
  }
}

typedef RoomUserCardKey = ({RoomInteractionKey session, int uid});

final roomUserCardProvider = StateNotifierProvider.autoDispose
    .family<RoomUserCardViewModel, RoomUserCardState, RoomUserCardKey>(
      (ref, key) => RoomUserCardViewModel(
        ref.watch(roomInteractionProvider(key.session).notifier),
        key.uid,
      ),
    );

class RoomUserCardState {
  const RoomUserCardState({
    this.user,
    this.loading = false,
    this.saving = false,
    this.following = false,
    this.error,
  });

  final RoomUserInfo? user;
  final bool loading;
  final bool saving;
  final bool following;
  final String? error;
}

class RoomUserCardViewModel extends StateNotifier<RoomUserCardState> {
  RoomUserCardViewModel(this.session, this.uid)
    : super(const RoomUserCardState(loading: true)) {
    Future.microtask(load);
  }

  final RoomInteractionViewModel session;
  final int uid;
  bool _fetching = false;
  bool _closed = false;
  bool get active => mounted && !_closed && session.active;

  void close() => _closed = true;

  Set<RoomModerationAction> actions(int? actorUid, RoomUserInfo user) =>
      actorUid == uid
      ? {}
      : availableRoomModeration(
          actor: session.actorRole(actorUid),
          target: user,
          seat: session.seatFor(uid),
        );

  Future<List<RoomSilenceOption>> silenceOptions(String language) =>
      session.api.silenceOptions(language);

  Future<bool> moderate(RoomModerationAction action, {int? duration}) async {
    if (!active || state.saving || state.user == null) return false;
    final before = state;
    state = RoomUserCardState(
      user: before.user,
      following: before.following,
      saving: true,
    );
    try {
      await session.moderate(
        uid,
        action,
        duration: duration,
        stillOpen: () => active,
      );
      if (!active) return false;
      state = before;
      if (action != RoomModerationAction.kick &&
          action != RoomModerationAction.block) {
        await load();
      }
      return active;
    } catch (error) {
      if (active) {
        state = RoomUserCardState(
          user: before.user,
          following: before.following,
          error: userFacingErrorMessage(error),
        );
      }
      return false;
    }
  }

  Future<void> load() async {
    if (!active || _fetching || state.saving) return;
    _fetching = true;
    state = const RoomUserCardState(loading: true);
    try {
      final user = await session.api.user(session.key.roomId, uid);
      if (active) {
        state = RoomUserCardState(user: user, following: user.isFollowing);
      }
    } catch (error) {
      if (active) {
        state = RoomUserCardState(error: userFacingErrorMessage(error));
      }
    } finally {
      _fetching = false;
    }
  }

  Future<void> follow(bool following) async {
    if (!active ||
        state.saving ||
        state.user == null ||
        following == state.following) {
      return;
    }
    final before = state;
    state = RoomUserCardState(
      user: before.user,
      following: before.following,
      saving: true,
    );
    try {
      final actor = await session.room.currentUid();
      if (!active) return;
      if (actor == null || actor == uid) {
        state = before;
        return;
      }
      await session.api.setFollowing(uid, following);
      if (active) {
        state = RoomUserCardState(user: before.user, following: following);
      }
    } catch (error) {
      if (active) {
        state = RoomUserCardState(
          user: before.user,
          following: before.following,
          error: userFacingErrorMessage(error),
        );
      }
    }
  }
}
