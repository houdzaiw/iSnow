import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'wallet_models.dart';
import 'wallet_product_card.dart';
import 'wallet_state.dart';
import 'wallet_view_model.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletViewModelProvider);
    final notifier = ref.read(walletViewModelProvider.notifier);

    ref.listen<WalletState>(walletViewModelProvider, (previous, next) {
      if (previous?.noticeKey == next.noticeKey || next.noticeKey == null) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t(next.noticeKey!))));
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: AppColors.walletBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.walletBackground,
        body: Stack(
          children: [
            Column(
              children: [
                _WalletHeader(balance: state.purse?.coin ?? 0),
                Expanded(
                  child: _WalletContent(
                    state: state,
                    onRefresh: () => notifier.load(refresh: true),
                    onSelect: notifier.selectProduct,
                    onTransfer: notifier.purchase,
                  ),
                ),
              ],
            ),
            if (state.isLoading && !state.isRefreshing)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.walletHeaderHeight.w,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: AppRadius.walletHeaderBorder,
              child: Image.asset(
                AppAssets.walletHeaderBackground,
                fit: BoxFit.fill,
              ),
            ),
          ),
          Positioned(
            top: safeTop,
            left: AppSpacing.walletBackLeftInset.w,
            right: AppSpacing.walletHistoryRightInset.w,
            height: AppSpacing.walletNavigationHeight.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Image.asset(
                      AppAssets.walletBack,
                      width: AppSpacing.walletHeaderIconBoxSize.w,
                      height: AppSpacing.walletHeaderIconBoxSize.w,
                    ),
                  ),
                ),
                Text(
                  context.l10n.t('wallet.agentAccount'),
                  style: AppTextStyles.walletNavigationTitle,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    label: context.l10n.t('wallet.paymentRecords'),
                    image: true,
                    child: SizedBox(
                      width: AppSpacing.walletHeaderIconBoxSize.w,
                      height: AppSpacing.walletHeaderIconBoxSize.w,
                      child: Center(
                        child: Image.asset(
                          AppAssets.walletHistory,
                          width: AppSpacing.walletHistoryIconSize.w,
                          height: AppSpacing.walletHistoryIconSize.w,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.walletTradingTitleTop.w,
            left: AppSpacing.walletHeaderHorizontalInset.w,
            child: Text(
              context.l10n.t('wallet.coinsTrading'),
              style: AppTextStyles.walletTradingTitle,
            ),
          ),
          Positioned(
            top: AppSpacing.walletBalanceTop.w,
            left: AppSpacing.walletHeaderHorizontalInset.w,
            right: AppSpacing.walletHeaderHorizontalInset.w,
            child: Row(
              children: [
                Image.asset(
                  AppAssets.walletBalanceCoin,
                  width: AppSpacing.walletBalanceCoinSize.w,
                  height: AppSpacing.walletBalanceCoinSize.w,
                ),
                SizedBox(width: AppSpacing.walletBalanceCoinGap.w),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatWalletWholeNumber(context, balance),
                      maxLines: 1,
                      style: AppTextStyles.walletBalance,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletContent extends StatelessWidget {
  const _WalletContent({
    required this.state,
    required this.onRefresh,
    required this.onSelect,
    required this.onTransfer,
  });

  final WalletState state;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSelect;
  final Future<void> Function(WalletRechargeProduct product) onTransfer;

  @override
  Widget build(BuildContext context) {
    final selectedProduct = state.selectedProduct;
    return RefreshIndicator(
      color: AppColors.walletBrandOrange,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom:
              AppSpacing.walletContentBottomInset.w +
              MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.walletContentTitleTop.w,
              left: AppSpacing.walletContentTitleHorizontalInset.w,
              right: AppSpacing.walletContentTitleHorizontalInset.w,
            ),
            child: Text(
              context.l10n.t('wallet.selectPaymentMethod'),
              style: AppTextStyles.walletPaymentTitle,
            ),
          ),
          SizedBox(height: AppSpacing.walletGridTop.w),
          if (state.loadError != null)
            _WalletStatus(
              message: context.l10n.t('wallet.loadFailed'),
              action: context.l10n.t('app.retry'),
              onAction: onRefresh,
            )
          else if (state.products.isEmpty)
            _WalletStatus(message: context.l10n.t('wallet.emptyProducts'))
          else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.walletGridHorizontalInset.w,
              ),
              itemCount: state.products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.walletGridCrossSpacing.w,
                mainAxisSpacing: AppSpacing.walletGridMainSpacing.w,
                mainAxisExtent: AppSpacing.walletProductTileHeight.w,
              ),
              itemBuilder: (context, index) {
                final product = state.products[index];
                return WalletProductCard(
                  product: product,
                  selected: product.id == state.selectedProductId,
                  onTap: () => onSelect(product.id),
                );
              },
            ),
            SizedBox(height: AppSpacing.walletTransferTop.w),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.walletTransferHorizontalInset.w,
              ),
              child: Semantics(
                button: true,
                enabled: selectedProduct != null && !state.isPurchasing,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: selectedProduct == null || state.isPurchasing
                      ? null
                      : () => onTransfer(selectedProduct),
                  child: Container(
                    height: AppSpacing.walletTransferHeight.w,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.walletBrandOrange,
                      borderRadius: AppRadius.pillBorder,
                    ),
                    child: state.isPurchasing
                        ? SizedBox(
                            width: AppSpacing.iconSizeSm.w,
                            height: AppSpacing.iconSizeSm.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: AppSpacing.xxs,
                              color: AppColors.textInverse,
                            ),
                          )
                        : Text(
                            context.l10n.t('wallet.transfer'),
                            style: AppTextStyles.walletTransfer,
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.walletContactTop.w),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/about-us'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.t('wallet.contactUs'),
                      style: AppTextStyles.walletContact,
                    ),
                    SizedBox(width: AppSpacing.walletContactGap.w),
                    Image.asset(
                      AppAssets.walletContactArrow,
                      width: AppSpacing.walletContactArrowWidth.w,
                      height: AppSpacing.walletContactArrowHeight.w,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WalletStatus extends StatelessWidget {
  const _WalletStatus({required this.message, this.action, this.onAction});

  final String message;
  final String? action;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.walletGridHorizontalInset.w,
        vertical: AppSpacing.walletStatusVerticalInset.w,
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.walletGuide,
          ),
          if (action != null && onAction != null) ...[
            SizedBox(height: AppSpacing.lg.w),
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: AppTextStyles.walletContact),
            ),
          ],
        ],
      ),
    );
  }
}
