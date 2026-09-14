import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

final walletPaymentServiceProvider = Provider<WalletPaymentService>((ref) {
  return WalletPaymentService(InAppPurchase.instance);
});

/// Owns the platform billing APIs used by the wallet workflow.
class WalletPaymentService {
  const WalletPaymentService(this._inAppPurchase);

  final InAppPurchase _inAppPurchase;

  Stream<List<PurchaseDetails>> get purchaseStream =>
      _inAppPurchase.purchaseStream;

  Future<bool> isAvailable() => _inAppPurchase.isAvailable();

  Future<ProductDetailsResponse> queryProducts(Set<String> productIds) {
    return _inAppPurchase.queryProductDetails(productIds);
  }

  Future<bool> buyConsumable({
    required ProductDetails product,
    required String applicationUserName,
  }) {
    return _inAppPurchase.buyConsumable(
      autoConsume: true,
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: applicationUserName,
      ),
    );
  }

  Future<void> completePurchase(PurchaseDetails purchase) {
    return _inAppPurchase.completePurchase(purchase);
  }

  /// Clears unfinished consumables using the same order as Nady: confirm first,
  /// then explicitly consume so the product can be purchased again.
  Future<int> recoverUnfinishedPurchases() async {
    if (Platform.isAndroid) {
      final addition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) {
        throw WalletPaymentServiceException(
          'Failed to query past Google Play purchases',
          cause: response.error,
        );
      }

      var recovered = 0;
      Object? firstError;
      for (final purchase in response.pastPurchases) {
        if (purchase.status != PurchaseStatus.purchased) continue;
        try {
          await _inAppPurchase.completePurchase(purchase);
          await addition.consumePurchase(purchase);
          recovered++;
        } catch (error) {
          firstError ??= error;
        }
      }
      if (firstError != null) {
        throw WalletPaymentServiceException(
          'Failed to finish one or more Google Play purchases',
          cause: firstError,
        );
      }
      return recovered;
    }

    if (Platform.isIOS) {
      await _inAppPurchase.restorePurchases();
    }
    return 0;
  }
}

class WalletPaymentServiceException implements Exception {
  const WalletPaymentServiceException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message: $cause';
}
