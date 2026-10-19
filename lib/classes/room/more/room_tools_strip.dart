import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'room_big_win_page.dart';
import 'room_entry_flow.dart';
import 'room_lobby_page.dart';
import 'room_lucky_box_page.dart';
import 'room_pk_page.dart';
import 'room_tools_controller.dart';
import 'room_tools_models.dart';
import 'room_tools_widgets.dart';
import 'room_world_banner.dart';

class RoomToolsStrip extends HookConsumerWidget {
  const RoomToolsStrip({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    final vm = ref.read(roomToolsControllerProvider(roomId).notifier);
    final banner = state.worldBanners.firstOrNull;
    final award = state.lobbyAwards.firstOrNull;
    useEffect(() {
      if (award == null) return null;
      final timer = Timer(
        Duration(seconds: toolInt(award['_duration'], 3)),
        () {
          if (vm.mounted) vm.completeAward('${award['_key']}');
        },
      );
      return timer.cancel;
    }, [award?['_key'], award?['_duration']]);
    useEffect(() {
      if (banner == null) return null;
      final timer = Timer(const Duration(seconds: 5), () {
        if (vm.mounted) vm.dismissWorld('${banner['_key']}');
      });
      return timer.cancel;
    }, [banner?['_key']]);
    if (!state.sessionActive) return const SizedBox.shrink();
    final ready = state.bags
        .where((bag) => bag.remaining(DateTime.now()) == 0)
        .firstOrNull;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height *
            AppSpacing.roomToolsStripMaxHeightRatio,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (award != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: ListTile(
                  key: ValueKey(award['_key']),
                  dense: true,
                  leading: ToolImage(
                    '${toolMap(award['userBaseInfo'])['avatar'] ?? ''}',
                    size: AppSpacing.iconSizeLg,
                  ),
                  title: Text(
                    '${toolMap(award['userBaseInfo'])['nick'] ?? ''} x${award['multiple'] ?? 1}  ${award['winAmount'] ?? 0}',
                    style: AppTextStyles.roomGiftStatus,
                  ),
                  onTap: () {
                    vm.completeAward('${award['_key']}');
                    vm.restoreLobby();
                    pushRoomTool(context, RoomLobbyPage(roomId: roomId));
                  },
                ),
              ),
            if (banner != null)
              RoomWorldBanner(
                banner: banner,
                onTap: () =>
                    enterSharedRoom(context, ref, '${banner['roomId'] ?? ''}'),
              ),
            if (state.prize.isNotEmpty)
              ListTile(
                dense: true,
                title: Text(
                  '${toolText(context, 'Big Win', '大奖')}: ${state.prize['userWinCoins'] ?? 0}',
                  style: AppTextStyles.roomGiftStatus,
                ),
                trailing: TextButton(
                  onPressed: vm.dismissPrize,
                  child: Image.asset(
                    AppAssets.roomMiniClose,
                    width: AppSpacing.iconSizeSm,
                  ),
                ),
                onTap: () =>
                    pushRoomTool(context, RoomBigWinPage(roomId: roomId)),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if ([1, 2].contains(state.lobbyType) &&
                      (state.config.enabled(state.lobbyType, 2) ||
                          vm.canManage &&
                              state.config.moreModes.contains(state.lobbyType)))
                    TextButton(
                      onPressed: () {
                        vm.restoreLobby();
                        pushRoomTool(context, RoomLobbyPage(roomId: roomId));
                      },
                      child: Text(
                        state.lobbyType == 2
                            ? toolText(context, 'Treasure', '宝藏大厅')
                            : 'Win',
                        style: AppTextStyles.roomGiftStatus,
                      ),
                    ),
                  if (state.pk.active || state.pk.terminal)
                    TextButton(
                      onPressed: () {
                        vm.showPk(true);
                        pushRoomTool(context, RoomPkPage(roomId: roomId));
                      },
                      child: Text(
                        state.pk.active
                            ? 'PK ${state.pk.secondsLeft(DateTime.now())}s'
                            : 'PK',
                        style: AppTextStyles.roomGiftStatus,
                      ),
                    ),
                  if (state.pk.active &&
                      state.pk.secondsLeft(DateTime.now()) <= 30)
                    Text(
                      toolText(context, 'Final 30s', '最后 30 秒'),
                      style: AppTextStyles.roomGiftStatus.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  if (state.musicStatus == 'PLAYING' ||
                      state.musicStatus == 'PAUSED')
                    Text(
                      state.musicStatus,
                      style: AppTextStyles.roomGiftStatus,
                    ),
                  if (state.bags.isNotEmpty)
                    TextButton(
                      onPressed: () => pushRoomTool(
                        context,
                        RoomLuckyBoxPage(roomId: roomId),
                      ),
                      child: Image.asset(
                        AppAssets.lanhuRoomMoreLuckyBox,
                        width: AppSpacing.iconSizeLg,
                      ),
                    ),
                  if (ready != null)
                    TextButton(
                      onPressed: state.busy.contains('grab:${ready.id}')
                          ? null
                          : () => openLuckyBox(context, ref, roomId, ready.id),
                      child: Text(
                        toolText(context, 'Open Lucky Box', '领取幸运盒'),
                        style: AppTextStyles.roomGiftStatus,
                      ),
                    ),
                  if (state.config.enabled(8, 17))
                    TextButton(
                      onPressed: () =>
                          pushRoomTool(context, RoomBigWinPage(roomId: roomId)),
                      child: Text(
                        toolText(context, 'Big Win', '游戏大奖'),
                        style: AppTextStyles.roomGiftStatus,
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
}
