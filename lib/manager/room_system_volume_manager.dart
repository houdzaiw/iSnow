import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:volume_controller/volume_controller.dart';

final roomSystemVolumeManagerProvider = Provider<RoomSystemVolumeManager>(
  (ref) => RoomSystemVolumeManager.instance,
);

/// Owns the plugin's single native observer and coalesces media-volume writes.
class RoomSystemVolumeManager {
  RoomSystemVolumeManager({
    Future<double> Function()? read,
    Future<void> Function(double)? write,
    Stream<double> Function()? observe,
  }) : _read = read ?? VolumeController.instance.getVolume,
       _write = write ?? _writeNative,
       _observe = observe ?? _observeNative {
    _changes = StreamController<double>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  static final instance = RoomSystemVolumeManager();
  final Future<double> Function() _read;
  final Future<void> Function(double) _write;
  final Stream<double> Function() _observe;
  late final StreamController<double> _changes;
  StreamSubscription<double>? _subscription;
  Future<void> _observerQueue = Future<void>.value();
  Future<void>? _writeTask;
  double? _pending;
  int _epoch = 0;
  bool _disposed = false;

  Stream<double> get changes => _changes.stream;

  static Future<void> _writeNative(double value) async {
    VolumeController.instance.showSystemUI = false;
    await VolumeController.instance.setVolume(value);
  }

  static Stream<double> _observeNative() {
    late StreamController<double> controller;
    controller = StreamController<double>(
      onListen: () {
        VolumeController.instance
            .addListener(controller.add, fetchInitialVolume: false)
            .onError(controller.addError);
      },
      onCancel: VolumeController.instance.removeListener,
    );
    return controller.stream;
  }

  void _start() {
    final epoch = ++_epoch;
    _observerQueue = _observerQueue.then((_) async {
      await _subscription?.cancel();
      _subscription = null;
      if (!_current(epoch)) return;
      try {
        var receivedEvent = false;
        _subscription = _observe().listen(
          (value) {
            receivedEvent = true;
            _publish(value, epoch);
          },
          onError: (Object error, StackTrace stack) {
            receivedEvent = true;
            if (_current(epoch)) _changes.addError(error, stack);
          },
        );
        unawaited(_readInitial(epoch, () => receivedEvent));
      } catch (error, stack) {
        if (_current(epoch)) _changes.addError(error, stack);
      }
    });
  }

  Future<void> _readInitial(int epoch, bool Function() receivedEvent) async {
    try {
      final value = await _read();
      if (!receivedEvent()) _publish(value, epoch);
    } catch (error, stack) {
      if (_current(epoch) && !receivedEvent()) _changes.addError(error, stack);
    }
  }

  bool _current(int epoch) =>
      !_disposed && _changes.hasListener && epoch == _epoch;

  void _publish(double value, int epoch) {
    if (_current(epoch) && value.isFinite) {
      _changes.add(value.clamp(0, 1));
    }
  }

  void _stop() {
    _epoch++;
    _pending = null;
    _observerQueue = _observerQueue.then((_) async {
      await _subscription?.cancel();
      _subscription = null;
    });
  }

  Future<void> setVolume(double value) {
    if (_disposed || !_changes.hasListener || !value.isFinite) {
      return Future<void>.value();
    }
    _pending = value.clamp(0, 1);
    return _writeTask ??= Future<void>.microtask(_drainWrites);
  }

  Future<void> _drainWrites() async {
    Object? lastError;
    StackTrace? lastStack;
    try {
      while (_pending != null && !_disposed) {
        final value = _pending!;
        final epoch = _epoch;
        _pending = null;
        try {
          await _write(value);
          lastError = null;
          if (_current(epoch) && _pending == null) {
            _publish(await _read(), epoch);
          }
        } catch (error, stack) {
          lastError = error;
          lastStack = stack;
        }
      }
      if (lastError != null) Error.throwWithStackTrace(lastError, lastStack!);
    } finally {
      _writeTask = null;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stop();
    await _observerQueue;
    await _changes.close();
  }
}
