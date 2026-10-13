import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  });
  final List<RoomMusicTrack> tracks;
  final RoomMusicPlaybackState playback;
  final RoomMusicMode mode;
  final bool loading;
  final bool busy;
  final String? error;
  final bool takeover;
}

final roomMusicViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomMusicViewModel, RoomMusicSheetState, String>(
      (ref, roomId) => RoomMusicViewModel(
        repository: ref.read(roomMusicRepositoryProvider),
        roomId: roomId,
      ),
    );

class RoomMusicViewModel extends StateNotifier<RoomMusicSheetState> {
  RoomMusicViewModel({
    required RoomMusicRepository repository,
    required String roomId,
  }) : _repository = repository,
       _roomId = roomId,
       super(const RoomMusicSheetState()) {
    _repository.addListener(_sync);
    unawaited(Future<void>.microtask(initialize));
  }
  final RoomMusicRepository _repository;
  final String _roomId;
  Future<void> Function(bool)? _takeoverAction;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  void _sync() {
    if (!mounted) return;
    state = RoomMusicSheetState(
      tracks: _repository.tracks,
      playback: _repository.playback,
      mode: _repository.mode,
      loading: _loading,
      busy: _busy,
      error: _error ?? _repository.automaticError ?? _repository.playback.error,
      takeover: _takeoverAction != null,
    );
  }

  Future<void> initialize() async {
    try {
      await _repository.load();
    } catch (error) {
      _error = error.toString();
    }
    _loading = false;
    _sync();
  }

  Future<void> _run(
    Future<void> Function(bool force) action, {
    bool force = false,
  }) async {
    if (!mounted || _busy || !_repository.isCurrentRoom(_roomId)) return;
    _busy = true;
    _error = null;
    _takeoverAction = null;
    _sync();
    try {
      await action(force);
    } catch (error) {
      if (error is NadyApiException && error.code == 4062 && !force) {
        _takeoverAction = action;
      }
      _error = error is NadyApiException ? error.message : error.toString();
    } finally {
      _busy = false;
      _sync();
    }
  }

  Future<void> add() => _run((_) => _repository.addAudio());
  Future<void> remove(RoomMusicTrack track) =>
      _run((_) => _repository.remove(track));
  Future<void> play(RoomMusicTrack track) =>
      _run((force) => _repository.play(_roomId, track, force: force));
  Future<void> toggle() =>
      _run((force) => _repository.toggle(_roomId, force: force));
  Future<void> next({bool previous = false}) => _run(
    (force) => _repository.next(_roomId, previous: previous, force: force),
  );
  Future<void> stop() => _run((_) => _repository.stop());
  Future<void> seek(int position) =>
      _run((_) => _repository.seek(_roomId, position));
  Future<void> volume(int volume) =>
      _run((_) => _repository.volume(_roomId, volume));
  void changeMode(RoomMusicMode mode) => _repository.changeMode(mode);

  Future<void> confirmTakeover(bool confirm) async {
    final action = _takeoverAction;
    _takeoverAction = null;
    _sync();
    if (confirm && action != null) await _run(action, force: true);
  }

  @override
  void dispose() {
    _repository.removeListener(_sync);
    super.dispose();
  }
}
