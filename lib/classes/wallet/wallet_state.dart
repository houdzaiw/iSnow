import 'wallet_models.dart';

const Object _walletStateUnset = Object();

class WalletState {
  const WalletState({
    this.purse,
    this.products = const <WalletRechargeProduct>[],
    this.selectedProductId,
    this.isLoading = false,
    this.isRefreshing = false,
    this.purchaseProductId,
    this.loadError,
    this.noticeKey,
  });

  final WalletPurse? purse;
  final List<WalletRechargeProduct> products;
  final String? selectedProductId;
  final bool isLoading;
  final bool isRefreshing;
  final String? purchaseProductId;
  final Object? loadError;
  final String? noticeKey;

  bool get isPurchasing => purchaseProductId != null;

  WalletRechargeProduct? get selectedProduct {
    for (final product in products) {
      if (product.id == selectedProductId) return product;
    }
    return null;
  }

  WalletState copyWith({
    WalletPurse? purse,
    List<WalletRechargeProduct>? products,
    Object? selectedProductId = _walletStateUnset,
    bool? isLoading,
    bool? isRefreshing,
    Object? purchaseProductId = _walletStateUnset,
    Object? loadError = _walletStateUnset,
    Object? noticeKey = _walletStateUnset,
  }) {
    return WalletState(
      purse: purse ?? this.purse,
      products: products ?? this.products,
      selectedProductId: identical(selectedProductId, _walletStateUnset)
          ? this.selectedProductId
          : selectedProductId as String?,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      purchaseProductId: identical(purchaseProductId, _walletStateUnset)
          ? this.purchaseProductId
          : purchaseProductId as String?,
      loadError: identical(loadError, _walletStateUnset)
          ? this.loadError
          : loadError,
      noticeKey: identical(noticeKey, _walletStateUnset)
          ? this.noticeKey
          : noticeKey as String?,
    );
  }
}
