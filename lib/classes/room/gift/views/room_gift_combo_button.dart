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
    this.size = AppSpacing.giftComboButtonSize,
    this.remainingMilliseconds = 0,
  });

  final bool enabled, sending;
  final VoidCallback onTap;
  final double size;
  final int remainingMilliseconds;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size.r,
    height: size.r,
    child: Material(
      color: AppColors.transparent,
      shape: const CircleBorder(),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: PAGView.asset(
                AppAssets.roomGiftComboEffect,
                width: size.r,
                height: size.r,
                autoPlay: true,
                repeatCount: PAGView.REPEAT_COUNT_LOOP,
                defaultBuilder: (_) => DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.roomGiftAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: size.r * AppSpacing.giftComboLabelTopRatio,
                        left: 0,
                        right: 0,
                        child: Text(
                          'Combo',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.giftComboLabel.copyWith(
                            fontSize: AppTextStyles.giftComboLabel.fontSize!.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: Stack(
              children: [
                if (sending)
                  Center(
                    child: SizedBox(
                      width: AppSpacing.iconSizeSm.r,
                      height: AppSpacing.iconSizeSm.r,
                      child: const CircularProgressIndicator(
                        color: AppColors.textInverse,
                        strokeWidth: AppSpacing.xxs,
                      ),
                    ),
                  ),
                if (!sending && remainingMilliseconds > 0)
                  Positioned(
                    bottom: size.r * AppSpacing.giftComboCountdownBottomRatio,
                    left: 0,
                    right: 0,
                    child: Text(
                      '${(remainingMilliseconds / 1000).toStringAsFixed(1)}s',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.giftComboCountdown.copyWith(
                        fontSize: AppTextStyles.giftComboCountdown.fontSize!.r,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
