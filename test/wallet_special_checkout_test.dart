import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:project/classes/wallet/wallet_models.dart';
import 'package:project/classes/wallet/wallet_payment_service.dart';
import 'package:project/classes/wallet/wallet_repository.dart';
import 'package:project/classes/wallet/wallet_view_model.dart';
import 'package:project/manager/http_dio_manager.dart';

const product = WalletRechargeProduct(
  id: 'first_pack',
  name: 'First pack',
  channel: 'google',
  currency: 'USD',
  currencyAmount: 199,
  coinAmount: 100,
  sortNo: 0,
  remark: null,
  merchant: '1',
  dollarAmount: 199,
  useType: 2,
);

void main() {
  late ProviderContainer container;
  late _Billing billing;
  late _Repository repository;
  setUp(() {
    billing = _Billing();
    repository = _Repository();
    container = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(repository),
        walletPaymentServiceProvider.overrideWithValue(billing),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await billing.events.close();
  });
  Future<void> flush() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'special product uses shared consumable checkout and cancellation unlocks',
    () async {
      final sub = container.listen(walletViewModelProvider, (_, __) {});
      final vm = container.read(walletViewModelProvider.notifier);
      await flush();
      await vm.purchase(product);
      expect(billing.buys, ['first_pack']);
      expect(container.read(walletViewModelProvider).isPurchasing, isTrue);
      billing.emit(PurchaseStatus.canceled);
      await flush();
      expect(container.read(walletViewModelProvider).isPurchasing, isFalse);
      expect(
        container.read(walletViewModelProvider).noticeKey,
        'wallet.paymentCanceled',
      );
      sub.close();
    },
  );
  test(
    'account/view invalidation while querying product prevents store launch',
    () async {
      final sub = container.listen(walletViewModelProvider, (_, __) {});
      final vm = container.read(walletViewModelProvider.notifier);
      await flush();
      billing.queryGate = Completer<ProductDetailsResponse>();
      var current = true;
      final task = vm.purchase(product, isCurrent: () => current);
      await flush();
      current = false;
      billing.queryGate!.complete(billing.products({'first_pack'}));
      await task;
      expect(billing.buys, isEmpty);
      expect(container.read(walletViewModelProvider).isPurchasing, isFalse);
      sub.close();
    },
  );
  test(
    'pending checkout survives page listener disposal until result completes',
    () async {
      final sub = container.listen(walletViewModelProvider, (_, __) {});
      final vm = container.read(walletViewModelProvider.notifier);
      await flush();
      await vm.purchase(product);
      sub.close();
      await container.pump();
      expect(billing.events.hasListener, isTrue);
      billing.emit(PurchaseStatus.canceled);
      await flush();
      await container.pump();
      expect(billing.events.hasListener, isFalse);
    },
  );
  test(
    'new checkout waits for unfinished-purchase recovery and never duplicates taps',
    () async {
      billing.recoveryGate = Completer<int>();
      final sub = container.listen(walletViewModelProvider, (_, __) {});
      final vm = container.read(walletViewModelProvider.notifier);
      final first = vm.purchase(product);
      await vm.purchase(product);
      await flush();
      expect(billing.buys, isEmpty);
      billing.recoveryGate!.complete(0);
      await first;
      expect(billing.buys, ['first_pack']);
      billing.emit(PurchaseStatus.canceled);
      await flush();
      sub.close();
    },
  );
}

class _Repository extends WalletRepository {
  _Repository() : super(HttpDioManager());
  @override
  Future<WalletPurse> fetchPurse() async =>
      const WalletPurse(uid: 10, coin: 100, diamond: 0, usd: 0, isFirst: true);
  @override
  Future<List<WalletRechargeProduct>> fetchRechargePackages() async => [];
}

class _Billing implements WalletPaymentService {
  final events = StreamController<List<PurchaseDetails>>.broadcast();
  final buys = <String>[];
  Completer<ProductDetailsResponse>? queryGate;
  Completer<int>? recoveryGate;
  ProductDetailsResponse products(Set<String> ids) => ProductDetailsResponse(
    productDetails: [
      for (final id in ids)
        ProductDetails(
          id: id,
          title: id,
          description: 'First',
          price: r'$1.99',
          rawPrice: 1.99,
          currencyCode: 'USD',
        ),
    ],
    notFoundIDs: [],
  );
  void emit(PurchaseStatus status) => events.add([
    PurchaseDetails(
      productID: 'first_pack',
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'fixture',
        source: 'google',
      ),
      transactionDate: null,
      status: status,
    ),
  ]);
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => events.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<int> recoverUnfinishedPurchases() async => recoveryGate?.future ?? 0;
  @override
  Future<ProductDetailsResponse> queryProducts(Set<String> productIds) async =>
      queryGate?.future ?? products(productIds);
  @override
  Future<bool> buyConsumable({
    required ProductDetails product,
    required String applicationUserName,
  }) async {
    buys.add(product.id);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}
