import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Owns Android's audio foreground service, independently of RoomPage lifetime.
class RoomBackgroundAudioManager with WidgetsBindingObserver {
  RoomBackgroundAudioManager._()
    : _isAndroid = Platform.isAndroid,
      _startNative = _startService,
      _stopNative = _stopService,
      _foreground = _appIsForeground {
    if (_isAndroid) WidgetsBinding.instance.addObserver(this);
  }

  @visibleForTesting
  RoomBackgroundAudioManager.forTesting({
    required Future<bool> Function(bool) start,
    required Future<void> Function() stop,
    required bool Function() foreground,
  }) : _isAndroid = true,
       _startNative = start,
       _stopNative = stop,
       _foreground = foreground;

  static final instance = RoomBackgroundAudioManager._();
  static const _channel = MethodChannel('isnow/room_audio');
  final bool _isAndroid;
  final Future<bool> Function(bool) _startNative;
  final Future<void> Function() _stopNative;
  final bool Function() _foreground;
  Future<void> _pending = Future<void>.value();
  bool _wanted = false;
  bool _microphone = false;
  bool _running = false;
  bool _startAttempted = false;
  bool? _lastRequestedMicrophone;

  Future<void> start({required bool useMicrophone}) {
    _wanted = true;
    _microphone = useMicrophone;
    return _enqueue();
  }

  Future<void> stop() {
    _wanted = false;
    return _enqueue();
  }

  Future<void> _enqueue() {
    _pending = _pending.then((_) => _sync()).catchError((Object error) {
      debugPrint('[RoomAudio] Foreground service failed: $error');
    });
    return _pending;
  }

  Future<void> _sync() async {
    if (!_isAndroid) return;
    if (!_wanted) {
      if (!_running && !_startAttempted) return;
      try {
        await _stopNative().timeout(const Duration(seconds: 5));
      } finally {
        _running = false;
        _startAttempted = false;
        _lastRequestedMicrophone = null;
      }
      return;
    }
    // Android 14+ microphone services must be started while the app is visible.
    if (!_foreground()) return;
    if (_running && _lastRequestedMicrophone == _microphone) return;
    _startAttempted = true;
    final microphone = _microphone;
    await _startNative(microphone).timeout(const Duration(seconds: 5));
    _lastRequestedMicrophone = microphone;
    _running = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wanted) {
      _lastRequestedMicrophone = null;
      unawaited(_enqueue());
    }
  }

  static bool _appIsForeground() =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  static Future<bool> _startService(bool microphone) async =>
      await _channel.invokeMethod<bool>('start', {'microphone': microphone}) ??
      false;

  static Future<void> _stopService() => _channel.invokeMethod<void>('stop');
}
