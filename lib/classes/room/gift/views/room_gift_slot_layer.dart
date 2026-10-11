import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/app_theme.dart';
import '../queue/room_gift_slot_queue.dart';
import 'room_gift_image.dart';

class RoomGiftSlotLayer extends StatelessWidget {
  const RoomGiftSlotLayer({
    super.key,
    required this.slots,
    required this.roomId,
  });
  final List<RoomGiftSlot?> slots;
  final String roomId;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slot in slots)
          SizedBox(
            height: (AppSpacing.giftSlotHeight + AppSpacing.xs).h,
            child: slot == null
                ? null
                : _GiftSlotCard(
                    key: ValueKey('$roomId:${slot.key}'),
                    slot: slot,
                  ),
          ),
      ],
    );
  }
}

class _GiftSlotCard extends StatelessWidget {
  const _GiftSlotCard({super.key, required this.slot});
  final RoomGiftSlot slot;
  @override
  Widget build(BuildContext context) {
    final message = slot.message;
    return Row(
      children: [
        Expanded(
          child: IgnorePointer(
            child: Container(
              height: AppSpacing.giftSlotHeight.h,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
              decoration: const BoxDecoration(
                color: AppColors.giftSlotBackground,
                borderRadius: AppRadius.pillBorder,
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: RoomGiftImage(
                      source: message.userInfo.avatar,
                      size: AppSpacing.giftSlotAvatarSize.r,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.userInfo.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.giftEffectTitle,
                        ),
                        Text(
                          '${message.gift.name} → ${message.targetLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.giftEffectSubtitle,
                        ),
                      ],
                    ),
                  ),
                  RoomGiftImage(
                    source: message.gift.icon,
                    size: AppSpacing.giftSlotIconSize.r,
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  SizedBox(
                    width: AppSpacing.giftSlotComboSize.w,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Text(
                          'x${message.displayCount}',
                          key: ValueKey(message.displayCount),
                          style: AppTextStyles.giftComboCount,
                        ),
                      ),
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
