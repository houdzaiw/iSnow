import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/room_manager.dart';
import '../models/room_session_state.dart';
import '../room_repository.dart';

final roomSessionViewModelProvider =
    StateNotifierProvider<RoomSessionViewModel, RoomSessionState>(
      (ref) => RoomSessionViewModel(ref.watch(roomRepositoryProvider)),
    );

/// Root session state outlives every individual RoomPage controller.
class RoomSessionViewModel extends StateNotifier<RoomSessionState> {
  RoomSessionViewModel(this._repository) : super(const RoomSessionState()) {
    _repository.addListener(_syncRoom);
    _repository.addAuthListener(_syncAuth);
    _syncRoom();
    _syncAuth();
  }

  final RoomRepository _repository;
  int _authRevision = 0;

  void _syncRoom() {
    if (!mounted) return;
    final room = _repository.roomState;
    final ended =
        room.status != RoomStatus.ready ||
        !room.isInRoom ||
        room.currentRoomId != state.room.currentRoomId;
    state = state.copyWith(room: room, isBusy: ended ? false : state.isBusy);
  }

  void _syncAuth() => unawaited(_readAuth());

  Future<void> _readAuth() async {
    final revision = ++_authRevision;
    try {
      final loggedIn = await _repository.isLoggedIn();
      if (!mounted || revision != _authRevision) return;
      state = state.copyWith(isLoggedIn: loggedIn);
      // Covers auth invalidation outside the Settings logout action as well.
      if (!loggedIn && _repository.roomState.status != RoomStatus.idle) {
        await _repository.leaveRoom();
      }
    } catch (error) {
      debugPrint('[RoomSession] Auth/room cleanup failed: $error');
    }
  }

  String? restoreRoom() {
    if (!state.canShowMini || state.isBusy) return null;
    final roomId = state.room.currentRoomId!;
    state = state.copyWith(isBusy: true);
    _repository.restoreRoom();
    final current = _repository.roomState;
    if (current.status != RoomStatus.ready ||
        !current.isInRoom ||
        current.currentRoomId != roomId ||
        current.isMinimized) {
      finishRestore();
      return null;
    }
    return roomId;
  }

  void finishRestore({bool navigationFailed = false, String? roomId}) {
    if (!mounted) return;
    if (navigationFailed &&
        _repository.roomState.currentRoomId == roomId &&
        _repository.roomState.status == RoomStatus.ready) {
      _repository.minimizeRoom();
    }
    state = state.copyWith(isBusy: false);
  }

  Future<void> exitMinimizedRoom() async {
    if (!state.canShowMini || state.isBusy) return;
    state = state.copyWith(isBusy: true);
    try {
      await _repository.exitMinimizedRoom();
    } catch (error) {
      debugPrint('[RoomSession] Mini-room exit failed: $error');
    } finally {
      if (mounted) {
        state = state.copyWith(isBusy: false, room: _repository.roomState);
      }
    }
  }

  @override
  void dispose() {
    _authRevision += 1;
    _repository.removeListener(_syncRoom);
    _repository.removeAuthListener(_syncAuth);
    super.dispose();
  }
}
