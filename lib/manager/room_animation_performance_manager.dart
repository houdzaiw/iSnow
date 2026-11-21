import 'dart:collection';

import 'package:flutter/scheduler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum RoomAnimationQuality { full, reduced, minimum }

/// Estimates dropped frames from engine timings, never from idle wall time.
class RoomAnimationPerformanceManager
    extends StateNotifier<RoomAnimationQuality> {
  RoomAnimationPerformanceManager({
    DateTime Function()? now,
    bool listen = true,
  }) : _now = now ?? DateTime.now,
       super(RoomAnimationQuality.full) {
    if (listen) SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _listening = listen;
  }
  final DateTime Function() _now;
  final Queue<({DateTime at, int occupied})> _samples = Queue();
  bool _listening = false;
  DateTime? _lastReport;
  int _recovery = 0;
  static const _interval = 16667;

  void _onTimings(List<FrameTiming> timings) {
    final now = _now();
    for (final frame in timings) {
      _samples.add((
        at: now,
        occupied:
            ((frame.totalSpan.inMicroseconds + _interval - 1) ~/ _interval)
                .clamp(1, 1000),
      ));
    }
    while (_samples.isNotEmpty &&
        now.difference(_samples.first.at) > const Duration(seconds: 10)) {
      _samples.removeFirst();
    }
    if (_samples.length < 30 ||
        _lastReport != null &&
            now.difference(_lastReport!) < const Duration(seconds: 1)) {
      return;
    }
    _lastReport = now;
    final occupied = _samples.fold<int>(0, (n, sample) => n + sample.occupied);
    sampleFps(60 * _samples.length / occupied);
  }

  void sampleFps(double fps) {
    if (!mounted || !fps.isFinite) return;
    final next = fps < 16
        ? RoomAnimationQuality.minimum
        : fps < 24
        ? RoomAnimationQuality.reduced
        : RoomAnimationQuality.full;
    if (next.index > state.index) {
      _recovery = 0;
      state = next;
    } else if (next.index < state.index &&
        fps >= (state == RoomAnimationQuality.minimum ? 20 : 28)) {
      if (++_recovery >= 3) {
        _recovery = 0;
        state = RoomAnimationQuality.values[state.index - 1];
      }
    } else {
      _recovery = 0;
    }
  }

  @override
  void dispose() {
    if (_listening) SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _samples.clear();
    super.dispose();
  }
}
