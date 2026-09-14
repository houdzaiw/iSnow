class WalletPurse {
  const WalletPurse({
    required this.uid,
    required this.coin,
    required this.diamond,
    required this.usd,
    required this.isFirst,
  });

  final int uid;
  final int coin;
  final int diamond;
  final int usd;
  final bool isFirst;

  factory WalletPurse.fromJson(Map<String, dynamic> json) {
    return WalletPurse(
      uid: _intValue(json['uid']),
      coin: _intValue(json['coin']),
      diamond: _intValue(json['diamond']),
      usd: _intValue(json['usd']),
      isFirst: _boolValue(json['isFirst']),
    );
  }
}

class WalletRechargeProduct {
  const WalletRechargeProduct({
    required this.id,
    required this.name,
    required this.channel,
    required this.currency,
    required this.currencyAmount,
    required this.coinAmount,
    required this.sortNo,
    required this.remark,
    required this.merchant,
    required this.dollarAmount,
    required this.useType,
  });

  final String id;
  final String name;
  final String channel;
  final String currency;
  final int currencyAmount;
  final int coinAmount;
  final int sortNo;
  final String? remark;
  final String merchant;
  final int dollarAmount;
  final int useType;

  factory WalletRechargeProduct.fromJson(Map<String, dynamic> json) {
    return WalletRechargeProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'USD',
      currencyAmount: _intValue(json['currencyAmount']),
      coinAmount: _intValue(json['coinAmount']),
      sortNo: _intValue(json['sortNo']),
      remark: json['remark']?.toString(),
      merchant: json['merchant']?.toString() ?? '',
      dollarAmount: _intValue(json['dollarAmount']),
      useType: _intValue(json['useType']),
    );
  }
}

class WalletConvertProportion {
  const WalletConvertProportion({required this.reminder});

  final String reminder;

  factory WalletConvertProportion.fromJson(Map<String, dynamic> json) {
    return WalletConvertProportion(
      reminder: json['reminder']?.toString() ?? '',
    );
  }
}

class WalletRechargeRequest {
  const WalletRechargeRequest({
    required this.productId,
    required this.channel,
    required this.merchant,
    this.orderId,
    this.purchaseToken,
    this.countryRechargeChannelConfigId = '',
  });

  final String productId;
  final String channel;
  final int merchant;
  final String? orderId;
  final String? purchaseToken;
  final String countryRechargeChannelConfigId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'productId': productId,
      'channel': channel,
      'merchant': merchant,
      'orderId': orderId,
      'purchaseToken': purchaseToken,
      'countryRechargeChannelConfigId': countryRechargeChannelConfigId,
    };
  }
}

int _intValue(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}
