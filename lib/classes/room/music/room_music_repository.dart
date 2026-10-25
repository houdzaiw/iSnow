import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/room_manager.dart';
import '../../../manager/room_music_library.dart';
import '../../../manager/room_local_music_manager.dart';
import '../../../model/room_music_state.dart';
import '../../../model/server_response.dart';
import '../room_repository.dart';
import 'room_music_track.dart';
import 'room_local_music_track.dart';

part 'room_music_repository_import.dart';

final roomMusicRepositoryProvider = Provider<RoomMusicRepository>(
  (ref) => RoomMusicRepository.instance,
);

/// Application-lifetime music library and playback coordination, independent of sheets.
class RoomMusicRepository extends ChangeNotifier {
  RoomMusicRepository({
    RoomRepository? room,
    RoomMusicLibrary? library,
    RoomLocalMusicManager? localMusic,
  }) : _room = room ?? RoomRepository(),
       _library = library ?? RoomMusicLibrary(),
       _localMusic = localMusic ?? RoomLocalMusicManager() {
    _room.addListener(_sync);
    _room.addAuthListener(_authChanged);
    _completed = playback.completed;
    _roomGeneration = _room.roomGeneration;
  }

  static final instance = RoomMusicRepository();
  final RoomRepository _room;
  final RoomMusicLibrary _library;
  final RoomLocalMusicManager _localMusic;
  Future<void> _editQueue = Future<void>.value();
  Future<RoomMusicImportResult>? _importTask;
  int _authEpoch = 0;
  int _playEpoch = 0;
  List<RoomMusicTrack> _tracks = const [];
  int? _uid;
  Future<void>? _loadTask;
  RoomMusicMode _mode = RoomMusicMode.loop;
  int _completed = 0;
  int _roomGeneration = 0;
  bool _disposed = false;
  String? _automaticError;

  List<RoomMusicTrack> get tracks => _tracks;
  RoomMusicPlaybackState get playback => _room.agoraState.music;
  RoomMusicMode get mode => _mode;
  String? get automaticError => _automaticError;
  bool get supportsLocalScan => _localMusic.supported;
  int get sessionGeneration => _room.roomGeneration;
  void _setTracks(List<RoomMusicTrack> tracks) {
    _tracks = tracks;
    notifyListeners();
  }

  RoomMusicTrack? get selected {
    for (final track in _tracks) {
      if (playback.path?.endsWith('/${track.fileName}') == true) return track;
    }
    return null;
  }

  bool isCurrentRoom(String roomId) =>
      _room.roomState.currentRoomId == roomId &&
      _room.roomState.isInRoom &&
      _room.roomState.status == RoomStatus.ready;

  bool canPresent(String roomId) =>
      isCurrentRoom(roomId) && !_room.roomState.isMinimized;

  Future<void> load() async {
    final uid = await _room.currentUid();
    if (_disposed) return;
    if (uid == null || uid <= 0) {
      _uid = null;
      _tracks = const [];
      notifyListeners();
      return;
    }
    if (_uid == uid) return;
    final pending = _loadTask;
    if (pending != null) {
      await pending;
      return load();
    }
    final task = _load(uid);
    _loadTask = task;
    try {
      await task;
    } finally {
      if (identical(_loadTask, task)) _loadTask = null;
    }
  }

  Future<void> _load(int uid) async {
    final epoch = _authEpoch;
    final tracks = await _library.load(uid);
    if (_disposed || epoch != _authEpoch || uid != await _room.currentUid()) {
      return;
    }
    _uid = uid;
    _tracks = List.unmodifiable(tracks);
    notifyListeners();
  }

  /// Discovers Android audio without importing files or acquiring the player.
  Future<RoomLocalMusicScanResult> scanLocalTracks({
    bool requestPermission = false,
  }) => _localMusic.scan(requestPermission: requestPermission);

  Future<void> openMusicSettings() => _localMusic.openSettings();

  Future<RoomMusicImportResult> addAudio({bool Function()? isCancelled}) =>
      _importMusic(
        (uid, cancelled) => _library.importAudio(uid, isCancelled: cancelled),
        isCancelled: isCancelled,
      );

  /// Copies selected audio into the current account's library without autoplay.
  Future<RoomMusicImportResult> addLocalTracks(
    List<RoomLocalMusicTrack> tracks, {
    bool Function()? isCancelled,
  }) => _importMusic(
    (uid, cancelled) =>
        _library.importLocal(uid, tracks, _localMusic, isCancelled: cancelled),
    isCancelled: isCancelled,
  );

  Future<void> remove(RoomMusicTrack track) {
    final epoch = _authEpoch;
    return _edit(() async {
      if (_disposed || epoch != _authEpoch) return;
      final uid = _uid;
      if (uid == null) return;
      final previous = _tracks;
      if (selected?.id == track.id) await _room.stopMusic();
      if (_disposed || epoch != _authEpoch || uid != _uid) return;
      final next = previous.where((item) => item.id != track.id).toList();
      await _library.save(uid, next);
      await _library.remove(uid, track);
      if (!_disposed && epoch == _authEpoch && uid == _uid) {
        _tracks = List.unmodifiable(next);
        notifyListeners();
      }
    });
  }

  Future<void> play(
    String roomId,
    RoomMusicTrack track, {
    bool force = false,
  }) async {
    final uid = _uid;
    final generation = _room.roomGeneration;
    final epoch = _playEpoch;
    if (uid == null || !isCurrentRoom(roomId)) {
      throw const NadyApiException(message: 'Room session ended');
    }
    _automaticError = null;
    final path = await _library.path(uid, track);
    if (epoch != _playEpoch ||
        !isCurrentRoom(roomId) ||
        generation != _room.roomGeneration) {
      throw const NadyApiException(message: 'Room session ended');
    }
    await _room.playMusic(
      roomId: roomId,
      path: path,
      title: track.name,
      force: force,
    );
  }

  Future<void> toggle(String roomId, {bool force = false}) async {
    switch (playback.status) {
      case RoomMusicPlayback.playing:
        await _room.pauseMusic(roomId);
      case RoomMusicPlayback.paused:
        await _room.resumeMusic(roomId);
      default:
        final track = selected ?? (_tracks.isEmpty ? null : _tracks.first);
        if (track == null) {
          throw const NadyApiException(message: 'The playlist is empty');
        }
        await play(roomId, track, force: force);
    }
  }

  Future<void> next(
    String roomId, {
    bool previous = false,
    bool automatic = false,
    bool force = false,
  }) async {
    if (_tracks.isEmpty) return;
    final index = _tracks.indexWhere((track) => track.id == selected?.id);
    final next = switch (_mode) {
      RoomMusicMode.single when automatic => index < 0 ? 0 : index,
      RoomMusicMode.shuffle =>
        _tracks.length == 1
            ? 0
            : (index + 1 + Random().nextInt(_tracks.length - 1)) %
                  _tracks.length,
      _ => (index + (previous ? -1 : 1)) % _tracks.length,
    };
    await play(roomId, _tracks[next], force: force);
  }

  void changeMode(RoomMusicMode mode) {
    _mode = mode;
    notifyListeners();
  }

  Future<void> stop() {
    _playEpoch++;
    return _room.stopMusic();
  }

  Future<void> seek(String roomId, int position) =>
      _room.seekMusic(roomId, position);
  Future<void> volume(String roomId, int volume) =>
      _room.setMusicVolume(roomId, volume);

  void _sync() {
    if (_disposed) return;
    if (_roomGeneration != _room.roomGeneration) {
      _roomGeneration = _room.roomGeneration;
      _automaticError = null;
    }
    if (playback.status == RoomMusicPlayback.failed) {
      _automaticError = playback.error;
    }
    if (playback.completed > _completed) {
      _completed = playback.completed;
      final roomId = _room.roomState.currentRoomId;
      if (roomId != null && isCurrentRoom(roomId)) {
        unawaited(_advance(roomId));
      }
    } else {
      _completed = playback.completed;
    }
    notifyListeners();
  }

  Future<void> _advance(String roomId) async {
    try {
      await next(roomId, automatic: true);
    } catch (error) {
      if (_disposed || !isCurrentRoom(roomId)) return;
      _automaticError = userFacingErrorMessage(error);
      notifyListeners();
    }
  }

  void _authChanged() {
    _authEpoch++;
    _playEpoch++;
    _uid = null;
    _tracks = const [];
    notifyListeners();
    unawaited(_reloadForAuth());
  }

  Future<void> _reloadForAuth() async {
    try {
      await load();
    } catch (error) {
      debugPrint('[RoomMusic] library reload failed: $error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _playEpoch++;
    _room.removeListener(_sync);
    _room.removeAuthListener(_authChanged);
    super.dispose();
  }
}
