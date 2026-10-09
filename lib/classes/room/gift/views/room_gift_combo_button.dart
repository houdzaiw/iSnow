import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pag/pag.dart';

import '../../../../theme/app_theme.dart';

class RoomGiftComboButton extends StatelessWidget {
  const RoomGiftComboButton({
    super.key,
    required this.enabled,
    required this.sending,
    required this.onTap,
    this.size = AppSpacing.giftSlotComboSize,
  });

  final bool enabled, sending;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size.r,
    height: size.r,
    child: Material(
      color: AppColors.roomGiftAccent,
      shape: const CircleBorder(),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: PAGView.asset(
                AppAssets.roomGiftComboEffect,
                autoPlay: true,
                repeatCount: PAGView.REPEAT_COUNT_LOOP,
              ),
            ),
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: Center(
              child: sending
                  ? SizedBox(
                      width: AppSpacing.iconSizeSm.r,
                      height: AppSpacing.iconSizeSm.r,
                      child: const CircularProgressIndicator(
                        color: AppColors.textInverse,
                        strokeWidth: AppSpacing.xxs,
                      ),
                    )
                  : Text('Combo', style: AppTextStyles.giftEffectSubtitle),
            ),
          ),
        ],
      ),
    ),
  );
}
