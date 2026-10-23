import 'package:flutter/services.dart';

/// Android transport only; feature models and workflows live in the app.
class RoomMusicScan {
  const RoomMusicScan({
    MethodChannel channel = const MethodChannel('isnow/room_music_scan'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<String> permission({bool request = false}) async =>
      await _channel.invokeMethod<String>(
        request ? 'requestPermission' : 'permission',
      ) ??
      'denied';

  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');

  Future<List<Map<String, dynamic>>> scan({int minBytes = 102400}) async {
    final rows = await _channel.invokeListMethod<dynamic>('scan', {
      'minBytes': minBytes,
    });
    return [
      for (final row in rows ?? const []) Map<String, dynamic>.from(row as Map),
    ];
  }

  Future<String> exportAudio({
    required String uri,
    required String name,
  }) async {
    final path = await _channel.invokeMethod<String>('exportAudio', {
      'uri': uri,
      'name': name,
    });
    if (path == null) throw StateError('Audio export returned no file');
    return path;
  }
}
