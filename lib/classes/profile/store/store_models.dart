import '../tools/profile_feature_repository.dart';

enum StoreCategory {
  avatar(3, 'avatar'),
  ripple(5, 'ripple'),
  bubble(2, 'bubble'),
  background(6, 'background'),
  entry(4, 'entry'),
  vehicle(8, 'vehicle'),
  profile(7, 'profileEffect');

  const StoreCategory(this.type, this.label);
  final int type;
  final String label;
}

class StorePrice {
  const StorePrice(this.currency, this.days, this.price);
  final int currency, days, price;
  bool get valid => {1, 2}.contains(currency) && days > 0 && price >= 0;
  String get key => '$currency:$days:$price';
  static int _price(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? -1;
    if (value is num && value.isFinite && value.truncateToDouble() == value) {
      return value.toInt();
    }
    return -1;
  }

  factory StorePrice.fromJson(Map<String, dynamic> j) => StorePrice(
    membershipInt(j['currencyType']),
    membershipInt(j['day']),
    _price(j['price']),
  );
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.animation,
    required this.prices,
    this.isNew = false,
    this.animationType,
    this.direction,
  });
  final int id, type;
  final String name, icon, animation;
  final bool isNew;
  final int? animationType, direction;
  final List<StorePrice> prices;
  factory StoreProduct.fromJson(Map<String, dynamic> j) => StoreProduct(
    id: membershipInt(j['id']),
    type: membershipInt(j['type']),
    name: membershipString(j['name']),
    icon: membershipString(j['icon']),
    animation: membershipString(j['animationUrl']),
    animationType: j['animationType'] == null
        ? null
        : membershipInt(j['animationType']),
    direction: j['direction'] == null ? null : membershipInt(j['direction']),
    isNew: membershipInt(j['markNewProduct']) == 1,
    prices: membershipList(
      j['priceList'],
      StorePrice.fromJson,
    ).where((p) => p.valid).toList(),
  );
}

class StorePageData {
  const StorePageData(this.items, this.hasMore);
  final List<StoreProduct> items;
  final bool hasMore;
}

class OwnedProp {
  const OwnedProp({
    required this.id,
    required this.goodsId,
    required this.type,
    required this.name,
    required this.icon,
    required this.animation,
    required this.expireTime,
    required this.state,
    this.animationType,
    this.direction,
    this.duration,
  });
  final int id, goodsId, type, expireTime, state;
  final String name, icon, animation;
  final int? animationType, direction, duration;
  bool get permanent => duration == -1 || expireTime == -1;
  DateTime? get expiresAt => expireTime > 0 && expireTime <= 8640000000000000
      ? DateTime.fromMillisecondsSinceEpoch(expireTime)
      : null;
  bool expired(DateTime now) => !permanent && expiresAt?.isAfter(now) != true;
  factory OwnedProp.fromJson(Map<String, dynamic> j) => OwnedProp(
    id: membershipInt(j['id']),
    goodsId: membershipInt(j['goodsId']),
    type: membershipInt(j['goodsType']),
    name: membershipString(j['name']),
    icon: membershipString(j['icon']),
    animation: membershipString(j['animationUrl']),
    expireTime: membershipInt(j['expireTime']),
    duration: j['duration'] == null ? null : membershipInt(j['duration']),
    state: membershipInt(j['state']),
    animationType: j['animationType'] == null
        ? null
        : membershipInt(j['animationType']),
    direction: j['direction'] == null ? null : membershipInt(j['direction']),
  );
  StoreProduct get preview => StoreProduct(
    id: goodsId,
    type: type,
    name: name,
    icon: icon,
    animation: animation,
    prices: const [],
    animationType: animationType,
    direction: direction,
  );
}

class StoreOrder {
  const StoreOrder(
    this.account,
    this.product,
    this.price, {
    this.targetUid,
    this.targetName = '',
  });
  final MembershipIdentity account;
  final StoreProduct product;
  final StorePrice price;
  final int? targetUid;
  final String targetName;
}

class StoreInsufficientBalance implements Exception {}

class PropTransfer {
  const PropTransfer(this.account, this.prop, this.targetUid, this.targetName);
  final MembershipIdentity account;
  final OwnedProp prop;
  final int targetUid;
  final String targetName;
}
