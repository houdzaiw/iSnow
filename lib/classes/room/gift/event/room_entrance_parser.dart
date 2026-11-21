import '../../../../model/room_socket_message.dart';
import '../models/room_entrance.dart';
import '../models/room_gift_event_models.dart';
import '../models/room_gift_models.dart';
import 'room_gift_event_parser.dart';

class RoomEntranceParser {
  RoomEntrance? parse(RoomSocketMessage message, String roomId, DateTime now) {
    if (message.event != 'RoomUserPropInfoEvent' ||
        !['room:$roomId', 'room', 'global'].contains(message.channel)) {
      return null;
    }
    final data = RoomGiftEventParser().decodePayload(message.payload);
    if ('${data['roomId'] ?? ''}' != roomId) return null;
    final time =
        message.receivedAt ??
        (message.timestamp == null
            ? now
            : DateTime.fromMillisecondsSinceEpoch(
                message.timestamp! < 1000000000000
                    ? message.timestamp! * 1000
                    : message.timestamp!,
              ));
    if (!now.isBefore(time.add(const Duration(seconds: 30)))) return null;
    final rawUser = giftMap(data['userBaseInfo']);
    final user = RoomGiftUser.fromJson(rawUser);
    if (user.uid <= 0) return null;
    final vehicle = giftMap(rawUser['vehicle']);
    final track = giftMap(rawUser['specialEffects']);
    final vehicleUrl = '${vehicle['animationUrl'] ?? ''}';
    final trackUrl = '${track['animationUrl'] ?? ''}';
    if (vehicleUrl.isEmpty && trackUrl.isEmpty) return null;
    return RoomEntrance(
      key: 'entrance:${message.msgId ?? data.toString()}',
      createdAt: time,
      user: user,
      trackUrl: trackUrl,
      vehicle: vehicleUrl.isEmpty
          ? null
          : RoomGift(
              id: -1,
              name: user.name,
              icon: user.avatar,
              price: 0,
              isCombo: 0,
              tabId: -1,
              animationUrl: vehicleUrl,
              animationType: giftInt(vehicle['animationType']),
              direction: giftInt(vehicle['direction'], 1),
            ),
    );
  }
}
