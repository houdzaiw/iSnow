import 'dart:convert';

import '../../../../model/room_socket_message.dart';
import '../models/room_gift_event_models.dart';
import '../models/room_gift_models.dart';

enum RoomGiftEventKind { gift, finalCombo, stream, banner, lucky }

class RoomGiftEvent {
  const RoomGiftEvent({
    required this.kind,
    required this.key,
    required this.createdAt,
    required this.roomId,
    this.gift,
    this.publicMessage,
    this.banner,
    this.lucky,
    this.roomWeekVal,
    this.comboId = '',
  });

  final RoomGiftEventKind kind;
  final String key, roomId, comboId;
  final DateTime createdAt;
  final RoomScreenGiftMsg? gift;
  final RoomGiftPublicMessage? publicMessage;
  final RoomGiftBanner? banner;
  final RoomLuckyGiftResult? lucky;
  final int? roomWeekVal;
}

class RoomGiftEventParser {
  static const events = {
    'roomScreenSendGiftComboEvent',
    'RoomSendGiftPublicScreenEvent',
    'RoomGiftStreamUpdateEvent',
    'RoomGiftSendBannerEvent',
    'RoomLuckGiftSendBannerEvent',
    'LuckyGiftSendMsg',
    'LuckyGiftSmallMultiple',
    'LuckyGiftBigMultiple',
    'LuckyGiftJackpotSuperMode',
  };

  /// A global channel is accepted only with an explicit matching room ID.
  RoomGiftEvent? parse(RoomSocketMessage message, String roomId, DateTime now) {
    if (!events.contains(message.event)) return null;
    final outer = _decodeMap(message.payload);
    final nested = _decodeMap(outer['msg']);
    final json = nested.isEmpty ? outer : {...outer, ...nested};
    final payloadRoomId = '${json['roomId'] ?? message.raw['roomId'] ?? ''}';
    if (payloadRoomId.isNotEmpty && payloadRoomId != roomId) {
      throw const FormatException('Gift roomId mismatch');
    }
    if (message.channel != 'room:$roomId' &&
        !(message.channel == 'room' && payloadRoomId == roomId)) {
      return null;
    }
    final rawTime = giftInt(message.timestamp ?? json['timestamp']);
    final createdAt = rawTime <= 0
        ? now
        : DateTime.fromMillisecondsSinceEpoch(
            rawTime < 1000000000000 ? rawTime * 1000 : rawTime,
          );
    final comboId = '${json['comboId'] ?? json['newComboId'] ?? ''}';
    final key = message.msgId?.isNotEmpty == true
        ? message.msgId!
        : '${message.event}:${jsonEncode(json)}';
    final event = message.event;
    if (event == 'RoomGiftStreamUpdateEvent') {
      if (!json.containsKey('roomWeekVal')) {
        throw const FormatException('Missing roomWeekVal');
      }
      return RoomGiftEvent(
        kind: RoomGiftEventKind.stream,
        key: key,
        createdAt: createdAt,
        roomId: roomId,
        roomWeekVal: giftInt(json['roomWeekVal']),
      );
    }
    if (event == 'RoomSendGiftPublicScreenEvent') {
      final giftId = giftInt(json['giftId']);
      if (giftId <= 0 || comboId.isEmpty) {
        throw const FormatException('Invalid combo end');
      }
      return RoomGiftEvent(
        kind: RoomGiftEventKind.finalCombo,
        key: key,
        createdAt: createdAt,
        roomId: roomId,
        comboId: comboId,
        publicMessage: RoomGiftPublicMessage(
          key: comboId,
          gift: RoomGift(
            id: giftId,
            name: '${json['giftName'] ?? ''}',
            icon: '${json['giftIcon'] ?? ''}',
            price: 0,
            isCombo: giftInt(json['isCombo']),
            tabId: 0,
          ),
          count: giftInt(json['giftNum']),
          targetLabel: '${giftInt(json['receivingGiftsPeople'])} recipients',
          sender: RoomGiftUser.fromJson(giftMap(json['userInfo'])),
          isFinal: true,
          winAmount: giftInt(json['winAmount']),
          createdAt: createdAt,
        ),
      );
    }
    if (event == 'roomScreenSendGiftComboEvent' ||
        event == 'LuckyGiftSendMsg') {
      final gift = RoomScreenGiftMsg.fromJson(json);
      if (gift.gift.id <= 0 || gift.uid <= 0 || gift.displayCount <= 0) {
        throw const FormatException('Missing gift, sender or quantity');
      }
      return RoomGiftEvent(
        kind: RoomGiftEventKind.gift,
        key: key,
        createdAt: createdAt,
        roomId: roomId,
        comboId: gift.comboId,
        gift: gift,
      );
    }
    if (event == 'RoomGiftSendBannerEvent' ||
        event == 'RoomLuckGiftSendBannerEvent') {
      final lucky = event == 'RoomLuckGiftSendBannerEvent';
      final user = RoomGiftUser.fromJson(
        giftMap(json[lucky ? 'userBaseInfo' : 'sendUserInfo']),
      );
      final rawGift = lucky
          ? giftMap(json['giftInfo'])
          : <String, dynamic>{
              'id': json['giftId'],
              'name': json['giftName'],
              'icon': json['giftPic'],
            };
      final gift = RoomGift.fromJson(rawGift, fallbackTabId: 0);
      if (user.uid <= 0 || gift.id <= 0) {
        throw const FormatException('Invalid gift banner');
      }
      return RoomGiftEvent(
        kind: RoomGiftEventKind.banner,
        key: key,
        createdAt: createdAt,
        roomId: roomId,
        comboId: comboId,
        banner: RoomGiftBanner(
          key: comboId.isEmpty ? key : comboId,
          sender: user,
          gift: gift,
          roomId: roomId,
          recipient: json['reviceUserInfo'] == null
              ? null
              : RoomGiftUser.fromJson(giftMap(json['reviceUserInfo'])),
          count: giftInt(json['giftNum'], 1),
          multiplier: double.tryParse('${json['multiply']}') ?? 0,
          amount: giftInt(json['amount']),
          effectUrl: '${json[lucky ? 'effectUrl' : 'bannerEffectUrl'] ?? ''}',
          upperEffect: '${json['upperEffect'] ?? ''}',
          contents: giftMap(
            json['bannerContentObj'],
          ).map((key, value) => MapEntry(key, '$value')),
        ),
      );
    }
    final userJson = giftMap(json['userBaseInfo']);
    final user = RoomGiftUser.fromJson(userJson.isEmpty ? json : userJson);
    if (user.uid <= 0) throw const FormatException('Invalid lucky sender');
    return RoomGiftEvent(
      kind: RoomGiftEventKind.lucky,
      key: key,
      createdAt: createdAt,
      roomId: roomId,
      comboId: comboId,
      lucky: RoomLuckyGiftResult(
        key: comboId.isEmpty ? key : comboId,
        sender: user,
        amount: giftInt(json['amount'] ?? json['awardAmount']),
        multiplier: double.tryParse('${json['multiply']}') ?? 0,
        isJackpot: event == 'LuckyGiftJackpotSuperMode',
      ),
    );
  }

  Map<String, dynamic> _decodeMap(Object? value) {
    if (value is String) {
      try {
        return giftMap(jsonDecode(value));
      } on FormatException {
        throw const FormatException('Invalid gift JSON');
      }
    }
    return giftMap(value);
  }
}
