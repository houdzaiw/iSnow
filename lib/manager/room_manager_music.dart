part of 'room_manager.dart';

extension RoomManagerMusic on RoomManager {
  Future<void> _queueMusic(Future<void> Function() action) {
    final task =
        _musicQueue?.then((_) => action()) ?? Future<void>.sync(action);
    final tail = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _musicQueue = tail;
    unawaited(
      tail.then((_) {
        if (identical(_musicQueue, tail)) _musicQueue = null;
      }),
    );
    return task;
  }

  Future<int> _requireMusicSeat(String roomId, int generation) async {
    final uid = await _authSession.uid();
    if (!_isCurrentSession(roomId, generation)) {
      throw const NadyApiException(message: 'Room session ended');
    }
    if (uid == null || !_state.micList.any((mic) => mic.uid == uid)) {
      throw const NadyApiException(
        code: -4062,
        message: 'Take a microphone seat to play music',
      );
    }
    return uid;
  }

  Future<void> _playMusic({
    required String roomId,
    required String path,
    required String title,
    required bool force,
  }) {
    final generation = _generation;
    final epoch = _musicEpoch;
    return _queueMusic(() async {
      final uid = await _requireMusicSeat(roomId, generation);
      if (epoch != _musicEpoch) {
        throw const NadyApiException(message: 'Music player closed');
      }
      if (_musicPlayerRoomId == null) {
        await _joinTask;
        if (!_isCurrentSession(roomId, generation)) return;
        await _socketManager.subscribeRoomMusicControl(uid);
        if (!_isCurrentSession(roomId, generation)) return;
        _musicUid = uid;
        _musicLeaseRevoked = false;
        await _api.openPlayer(roomId, force: force);
        _musicPlayerRoomId = roomId;
      }
      try {
        await _requireMusicSeat(roomId, generation);
        if (epoch != _musicEpoch) return;
        await _agoraJoinTask;
        if (!_isCurrentSession(roomId, generation) || epoch != _musicEpoch) {
          return;
        }
        await _agoraManager.startMusic(path: path, title: title);
      } catch (_) {
        await _closeMusicPlayer();
        rethrow;
      }
    });
  }

  Future<void> _controlMusic(
    String roomId,
    Future<void> Function() action, {
    bool requirePlayer = true,
  }) {
    final generation = _generation;
    final epoch = _musicEpoch;
    return _queueMusic(() async {
      await _requireMusicSeat(roomId, generation);
      if (epoch != _musicEpoch ||
          (requirePlayer && _musicPlayerRoomId != roomId)) {
        return;
      }
      await action();
    });
  }

  Future<void> _closeMusicPlayer({bool revoked = false}) async {
    final roomId = _musicPlayerRoomId;
    _musicPlayerRoomId = null;
    await _agoraManager.stopMusic();
    if (roomId != null && !revoked) {
      await _api.closePlayer(roomId);
    }
  }

  void _notifyMusicStatus() {
    final status = _agoraManager.state.music.status;
    if (_lastMusicStatus == status) return;
    _lastMusicStatus = status;
    final roomId = _state.currentRoomId;
    final generation = _generation;
    if (roomId == null ||
        _musicUid == null ||
        _musicLeaseRevoked ||
        status == RoomMusicPlayback.preparing) {
      return;
    }
    if (_state.enterResponse?.identity?.isOwnerOrManager != true &&
        _state.roomInfo?.roomOwnerUid != _musicUid) {
      return;
    }
    final epoch = _musicEpoch;
    Future<void> pushStatus() async {
      if (_state.currentRoomId != roomId ||
          generation != _generation ||
          epoch != _musicEpoch) {
        return;
      }
      await _cleanupStep(
        'music status push',
        () => _api.musicStatus(roomId, status.name),
      );
    }

    _musicStatusQueue =
        _musicStatusQueue?.then((_) => pushStatus()) ??
        Future<void>.sync(pushStatus);
    final pending = _musicStatusQueue!;
    unawaited(
      pending.then((_) {
        if (identical(_musicStatusQueue, pending)) _musicStatusQueue = null;
      }),
    );
  }
}
