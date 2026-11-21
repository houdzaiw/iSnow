import 'room_gift_event_models.dart';
import 'room_gift_models.dart';

class RoomEntrance {
  const RoomEntrance({
    required this.key,
    required this.createdAt,
    required this.user,
    this.trackUrl = '',
    this.vehicle,
  });
  final String key, trackUrl;
  final DateTime createdAt;
  final RoomGiftUser user;
  final RoomGift? vehicle;
  DateTime get deadline => createdAt.add(const Duration(seconds: 30));
}
