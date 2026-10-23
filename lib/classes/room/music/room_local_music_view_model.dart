import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'room_local_music_track.dart';
import 'room_music_repository.dart';

class RoomLocalMusicState {
  const RoomLocalMusicState({
    this.tracks = const [],
    this.selectedIds = const {},
    this.query = '',
    this.permission = RoomMusicPermission.denied,
    this.scanning = true,
    this.importing = false,
    this.errorKey,
    this.failedCount = 0,
    this.completed = false,
  });

  final List<RoomLocalMusicTrack> tracks;
  final Set<String> selectedIds;
  final String query;
  final RoomMusicPermission permission;
  final bool scanning;
  final bool importing;
  final String? errorKey;
  final int failedCount;
  final bool completed;

  List<RoomLocalMusicTrack> get visibleTracks => tracks
      .where(
        (track) =>
            track.name.toLowerCase().contains(query.trim().toLowerCase()),
      )
      .toList();
}

final roomLocalMusicViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomLocalMusicViewModel, RoomLocalMusicState, String>(
      (ref, roomId) => RoomLocalMusicViewModel(
        repository: ref.read(roomMusicRepositoryProvider),
        roomId: roomId,
      ),
    );

class RoomLocalMusicViewModel extends StateNotifier<RoomLocalMusicState> {
  RoomLocalMusicViewModel({
    required RoomMusicRepository repository,
    required String roomId,
  }) : _repository = repository,
       _roomId = roomId,
       _generation = repository.sessionGeneration,
       super(const RoomLocalMusicState()) {
    unawaited(Future<void>.microtask(() => scan(requestPermission: true)));
  }

  final RoomMusicRepository _repository;
  final String _roomId;
  final int _generation;
  List<RoomLocalMusicTrack> _tracks = const [];
  final Set<String> _selected = {};
  RoomMusicPermission _permission = RoomMusicPermission.denied;
  String _query = '';
  bool _scanning = false;
  bool _importing = false;
  bool _waitingSettings = false;
  String? _errorKey;
  int _failedCount = 0;
  bool _completed = false;

  bool get _active =>
      mounted &&
      _generation == _repository.sessionGeneration &&
      _repository.isCurrentRoom(_roomId);

  void _sync() {
    if (!mounted) return;
    state = RoomLocalMusicState(
      tracks: _tracks,
      selectedIds: Set.unmodifiable(_selected),
      query: _query,
      permission: _permission,
      scanning: _scanning,
      importing: _importing,
      errorKey: _errorKey,
      failedCount: _failedCount,
      completed: _completed,
    );
  }

  Future<void> scan({bool requestPermission = false}) async {
    if (!_active || _scanning || _importing) return;
    _scanning = true;
    _errorKey = null;
    _sync();
    try {
      final result = await _repository.scanLocalTracks(
        requestPermission: requestPermission,
      );
      if (!_active) return;
      _permission = result.permission;
      _tracks = result.tracks;
      _selected.retainAll(_tracks.map((track) => track.id));
    } catch (_) {
      if (_active) _errorKey = 'room.music.scanFailed';
    } finally {
      _scanning = false;
      _sync();
    }
  }

  void search(String query) {
    _query = query;
    _sync();
  }

  void select(String id) {
    if (!_active ||
        _scanning ||
        _importing ||
        !_tracks.any((track) => track.id == id)) {
      return;
    }
    if (!_selected.remove(id)) _selected.add(id);
    _sync();
  }

  Future<void> openSettings() async {
    if (!_active || _importing) return;
    _waitingSettings = true;
    try {
      await _repository.openMusicSettings();
    } catch (_) {
      _waitingSettings = false;
      _errorKey = 'room.music.settingsFailed';
      _sync();
    }
  }

  void onResumed() {
    if (!_waitingSettings) return;
    _waitingSettings = false;
    unawaited(scan());
  }

  Future<void> addSelected() async {
    if (_selected.isEmpty) return;
    final selected = _tracks
        .where((track) => _selected.contains(track.id))
        .toList();
    await _import(
      () => _repository.addLocalTracks(selected, isCancelled: () => !_active),
    );
  }

  Future<void> importFiles() =>
      _import(() => _repository.addAudio(isCancelled: () => !_active));

  Future<void> _import(Future<RoomMusicImportResult> Function() action) async {
    if (!_active || _importing || _scanning) return;
    _importing = true;
    _errorKey = null;
    _failedCount = 0;
    _sync();
    try {
      final result = await action();
      if (!_active || result.cancelled) return;
      _failedCount = result.failedCount;
      if (_failedCount > 0) {
        _errorKey = result.importedCount > 0
            ? 'room.music.importPartial'
            : 'room.music.importFailed';
      }
      _completed = result.importedCount > 0 && _failedCount == 0;
    } catch (_) {
      if (_active) _errorKey = 'room.music.importFailed';
    } finally {
      _importing = false;
      _sync();
    }
  }
}
