import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../gift/event/room_gift_event_provider.dart';
import '../gift/viewmodel/room_gift_send_controller.dart';
import '../lucky_box/room_lucky_box_view_model.dart';
import '../more/room_tools_controller.dart';
import '../more/room_tools_widgets.dart';
import '../pk/room_pk_board.dart';
import '../pk/room_pk_result_card.dart';
import '../pk/room_pk_view_model.dart';
import '../pk/room_pk_winner_effect.dart';
import 'room_activity_widgets.dart';

/// Back dismisses local activity presentation before offering to leave the room.
bool dismissRoomActivity(WidgetRef ref, String roomId) {
  final box = ref.read(roomLuckyBoxProvider(roomId));
  if (box.current != null) {
    ref.read(roomLuckyBoxProvider(roomId).notifier).close();
    return true;
  }
  final pk = ref.read(roomPkProvider(roomId));
  if (pk.result != null) {
    ref.read(roomPkProvider(roomId).notifier).closeResult();
    return true;
  }
  if (pk.data.active && !pk.data.doublePk && !pk.mini) {
    ref.read(roomPkProvider(roomId).notifier).fold(true);
    return true;
  }
  return false;
}

class RoomActivityHost extends HookConsumerWidget {
  const RoomActivityHost({
    super.key,
    required this.roomId,
    required this.onUser,
  });
  final String roomId;
  final ValueChanged<int> onUser;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pk = ref.watch(roomPkProvider(roomId));
    final pkVm = ref.read(roomPkProvider(roomId).notifier);
    final lucky = ref.watch(roomLuckyBoxProvider(roomId));
    final luckyVm = ref.read(roomLuckyBoxProvider(roomId).notifier);
    final tools = ref.watch(roomToolsControllerProvider(roomId));
    final gift = ref.watch(roomGiftEventManagerProvider(roomId));
    final sender = ref.watch(roomGiftSendControllerProvider(roomId));
    final clock = useState(0);
    final winnerPlaying = useState(false);
    useEffect(() {
      final timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (context.mounted &&
            ref.read(roomToolsControllerProvider(roomId)).bags.isNotEmpty) {
          clock.value++;
        }
      });
      return timer.cancel;
    }, [roomId]);
    final roomVisible = tools.sessionActive && pkVm.visible;
    final visible =
        roomVisible &&
        TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? false) &&
        MediaQuery.viewInsetsOf(context).bottom == 0;
    final free =
        gift.effects.isEmpty &&
        !gift.canPlayLucky &&
        !sender.canContinue &&
        !sender.isSending;
    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || !pkVm.mounted || !luckyVm.mounted) return;
          pkVm.setVisible(roomVisible);
          if (!roomVisible) {
            winnerPlaying.value = false;
            luckyVm.suspend();
          } else {
            if (pk.winnerPending && free && lucky.current == null) {
              winnerPlaying.value = true;
            }
            luckyVm.tick(
              presentable:
                  visible && free && pk.result == null && !winnerPlaying.value,
            );
          }
        });
        return null;
      },
      [
        visible,
        roomVisible,
        free,
        clock.value,
        pk.result,
        pk.winnerPending,
        lucky.current,
      ],
    );
    if (!visible) return const SizedBox.shrink();
    return Stack(
      children: [
        if (pk.data.active && !pk.data.doublePk)
          Positioned.fill(
            child: RoomMultiPkOverlay(roomId: roomId, onUser: onUser),
          ),
        if (pk.result != null && !pk.winnerPending)
          Positioned.fill(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: RoomActivityTheme.scrim),
                ),
                RoomPkResultCard(
                  roomId: roomId,
                  data: pk.result!,
                  onUser: onUser,
                ),
              ],
            ),
          ),
        if (pk.winnerPending &&
            winnerPlaying.value &&
            pk.result?.winner != null)
          Positioned.fill(
            child: RoomPkWinnerEffect(
              key: ValueKey(pk.result!.id),
              user: pk.result!.winner!,
              onEnd: () {
                winnerPlaying.value = false;
                if (pkVm.mounted) pkVm.winnerFinished();
              },
            ),
          ),
        if (lucky.current != null)
          Positioned.fill(
            child: RoomLuckyBoxOpenLayer(
              key: ValueKey((lucky.current!.id, pkVm.generation)),
              roomId: roomId,
            ),
          ),
      ],
    );
  }
}

class RoomLuckyBoxOpenLayer extends HookConsumerWidget {
  const RoomLuckyBoxOpenLayer({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomLuckyBoxProvider(roomId));
    final vm = ref.read(roomLuckyBoxProvider(roomId).notifier);
    final revealed = useState(false);
    useEffect(() {
      if (state.phase != RoomLuckyBoxPhase.result) return null;
      final reveal = Timer(const Duration(milliseconds: 1750), () {
        if (context.mounted) revealed.value = true;
      });
      final close = Timer(const Duration(milliseconds: 4750), () {
        if (vm.mounted) vm.close();
      });
      return () {
        reveal.cancel();
        close.cancel();
      };
    }, [state.phase, state.current?.id]);
    if (state.current == null) return const SizedBox.shrink();
    final source = state.phase == RoomLuckyBoxPhase.result
        ? (state.result!.count > 0
              ? AppAssets.roomActivityLuckyBagWinning
              : AppAssets.roomActivityLuckyBagLosing)
        : AppAssets.roomActivityLuckyBagChest;
    return Material(
      color: RoomActivityTheme.scrim,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: RoomActivityArtwork(
                source: AppAssets.roomActivityBgLuckyBagOpen,
                repeat: true,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: RoomActivityArtwork(
                source: source,
                repeat: state.phase != RoomLuckyBoxPhase.result,
                fullscreen: true,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(RoomActivityTheme.edge.r),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: RoomActivityClose(onTap: vm.close),
                  ),
                  const Spacer(),
                  if (revealed.value && state.result != null) ...[
                    Image.asset(
                      state.result!.count > 0
                          ? AppAssets.roomActivityIcLuckyBagWinningGold
                          : AppAssets.roomActivityIcLuckyBagLosing,
                      width: RoomActivityTheme.winnerAvatar.r,
                      height: RoomActivityTheme.winnerAvatar.r,
                    ),
                    Text(
                      state.result!.count > 0
                          ? '+${state.result!.count}'
                          : toolText(context, 'Better luck next time', '下次好运'),
                      style: RoomActivityTheme.title,
                    ),
                  ] else ...[
                    ToolImage(state.current!.avatar),
                    Text(state.current!.name, style: RoomActivityTheme.title),
                    Text(
                      toolText(context, 'Send you a Lucky Box', '送你一个幸运盒'),
                      style: RoomActivityTheme.body,
                    ),
                  ],
                  const Spacer(),
                  if (state.error != null &&
                      state.phase == RoomLuckyBoxPhase.error)
                    RoomActivityError(state.error!),
                  if (state.phase != RoomLuckyBoxPhase.result)
                    RoomActivityImageButton(
                      asset: AppAssets.roomActivityBtnLuckyOpen,
                      text: toolText(context, 'Open', '领取'),
                      busy: state.phase == RoomLuckyBoxPhase.requesting,
                      onTap: state.phase == RoomLuckyBoxPhase.requesting
                          ? null
                          : vm.grab,
                    ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
