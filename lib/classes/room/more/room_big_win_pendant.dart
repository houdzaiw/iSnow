import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'room_big_win_page.dart';
import 'room_tools_controller.dart';
import 'room_tools_widgets.dart';

/// Activity entry only; placement belongs to the room's floating layer.
class RoomBigWinPendant extends ConsumerWidget {
  const RoomBigWinPendant({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    if (!state.showBigWinPendant) return const SizedBox.shrink();
    final amount = state.bigWinSnapshot.poolLabel;
    final label = '${toolText(context, 'Game Big Win', '游戏大奖')}: $amount';
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadius.fieldBorder,
          child: InkWell(
            key: const ValueKey('room-big-win-pendant'),
            borderRadius: AppRadius.fieldBorder,
            onTap: () => pushRoomTool(context, RoomBigWinPage(roomId: roomId)),
            child: ExcludeSemantics(
              child: SizedBox(
                width: AppSpacing.controlHeightLg.r,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.lanhuRoomBigWinBanner,
                      width: AppSpacing.controlHeightLg.r,
                      height: AppSpacing.controlHeightLg.r,
                      fit: BoxFit.contain,
                    ),
                    if (amount.isNotEmpty)
                      Container(
                        height: AppSpacing.xl.r,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs.w,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.roomMusicStripSurface,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            amount,
                            key: const ValueKey('room-big-win-pool'),
                            maxLines: 1,
                            style: AppTextStyles.roomPendantAmount,
                          ),
                        ),
                      )
                    else
                      SizedBox(height: AppSpacing.xl.r),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
