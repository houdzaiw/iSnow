import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../activities/room_activity_widgets.dart';
import '../more/room_tool_navigation.dart';
import '../more/room_tools_widgets.dart';
import 'room_pk_models.dart';
import 'room_pk_result_card.dart';
import 'room_pk_view_model.dart';

class RoomPkBoard extends ConsumerWidget {
  const RoomPkBoard({super.key, required this.roomId, required this.onUser});
  final String roomId;
  final ValueChanged<int> onUser;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomPkProvider(roomId));
    if (!state.active ||
        !ref.read(roomPkProvider(roomId).notifier).visible ||
        !state.data.active ||
        !state.data.doublePk) {
      return const SizedBox.shrink();
    }
    final users = [
      state.data.side(1) ?? state.data.users.first,
      state.data.side(2) ?? state.data.users.last,
    ];
    final total = users[0].score + users[1].score;
    final ratio = total > 0 ? (users[0].score / total).clamp(.14, .9) : .5;
    return SizedBox(
      height: RoomActivityTheme.pkHeight.h,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: RoomActivityArtwork(
                source: AppAssets.roomActivityDoublePkBg,
                repeat: true,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: RoomActivityTheme.edge.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _PkClock(data: state.data)),
                    if (state.manager)
                      TextButton(
                        onPressed: state.busy
                            ? null
                            : () => _confirmEnd(context, ref, roomId),
                        child: Text(toolText(context, 'Turn Off', '结束')),
                      ),
                  ],
                ),
                Expanded(
                  child: Row(
                    children: [
                      for (final user in users)
                        Expanded(
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => onUser(user.uid),
                                child: ToolImage(
                                  user.avatar,
                                  size: RoomActivityTheme.icon.r,
                                ),
                              ),
                              SizedBox(width: RoomActivityTheme.gap.w),
                              Expanded(
                                child: InkWell(
                                  onTap: () => showRoomPkContributors(
                                    context,
                                    user,
                                    onUser,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: RoomActivityTheme.body,
                                      ),
                                      Text(
                                        '${user.score}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: RoomActivityTheme.body,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              InkWell(
                                key: ValueKey('pk-gift-${user.uid}'),
                                onTap: () => openRoomToolGift(
                                  context,
                                  ref,
                                  roomId,
                                  targetUid: user.uid,
                                ),
                                child: SizedBox(
                                  width: RoomActivityTheme.avatar.w,
                                  height: RoomActivityTheme.icon.h,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        AppAssets.roomActivityPkOnBtnPick,
                                        fit: BoxFit.fill,
                                      ),
                                      Text(
                                        toolText(context, 'Pick', '支持'),
                                        style: RoomActivityTheme.body,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: RoomActivityTheme.gap.h,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (ratio * 1000).round(),
                        child: const ColoredBox(
                          color: RoomActivityTheme.red,
                          child: SizedBox.expand(),
                        ),
                      ),
                      Expanded(
                        flex: ((1 - ratio) * 1000).round(),
                        child: const ColoredBox(
                          color: RoomActivityTheme.blue,
                          child: SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PkClock extends HookWidget {
  const _PkClock({required this.data});
  final RoomPkData data;
  @override
  Widget build(BuildContext context) {
    final seconds = data.remaining(DateTime.now());
    final pulse = useAnimationController(
      duration: RoomActivityTheme.countdownPulse,
    );
    final animate =
        seconds > 0 &&
        seconds <= 30 &&
        !MediaQuery.disableAnimationsOf(context);
    useEffect(() {
      if (animate) {
        pulse.repeat(reverse: true);
      } else {
        pulse.stop();
      }
      return null;
    }, [animate]);
    final value = useAnimation(pulse);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Transform.scale(
        alignment: AlignmentDirectional.centerStart,
        scale: animate
            ? RoomActivityTheme.countdownMinScale +
                  (RoomActivityTheme.countdownMaxScale -
                          RoomActivityTheme.countdownMinScale) *
                      value
            : 1,
        child: Text(
          'PK ${data.time(DateTime.now())}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: seconds <= 30
              ? RoomActivityTheme.criticalTitle
              : RoomActivityTheme.title,
        ),
      ),
    );
  }
}

Future<void> _confirmEnd(BuildContext context, WidgetRef ref, String id) async {
  final vm = ref.read(roomPkProvider(id).notifier);
  if (await confirmRoomTool(
        context,
        'PK',
        toolText(context, 'PK is not finished. Turn off?', 'PK 尚未结束，确认提前结束？'),
      ) &&
      vm.mounted &&
      vm.valid) {
    await vm.end();
  }
}

class RoomMultiPkOverlay extends HookConsumerWidget {
  const RoomMultiPkOverlay({
    super.key,
    required this.roomId,
    required this.onUser,
  });
  final String roomId;
  final ValueChanged<int> onUser;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomPkProvider(roomId));
    final vm = ref.read(roomPkProvider(roomId).notifier);
    final drag = useState(Offset.zero);
    if (!state.active || !state.data.active || state.data.doublePk) {
      return const SizedBox.shrink();
    }
    final data = state.data;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (state.mini
                    ? RoomActivityTheme.miniWidth
                    : RoomActivityTheme.multiWidth)
                .w
                .clamp(
                  0.0,
                  constraints.maxWidth - RoomActivityTheme.edge.w * 2,
                );
        final height =
            (state.mini
                    ? RoomActivityTheme.miniHeight
                    : RoomActivityTheme.multiHeight)
                .h
                .clamp(
                  0.0,
                  constraints.maxHeight - RoomActivityTheme.edge.h * 2,
                );
        final left = state.mini
            ? (constraints.maxWidth -
                      width -
                      RoomActivityTheme.edge.w +
                      drag.value.dx)
                  .clamp(0.0, constraints.maxWidth - width)
            : (constraints.maxWidth - width) / 2;
        final top = state.mini
            ? (constraints.maxHeight * .45 + drag.value.dy).clamp(
                0.0,
                constraints.maxHeight - height,
              )
            : (constraints.maxHeight - height) / 2;
        return Stack(
          children: [
            if (!state.mini)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => vm.fold(true),
                  child: const ColoredBox(color: RoomActivityTheme.scrim),
                ),
              ),
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: GestureDetector(
                key: const ValueKey('room-multi-pk-panel'),
                onPanUpdate: state.mini
                    ? (event) => drag.value = Offset(
                        (left + event.delta.dx).clamp(
                              0.0,
                              constraints.maxWidth - width,
                            ) -
                            (constraints.maxWidth -
                                width -
                                RoomActivityTheme.edge.w),
                        (top + event.delta.dy).clamp(
                              0.0,
                              constraints.maxHeight - height,
                            ) -
                            constraints.maxHeight * .45,
                      )
                    : null,
                onTap: state.mini ? () => vm.fold(false) : null,
                child: Container(
                  decoration: const BoxDecoration(
                    color: RoomActivityTheme.surface,
                    borderRadius: RoomActivityTheme.cardRadius,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RoomActivityArtwork(
                            source: state.mini
                                ? AppAssets.roomActivityMultiPkMinBg
                                : AppAssets.roomActivityMultiPkBg,
                            repeat: true,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(RoomActivityTheme.gap.r),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _PkClock(data: data)),
                                if (!state.mini)
                                  InkWell(
                                    onTap: () => vm.fold(true),
                                    child: SizedBox(
                                      width: RoomActivityTheme.avatar.r,
                                      height: RoomActivityTheme.avatar.r,
                                      child: Center(
                                        child: Image.asset(
                                          AppAssets
                                              .roomActivityPkMinimizeBtnIcon,
                                          width: RoomActivityTheme.icon.r,
                                          height: RoomActivityTheme.icon.r,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Expanded(
                              child: ListView(
                                children: [
                                  for (final (index, user)
                                      in data.users.indexed)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: RoomActivityTheme.gap.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${index + 1}',
                                            style: RoomActivityTheme.body,
                                          ),
                                          SizedBox(
                                            width: RoomActivityTheme.gap.w,
                                          ),
                                          InkWell(
                                            onTap: () => onUser(user.uid),
                                            child: ToolImage(
                                              user.avatar,
                                              size: RoomActivityTheme.icon.r,
                                            ),
                                          ),
                                          SizedBox(
                                            width: RoomActivityTheme.gap.w,
                                          ),
                                          Expanded(
                                            child: Text(
                                              state.mini
                                                  ? '${user.score}'
                                                  : '${user.name} · ${user.score}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: RoomActivityTheme.body,
                                            ),
                                          ),
                                          if (!state.mini)
                                            TextButton(
                                              onPressed: () => openRoomToolGift(
                                                context,
                                                ref,
                                                roomId,
                                                targetUid: user.uid,
                                              ),
                                              child: Text(
                                                toolText(context, 'Pick', '支持'),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!state.mini && state.manager)
                              TextButton(
                                onPressed: state.busy
                                    ? null
                                    : () => _confirmEnd(context, ref, roomId),
                                child: Text(
                                  toolText(context, 'Turn Off', '结束 PK'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
