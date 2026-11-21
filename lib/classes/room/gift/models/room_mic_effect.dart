import 'room_gift_models.dart';

/// A seat owns one temporary visual, shared by magic gifts and expressions.
class RoomMicEffect {
  const RoomMicEffect({
    required this.key,
    required this.uid,
    required this.position,
    required this.gift,
    required this.expiresAt,
  });
  final String key;
  final int uid, position;
  final RoomGift gift;
  final DateTime expiresAt;
}
