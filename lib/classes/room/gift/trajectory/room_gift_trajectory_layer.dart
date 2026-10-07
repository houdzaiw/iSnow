import 'dart:math' as math;

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
  final Map<String, RoomGiftTrajectoryTask> _tasks = {};
  final Set<String> _seen = {};
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final event in widget.events) {
        if (!_seen.add(event.key)) continue;
        if (_seen.length > 300) _seen.remove(_seen.first);
        for (final task in RoomGiftTrajectoryTask.fromEvent(
          event,
          widget.registry.coordinate,
        )) {
          if (_tasks.length < 32) _tasks[task.key] = task;
        }
        widget.onConsumed(event.key);
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: [
        for (final task in _tasks.values)
          _FlyingGift(
            key: ValueKey(task.key),
            task: task,
            registry: widget.registry,
            onEnd: () {
              if (mounted) setState(() => _tasks.remove(task.key));
            },
          ),
      ],
    ),
  );
}

class _FlyingGift extends StatefulWidget {
  const _FlyingGift({
    super.key,
    required this.task,
    required this.registry,
    required this.onEnd,
  });
  final RoomGiftTrajectoryTask task;
  final RoomGiftSeatRegistry registry;
  final VoidCallback onEnd;
  @override
  State<_FlyingGift> createState() => _FlyingGiftState();
}

class _FlyingGiftState extends State<_FlyingGift>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
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

  bool _matches(RoomGiftSeatCoordinate original) {
    final current = widget.registry.coordinate(original.uid);
    return current != null &&
        current.position == original.position &&
        (current.offset - original.offset).distance < AppSpacing.xs;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final task = widget.task;
      if (!_matches(task.source) || !_matches(task.target)) {
        _end();
        return const SizedBox.shrink();
      }
      final t = Curves.easeInOutCubic.transform(_controller.value);
      final offset =
          Offset.lerp(task.source.offset, task.target.offset, t)! -
          Offset(
            0,
            math.sin(t * math.pi) * AppSpacing.giftTrajectoryArcHeight.h,
          );
      final size = AppSpacing.giftTrajectoryIconSize.r;
      return Positioned(
        left: offset.dx - size / 2,
        top: offset.dy - size / 2,
        child: Transform.scale(
          scale: 0.7 + math.sin(t * math.pi) * 0.3,
          child: RoomGiftImage(
            source: task.event.message.gift.icon,
            size: size,
          ),
        ),
      );
    },
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
