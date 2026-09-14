import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'wallet_models.dart';
import 'wallet_state.dart';
import 'wallet_view_model.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  bool _didApplyInitialTab = false;

  @override
  Widget build(BuildContext context) {
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

    if (!_didApplyInitialTab) {
      _didApplyInitialTab = true;
      final tab = widget.initialTab.clamp(0, 1);
      if (tab != state.selectedTab) {
        Future.microtask(() => notifier.selectTab(tab));
      }
    }

    final background = state.selectedTab == 0
        ? AppAssets.walletTopBgCoins
        : AppAssets.walletTopBgDiamonds;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.walletBackground,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Image.asset(AppAssets.walletBack, width: 36.w, height: 36.w),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: _WalletTabs(
          selectedTab: state.selectedTab,
          onSelected: notifier.selectTab,
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              background,
              height: (1.sw * 625) / 1125,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Column(
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top + 22.w),
              Expanded(
                child: IndexedStack(
                  index: state.selectedTab,
                  children: [
                    _WalletCoinsView(
                      state: state,
                      onRefresh: () => notifier.load(refresh: true),
                      onPurchase: notifier.purchase,
                    ),
                    _WalletDiamondsView(
                      state: state,
                      onRefresh: () => notifier.load(refresh: true),
                    ),
                  ],
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
    );
  }
}

class _WalletTabs extends StatelessWidget {
  const _WalletTabs({required this.selectedTab, required this.onSelected});

  final int selectedTab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31.w,
      decoration: BoxDecoration(
        color: const Color(0x80000000),
        borderRadius: BorderRadius.circular(22.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WalletTab(
            title: context.l10n.t('wallet.coins'),
            selected: selectedTab == 0,
            onTap: () => onSelected(0),
          ),
          _WalletTab(
            title: context.l10n.t('wallet.diamonds'),
            selected: selectedTab == 1,
            onTap: () => onSelected(1),
          ),
        ],
      ),
    );
  }
}

class _WalletTab extends StatelessWidget {
  const _WalletTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 84.w,
        height: 31.w,
        alignment: Alignment.center,
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(22.w),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE9DB94),
                    Color(0xFFF5F3DB),
                    Color(0xFFE9DB94),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        child: Text(
          title,
          style: selected
              ? AppTextStyles.walletTabSelected
              : AppTextStyles.walletTab,
        ),
      ),
    );
  }
}

class _WalletCoinsView extends StatelessWidget {
  const _WalletCoinsView({
    required this.state,
    required this.onRefresh,
    required this.onPurchase,
  });

  final WalletState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function(WalletRechargeProduct product) onPurchase;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WalletBalance(
          balance: state.purse?.coin ?? 0,
          icon: AppAssets.walletBalanceCoin,
        ),
        Expanded(
          child: _WalletPanel(
            child: RefreshIndicator(
              color: AppColors.primaryPink,
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: AppSpacing.walletPanelTopInset.w,
                  bottom:
                      AppSpacing.walletPanelBottomInset.w +
                      MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _WalletSectionHeader(
                    title: context.l10n.t('wallet.recharge'),
                    showFirst: state.purse?.isFirst ?? false,
                  ),
                  if (state.loadError != null)
                    _WalletLoadError(onRetry: onRefresh)
                  else if (state.products.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 44.w),
                      child: Text(
                        context.l10n.t('wallet.emptyProducts'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.walletGuide,
                      ),
                    )
                  else
                    for (
                      var index = 0;
                      index < state.products.length;
                      index++
                    ) ...[
                      _RechargeProductRow(
                        product: state.products[index],
                        isPurchasing:
                            state.purchaseProductId == state.products[index].id,
                        onPurchase: () => onPurchase(state.products[index]),
                      ),
                      if (index != state.products.length - 1)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                          child: const Divider(
                            height: 1,
                            color: AppColors.walletPanelDivider,
                          ),
                        ),
                    ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletDiamondsView extends StatelessWidget {
  const _WalletDiamondsView({required this.state, required this.onRefresh});

  final WalletState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final reminder = _plainText(state.diamondReminder);
    return Column(
      children: [
        _WalletBalance(
          balance: state.purse?.diamond ?? 0,
          icon: AppAssets.walletDiamondBalance,
        ),
        Expanded(
          child: _WalletPanel(
            child: RefreshIndicator(
              color: AppColors.primaryPink,
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: AppSpacing.walletPanelTopInset.w,
                  bottom:
                      AppSpacing.walletPanelBottomInset.w +
                      MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Text(
                      context.l10n.t('wallet.earnDiamonds'),
                      style: AppTextStyles.walletSectionTitle,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10.w, 16.w, 10.w, 20.w),
                    child: const Divider(
                      height: 1,
                      color: AppColors.walletPanelDivider,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Text(
                      reminder.isEmpty
                          ? context.l10n.t('wallet.earnDiamonds')
                          : reminder,
                      style: AppTextStyles.walletGuide,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletLoadError extends StatelessWidget {
  const _WalletLoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.w),
      child: Column(
        children: [
          Text(
            context.l10n.t('wallet.loadFailed'),
            textAlign: TextAlign.center,
            style: AppTextStyles.walletGuide,
          ),
          SizedBox(height: 12.w),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              context.l10n.t('app.retry'),
              style: AppTextStyles.walletSectionTitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBalance extends StatelessWidget {
  const _WalletBalance({required this.balance, required this.icon});

  final int balance;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.walletContentWidth.w,
      height: (AppSpacing.walletBalanceTop + AppSpacing.walletBalanceHeight).w,
      child: Padding(
        padding: EdgeInsets.only(top: AppSpacing.walletBalanceTop.w),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    icon,
                    width: 30.w,
                    height: 32.w,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    context.l10n.t('wallet.myBalance'),
                    style: AppTextStyles.walletBalanceLabel,
                  ),
                  SizedBox(width: 6.w),
                  Image.asset(
                    AppAssets.walletBalanceArrow,
                    width: 18.w,
                    height: 18.w,
                  ),
                ],
              ),
              SizedBox(height: 8.w),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFEE52)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text('$balance', style: AppTextStyles.walletBalance),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletPanel extends StatelessWidget {
  const _WalletPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.walletPanelHorizontalInset.w,
      ),
      decoration: BoxDecoration(
        color: AppColors.walletPanelEnd,
        image: const DecorationImage(
          image: AssetImage(AppAssets.walletCommonHeader),
          alignment: Alignment.topCenter,
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.walletPanelTopRadius.w),
          topRight: Radius.circular(AppSpacing.walletPanelTopRadius.w),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _WalletSectionHeader extends StatelessWidget {
  const _WalletSectionHeader({required this.title, required this.showFirst});

  final String title;
  final bool showFirst;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.walletRechargeHeaderHeight.w,
      child: Row(
        children: [
          SizedBox(width: 10.w),
          if (showFirst) ...[
            Image.asset(AppAssets.walletCoinsTop, width: 47.w, height: 41.w),
            SizedBox(width: 2.w),
          ],
          Text(title, style: AppTextStyles.walletSectionTitle),
        ],
      ),
    );
  }
}

class _RechargeProductRow extends StatelessWidget {
  const _RechargeProductRow({
    required this.product,
    required this.isPurchasing,
    required this.onPurchase,
  });

  final WalletRechargeProduct product;
  final bool isPurchasing;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final price = (product.dollarAmount / 100).toStringAsFixed(2);
    return SizedBox(
      height: AppSpacing.walletRechargeRowHeight.w,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.walletRechargeRowHorizontalInset.w,
        ),
        child: Row(
          children: [
            Image.asset(AppAssets.walletCoin, width: 24.w, height: 24.w),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                product.coinAmount.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.walletCoinAmount,
              ),
            ),
            SizedBox(width: 12.w),
            Semantics(
              button: true,
              label: '\$ $price',
              child: GestureDetector(
                onTap: isPurchasing ? null : onPurchase,
                child: Container(
                  width: AppSpacing.walletRechargeButtonWidth.w,
                  height: AppSpacing.walletRechargeButtonHeight.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFFFDF2BC), Color(0xFFAC9553)],
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppSpacing.walletRechargeButtonRadius),
                    ),
                  ),
                  child: isPurchasing
                      ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.walletActionText,
                          ),
                        )
                      : Text('\$ $price', style: AppTextStyles.walletPrice),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _plainText(String value) {
  return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}
