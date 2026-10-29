import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_theme.dart';
import 'room_settings_content.dart';
import 'room_tools_widgets.dart';

Future<void> showRoomCharmSettingsSheet(BuildContext context, String roomId) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.modalScrimStrong,
      builder: (_) => RoomCharmSettingsSheet(roomId: roomId),
    );

class RoomCharmSettingsSheet extends StatelessWidget {
  const RoomCharmSettingsSheet({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        key: const ValueKey('room-charm-settings-sheet'),
        width: double.infinity,
        height: AppSpacing.roomCharmSheetHeight.h.clamp(
          0,
          constraints.maxHeight,
        ),
        child: Material(
          borderRadius: AppRadius.roomToolsSheetBorder,
          clipBehavior: Clip.antiAlias,
          child: ScaffoldMessenger(
            child: Scaffold(
              backgroundColor: AppColors.roomToolsSheet,
              resizeToAvoidBottomInset: false,
              body: SafeArea(
                top: false,
                child: Column(
                  children: [
                    SizedBox(
                      height: AppSpacing.roomToolsTabHeight.h,
                      child: Row(
                        children: [
                          SizedBox(
                            width: AppSpacing.controlHeightMd.w,
                            child: IconButton(
                              key: const ValueKey('room-charm-settings-back'),
                              tooltip: toolText(context, 'Back', '返回'),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Image.asset(
                                AppAssets.lanhuNavBack,
                                width: AppSpacing.iconSizeMd.r,
                                height: AppSpacing.iconSizeMd.r,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              toolText(context, 'Charm Setting', '魅力值设置'),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.roomToolsHeading,
                            ),
                          ),
                          SizedBox(width: AppSpacing.controlHeightMd.w),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(
                          AppSpacing.roomToolsContentInset.w,
                        ),
                        child: RoomCharmCurrencyContent(roomId: roomId),
                      ),
                    ),
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
