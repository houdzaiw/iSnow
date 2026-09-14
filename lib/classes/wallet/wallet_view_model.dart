import 'dart:async';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'wallet_models.dart';
import 'wallet_repository.dart';
import 'wallet_state.dart';

final walletViewModelProvider =
    AutoDisposeNotifierProvider<WalletViewModel, WalletState>(
      WalletViewModel.new,
    );

class WalletViewModel extends AutoDisposeNotifier<WalletState> {
  WalletRepository get _repository => ref.read(walletRepositoryProvider);

  final Map<String, ProductDetails> _iapProducts = <String, ProductDetails>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool? _iapAvailable;

  @override
  WalletState build() {
    _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdates,
    );
    ref.onDispose(() {
      unawaited(_purchaseSubscription?.cancel());
    });
    Future.microtask(load);
    return const WalletState(isLoading: true);
  }

  Future<void> load({bool refresh = false}) async {
    state = state.copyWith(
      isLoading: true,
      isRefreshing: refresh,
      loadError: null,
      noticeKey: null,
    );

    Object? firstError;
    try {
      final purse = await _repository.fetchPurse();
      state = state.copyWith(purse: purse);
    } catch (error) {
      firstError = error;
    }

    try {
      final products = await _repository.fetchRechargePackages();
      state = state.copyWith(products: products);
      unawaited(_loadIapProducts(products));
    } catch (error) {
      firstError ??= error;
    }

    try {
      final reminder = await _repository.fetchDiamondReminder();
      state = state.copyWith(diamondReminder: reminder.reminder);
    } catch (_) {
      // The reminder is supplementary; the balance and recharge list stay usable.
    }

    state = state.copyWith(
      isLoading: false,
      isRefreshing: false,
      loadError: firstError,
    );
  }

  void selectTab(int index) {
    if (index < 0 || index > 1 || index == state.selectedTab) return;
    state = state.copyWith(selectedTab: index);
  }

  Future<void> purchase(WalletRechargeProduct product) async {
    if (state.isPurchasing) return;
    state = state.copyWith(purchaseProductId: product.id, noticeKey: null);

    try {
      final available = _iapAvailable ??= await InAppPurchase.instance
          .isAvailable();
      if (!available) throw const _WalletPaymentException('unavailable');

      var productDetails = _iapProducts[product.id];
      productDetails ??= await _queryIapProduct(product.id);
      if (productDetails == null) {
        throw const _WalletPaymentException('unavailable');
      }

      var applicationUserName = '';
      if (Platform.isAndroid) {
        applicationUserName = await _repository.createGoogleRechargeOrder(
          product,
        );
      }

      final started = await InAppPurchase.instance.buyConsumable(
        autoConsume: true,
        purchaseParam: PurchaseParam(
          productDetails: productDetails,
          applicationUserName: applicationUserName,
        ),
      );
      if (!started) throw const _WalletPaymentException('failed');
    } catch (error) {
      state = state.copyWith(
        purchaseProductId: null,
        noticeKey:
            error is _WalletPaymentException && error.reason == 'unavailable'
            ? 'wallet.paymentUnavailable'
            : 'wallet.paymentFailed',
      );
    }
  }

  Future<void> _loadIapProducts(List<WalletRechargeProduct> products) async {
    try {
      _iapAvailable = await InAppPurchase.instance.isAvailable();
      if (!(_iapAvailable ?? false)) return;
      final response = await InAppPurchase.instance.queryProductDetails(
        products.map((product) => product.id).toSet(),
      );
      for (final product in response.productDetails) {
        _iapProducts[product.id] = product;
      }
    } catch (_) {
      // The server list remains visible when the store is not configured.
    }
  }

  Future<ProductDetails?> _queryIapProduct(String productId) async {
    final response = await InAppPurchase.instance.queryProductDetails({
      productId,
    });
    for (final product in response.productDetails) {
      if (product.id == productId) {
        _iapProducts[product.id] = product;
        return product;
      }
    }
    return null;
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        state = state.copyWith(noticeKey: 'wallet.purchasePending');
        continue;
      }

      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        state = state.copyWith(
          purchaseProductId: null,
          noticeKey: 'wallet.paymentFailed',
        );
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          if (Platform.isIOS) {
            final product = _productForId(purchase.productID);
            if (product != null) {
              await _repository.createAppleRechargeRecord(
                product: product,
                orderId: purchase.purchaseID ?? '',
                purchaseToken: purchase.verificationData.serverVerificationData,
              );
            }
          }
          await load(refresh: true);
          state = state.copyWith(
            purchaseProductId: null,
            noticeKey: 'wallet.paymentSuccess',
          );
        } catch (_) {
          state = state.copyWith(
            purchaseProductId: null,
            noticeKey: 'wallet.paymentFailed',
          );
        }
      }

      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  WalletRechargeProduct? _productForId(String id) {
    for (final product in state.products) {
      if (product.id == id) return product;
    }
    return null;
  }
}

class _WalletPaymentException implements Exception {
  const _WalletPaymentException(this.reason);

  final String reason;
}
