import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';

class RoomGiftPromotionBar extends StatelessWidget {
  const RoomGiftPromotionBar({
    super.key,
    this.onOpenFirstRecharge,
    this.showFirstRecharge = false,
    this.onOpenCampaign,
    this.bannerUrl,
  });

  final VoidCallback? onOpenFirstRecharge;
  final bool showFirstRecharge;
  final VoidCallback? onOpenCampaign;
  final String? bannerUrl;

  @override
  Widget build(BuildContext context) {
    final first = showFirstRecharge && onOpenFirstRecharge != null;
    final banner = bannerUrl?.trim() ?? '';
    if (!first && banner.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: AppSpacing.roomGiftPromotionHeight.h,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.roomGiftPromotionInset.w,
        ),
        child: Row(
          children: [
            if (first)
              Semantics(
                label: context.l10n.t('room.gift.firstRecharge'),
                button: true,
                child: InkWell(
                  onTap: onOpenFirstRecharge,
                  child: Image.asset(
                    AppAssets.roomGiftFirstRecharge,
                    width: AppSpacing.roomGiftRechargeWidth.w,
                    height: AppSpacing.roomGiftRechargeHeight.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (first && banner.isNotEmpty) SizedBox(width: AppSpacing.xxs.w),
            if (banner.isNotEmpty)
              Expanded(
                child: SizedBox(
                  height: AppSpacing.roomGiftCampaignHeight.h,
                  child: CachedNetworkImage(
                    imageUrl: banner,
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
