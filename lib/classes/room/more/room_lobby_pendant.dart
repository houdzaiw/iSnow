import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'room_lobby_navigation.dart';
import 'room_tools_controller.dart';
import 'room_tools_widgets.dart';

/// Local lobby entry, separate from the Game Big Win activity pendant.
class RoomLobbyPendant extends ConsumerWidget {
  const RoomLobbyPendant({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    final vm = ref.read(roomToolsControllerProvider(roomId).notifier);
    if (!vm.showLobbyPendant) return const SizedBox.shrink();
    final label = state.lobbyType == 2
        ? toolText(context, 'Treasure', '宝藏大厅')
        : toolText(context, 'Win lobby', 'Win 大厅');
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.sm.h),
      child: Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: Material(
            color: AppColors.transparent,
            borderRadius: AppRadius.fieldBorder,
            child: InkWell(
              key: const ValueKey('room-lobby-pendant'),
              borderRadius: AppRadius.fieldBorder,
              onTap: () => openRoomLobby(context, ref, roomId),
              child: ExcludeSemantics(
                child: Image.asset(
                  state.lobbyType == 2
                      ? AppAssets.roomLobbyTreasure
                      : AppAssets.roomLobbyWin,
                  width: AppSpacing.controlHeightLg.r,
                  height: AppSpacing.controlHeightLg.r,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    AppAssets.lanhuRoomIconMissing,
                    width: AppSpacing.controlHeightLg.r,
                    height: AppSpacing.controlHeightLg.r,
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
