import 'wallet_models.dart';

const Object _walletStateUnset = Object();

class WalletState {
  const WalletState({
    this.selectedTab = 0,
    this.purse,
    this.products = const <WalletRechargeProduct>[],
    this.diamondReminder = '',
    this.isLoading = false,
    this.isRefreshing = false,
    this.purchaseProductId,
    this.loadError,
    this.noticeKey,
  });

  final int selectedTab;
  final WalletPurse? purse;
  final List<WalletRechargeProduct> products;
  final String diamondReminder;
  final bool isLoading;
  final bool isRefreshing;
  final String? purchaseProductId;
  final Object? loadError;
  final String? noticeKey;

  bool get isPurchasing => purchaseProductId != null;

  WalletState copyWith({
    int? selectedTab,
    WalletPurse? purse,
    List<WalletRechargeProduct>? products,
    String? diamondReminder,
    bool? isLoading,
    bool? isRefreshing,
    Object? purchaseProductId = _walletStateUnset,
    Object? loadError = _walletStateUnset,
    Object? noticeKey = _walletStateUnset,
  }) {
    return WalletState(
      selectedTab: selectedTab ?? this.selectedTab,
      purse: purse ?? this.purse,
      products: products ?? this.products,
      diamondReminder: diamondReminder ?? this.diamondReminder,
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
