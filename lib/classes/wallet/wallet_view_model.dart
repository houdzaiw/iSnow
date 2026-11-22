import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../manager/api_error_message.dart';
import '../../manager/account_balance_revision.dart';
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
  int _purseRevision = 0;
  bool _alive = false;
  void Function()? _releasePurchaseHold;
  final Map<String, WalletRechargeProduct> _checkoutProducts = {};
  Future<void>? _initialization;
  bool _checkoutStarting = false;
  bool get hasPendingCheckout => _checkoutStarting || state.isPurchasing;

  @override
  WalletState build() {
    _alive = true;
    ref.listen(accountBalanceRevisionProvider, (_, _) => refreshPurse());
    _purchaseSubscription = _paymentService.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: _handlePurchaseStreamError,
    );
    ref.onDispose(() {
      _alive = false;
      _releasePurchaseHold = null;
      _purseRevision++;
      unawaited(_purchaseSubscription?.cancel());
    });
    _initialization = Future.microtask(_initialize);
    return const WalletState(isLoading: true);
  }

  /// Refresh only the balance after a membership debit; do not restart billing.
  Future<void> refreshPurse() async {
    if (!_alive) return;
    final revision = ++_purseRevision;
    try {
      final purse = await _repository.fetchPurse();
      if (_alive && revision == _purseRevision) {
        state = state.copyWith(purse: purse);
      }
    } catch (_) {
      /* Existing balance remains visible until a manual refresh. */
    }
  }

  Future<void> _initialize() async {
    try {
      _iapAvailable = await _paymentService.isAvailable();
      if (!_alive) return;
      if (_iapAvailable ?? false) {
        await _paymentService.recoverUnfinishedPurchases();
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[WalletPayment] unfinished purchase recovery failed: '
        '$error\n$stackTrace',
      );
    }
    if (_alive) await load();
  }

  Future<void> load({bool refresh = false}) async {
    if (!_alive) return;
    state = state.copyWith(
      isLoading: true,
      isRefreshing: refresh,
      loadError: null,
      noticeKey: null,
    );

    Object? firstError;
    try {
      final purse = await _repository.fetchPurse();
      if (!_alive) return;
      state = state.copyWith(purse: purse);
    } catch (error) {
      firstError = error;
    }

    try {
      if (!_alive) return;
      final serverProducts = await _repository.fetchRechargePackages();
      if (!_alive) return;
      final products = await _loadIapProducts(serverProducts);
      if (!_alive) return;
      final currentSelection = state.selectedProductId;
      final selectedProductId =
          products.any((product) => product.id == currentSelection)
          ? currentSelection
          : products.firstOrNull?.id;
      state = state.copyWith(
        products: products,
        selectedProductId: selectedProductId,
      );
    } catch (error) {
      firstError ??= error;
    }

    if (!_alive) return;
    state = state.copyWith(
      isLoading: false,
      isRefreshing: false,
      loadError: firstError,
      noticeMessage: serverErrorMessage(firstError),
    );
  }

  void selectProduct(String productId) {
    if (state.isPurchasing || productId == state.selectedProductId) return;
    if (!state.products.any((product) => product.id == productId)) return;
    state = state.copyWith(selectedProductId: productId);
  }

  Future<void> purchase(
    WalletRechargeProduct product, {
    bool Function()? isCurrent,
  }) async {
    bool valid() => _alive && isCurrent?.call() != false;
    if (!valid() || hasPendingCheckout) return;
    _checkoutStarting = true;
    _releasePurchaseHold ??= ref.keepAlive().close;
    _checkoutProducts[product.id] = product;
    void cancelStart() {
      if (_alive) state = state.copyWith(purchaseProductId: null);
      _finishPurchaseHold();
    }

    try {
      await _initialization;
      if (!valid()) {
        cancelStart();
        return;
      }
      state = state.copyWith(purchaseProductId: product.id, noticeKey: null);
      final available = _iapAvailable ??= await _paymentService.isAvailable();
      if (!valid()) {
        cancelStart();
        return;
      }
      if (!available) throw const _WalletPaymentException('unavailable');

      var productDetails = _iapProducts[product.id];
      productDetails ??= await _queryIapProduct(product.id);
      if (!valid()) {
        cancelStart();
        return;
      }
      if (productDetails == null) {
        throw const _WalletPaymentException('unavailable');
      }

      var applicationUserName = '';
      if (Platform.isAndroid) {
        applicationUserName = await _repository.createGoogleRechargeOrder(
          product,
        );
        if (!valid()) {
          cancelStart();
          return;
        }
      }

      final started = await _paymentService.buyConsumable(
        product: productDetails,
        applicationUserName: applicationUserName,
      );
      if (!started) throw const _WalletPaymentException('failed');
    } catch (error) {
      if (!valid()) {
        cancelStart();
        return;
      }
      final message = serverErrorMessage(error);
      state = state.copyWith(
        purchaseProductId: null,
        noticeMessage: message,
        noticeKey: message != null
            ? null
            : error is _WalletPaymentException && error.reason == 'unavailable'
            ? 'wallet.paymentUnavailable'
            : 'wallet.paymentFailed',
      );
      _finishPurchaseHold();
    } finally {
      _checkoutStarting = false;
    }
  }

  void _finishPurchaseHold() {
    final close = _releasePurchaseHold;
    _releasePurchaseHold = null;
    close?.call();
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
        debugPrint(
          '[WalletPayment] billing unavailable; showing '
          '${rechargeProducts.length} server recharge products',
        );
        return rechargeProducts;
      }
      final serverIds = rechargeProducts.map((product) => product.id).toSet();
      final response = await _paymentService.queryProducts(serverIds);
      if (response.error != null) {
        debugPrint(
          '[WalletPayment] queryProductDetails failed: ${response.error}',
        );
        return rechargeProducts;
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
      return rechargeProducts;
    } catch (error, stackTrace) {
      debugPrint('[WalletPayment] product loading failed: $error\n$stackTrace');
      return rechargeProducts;
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
      if (!_alive) return;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(noticeKey: 'wallet.purchasePending');
        case PurchaseStatus.error:
          state = state.copyWith(
            purchaseProductId: null,
            noticeKey: 'wallet.paymentFailed',
          );
          _finishPurchaseHold();
        case PurchaseStatus.canceled:
          state = state.copyWith(
            purchaseProductId: null,
            noticeKey: 'wallet.paymentCanceled',
          );
          await _completePurchaseSafely(purchase, force: true);
          _finishPurchaseHold();
        case PurchaseStatus.purchased:
          await _handlePurchased(purchase);
          await _completePurchaseSafely(purchase);
          _finishPurchaseHold();
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
    final previousBalance = state.purse?.coin;
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
      if (!_alive) return;
      state = state.copyWith(
        purchaseProductId: null,
        noticeKey: 'wallet.paymentSuccess',
        verifiedPaymentRevision:
            previousBalance != null &&
                state.loadError == null &&
                (state.purse?.coin ?? 0) > previousBalance
            ? state.verifiedPaymentRevision + 1
            : state.verifiedPaymentRevision,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[WalletPayment] purchase callback failed: $error\n$stackTrace',
      );
      if (!_alive) return;
      state = state.copyWith(
        purchaseProductId: null,
        noticeMessage: serverErrorMessage(error),
        noticeKey: serverErrorMessage(error) == null
            ? 'wallet.paymentFailed'
            : null,
      );
    }
  }

  void _handlePurchaseStreamError(Object error, StackTrace stackTrace) {
    debugPrint('[WalletPayment] purchase stream failed: $error\n$stackTrace');
    if (!_alive) return;
    state = state.copyWith(
      purchaseProductId: null,
      noticeMessage: serverErrorMessage(error),
      noticeKey: serverErrorMessage(error) == null
          ? 'wallet.paymentFailed'
          : null,
    );
    _finishPurchaseHold();
  }

  WalletRechargeProduct? _productForId(String id) {
    for (final product in state.products) {
      if (product.id == id) return product;
    }
    return _checkoutProducts[id];
  }
}

class _WalletPaymentException implements Exception {
  const _WalletPaymentException(this.reason);

  final String reason;
}
