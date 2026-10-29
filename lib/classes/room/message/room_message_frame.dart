import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_theme.dart';

class RoomMessageFrame extends StatelessWidget {
  const RoomMessageFrame({
    super.key,
    required this.title,
    required this.child,
    this.chat = false,
    this.onBack,
  });
  final String title;
  final Widget child;
  final bool chat;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: double.infinity,
          height: math.min(
            constraints.maxHeight,
            chat && media.viewInsets.bottom > 0
                ? constraints.maxHeight
                : media.size.height * AppSpacing.roomMessageHeightRatio,
          ),
          child: Material(
            color: AppColors.roomMessagePanel,
            borderRadius: AppRadius.roomToolsSheetBorder,
            clipBehavior: Clip.antiAlias,
            child: ScaffoldMessenger(
              child: Scaffold(
                backgroundColor: AppColors.roomMessageSurface,
                resizeToAvoidBottomInset: false,
                body: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      SizedBox(
                        height: AppSpacing.roomMessageHandleArea.h,
                        child: Center(
                          child: Container(
                            width: AppSpacing.roomMessageHandleWidth.w,
                            height: AppSpacing.roomMessageHandleHeight.h,
                            decoration: const BoxDecoration(
                              color: AppColors.roomMessageHandle,
                              borderRadius: AppRadius.fieldBorder,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: AppSpacing.controlHeightMd.h,
                        child: Row(
                          children: [
                            SizedBox(
                              width: AppSpacing.controlHeightMd.w,
                              child: onBack == null
                                  ? null
                                  : IconButton(
                                      key: const ValueKey(
                                        'room-private-chat-back',
                                      ),
                                      tooltip: 'Back',
                                      onPressed: onBack,
                                      icon: Image.asset(
                                        AppAssets.backWhiteButton,
                                        width: AppSpacing.iconSizeMd.r,
                                        height: AppSpacing.iconSizeMd.r,
                                      ),
                                    ),
                            ),
                            Expanded(
                              child: Text(
                                title,
                                style: AppTextStyles.roomMessageTitle,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: AppSpacing.controlHeightMd.w),
                          ],
                        ),
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
