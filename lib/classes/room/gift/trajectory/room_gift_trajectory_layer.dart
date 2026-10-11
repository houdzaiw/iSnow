import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/app_theme.dart';
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
  });
  final List<RoomGiftEffectTask> events;
  final RoomGiftSeatRegistry registry;
  final ValueChanged<String> onConsumed;
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
      for (final event in widget.events) {
        if (!_seen.add(event.key)) continue;
        if (_seen.length > 300) _seen.remove(_seen.first);
        final capacity =
            32 -
            _bursts.values.fold<int>(0, (count, tasks) => count + tasks.length);
        final tasks = RoomGiftTrajectoryTask.fromEvent(
          event,
          widget.registry.coordinate,
          viewport: viewport,
        ).take(capacity).toList();
        if (tasks.isNotEmpty) _bursts[event.key] = tasks;
        widget.onConsumed(event.key);
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
            onEnd: () {
              if (mounted) setState(() => _bursts.remove(burst.key));
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
  });
  final List<RoomGiftTrajectoryTask> tasks;
  final RoomGiftSeatRegistry registry;
  final VoidCallback onEnd;
  @override
  State<_GiftBurst> createState() => _GiftBurstState();
}

class _GiftBurstState extends State<_GiftBurst>
    with SingleTickerProviderStateMixin {
  // Match Nady's central elastic reveal and its delayed ~666ms flight.
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.roomGiftBurst,
  );
  bool _ended = false;

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
    return current != null &&
        current.position == task.target.position &&
        (current.offset - task.target.offset).distance < AppSpacing.xs;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final elapsed =
          _controller.value * AppMotion.roomGiftBurst.inMilliseconds;
      final first = widget.tasks.first;
      final active = widget.tasks.where(_matches).toList();
      if (active.isEmpty) {
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
      final t = AppMotion.roomGiftFlightCurve.transform(
        ((elapsed - AppMotion.roomGiftReveal.inMilliseconds) /
                AppMotion.roomGiftFlight.inMilliseconds)
            .clamp(0.0, 1.0),
      );
      final size = AppSpacing.giftTrajectoryIconSize.r;
      return Stack(
        children: [
          for (final task in active)
            Positioned(
              left:
                  Offset.lerp(task.source, task.target.offset, t)!.dx -
                  size / 2,
              top:
                  Offset.lerp(task.source, task.target.offset, t)!.dy -
                  size / 2,
              child: Opacity(
                opacity: task.isScatter ? 1 - t : 1,
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
