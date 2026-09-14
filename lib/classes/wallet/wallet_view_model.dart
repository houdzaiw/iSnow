import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'wallet_models.dart';
import 'wallet_payment_service.dart';
import 'wallet_repository.dart';
import 'wallet_state.dart';

final walletViewModelProvider =
    AutoDisposeNotifierProvider<WalletViewModel, WalletState>(
      WalletViewModel.new,
    );

class WalletViewModel extends AutoDisposeNotifier<WalletState> {
  WalletRepository get _repository => ref.read(walletRepositoryProvider);
  WalletPaymentService get _paymentService =>
      ref.read(walletPaymentServiceProvider);

  final Map<String, ProductDetails> _iapProducts = <String, ProductDetails>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool? _iapAvailable;

  @override
  WalletState build() {
    _purchaseSubscription = _paymentService.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: _handlePurchaseStreamError,
    );
    ref.onDispose(() {
      unawaited(_purchaseSubscription?.cancel());
    });
    Future.microtask(_initialize);
    return const WalletState(isLoading: true);
  }

  Future<void> _initialize() async {
    try {
      _iapAvailable = await _paymentService.isAvailable();
      if (_iapAvailable ?? false) {
        await _paymentService.recoverUnfinishedPurchases();
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[WalletPayment] unfinished purchase recovery failed: '
        '$error\n$stackTrace',
      );
    }
    await load();
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
      final serverProducts = await _repository.fetchRechargePackages();
      final products = await _loadIapProducts(serverProducts);
      state = state.copyWith(products: products);
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
      final available = _iapAvailable ??= await _paymentService.isAvailable();
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

      final started = await _paymentService.buyConsumable(
        product: productDetails,
        applicationUserName: applicationUserName,
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

  Future<List<WalletRechargeProduct>> _loadIapProducts(
    List<WalletRechargeProduct> products,
  ) async {
    final rechargeProducts = products
        .where((product) => product.useType == 1)
        .toList(growable: false);
    _iapProducts.clear();
    if (rechargeProducts.isEmpty) {
      return const <WalletRechargeProduct>[];
    }

    try {
      _iapAvailable ??= await _paymentService.isAvailable();
      if (!(_iapAvailable ?? false)) {
        return const <WalletRechargeProduct>[];
      }
      final serverIds = rechargeProducts.map((product) => product.id).toSet();
      final response = await _paymentService.queryProducts(serverIds);
      if (response.error != null) {
        debugPrint(
          '[WalletPayment] queryProductDetails failed: ${response.error}',
        );
        return const <WalletRechargeProduct>[];
      }

      final platformIds = response.productDetails
          .map((product) => product.id)
          .toSet();
      final visibleIds = serverIds.intersection(platformIds);
      for (final product in response.productDetails) {
        if (visibleIds.contains(product.id)) {
          _iapProducts[product.id] = product;
        }
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          '[WalletPayment] products missing from store: '
          '${response.notFoundIDs.join(', ')}',
        );
      }
      return rechargeProducts
          .where((product) => visibleIds.contains(product.id))
          .toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('[WalletPayment] product loading failed: $error\n$stackTrace');
      return const <WalletRechargeProduct>[];
    }
  }

  Future<ProductDetails?> _queryIapProduct(String productId) async {
    final response = await _paymentService.queryProducts({productId});
    if (response.error != null) return null;
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
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(noticeKey: 'wallet.purchasePending');
        case PurchaseStatus.error:
          state = state.copyWith(
            purchaseProductId: null,
            noticeKey: 'wallet.paymentFailed',
          );
        case PurchaseStatus.canceled:
          state = state.copyWith(
            purchaseProductId: null,
            noticeKey: 'wallet.paymentCanceled',
          );
          await _completePurchaseSafely(purchase, force: true);
        case PurchaseStatus.purchased:
          await _handlePurchased(purchase);
          await _completePurchaseSafely(purchase);
        case PurchaseStatus.restored:
          break;
      }
    }
  }

  Future<void> _completePurchaseSafely(
    PurchaseDetails purchase, {
    bool force = false,
  }) async {
    if (!force && !purchase.pendingCompletePurchase) return;
    try {
      await _paymentService.completePurchase(purchase);
    } catch (error, stackTrace) {
      debugPrint(
        '[WalletPayment] completePurchase failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> _handlePurchased(PurchaseDetails purchase) async {
    try {
      if (Platform.isIOS) {
        final product = _productForId(purchase.productID);
        final orderId = purchase.purchaseID;
        if (product == null || orderId == null || orderId.isEmpty) {
          throw const _WalletPaymentException('validation');
        }
        await _repository.createAppleRechargeRecord(
          product: product,
          orderId: orderId,
          purchaseToken: purchase.verificationData.serverVerificationData,
        );
      } else if (Platform.isAndroid) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      await load(refresh: true);
      state = state.copyWith(
        purchaseProductId: null,
        noticeKey: 'wallet.paymentSuccess',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[WalletPayment] purchase callback failed: $error\n$stackTrace',
      );
      state = state.copyWith(
        purchaseProductId: null,
        noticeKey: 'wallet.paymentFailed',
      );
    }
  }

  void _handlePurchaseStreamError(Object error, StackTrace stackTrace) {
    debugPrint('[WalletPayment] purchase stream failed: $error\n$stackTrace');
    state = state.copyWith(
      purchaseProductId: null,
      noticeKey: 'wallet.paymentFailed',
    );
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
