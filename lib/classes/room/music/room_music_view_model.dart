import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/room_system_volume_manager.dart';
import '../../../model/room_music_state.dart';
import '../../../model/server_response.dart';
import 'room_music_repository.dart';
import 'room_music_track.dart';

class RoomMusicSheetState {
  const RoomMusicSheetState({
    this.tracks = const [],
    this.playback = const RoomMusicPlaybackState(),
    this.mode = RoomMusicMode.loop,
    this.loading = true,
    this.busy = false,
    this.error,
    this.takeover = false,
    this.query = '',
    this.noticeKey,
    this.totalTracks = 0,
    this.expanded = false,
    this.closing = false,
    this.systemVolume,
    this.systemVolumeError = false,
  });
  final List<RoomMusicTrack> tracks;
  final RoomMusicPlaybackState playback;
  final RoomMusicMode mode;
  final bool loading;
  final bool busy;
  final String? error;
  final bool takeover;
  final String query;
  final String? noticeKey;
  final int totalTracks;
  final bool expanded;
  final bool closing;
  final double? systemVolume;
  final bool systemVolumeError;
}

final roomMusicViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomMusicViewModel, RoomMusicSheetState, String>(
      (ref, roomId) => RoomMusicViewModel(
        repository: ref.read(roomMusicRepositoryProvider),
        roomId: roomId,
        systemVolume: ref.read(roomSystemVolumeManagerProvider),
      ),
    );

class RoomMusicViewModel extends StateNotifier<RoomMusicSheetState> {
  RoomMusicViewModel({
    required RoomMusicRepository repository,
    required String roomId,
    RoomSystemVolumeManager? systemVolume,
  }) : _repository = repository,
       _roomId = roomId,
       _systemVolume = systemVolume ?? RoomSystemVolumeManager.instance,
       super(const RoomMusicSheetState()) {
    _repository.addListener(_sync);
    _sessionGeneration = _repository.sessionGeneration;
    _sync();
  }
  final RoomMusicRepository _repository;
  final String _roomId;
  final RoomSystemVolumeManager _systemVolume;
  StreamSubscription<double>? _volumeSubscription;
  double? _systemValue;
  bool _systemError = false;
  bool _expanded = false;
  bool _closing = false;
  bool _dialogClaimed = false;
  int _actionEpoch = 0;
  late int _sessionGeneration;
  int? _expandedGeneration;
  int? _pendingVolume;
  Future<void>? _volumeTask;
  Future<void>? _stopTask;
  Future<void>? _initialization;
  Future<void> Function(bool)? _takeoverAction;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _query = '';
  String? _noticeKey;
  bool get supportsLocalScan => _repository.supportsLocalScan;

  void _sync() {
    if (!mounted) return;
    if (_sessionGeneration != _repository.sessionGeneration) {
      _sessionGeneration = _repository.sessionGeneration;
      _actionEpoch++;
      _busy = false;
      _takeoverAction = null;
      _pendingVolume = null;
      _error = null;
    }
    if (_expanded &&
        (!_repository.canPresent(_roomId) ||
            _expandedGeneration != _repository.sessionGeneration)) {
      _expanded = false;
      _detachVolume();
      _actionEpoch++;
      _busy = false;
      _takeoverAction = null;
    }
    state = RoomMusicSheetState(
      tracks: _repository.tracks
          .where(
            (track) =>
                track.name.toLowerCase().contains(_query.trim().toLowerCase()),
          )
          .toList(),
      playback: _repository.playback,
      mode: _repository.mode,
      loading: _loading,
      busy: _busy,
      error: _error ?? _repository.automaticError ?? _repository.playback.error,
      takeover: _takeoverAction != null,
      query: _query,
      noticeKey: _noticeKey,
      totalTracks: _repository.tracks.length,
      expanded: _expanded,
      closing: _closing,
      systemVolume: _systemValue,
      systemVolumeError: _systemError,
    );
  }

  Future<void> initialize() {
    if (!mounted) return Future<void>.value();
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _repository.load();
    } catch (error) {
      _error = userFacingErrorMessage(error);
    }
    _loading = false;
    _sync();
  }

  Future<void> _run(
    Future<void> Function(bool force) action, {
    bool force = false,
  }) async {
    if (!mounted || _busy || _closing || !_repository.isCurrentRoom(_roomId)) {
      return;
    }
    final epoch = ++_actionEpoch;
    final generation = _repository.sessionGeneration;
    _busy = true;
    _error = null;
    _noticeKey = null;
    _takeoverAction = null;
    _sync();
    try {
      await action(force);
    } catch (error) {
      if (!mounted ||
          epoch != _actionEpoch ||
          generation != _repository.sessionGeneration) {
        return;
      }
      if (error is NadyApiException && error.code == 4062 && !force) {
        _takeoverAction = action;
      }
      _error = userFacingErrorMessage(error);
    } finally {
      if (mounted && epoch == _actionEpoch) {
        _busy = false;
        _sync();
      }
    }
  }

  void search(String query) {
    _query = query;
    _sync();
  }

  Future<void> add() => _run((_) async {
    final generation = _repository.sessionGeneration;
    final epoch = _actionEpoch;
    final result = await _repository.addAudio(
      isCancelled: () =>
          !mounted ||
          epoch != _actionEpoch ||
          generation != _repository.sessionGeneration,
    );
    if (result.failedCount > 0) _noticeKey = 'room.music.importFailed';
  });
  Future<void> remove(RoomMusicTrack track) =>
      _run((_) => _repository.remove(track));
  Future<void> play(RoomMusicTrack track) =>
      _run((force) => _repository.play(_roomId, track, force: force));
  Future<void> toggle() =>
      _run((force) => _repository.toggle(_roomId, force: force));
  Future<void> next({bool previous = false}) => _run(
    (force) => _repository.next(_roomId, previous: previous, force: force),
  );
  Future<void> stop() {
    if (!mounted || !_repository.isCurrentRoom(_roomId)) {
      return Future<void>.value();
    }
    if (_stopTask != null) return _stopTask!;
    _actionEpoch++;
    _busy = false;
    _closing = true;
    _pendingVolume = null;
    _takeoverAction = null;
    _error = null;
    _sync();
    return _stopTask = _stopPlayer();
  }

  Future<void> _stopPlayer() async {
    final generation = _repository.sessionGeneration;
    try {
      await _repository.stop();
    } catch (error) {
      if (mounted && generation == _repository.sessionGeneration) {
        _error = userFacingErrorMessage(error);
      }
    } finally {
      _stopTask = null;
      _closing = false;
      _sync();
    }
  }

  Future<void> seek(int position) =>
      _run((_) => _repository.seek(_roomId, position));
  Future<void> volume(int volume) {
    if (!mounted || _closing || !_repository.isCurrentRoom(_roomId)) {
      return Future<void>.value();
    }
    _pendingVolume = volume.clamp(0, 100);
    return _volumeTask ??= Future<void>.microtask(_drainVolume);
  }

  Future<void> _drainVolume() async {
    final generation = _repository.sessionGeneration;
    try {
      while (mounted &&
          !_closing &&
          _pendingVolume != null &&
          generation == _repository.sessionGeneration &&
          _repository.isCurrentRoom(_roomId)) {
        final value = _pendingVolume!;
        _pendingVolume = null;
        try {
          await _repository.volume(_roomId, value);
        } catch (error) {
          if (mounted && generation == _repository.sessionGeneration) {
            _error = userFacingErrorMessage(error);
            _sync();
          }
        }
      }
    } finally {
      _pendingVolume = null;
      _volumeTask = null;
    }
  }

  void expand() {
    if (!mounted || _closing || !_repository.canPresent(_roomId)) return;
    _expanded = true;
    unawaited(initialize());
    _expandedGeneration = _repository.sessionGeneration;
    _systemError = false;
    _volumeSubscription ??= _systemVolume.changes.listen(
      (value) {
        if (!mounted || !_expanded) return;
        _systemValue = value;
        _systemError = false;
        _sync();
      },
      onError: (Object _) {
        if (!mounted || !_expanded) return;
        _systemError = true;
        _sync();
      },
    );
    _sync();
  }

  void _detachVolume() {
    unawaited(_volumeSubscription?.cancel());
    _volumeSubscription = null;
    _systemValue = null;
  }

  void collapse() {
    if (!_expanded && _volumeSubscription == null) return;
    _expanded = false;
    _detachVolume();
    _sync();
  }

  Future<void> close() {
    collapse();
    return stop();
  }

  Future<void> systemVolume(double value) async {
    if (!mounted || !_expanded || _systemError) return;
    try {
      await _systemVolume.setVolume(value);
    } catch (_) {
      if (mounted && _expanded) {
        _systemError = true;
        _sync();
      }
    }
  }

  void cycleMode() => changeMode(
    RoomMusicMode.values[(state.mode.index + 1) % RoomMusicMode.values.length],
  );
  void changeMode(RoomMusicMode mode) => _repository.changeMode(mode);

  int get takeoverRevision => _actionEpoch;
  bool claimTakeoverDialog() {
    if (_takeoverAction == null || _dialogClaimed) return false;
    _dialogClaimed = true;
    return true;
  }

  Future<void> confirmTakeover(bool confirm, {int? revision}) async {
    _dialogClaimed = false;
    if (revision != null && revision != _actionEpoch) return;
    final action = _takeoverAction;
    _takeoverAction = null;
    _sync();
    if (confirm && action != null) await _run(action, force: true);
  }

  @override
  void dispose() {
    _actionEpoch++;
    _pendingVolume = null;
    _detachVolume();
    _repository.removeListener(_sync);
    super.dispose();
  }
}
