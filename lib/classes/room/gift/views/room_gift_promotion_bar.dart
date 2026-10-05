import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';

class RoomGiftPromotionBar extends StatelessWidget {
  const RoomGiftPromotionBar({
    super.key,
    required this.onOpenWallet,
    this.onOpenCampaign,
    this.bannerUrl,
  });

  final VoidCallback onOpenWallet;
  final VoidCallback? onOpenCampaign;
  final String? bannerUrl;

  @override
  Widget build(BuildContext context) {
    final campaign = Image.asset(
      AppAssets.roomGiftCampaign,
      fit: BoxFit.contain,
    );
    return SizedBox(
      height: AppSpacing.roomGiftPromotionHeight.h,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.roomGiftPromotionInset.w,
        ),
        child: Row(
          children: [
            Semantics(
              label: context.l10n.t('profile.recharge'),
              button: true,
              child: InkWell(
                onTap: onOpenWallet,
                child: Image.asset(
                  AppAssets.roomGiftFirstRecharge,
                  width: AppSpacing.roomGiftRechargeWidth.w,
                  height: AppSpacing.roomGiftRechargeHeight.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.xxs.w),
            Expanded(
              child: SizedBox(
                height: AppSpacing.roomGiftCampaignHeight.h,
                child: bannerUrl?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: bannerUrl!,
                        fit: BoxFit.contain,
                        imageBuilder: (_, image) => GestureDetector(
                          onTap: onOpenCampaign,
                          child: Image(image: image, fit: BoxFit.contain),
                        ),
                        placeholder: (_, __) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => Image.asset(
                          AppAssets.lanhuRoomIconMissing,
                          fit: BoxFit.contain,
                        ),
                      )
                    : campaign,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
