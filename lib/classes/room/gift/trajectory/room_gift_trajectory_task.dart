import '../event/room_gift_event_manager.dart';
import 'room_gift_seat_registry.dart';

class RoomGiftTrajectoryTask {
  const RoomGiftTrajectoryTask({
    required this.key,
    required this.event,
    required this.source,
    required this.target,
  });
  final String key;
  final RoomGiftEffectTask event;
  final RoomGiftSeatCoordinate source, target;

  static List<RoomGiftTrajectoryTask> fromEvent(
    RoomGiftEffectTask event,
    RoomGiftSeatCoordinate? Function(int) coordinate, {
    RoomGiftSeatCoordinate? Function(int)? sourceCoordinate,
  }) {
    final source = (sourceCoordinate ?? coordinate)(event.message.uid);
    if (source == null) return const [];
    return [
      for (final uid in event.message.targetUids.toSet())
        if (uid != source.uid && coordinate(uid) != null)
          RoomGiftTrajectoryTask(
            key: '${event.key}:$uid',
            event: event,
            source: source,
            target: coordinate(uid)!,
          ),
    ];
  }
}
