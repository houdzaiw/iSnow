import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../theme/app_theme.dart';
import '../event/room_gift_event_manager.dart';
import 'room_gift_seat_registry.dart';

class RoomGiftTrajectoryTask {
  const RoomGiftTrajectoryTask({
    required this.key,
    required this.event,
    required this.source,
    required this.target,
    this.isScatter = false,
  });

  final String key;
  final RoomGiftEffectTask event;
  final Offset source;
  final RoomGiftSeatCoordinate target;
  final bool isScatter;

  static List<RoomGiftTrajectoryTask> fromEvent(
    RoomGiftEffectTask event,
    RoomGiftSeatCoordinate? Function(int) coordinate, {
    required Size viewport,
  }) {
    final center = viewport.center(Offset.zero);
    final targets = event.message.targetUids
        .toSet()
        .map(coordinate)
        .whereType<RoomGiftSeatCoordinate>()
        .toList();
    if (targets.isNotEmpty &&
        event.message.sendType != 3 &&
        event.message.sendType != 4) {
      final copies = event.message.giftCount.clamp(1, 8);
      return [
        for (var copy = 0; copy < copies; copy++)
          for (final target in targets)
            RoomGiftTrajectoryTask(
              key: '${event.key}:${target.uid}:$copy',
              event: event,
              source: center,
              target: target,
            ),
      ].take(32).toList();
    }
    // Off-mic recipients (including an empty room's owner) still receive
    // the central reveal followed by a bounded outward burst.
    return List.generate(8, (index) {
      final angle = math.pi * 2 * index / 8;
      return RoomGiftTrajectoryTask(
        key: '${event.key}:scatter:$index',
        event: event,
        source: center,
        isScatter: true,
        target: RoomGiftSeatCoordinate(
          uid: 0,
          position: -1,
          offset:
              center +
              Offset(
                math.cos(angle) *
                    viewport.width *
                    AppSpacing.giftTrajectoryScatterWidthRatio,
                math.sin(angle) *
                    viewport.height *
                    AppSpacing.giftTrajectoryScatterHeightRatio,
              ),
        ),
      );
    });
  }
}
