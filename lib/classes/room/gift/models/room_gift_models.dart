enum RoomGiftTargetMode { allMic, allRoom, selected, room }

class RoomGiftAudience {
  const RoomGiftAudience({
    required this.isInRoom,
    required this.onlineCount,
    required this.recipients,
  });
  final bool isInRoom;
  final int onlineCount;
  final List<RoomGiftRecipient> recipients;
}

enum RoomGiftSendType {
  single(1),
  onMic(2),
  onRoom(3),
  room(4),
  multi(6);

  const RoomGiftSendType(this.value);

  final int value;
}

class RoomGiftRecipient {
  const RoomGiftRecipient({
    required this.uid,
    required this.nickname,
    required this.seatPosition,
    this.avatar,
  });

  final int uid;
  final String nickname;
  final int seatPosition;
  final String? avatar;
}

class RoomGift {
  const RoomGift({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.isCombo,
    required this.tabId,
    this.cornerMark = '',
    this.amount,
    this.userBackpackId,
    this.defaultGiftNum = 1,
    this.defaultGiftNumConfig,
    this.animationUrl,
    this.animationType,
    this.giftType,
    this.itemType,
    this.banner,
    this.jumpLink,
    this.direction,
    this.videoMode,
  });

  final int id;
  final String name;
  final String icon;
  final int price;
  final int isCombo;
  final int tabId;
  final String cornerMark;
  final int? amount;
  final int? userBackpackId;
  final int defaultGiftNum;
  final String? defaultGiftNumConfig;
  final String? animationUrl;
  final int? animationType;
  final int? giftType;
  final String? itemType;
  final String? banner;
  final String? jumpLink;
  final int? direction;
  final int? videoMode;

  bool get isBackpack => tabId == RoomGiftTab.backpackId;

  String get selectionKey => '$tabId:$id:${userBackpackId ?? 0}';

  // Value equality keeps animation-family providers stable across combo rebuilds.
  @override
  bool operator ==(Object other) =>
      other is RoomGift &&
      id == other.id &&
      tabId == other.tabId &&
      name == other.name &&
      icon == other.icon &&
      price == other.price &&
      isCombo == other.isCombo &&
      amount == other.amount &&
      userBackpackId == other.userBackpackId &&
      animationUrl == other.animationUrl &&
      animationType == other.animationType &&
      direction == other.direction &&
      videoMode == other.videoMode &&
      cornerMark == other.cornerMark &&
      defaultGiftNum == other.defaultGiftNum &&
      defaultGiftNumConfig == other.defaultGiftNumConfig &&
      giftType == other.giftType &&
      itemType == other.itemType &&
      banner == other.banner &&
      jumpLink == other.jumpLink;
  @override
  int get hashCode => Object.hashAll([
    id,
    tabId,
    name,
    icon,
    price,
    isCombo,
    amount,
    userBackpackId,
    animationUrl,
    animationType,
    direction,
    videoMode,
    cornerMark,
    defaultGiftNum,
    defaultGiftNumConfig,
    giftType,
    itemType,
    banner,
    jumpLink,
  ]);

  /// Preserves campaign parameters while adding the current app language.
  String resolvedCampaignUrl(String languageCode) {
    final uri = Uri.tryParse(jumpLink?.trim() ?? '');
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return '';
    }
    return uri
        .replace(
          queryParameters: {...uri.queryParameters, 'language': languageCode},
        )
        .toString();
  }

  List<int> get countOptions {
    final configured = (defaultGiftNumConfig ?? '')
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .where((value) => value > 0)
        .toSet()
        .toList(growable: false);
    return configured.isEmpty ? const [1, 8, 18, 888] : configured;
  }

  RoomGift copyWith({int? amount, String? animationUrl}) {
    return RoomGift(
      id: id,
      name: name,
      icon: icon,
      price: price,
      isCombo: isCombo,
      tabId: tabId,
      cornerMark: cornerMark,
      amount: amount ?? this.amount,
      userBackpackId: userBackpackId,
      defaultGiftNum: defaultGiftNum,
      defaultGiftNumConfig: defaultGiftNumConfig,
      animationUrl: animationUrl ?? this.animationUrl,
      animationType: animationType,
      giftType: giftType,
      itemType: itemType,
      banner: banner,
      jumpLink: jumpLink,
      direction: direction,
      videoMode: videoMode,
    );
  }

  factory RoomGift.fromJson(
    Map<String, dynamic> json, {
    required int fallbackTabId,
  }) {
    final defaultGiftNum = _nullableIntValue(json['defaultGiftNum']);
    return RoomGift(
      id: _intValue(json['goodsId'] ?? json['id']),
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      price: _intValue(json['price']),
      isCombo: _intValue(json['isCombo']),
      tabId: _nullableIntValue(json['tabId']) ?? fallbackTabId,
      cornerMark: json['cornerMark']?.toString() ?? '',
      amount: _nullableIntValue(json['amount']),
      userBackpackId: _nullableIntValue(json['userBackpackId']),
      defaultGiftNum: defaultGiftNum != null && defaultGiftNum > 0
          ? defaultGiftNum
          : 1,
      defaultGiftNumConfig: json['defaultGiftNumConfig']?.toString(),
      animationUrl: json['animationUrl']?.toString(),
      animationType: _nullableIntValue(json['animationType']),
      giftType: _nullableIntValue(json['giftType']),
      itemType: json['itemType']?.toString(),
      banner: json['banner']?.toString(),
      jumpLink: json['jumpLink']?.toString(),
      direction: _nullableIntValue(json['direction']),
      videoMode: _nullableIntValue(json['videoMode']),
    );
  }
}

class RoomGiftTab {
  const RoomGiftTab({
    required this.id,
    required this.name,
    required this.gifts,
  });

  static const int backpackId = -99999;

  final int id;
  final String name;
  final List<RoomGift> gifts;

  bool get isBackpack => id == backpackId;

  RoomGiftTab copyWith({List<RoomGift>? gifts}) {
    return RoomGiftTab(id: id, name: name, gifts: gifts ?? this.gifts);
  }

  factory RoomGiftTab.fromJson(Map<String, dynamic> json) {
    final id = _intValue(json['tabId']);
    return RoomGiftTab(
      id: id,
      name: json['tab']?.toString() ?? '',
      gifts: _mapList(json['giftInfoDTOS'])
          .map((item) => RoomGift.fromJson(item, fallbackTabId: id))
          .where((gift) => gift.id != 0)
          .toList(growable: false),
    );
  }
}

class RoomGiftCatalog {
  const RoomGiftCatalog({
    required this.balance,
    required this.canSendSelf,
    required this.tabs,
  });

  final int balance;
  final bool canSendSelf;
  final List<RoomGiftTab> tabs;

  RoomGiftCatalog copyWith({
    int? balance,
    bool? canSendSelf,
    List<RoomGiftTab>? tabs,
  }) {
    return RoomGiftCatalog(
      balance: balance ?? this.balance,
      canSendSelf: canSendSelf ?? this.canSendSelf,
      tabs: tabs ?? this.tabs,
    );
  }
}

class SendRoomGiftRequest {
  const SendRoomGiftRequest({
    required this.targetUids,
    required this.sendType,
    required this.roomId,
    required this.giftId,
    required this.giftCount,
    required this.giftSource,
    required this.comboId,
    required this.comboCount,
    required this.price,
    this.userBackpackId,
  });

  final List<int>? targetUids;
  final RoomGiftSendType sendType;
  final String roomId;
  final int giftId;
  final int giftCount;
  final int giftSource;
  final String comboId;
  final int comboCount;
  final int price;
  final int? userBackpackId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'targetUids': targetUids,
      'sendType': sendType.value,
      'roomId': roomId,
      'giftId': giftId,
      'giftCount': giftCount,
      'giftSource': giftSource,
      'comboId': comboId,
      'comboCount': comboCount,
      'price': price,
      'userBackpackId': userBackpackId,
    };
  }
}

class RoomGiftSendResult {
  const RoomGiftSendResult({this.comboId});

  final String? comboId;

  factory RoomGiftSendResult.fromJson(Object? value) {
    final id = value is Map ? value['comboId'] : value;
    return RoomGiftSendResult(comboId: id is String ? id : null);
  }
}

int _intValue(Object? value) => _nullableIntValue(value) ?? 0;

int? _nullableIntValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
}
