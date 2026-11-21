import 'room_gift_event_models.dart';

enum RoomGiftEffectKind { gift, entrance, prize, preview }

class RoomGiftEffectTask {
  const RoomGiftEffectTask({
    required this.key,
    required this.message,
    required this.createdAt,
    this.kind = RoomGiftEffectKind.gift,
    this.giftIcon,
  });

  final String key;
  final RoomScreenGiftMsg message;
  final DateTime createdAt;
  final RoomGiftEffectKind kind;
  final String? giftIcon;

  String get identity => message.comboId.isEmpty ? key : message.comboKey;
  int get value => message.gift.price * message.displayCount;
}
