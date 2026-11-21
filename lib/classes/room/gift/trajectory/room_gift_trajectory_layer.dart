import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/app_theme.dart';
import '../../../../manager/room_animation_performance_manager.dart';
import '../event/room_gift_event_manager.dart';
import '../views/room_gift_image.dart';
import 'room_gift_seat_registry.dart';
import 'room_gift_trajectory_task.dart';

class RoomGiftTrajectoryLayer extends StatefulWidget {
  const RoomGiftTrajectoryLayer({
    super.key,
    required this.events,
    required this.registry,
    required this.onConsumed,
    this.quality = RoomAnimationQuality.full,
    this.maxPerTarget = 8,
  });
  final List<RoomGiftEffectTask> events;
  final RoomGiftSeatRegistry registry;
  final ValueChanged<String> onConsumed;
  final RoomAnimationQuality quality;
  final int maxPerTarget;
  @override
  State<RoomGiftTrajectoryLayer> createState() =>
      _RoomGiftTrajectoryLayerState();
}

class _RoomGiftTrajectoryLayerState extends State<RoomGiftTrajectoryLayer> {
  final Map<String, List<RoomGiftTrajectoryTask>> _bursts = {};
  final Set<String> _seen = {};
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(RoomGiftTrajectoryLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final viewport = widget.registry.viewport;
      if (viewport == null || viewport.isEmpty) return;
      final valid = widget.events.map((event) => event.key).toSet();
      _bursts.removeWhere((key, _) => !valid.contains(key));
      if (_bursts.isNotEmpty) {
        setState(() {});
        return;
      }
      for (final event in widget.events.take(1)) {
        if (!_seen.add(event.key)) continue;
        if (_seen.length > 300) _seen.remove(_seen.first);
        final tasks = RoomGiftTrajectoryTask.fromEvent(
          event,
          widget.registry.coordinate,
          viewport: viewport,
          quality: widget.quality,
          maxPerTarget: widget.maxPerTarget,
        );
        if (tasks.isNotEmpty) _bursts[event.key] = tasks;
        if (tasks.isEmpty) widget.onConsumed(event.key);
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: [
        for (final burst in _bursts.entries)
          _GiftBurst(
            key: ValueKey(burst.key),
            tasks: burst.value,
            registry: widget.registry,
            maxCopies: switch (widget.quality) {
              RoomAnimationQuality.full => widget.maxPerTarget.clamp(1, 9999),
              RoomAnimationQuality.reduced => widget.maxPerTarget.clamp(1, 3),
              RoomAnimationQuality.minimum => 1,
            },
            onEnd: () {
              if (mounted) {
                setState(() => _bursts.remove(burst.key));
                widget.onConsumed(burst.key);
              }
            },
          ),
      ],
    ),
  );
}

class _GiftBurst extends StatefulWidget {
  const _GiftBurst({
    required super.key,
    required this.tasks,
    required this.registry,
    required this.onEnd,
    required this.maxCopies,
  });
  final List<RoomGiftTrajectoryTask> tasks;
  final RoomGiftSeatRegistry registry;
  final VoidCallback onEnd;
  final int maxCopies;
  @override
  State<_GiftBurst> createState() => _GiftBurstState();
}

class _GiftBurstState extends State<_GiftBurst>
    with SingleTickerProviderStateMixin {
  // Match Nady's central elastic reveal and its delayed ~666ms flight.
  late final _controller = AnimationController(
    vsync: this,
    duration:
        AppMotion.roomGiftBurst +
        widget.tasks.map((task) => task.delay).reduce((a, b) => a > b ? a : b),
  );
  bool _ended = false;
  final _paths = <String, _FlightPath>{};

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _end();
    });
    _controller.forward();
  }

  void _end() {
    if (_ended) return;
    _ended = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onEnd();
    });
  }

  bool _matches(RoomGiftTrajectoryTask task) {
    if (task.isScatter) return true;
    final current = widget.registry.coordinate(task.target.uid);
    return current != null;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final elapsed = _controller.value * _controller.duration!.inMilliseconds;
      final first = widget.tasks.first;
      final active = widget.tasks
          .where((task) => task.copyIndex < widget.maxCopies && _matches(task))
          .toList();
      if (active.isEmpty) {
        _end();
        return const SizedBox.shrink();
      }
      final lastDelay = active
          .map((task) => task.delay.inMilliseconds)
          .reduce((a, b) => a > b ? a : b);
      if (elapsed >= AppMotion.roomGiftBurst.inMilliseconds + lastDelay) {
        _end();
        return const SizedBox.shrink();
      }
      if (elapsed < AppMotion.roomGiftReveal.inMilliseconds) {
        final scale =
            AppSpacing.giftTrajectoryInitialScale +
            (1 - AppSpacing.giftTrajectoryInitialScale) *
                AppMotion.roomGiftRevealCurve.transform(
                  elapsed / AppMotion.roomGiftRevealScale.inMilliseconds,
                );
        final size = AppSpacing.giftTrajectoryCenterSize.r;
        return Stack(
          children: [
            Positioned(
              left: first.source.dx - size / 2,
              top: first.source.dy - size / 2,
              child: Transform.scale(
                scale: scale,
                child: RoomGiftImage(
                  key: ValueKey('gift-reveal-${first.event.key}'),
                  source: first.event.message.gift.icon,
                  size: size,
                ),
              ),
            ),
          ],
        );
      }
      final size = AppSpacing.giftTrajectoryIconSize.r;
      final positions = <String, Offset>{};
      final progress = <String, double>{};
      for (final task in active) {
        final raw =
            (elapsed -
                AppMotion.roomGiftReveal.inMilliseconds -
                task.delay.inMilliseconds) /
            AppMotion.roomGiftFlight.inMilliseconds;
        if (raw < 0 || raw > 1) continue;
        final t = AppMotion.roomGiftFlightCurve.transform(raw.clamp(0.0, 1.0));
        final target = task.isScatter
            ? task.target.offset
            : widget.registry.coordinate(task.target.uid)!.offset;
        final path = _paths.putIfAbsent(
          task.key,
          () => _FlightPath(task.source, target),
        );
        positions[task.key] = path.position(t, target);
        progress[task.key] = t;
      }
      return Stack(
        children: [
          for (final task in active)
            if (positions.containsKey(task.key))
              Positioned(
                left: positions[task.key]!.dx - size / 2,
                top: positions[task.key]!.dy - size / 2,
                child: Opacity(
                  opacity: task.isScatter ? 1 - progress[task.key]! : 1,
                  child: RoomGiftImage(
                    key: ValueKey('gift-flight-${task.key}'),
                    source: task.event.message.gift.icon,
                    size: size,
                  ),
                ),
              ),
        ],
      );
    },
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _FlightPath {
  _FlightPath(this.start, this.target) : last = start;
  Offset start, target, last;
  double changedAt = 0;
  Offset position(double t, Offset destination) {
    if (target != destination) {
      start = last;
      target = destination;
      changedAt = t;
    }
    final local = changedAt >= 1
        ? 1.0
        : ((t - changedAt) / (1 - changedAt)).clamp(0.0, 1.0);
    return last = Offset.lerp(start, target, local)!;
  }
}
