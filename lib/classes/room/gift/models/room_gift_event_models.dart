import 'room_gift_models.dart';

class RoomGiftUser {
  const RoomGiftUser({required this.uid, this.name = '', this.avatar = ''});

  final int uid;
  final String name;
  final String avatar;

  factory RoomGiftUser.fromJson(Map<String, dynamic> json) => RoomGiftUser(
    uid: giftInt(json['uid']),
    name: '${json['nick'] ?? json['nickname'] ?? json['userName'] ?? ''}',
    avatar: '${json['avatar'] ?? json['headUrl'] ?? ''}',
  );
}

/// Nady's broadcast contract, independent of HTTP send acknowledgements.
class RoomScreenGiftMsg {
  const RoomScreenGiftMsg({
    required this.gift,
    required this.uid,
    required this.userInfo,
    this.count = 0,
    this.giftCount = 0,
    this.comboCount = 1,
    this.giftSource = 1,
    this.sendType = 1,
    this.gold = 0,
    this.uids = const [],
    this.event = '',
    this.targetUsers,
    this.isHideLuckyGift = false,
    this.isLuckyGift = false,
    this.playWinGoldCount = false,
    this.totalCoinCount = 0,
    this.totalGiftCount = 0,
    this.comboId = '',
    this.roomId = '',
    this.isJackpot = false,
  });

  final RoomGift gift;
  final int uid;
  final RoomGiftUser userInfo;
  final int count, giftCount, comboCount, giftSource, sendType, gold;
  final List<int> uids;
  final String event, comboId, roomId;
  final RoomGiftUser? targetUsers;
  final bool isHideLuckyGift, isLuckyGift, playWinGoldCount, isJackpot;
  final int totalCoinCount, totalGiftCount;

  String get comboKey => '$uid:${gift.id}:$giftSource:$comboId';
  int get displayCount => totalGiftCount > 0
      ? totalGiftCount
      : (count > 0 ? count : giftCount * comboCount);
  List<int> get targetUids => uids.isNotEmpty
      ? uids
      : targetUsers == null
      ? const []
      : [targetUsers!.uid];
  String get targetLabel => switch (sendType) {
    2 => 'All mic',
    3 => 'All room',
    4 => 'Room',
    _ =>
      targetUsers?.name.isNotEmpty == true
          ? targetUsers!.name
          : '${targetUids.length} recipients',
  };

  factory RoomScreenGiftMsg.fromJson(Map<String, dynamic> json) {
    final user = RoomGiftUser.fromJson(giftMap(json['userInfo']));
    final target = giftMap(json['targetUsers']);
    final source = giftInt(json['giftSource'], 1);
    return RoomScreenGiftMsg(
      gift: RoomGift.fromJson(
        giftMap(json['gift']),
        fallbackTabId: source == 2 ? RoomGiftTab.backpackId : 0,
      ),
      uid: giftInt(json['uid'], user.uid),
      userInfo: user,
      count: giftInt(json['count']),
      giftCount: giftInt(json['giftCount']),
      comboCount: giftInt(json['comboCount'], 1),
      giftSource: source,
      sendType: giftInt(json['sendType'], 1),
      gold: giftInt(json['gold']),
      uids: json['uids'] is List
          ? (json['uids'] as List)
                .map(giftInt)
                .where((uid) => uid > 0)
                .toSet()
                .toList()
          : const [],
      event: '${json['event'] ?? ''}',
      targetUsers: target.isEmpty ? null : RoomGiftUser.fromJson(target),
      isHideLuckyGift: giftBool(json['isHideLuckyGift']),
      isLuckyGift: giftBool(json['isLuckyGift']),
      playWinGoldCount: giftBool(json['playWinGoldCount']),
      totalCoinCount: giftInt(json['totalCoinCount']),
      totalGiftCount: giftInt(json['totalGiftCount']),
      comboId: '${json['comboId'] ?? json['newComboId'] ?? ''}',
      roomId: '${json['roomId'] ?? ''}',
      isJackpot: giftBool(json['isJackpot']),
    );
  }
}

class RoomGiftPublicMessage {
  const RoomGiftPublicMessage({
    required this.key,
    required this.gift,
    required this.count,
    required this.targetLabel,
    required this.createdAt,
    this.sender = const RoomGiftUser(uid: 0),
    this.isFinal = false,
    this.winAmount = 0,
  });

  final String key;
  final RoomGift gift;
  final RoomGiftUser sender;
  final int count, winAmount;
  final String targetLabel;
  final DateTime createdAt;
  final bool isFinal;
}

class RoomGiftBanner {
  const RoomGiftBanner({
    required this.key,
    required this.sender,
    required this.gift,
    required this.roomId,
    this.recipient,
    this.count = 1,
    this.multiplier = 0,
    this.amount = 0,
    this.effectUrl = '',
    this.upperEffect = '',
    this.contents = const {},
  });

  final String key, roomId, effectUrl, upperEffect;
  final RoomGiftUser sender;
  final RoomGiftUser? recipient;
  final RoomGift gift;
  final int count, amount;
  final double multiplier;
  final Map<String, String> contents;
  RoomGift get effectGift => gift.copyWith(animationUrl: effectUrl);
}

class RoomLuckyGiftResult {
  const RoomLuckyGiftResult({
    required this.key,
    required this.sender,
    required this.amount,
    this.multiplier = 0,
    this.isJackpot = false,
    this.giftCount = 0,
    this.showCoins = true,
  });

  final String key;
  final RoomGiftUser sender;
  final int amount, giftCount;
  final double multiplier;
  final bool isJackpot, showCoins;
}

int giftInt(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
bool giftBool(Object? value) => value == true || value == 1 || value == 'true';
Map<String, dynamic> giftMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
