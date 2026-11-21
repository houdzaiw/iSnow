import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class VapController {
  late final MethodChannel _methodChannel;
  final int viewId;
  final void Function(dynamic event, dynamic arguments)? onEvent;

  VapController({
    required this.viewId,
    this.onEvent,
  }) {
    _methodChannel = MethodChannel('flutter_vap_controller_$viewId');
    _methodChannel.setMethodCallHandler(_onMethodCallHandler);
  }

  Completer<void>? playCompleter;
  Timer? _watchdog;
  Future<void>? _stopTask;
  int _playEpoch = 0;
  bool _looping = false, _nativeActive = false, _disposed = false;

  Future<void> play(
      {required String source,
      required String playMethod,
      required String playArg,
      bool loop = false,
      List<FetchResourceModel> fetchResources = const []}) async {
    if (_disposed) throw StateError('VAP controller is disposed');
    if (_stopTask != null) await _stopTask;
    if (_nativeActive || playCompleter?.isCompleted == false) await stop();
    if (_disposed) throw StateError('VAP controller is disposed');
    _stopTask = null;
    final epoch = ++_playEpoch;
    final completer = Completer<void>();
    // Configuration can still be awaiting a platform reply when cancellation
    // or the watchdog settles the future. Keep that error observed until the
    // caller receives the same future below.
    completer.future.ignore();
    if (playCompleter?.isCompleted == false) playCompleter!.complete();
    playCompleter = completer;
    _looping = loop;
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 20), () {
      if (_disposed || epoch != _playEpoch || completer.isCompleted) return;
      _playEpoch++;
      _settle(TimeoutException('VAP playback timed out'));
    });
    try {
      /// 先设置融合动画参数再播放，不然会出现融合动画不起作用的问题
      await setFetchResources(fetchResources);
      if (!_isCurrent(epoch)) return completer.future;

      await setLoop(loop);
      if (!_isCurrent(epoch)) return completer.future;

      _nativeActive = true;
      await _methodChannel.invokeMethod(playMethod, {playArg: source});
    } catch (e, s) {
      if (_isCurrent(epoch)) _settle(e, s);
    }
    return completer.future;
  }

  bool _isCurrent(int epoch) => !_disposed && epoch == _playEpoch;

  void _settle([Object? error, StackTrace? stack]) {
    _watchdog?.cancel();
    _watchdog = null;
    final current = playCompleter;
    if (current == null || current.isCompleted) return;
    if (error == null) {
      current.complete();
    } else {
      current.completeError(error, stack);
    }
  }

  Future<void> playPath(String path,
      {bool loop = false, List<FetchResourceModel> fetchResources = const []}) {
    return play(
        source: path,
        playMethod: 'playPath',
        playArg: 'path',
        loop: loop,
        fetchResources: fetchResources);
  }

  Future<void> playAsset(String asset,
      {bool loop = false, List<FetchResourceModel> fetchResources = const []}) {
    return play(
        source: asset,
        playMethod: 'playAsset',
        playArg: 'asset',
        loop: loop,
        fetchResources: fetchResources);
  }

  Future<void> stop() {
    if (_stopTask != null) return _stopTask!;
    _playEpoch++;
    _watchdog?.cancel();
    _watchdog = null;
    return _stopTask = _stopNative(playCompleter);
  }

  Future<void> _stopNative(Completer<void>? playing) async {
    try {
      await _methodChannel.invokeMethod('stop');
      _nativeActive = false;
      if (playing?.isCompleted == false) playing!.complete();
    } catch (error, stack) {
      if (playing?.isCompleted == false) playing!.completeError(error, stack);
      rethrow;
    }
  }

  Future setFetchResources(List<FetchResourceModel> resources) {
    return _methodChannel.invokeMethod('setFetchResource',
        jsonEncode(resources.map((e) => e.toMap()).toList()));
  }

  Future setLoop(bool loop) {
    return _methodChannel.invokeMethod('setLoop', loop);
  }

  Future<void> setVideoMode(int mode) async {
    await _methodChannel.invokeMethod('setVideoMode', mode);
  }

  void dispose() {
    _disposed = true;
    _playEpoch++;
    _watchdog?.cancel();
    _methodChannel.setMethodCallHandler(null);
    if (playCompleter?.isCompleted == false) playCompleter?.complete();
  }

  Future _onMethodCallHandler(MethodCall call) async {
    if (_disposed) return;
    switch (call.method) {
      case "onStart":
        // A looping clip has no completion deadline after its native decoder
        // actually starts. An unstarted clip still has the startup watchdog.
        if (_looping) _watchdog?.cancel();
        break;
      case "onComplete":
        _settle();
        break;
      case "onFailed":
        _playEpoch++;
        _settle(call.arguments ?? StateError('VAP playback failed'));
        break;
      case "onDestroy":
        _nativeActive = false;
        break;
    }
    onEvent?.call(call.method, call.arguments);
  }
}

class FetchResourceModel {
  /// vap资源文件中预设的tag
  /// Preset tag in vap resource file
  final String tag;

  /// 图片本地路径或者文本字符串
  /// image local path or text
  final String resource;

  FetchResourceModel({required this.tag, required this.resource});

  Map<String, String> toMap() => {
        'tag': tag,
        'resource': resource,
      };
}
