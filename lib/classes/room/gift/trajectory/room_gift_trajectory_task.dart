import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../theme/app_theme.dart';
import '../../../../manager/room_animation_performance_manager.dart';
import '../event/room_gift_event_manager.dart';
import 'room_gift_seat_registry.dart';

class RoomGiftTrajectoryTask {
  const RoomGiftTrajectoryTask({
    required this.key,
    required this.event,
    required this.source,
    required this.target,
    this.isScatter = false,
    this.copyIndex = 0,
  });

  final String key;
  final RoomGiftEffectTask event;
  final Offset source;
  final RoomGiftSeatCoordinate target;
  final bool isScatter;
  final int copyIndex;
  Duration get delay =>
      isScatter ? Duration.zero : Duration(milliseconds: copyIndex * 100);

  static List<RoomGiftTrajectoryTask> fromEvent(
    RoomGiftEffectTask event,
    RoomGiftSeatCoordinate? Function(int) coordinate, {
    required Size viewport,
    int maxPerTarget = 8,
    RoomAnimationQuality quality = RoomAnimationQuality.full,
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
      final cap = switch (quality) {
        RoomAnimationQuality.full => maxPerTarget.clamp(1, 9999),
        RoomAnimationQuality.reduced => maxPerTarget.clamp(1, 3),
        RoomAnimationQuality.minimum => 1,
      };
      final copies = event.message.giftCount.clamp(1, cap);
      return [
        for (var copy = 0; copy < copies; copy++)
          for (final target in targets)
            RoomGiftTrajectoryTask(
              key: '${event.key}:${target.uid}:$copy',
              event: event,
              source: center,
              target: target,
              copyIndex: copy,
            ),
      ];
    }
    // Off-mic recipients (including an empty room's owner) still receive
    // the central reveal followed by a bounded outward burst.
    final rays = switch (quality) {
      RoomAnimationQuality.full => maxPerTarget.clamp(1, 8),
      RoomAnimationQuality.reduced => maxPerTarget.clamp(1, 3),
      RoomAnimationQuality.minimum => 1,
    };
    return List.generate(rays, (index) {
      final angle = math.pi * 2 * index / rays;
      return RoomGiftTrajectoryTask(
        key: '${event.key}:scatter:$index',
        event: event,
        source: center,
        isScatter: true,
        copyIndex: index,
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
