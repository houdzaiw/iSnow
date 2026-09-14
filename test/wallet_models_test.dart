import 'package:flutter_test/flutter_test.dart';

import 'package:project/classes/wallet/wallet_models.dart';

void main() {
  test('parses wallet purse values from the API response', () {
    final purse = WalletPurse.fromJson({
      'uid': '72546721',
      'coin': '1200',
      'diamond': 45.8,
      'usd': 99,
      'isFirst': 1,
    });

    expect(purse.uid, 72546721);
    expect(purse.coin, 1200);
    expect(purse.diamond, 45);
    expect(purse.usd, 99);
    expect(purse.isFirst, isTrue);
  });

  test('parses recharge product amounts used by the list UI', () {
    final product = WalletRechargeProduct.fromJson({
      'id': 'coins_1000',
      'name': '1000 Coins',
      'channel': 'google',
      'currency': 'USD',
      'currencyAmount': '1000',
      'coinAmount': 1000,
      'sortNo': 1,
      'merchant': 1,
      'dollarAmount': '199',
      'useType': 1,
    });

    expect(product.id, 'coins_1000');
    expect(product.coinAmount, 1000);
    expect(product.dollarAmount, 199);
    expect(product.merchant, '1');
  });

  test('serializes Google recharge request with Nady-compatible fields', () {
    const request = WalletRechargeRequest(
      productId: 'coin_100',
      channel: 'google',
      merchant: 1,
    );

    expect(request.toJson(), <String, dynamic>{
      'productId': 'coin_100',
      'channel': 'google',
      'merchant': 1,
      'orderId': null,
      'purchaseToken': null,
      'countryRechargeChannelConfigId': '',
    });
  });
}
