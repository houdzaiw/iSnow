import 'dart:convert';

import '../../../../model/room_socket_message.dart';
import '../../../../theme/app_theme.dart';
import '../models/room_gift_effect_task.dart';
import '../models/room_gift_event_models.dart';
import '../models/room_gift_models.dart';

/// Only protocol-confirmed visual fields become full-screen tasks.
class RoomFullscreenEventParser {
  static const events = {'RoomBigRocketPrizeEvent'};

  List<RoomGiftEffectTask> parse(
    RoomSocketMessage event,
    String roomId,
    DateTime now, {
    String? countryCode,
  }) {
    if (!events.contains(event.event)) return const [];
    if (!['room:$roomId', 'room', 'global'].contains(event.channel)) {
      return const [];
    }
    final outer = _map(event.payload);
    final nested = _map(outer['msg']);
    final data = nested.isEmpty ? outer : nested;
    final payloadRoom = '${data['roomId'] ?? outer['roomId'] ?? ''}';
    if (payloadRoom.isNotEmpty && payloadRoom != roomId) return const [];
    final scoped = event.channel == 'room:$roomId';
    if (!scoped && payloadRoom != roomId) return const [];
    final timestamp = event.timestamp;
    final createdAt =
        event.receivedAt ??
        (timestamp == null
            ? now
            : DateTime.fromMillisecondsSinceEpoch(
                timestamp < 1000000000000 ? timestamp * 1000 : timestamp,
              ));
    if (now.difference(createdAt) > const Duration(seconds: 10)) {
      return const [];
    }
    final key = '${event.event}:${event.msgId ?? jsonEncode(data)}';
    final countries = data['countryCodes'];
    if (countryCode?.isNotEmpty == true &&
        countries is List &&
        countries.isNotEmpty &&
        !countries.any(
          (value) => '$value'.toUpperCase() == countryCode!.toUpperCase(),
        )) {
      return const [];
    }
    final winners = data['winnerList'];
    final mvp = winners is List
        ? winners
              .map(_map)
              .where((user) => giftInt(user['role']) == 2)
              .firstOrNull
        : null;
    final user = RoomGiftUser.fromJson(mvp ?? const {});
    final sources = [
      (
        'prize',
        <String, dynamic>{
          'animationUrl': AppAssets
              .roomGiftRocketEffects[giftInt(data['level'], 1).clamp(1, 6) - 1],
        },
      ),
    ];
    return [
      for (final (name, source) in sources)
        if ('${source['animationUrl'] ?? ''}'.isNotEmpty)
          RoomGiftEffectTask(
            key: '$key:$name',
            createdAt: createdAt,
            kind: RoomGiftEffectKind.prize,
            message: RoomScreenGiftMsg(
              uid: user.uid,
              userInfo: user,
              roomId: roomId,
              giftCount: 1,
              gift: RoomGift(
                id: -1,
                tabId: -1,
                name: user.name,
                icon: user.avatar,
                price: 0,
                isCombo: 0,
                animationUrl: '${source['animationUrl']}',
                animationType: giftInt(source['animationType']),
                direction: giftInt(source['direction'], 1),
              ),
            ),
          ),
    ];
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is String) {
      try {
        return giftMap(jsonDecode(value));
      } on FormatException {
        return const {};
      }
    }
    return giftMap(value);
  }
}
