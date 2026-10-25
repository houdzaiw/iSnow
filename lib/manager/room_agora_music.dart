part of 'room_agora_manager.dart';

extension RoomAgoraMusic on RoomAgoraManager {
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

  /// Publish mixing to the room while leaving the recording mute unchanged.
  Future<void> _startMusic({
    required String path,
    required String title,
    bool Function()? isCancelled,
  }) {
    final generation = _generation;
    final roomId = _expectedRoomId;
    return _queueMusic(() async {
      final engine = _requireEngine();
      if (roomId == null ||
          !_isCurrentChannel(engine, roomId, generation) ||
          isCancelled?.call() == true) {
        return;
      }
      await publish();
      if (!_isCurrentChannel(engine, roomId, generation)) return;
      if (!_state.joined || !_state.publishing) {
        throw StateError('Agora has not connected yet');
      }
      await _stopMixing(engine);
      // Agora requires at least 500 ms between successive mixing starts.
      final lastStart = _lastMusicStart;
      if (lastStart != null) {
        final remaining =
            550 - DateTime.now().difference(lastStart).inMilliseconds;
        if (remaining > 0) {
          await Future<void>.delayed(Duration(milliseconds: remaining));
        }
      }
      if (!_isCurrentChannel(engine, roomId, generation) ||
          isCancelled?.call() == true) {
        return;
      }
      _mixingActive = true;
      _setMusic(
        RoomMusicPlaybackState(
          status: RoomMusicPlayback.preparing,
          title: title,
          path: path,
          volume: _state.music.volume,
          completed: _state.music.completed,
        ),
      );
      try {
        _lastMusicStart = DateTime.now();
        await engine.startAudioMixing(
          filePath: path,
          loopback: false,
          cycle: 1,
        );
        if (isCancelled?.call() == true) {
          await _stopMixing(engine);
          return;
        }
        if (!_isCurrentChannel(engine, roomId, generation)) return;
        await engine.adjustAudioMixingVolume(_state.music.volume);
        await engine.adjustAudioMixingPublishVolume(_state.music.volume);
        if (!_isCurrentChannel(engine, roomId, generation)) return;
        // SDK callbacks acknowledge playback. Do not claim Playing on invocation.
        _musicProgressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          unawaited(_pollMusic(engine, roomId, generation));
        });
      } catch (error) {
        if (!_isCurrentChannel(engine, roomId, generation)) return;
        await _stopMixing(engine);
        _setMusic(
          _state.music.copyWith(
            status: RoomMusicPlayback.failed,
            error: userFacingErrorMessage(error),
          ),
        );
        rethrow;
      }
    });
  }

  Future<void> _pauseMusic() => _changeMusic(
    (engine) => engine.pauseAudioMixing(),
    RoomMusicPlayback.paused,
  );

  Future<void> _resumeMusic() {
    final roomId = _expectedRoomId;
    final generation = _generation;
    return _changeMusic((engine) async {
      await publish();
      if (roomId != null && _isCurrentChannel(engine, roomId, generation)) {
        await engine.resumeAudioMixing();
      }
    }, RoomMusicPlayback.playing);
  }

  Future<void> _changeMusic(
    Future<void> Function(RtcEngine) action,
    RoomMusicPlayback status,
  ) {
    final generation = _generation;
    final roomId = _expectedRoomId;
    return _queueMusic(() async {
      final engine = _requireEngine();
      if (roomId == null ||
          !_isCurrentChannel(engine, roomId, generation) ||
          !_mixingActive) {
        return;
      }
      await action(engine);
      if (_isCurrentChannel(engine, roomId, generation)) {
        _setMusic(_state.music.copyWith(status: status));
      }
    });
  }

  Future<void> _seekMusic(int position) {
    final generation = _generation;
    return _changeMusic((engine) async {
      final next = position.clamp(0, _state.music.duration);
      await engine.setAudioMixingPosition(next);
      if (generation == _generation) {
        _setMusic(_state.music.copyWith(position: next));
      }
    }, _state.music.status);
  }

  Future<void> _setMusicVolume(int volume) {
    final generation = _generation;
    return _queueMusic(() async {
      if (generation != _generation || _expectedRoomId == null) return;
      final next = volume.clamp(0, 100);
      if (_mixingActive) {
        final engine = _requireEngine();
        await engine.adjustAudioMixingVolume(next);
        await engine.adjustAudioMixingPublishVolume(next);
      }
      if (generation == _generation) {
        _setMusic(_state.music.copyWith(volume: next));
      }
    });
  }

  Future<void> _stopMusic() => _queueMusic(() async {
    final engine = _engine;
    if (engine != null) await _stopMixing(engine);
    _setMusic(
      RoomMusicPlaybackState(
        volume: _state.music.volume,
        completed: _state.music.completed,
      ),
    );
  });

  Future<void> _stopMixing(RtcEngine engine) async {
    _musicProgressTimer?.cancel();
    _musicProgressTimer = null;
    final active = _mixingActive;
    _mixingActive = false;
    if (active) await _cleanup('stop music', engine.stopAudioMixing);
  }

  void _onMusicStateChanged(
    AudioMixingStateType status,
    AudioMixingReasonType reason,
  ) {
    if (_expectedRoomId == null || !_mixingActive) return;
    // stopMusic already resets state. Its delayed SDK acknowledgement must not
    // stop a replacement track that has since started on the same engine.
    if (status == AudioMixingStateType.audioMixingStateStopped &&
        reason == AudioMixingReasonType.audioMixingReasonStoppedByUser) {
      return;
    }
    switch (status) {
      case AudioMixingStateType.audioMixingStatePlaying:
        _setMusic(_state.music.copyWith(status: RoomMusicPlayback.playing));
      case AudioMixingStateType.audioMixingStatePaused:
        _setMusic(_state.music.copyWith(status: RoomMusicPlayback.paused));
      case AudioMixingStateType.audioMixingStateFailed:
        _mixingActive = false;
        _musicProgressTimer?.cancel();
        _setMusic(
          _state.music.copyWith(
            status: RoomMusicPlayback.failed,
            error: reason.name,
          ),
        );
      case AudioMixingStateType.audioMixingStateStopped:
        _mixingActive = false;
        _musicProgressTimer?.cancel();
        _setMusic(
          _state.music.copyWith(
            status: RoomMusicPlayback.stopped,
            completed:
                reason ==
                    AudioMixingReasonType.audioMixingReasonAllLoopsCompleted
                ? _state.music.completed + 1
                : _state.music.completed,
          ),
        );
    }
  }

  Future<void> _pollMusic(
    RtcEngine engine,
    String roomId,
    int generation,
  ) async {
    if (_pollingMusic || !_mixingActive) return;
    _pollingMusic = true;
    try {
      final duration = await engine.getAudioMixingDuration();
      final position = await engine.getAudioMixingCurrentPosition();
      if (_isCurrentChannel(engine, roomId, generation) &&
          _mixingActive &&
          duration > 0) {
        _setMusic(
          _state.music.copyWith(
            duration: duration,
            position: position.clamp(0, duration),
          ),
        );
      }
    } catch (error) {
      debugPrint('[RoomMusic] progress unavailable: $error');
    } finally {
      _pollingMusic = false;
    }
  }

  void _setMusic(RoomMusicPlaybackState music) =>
      _setState(_state.copyWith(music: music));
}
