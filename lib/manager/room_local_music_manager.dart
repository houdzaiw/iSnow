import 'dart:io';

import 'package:room_music_scan/room_music_scan.dart';

import '../classes/room/music/room_local_music_track.dart';

/// Android system catalog transport; never starts a player or opens UI.
class RoomLocalMusicManager {
  RoomLocalMusicManager({RoomMusicScan? scanner, bool? supported})
    : _scanner = scanner ?? const RoomMusicScan(),
      supported = supported ?? Platform.isAndroid;

  final RoomMusicScan _scanner;
  final bool supported;

  Future<RoomLocalMusicScanResult> scan({
    bool requestPermission = false,
  }) async {
    if (!supported) {
      return const RoomLocalMusicScanResult(RoomMusicPermission.denied);
    }
    final status = await _scanner.permission(request: requestPermission);
    final permission = RoomMusicPermission.values.firstWhere(
      (value) => value.name == status,
      orElse: () => RoomMusicPermission.denied,
    );
    if (permission != RoomMusicPermission.granted) {
      return RoomLocalMusicScanResult(permission);
    }
    final rows = await _scanner.scan();
    final tracks = <String, RoomLocalMusicTrack>{};
    for (final row in rows) {
      final track = RoomLocalMusicTrack.fromJson(row);
      tracks.putIfAbsent(track.id, () => track);
    }
    return RoomLocalMusicScanResult(
      permission,
      List.unmodifiable(tracks.values),
    );
  }

  Future<void> openSettings() => _scanner.openSettings();

  /// Returns an owned temporary file; the importer must delete it after use.
  Future<String> exportAudio(RoomLocalMusicTrack track) =>
      _scanner.exportAudio(uri: track.uri, name: track.name);
}
