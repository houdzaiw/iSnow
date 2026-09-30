import 'package:flutter_test/flutter_test.dart';

import 'package:project/classes/wallet/wallet_models.dart';
import 'package:project/classes/wallet/wallet_state.dart';

void main() {
  const first = WalletRechargeProduct(
    id: 'coins_100',
    name: '100 coins',
    channel: 'google',
    currency: 'USD',
    currencyAmount: 99,
    coinAmount: 100,
    sortNo: 1,
    remark: null,
    merchant: 'google',
    dollarAmount: 99,
    useType: 1,
  );
  const second = WalletRechargeProduct(
    id: 'coins_500',
    name: '500 coins',
    channel: 'google',
    currency: 'USD',
    currencyAmount: 499,
    coinAmount: 500,
    sortNo: 2,
    remark: null,
    merchant: 'google',
    dollarAmount: 499,
    useType: 1,
  );

  test('resolves the selected recharge product', () {
    const state = WalletState(
      products: [first, second],
      selectedProductId: 'coins_500',
    );

    expect(state.selectedProduct, same(second));
  });

  test('can clear the selected recharge product', () {
    const state = WalletState(
      products: [first],
      selectedProductId: 'coins_100',
    );

    expect(state.copyWith(selectedProductId: null).selectedProduct, isNull);
  });
}
