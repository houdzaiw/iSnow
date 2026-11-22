import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../activities/room_activity_widgets.dart';
import '../more/room_tools_widgets.dart';
import 'room_pk_models.dart';
import 'room_pk_view_model.dart';

Future<void> showRoomPkSheet(BuildContext context, String id) =>
    showRoomActivitySheet(context, id, RoomPkPage(roomId: id));

class RoomPkPage extends HookConsumerWidget {
  const RoomPkPage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomPkProvider(roomId));
    final vm = ref.read(roomPkProvider(roomId).notifier);
    final tabs = useTabController(initialLength: 2);
    useEffect(() {
      Future.microtask(() {
        if (vm.mounted) vm.resetSetup();
      });
      return null;
    }, [vm]);
    useEffect(() {
      void changed() {
        if (!tabs.indexIsChanging) vm.mode(tabs.index == 0);
      }

      tabs.addListener(changed);
      return () => tabs.removeListener(changed);
    }, [tabs, vm]);
    return RoomActivityPanel(
      title: 'PK',
      child: Column(
        children: [
          if (state.error != null)
            RoomActivityError(state.error!, retry: vm.refresh),
          if (state.data.active) ...[
            Text(
              toolText(context, 'PK has already started!', 'PK 已在进行中'),
              style: RoomActivityTheme.title,
            ),
            TextButton(
              onPressed: () {
                vm.fold(false);
                Navigator.of(context).pop();
              },
              child: Text(toolText(context, 'View PK', '查看 PK')),
            ),
          ] else if (!state.manager)
            Text(
              toolText(
                context,
                'Room management permission required',
                '需要房间管理权限',
              ),
              style: RoomActivityTheme.body,
            )
          else
            Expanded(
              child: Column(
                children: [
                  ExtendedTabBar(
                    controller: tabs,
                    tabs: const [
                      Tab(text: '1V1'),
                      Tab(text: 'Multi-player'),
                    ],
                    onTap: (index) => vm.mode(index == 0),
                  ),
                  Expanded(
                    child: ExtendedTabBarView(
                      controller: tabs,
                      children: [
                        for (final doubleMode in [true, false])
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(
                                    RoomActivityTheme.edge.r,
                                  ),
                                  child: Text(
                                    toolText(
                                      context,
                                      'Choose PK user',
                                      '选择 PK 用户',
                                    ),
                                    style: RoomActivityTheme.body,
                                  ),
                                ),
                                if (doubleMode)
                                  Container(
                                    height: RoomActivityTheme.pkHeight.h,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          AppAssets
                                              .roomActivityDoublePeoplePkBackground,
                                        ),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        for (final index in [0, 1])
                                          _SelectedUser(
                                            user: state.selected.length > index
                                                ? state.seats
                                                      .where(
                                                        (u) =>
                                                            u.uid ==
                                                            state
                                                                .selected[index],
                                                      )
                                                      .firstOrNull
                                                : null,
                                          ),
                                      ],
                                    ),
                                  ),
                                Text(
                                  toolText(
                                    context,
                                    'The result of PK is calculated based on the value of the coins received as gifts.',
                                    'PK 结果根据收到礼物的金币价值计算。',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: RoomActivityTheme.body,
                                ),
                                if (!doubleMode)
                                  TextButton(
                                    onPressed: state.busy ? null : vm.selectAll,
                                    child: Text(
                                      toolText(context, 'Choose all', '全选'),
                                    ),
                                  ),
                                Wrap(
                                  spacing: RoomActivityTheme.gap.w,
                                  runSpacing: RoomActivityTheme.gap.h,
                                  children: [
                                    for (final user in state.seats)
                                      GestureDetector(
                                        onTap: state.busy
                                            ? null
                                            : () => vm.select(user.uid),
                                        child: Container(
                                          width: RoomActivityTheme.luckyCard.w,
                                          padding: EdgeInsets.all(
                                            RoomActivityTheme.gap.r,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                state.selected.contains(
                                                  user.uid,
                                                )
                                                ? RoomActivityTheme.red
                                                : RoomActivityTheme.panel,
                                            borderRadius:
                                                RoomActivityTheme.cardRadius,
                                          ),
                                          child: Column(
                                            children: [
                                              ToolImage(
                                                user.avatar,
                                                size:
                                                    RoomActivityTheme.avatar.r,
                                              ),
                                              Text(
                                                user.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: RoomActivityTheme.body,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (state.seats.length < 2)
                                  Text(
                                    toolText(
                                      context,
                                      'At least two users must be on mic',
                                      '至少需要两位用户在麦上',
                                    ),
                                    style: RoomActivityTheme.body,
                                  ),
                                Padding(
                                  padding: EdgeInsets.all(
                                    RoomActivityTheme.edge.r,
                                  ),
                                  child: ToolChoices<int>(
                                    values: const [
                                      3,
                                      5,
                                      10,
                                      20,
                                      30,
                                      40,
                                      50,
                                      60,
                                    ],
                                    selected: state.duration,
                                    label: (n) => '$n min',
                                    onSelected: state.busy ? null : vm.duration,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  RoomActivityImageButton(
                    asset: AppAssets.roomActivityPkStartBtnBg,
                    text: toolText(context, 'Start PK', '开始 PK'),
                    busy: state.busy,
                    onTap: state.canStart
                        ? () async {
                            final ok = await vm.begin();
                            if (context.mounted && ok) {
                              Navigator.of(context).pop();
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedUser extends StatelessWidget {
  const _SelectedUser({this.user});
  final RoomPkUser? user;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: RoomActivityTheme.luckyCard.w,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ToolImage(user?.avatar ?? '', size: RoomActivityTheme.avatar.r),
        Text(
          user?.name ?? toolText(context, 'Choose user', '选择用户'),
          style: RoomActivityTheme.body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
