import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'wallet_models.dart';

class WalletProductCard extends StatelessWidget {
  const WalletProductCard({
    super.key,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final WalletRechargeProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = product.remark?.trim() ?? '';
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${formatWalletWholeNumber(context, product.coinAmount)}, '
          '${formatWalletPrice(context, product.dollarAmount)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: AppSpacing.walletProductCardTop.w,
              left: 0,
              right: 0,
              child: Container(
                height: AppSpacing.walletProductCardHeight.w,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: selected ? null : AppColors.walletProductSurface,
                  gradient: selected
                      ? AppGradients.walletSelectedProduct
                      : null,
                  border: Border.all(
                    color: selected
                        ? AppColors.walletSelectedBorder
                        : AppColors.walletProductBorder,
                    width: AppSpacing.walletProductBorderWidth.w,
                  ),
                  borderRadius: AppRadius.walletProductCardBorder,
                ),
                child: Column(
                  children: [
                    SizedBox(height: AppSpacing.walletProductContentTop.w),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.walletProductHorizontalInset.w,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            AppAssets.walletProductCoin,
                            width: AppSpacing.walletProductCoinSize.w,
                            height: AppSpacing.walletProductCoinSize.w,
                          ),
                          SizedBox(width: AppSpacing.walletProductAmountGap.w),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatWalletWholeNumber(
                                  context,
                                  product.coinAmount,
                                ),
                                maxLines: 1,
                                style: selected
                                    ? AppTextStyles.walletProductAmountSelected
                                    : AppTextStyles.walletProductAmount,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.walletProductSubtitleTop.w),
                    SizedBox(
                      height: AppSpacing.walletProductSubtitleHeight.w,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.walletProductHorizontalInset.w,
                        ),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: selected
                              ? AppTextStyles.walletProductSubtitleSelected
                              : AppTextStyles.walletProductSubtitle,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: AppSpacing.walletProductPriceHeight.w,
                      alignment: Alignment.center,
                      decoration: selected
                          ? const BoxDecoration(
                              gradient: AppGradients.walletSelectedPrice,
                              borderRadius: AppRadius.walletProductPriceBorder,
                            )
                          : null,
                      child: Text(
                        formatWalletPrice(context, product.dollarAmount),
                        style: selected
                            ? AppTextStyles.walletProductPriceSelected
                            : AppTextStyles.walletProductPrice,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: AppSpacing.walletPromotionWidth.w,
                  height: AppSpacing.walletPromotionHeight.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.walletSelectedAmount,
                    borderRadius: AppRadius.walletPromotionBorder,
                  ),
                  child: Text(
                    context.l10n.t('wallet.promotion'),
                    style: AppTextStyles.walletPromotion,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String formatWalletWholeNumber(BuildContext context, int value) {
  return NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);
}

String formatWalletPrice(BuildContext context, int cents) {
  final amount = cents / 100;
  final decimalDigits = cents % 100 == 0 ? 0 : 2;
  return NumberFormat.currency(
    locale: Localizations.localeOf(context).toLanguageTag(),
    symbol: r'$',
    decimalDigits: decimalDigits,
  ).format(amount);
}
