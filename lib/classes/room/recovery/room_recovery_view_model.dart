import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/room_manager.dart';
import '../../../model/room_recovery_notice.dart';
import '../room_repository.dart';

final roomRecoveryProvider =
    StateNotifierProvider<RoomRecoveryViewModel, RoomRecoveryState>(
      (ref) => RoomRecoveryViewModel(ref.watch(roomRepositoryProvider)),
    );

abstract interface class RoomRecoveryNavigator {
  Future<bool> enterRoom(
    String roomId,
    bool Function() isCurrent,
    void Function() onPrompt,
  );
  void cancelPending();
}

class RoomRecoveryState {
  const RoomRecoveryState({
    this.notice,
    this.busy = false,
    this.prompt = false,
    this.issue,
  });
  final RoomRecoveryNotice? notice;
  final bool busy;
  final bool prompt;
  final String? issue;
}

/// Survives RoomPage disposal; retries are exclusively initiated by the user.
class RoomRecoveryViewModel extends StateNotifier<RoomRecoveryState> {
  RoomRecoveryViewModel(this._repository) : super(const RoomRecoveryState()) {
    _repository.addListener(_syncRoom);
    _repository.addAuthListener(_authChanged);
    unawaited(_readAccount());
  }

  final RoomRepository _repository;
  int? _uid;
  int _revision = 0;
  RoomRecoveryNavigator? _navigation;

  void _syncRoom() {
    if (!mounted) return;
    final notice = _repository.recoveryNotice;
    final available =
        _uid != null &&
        _repository.roomState.status == RoomStatus.idle &&
        notice?.generation == _repository.roomGeneration;
    final next = available ? notice : null;
    if (identical(next, state.notice)) return;
    _navigation?.cancelPending();
    _navigation = null;
    state = RoomRecoveryState(notice: next);
  }

  void _authChanged() {
    _uid = null;
    final notice = _repository.recoveryNotice;
    if (notice != null) _repository.dismissRecovery(notice);
    _navigation?.cancelPending();
    _navigation = null;
    state = const RoomRecoveryState();
    unawaited(_readAccount());
  }

  Future<void> _readAccount() async {
    final revision = ++_revision;
    try {
      final uid = await _repository.currentUid();
      if (!mounted || revision != _revision) return;
      _uid = uid != null && uid > 0 ? uid : null;
      if (_uid == null) {
        final notice = _repository.recoveryNotice;
        if (notice != null) _repository.dismissRecovery(notice);
      }
      _syncRoom();
    } catch (_) {
      if (!mounted || revision != _revision) return;
      _uid = null;
      final notice = _repository.recoveryNotice;
      if (notice != null) _repository.dismissRecovery(notice);
      _syncRoom();
    }
  }

  bool _valid(RoomRecoveryNotice notice, int revision) =>
      mounted &&
      revision == _revision &&
      _uid != null &&
      identical(state.notice, notice) &&
      identical(_repository.recoveryNotice, notice) &&
      _repository.roomGeneration == notice.generation &&
      _repository.roomState.status == RoomStatus.idle;

  void dismiss() {
    final notice = state.notice;
    if (notice != null) _repository.dismissRecovery(notice);
  }

  Future<void> retry(RoomRecoveryNavigator navigation) async {
    final notice = state.notice;
    final revision = _revision;
    if (notice == null || state.busy || !_valid(notice, revision)) return;
    _navigation = navigation;
    state = RoomRecoveryState(notice: notice, busy: true);
    String? issue;
    try {
      final opened = await navigation.enterRoom(
        notice.roomId,
        () => _valid(notice, revision),
        () {
          if (_valid(notice, revision)) {
            state = RoomRecoveryState(notice: notice, busy: true, prompt: true);
          }
        },
      );
      if (_valid(notice, revision) && opened) dismiss();
    } catch (error) {
      issue = userFacingErrorMessage(error, fallback: 'room.recovery.failed');
    } finally {
      if (identical(_navigation, navigation)) _navigation = null;
      if (_valid(notice, revision)) {
        state = RoomRecoveryState(notice: notice, issue: issue);
      }
    }
  }

  @override
  void dispose() {
    _revision++;
    _navigation?.cancelPending();
    _repository.removeListener(_syncRoom);
    _repository.removeAuthListener(_authChanged);
    super.dispose();
  }
}
