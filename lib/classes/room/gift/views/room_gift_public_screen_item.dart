import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/app_theme.dart';
import '../models/room_gift_event_models.dart';
import 'room_gift_image.dart';

class RoomGiftPublicScreenItem extends StatelessWidget {
  const RoomGiftPublicScreenItem({super.key, required this.message});
  final RoomGiftPublicMessage message;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipOval(
        child: RoomGiftImage(
          source: message.sender.avatar,
          size: AppSpacing.giftSlotAvatarSize.r,
        ),
      ),
      SizedBox(width: AppSpacing.sm.w),
      Expanded(
        child: Container(
          padding: EdgeInsets.all(AppSpacing.sm.r),
          decoration: const BoxDecoration(
            color: AppColors.giftSlotBackground,
            borderRadius: AppRadius.cardBorder,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.sender.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.giftEffectTitle,
                    ),
                    Text(
                      '${message.gift.name} x${message.count} → ${message.targetLabel}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.giftEffectSubtitle,
                    ),
                    if (message.winAmount > 0)
                      Text(
                        '+${message.winAmount} coins',
                        style: AppTextStyles.giftEffectTitle,
                      ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.xs.w),
              RoomGiftImage(
                source: message.gift.icon,
                size: AppSpacing.giftSlotAvatarSize.r,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
