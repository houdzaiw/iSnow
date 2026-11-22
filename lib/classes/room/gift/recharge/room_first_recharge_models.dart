import '../../../wallet/wallet_models.dart';

class RoomFirstRechargeReward {
  const RoomFirstRechargeReward({
    required this.name,
    required this.icon,
    required this.amount,
    required this.days,
    this.permanent = false,
  });
  final String name, icon;
  final int amount, days;
  final bool permanent;
  factory RoomFirstRechargeReward.fromJson(
    Map<String, dynamic> json,
  ) => RoomFirstRechargeReward(
    name: '${json['prizeName'] ?? json['name'] ?? ''}',
    icon: '${json['prizeIcon'] ?? ''}',
    amount: _int(json['goodsConsumeType']) == 1 ? _int(json['amount']) : 0,
    days: _int(json['goodsConsumeType']) != 1 && _int(json['durationType']) != 1
        ? (json['durationDays'] == null
              ? _int(json['durationMillis']) ~/ 86400000
              : _int(json['durationDays']))
        : 0,
    permanent:
        _int(json['goodsConsumeType']) != 1 && _int(json['durationType']) == 1,
  );
}

/// Nady isBuy=true means this package is available to buy, not already bought.
class RoomFirstRechargePack {
  const RoomFirstRechargePack({
    required this.id,
    required this.name,
    required this.coin,
    required this.dollarAmount,
    required this.originalPrice,
    required this.isBuy,
    required this.sortNo,
    required this.rewards,
  });
  final String id, name;
  final int coin, dollarAmount, originalPrice, sortNo;
  final bool isBuy;
  final List<RoomFirstRechargeReward> rewards;
  String get price => 'USD ${(dollarAmount / 100).toStringAsFixed(2)}';
  bool get purchasable => isBuy && id.isNotEmpty && dollarAmount > 0;
  factory RoomFirstRechargePack.fromJson(Map<String, dynamic> json) {
    final pack = json['rewardPack'];
    final resources = pack is Map
        ? pack['resourceVOList'] ?? json['resourceVOList']
        : json['resourceVOList'];
    return RoomFirstRechargePack(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      coin: _int(json['coinAmount']),
      dollarAmount: _int(json['dollarAmount']),
      originalPrice: _int(json['originalPrice']),
      isBuy:
          json['isBuy'] == true ||
          json['isBuy'] == 1 ||
          json['isBuy'] == 'true',
      sortNo: _int(json['sortNo']),
      rewards: [
        if (resources is List)
          for (final item in resources)
            if (item is Map)
              RoomFirstRechargeReward.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  WalletRechargeProduct get paymentProduct => WalletRechargeProduct(
    id: id,
    name: name,
    channel: 'google',
    currency: 'USD',
    currencyAmount: dollarAmount,
    coinAmount: coin,
    sortNo: sortNo,
    remark: null,
    merchant: '1',
    dollarAmount: dollarAmount,
    useType: 2,
  );
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
