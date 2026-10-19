import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../room_repository.dart';
import 'room_tools_controller.dart';
import 'room_tools_models.dart';
import 'room_tools_widgets.dart';
import 'room_tool_navigation.dart';

class RoomPkPage extends HookConsumerWidget {
  const RoomPkPage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    final vm = ref.read(roomToolsControllerProvider(roomId).notifier);
    final oneOnOne = useState(true);
    final selected = useState(<int>{});
    final duration = useState(3);
    final seats = ref.read(roomRepositoryProvider).roomState.micList;
    final occupied = seats
        .where((mic) => (mic.uid ?? 0) > 0)
        .map((mic) => mic.uid!)
        .toSet();
    useEffect(() {
      Future.microtask(() {
        if (context.mounted) {
          selected.value = selected.value.intersection(occupied);
        }
      });
      return null;
    }, [occupied.toList().join(',')]);
    final busy = state.busy.contains('pk');
    return RoomToolPage(
      roomId: roomId,
      title: 'PK',
      child: Column(
        children: [
          if (state.pk.active || state.pk.terminal) ...[
            ToolHeading(
              state.pk.active
                  ? '${state.pk.secondsLeft(DateTime.now())}s'
                  : toolText(
                      context,
                      state.pk.eventType == 3 ? 'PK ended early' : 'PK results',
                      state.pk.eventType == 3 ? 'PK 已提前结束' : 'PK 结果',
                    ),
            ),
            for (final (index, player) in state.pk.users.indexed)
              ListTile(
                leading: ToolImage(
                  '${toolMap(player['userInfo'])['avatar'] ?? ''}',
                ),
                title: Text(
                  '${toolMap(player['userInfo'])['nick'] ?? toolMap(player['userInfo'])['nickName'] ?? ''}',
                ),
                subtitle: Text(
                  '${player['pkScore'] ?? 0}${!state.pk.active && index == 0 && toolInt(player['pkScore']) > 0 ? ' WIN' : ''}',
                ),
                trailing: TextButton(
                  onPressed: toolInt(toolMap(player['userInfo'])['uid']) <= 0
                      ? null
                      : () => openRoomToolGift(
                          context,
                          ref,
                          roomId,
                          targetUid: toolInt(
                            toolMap(player['userInfo'])['uid'],
                          ),
                        ),
                  child: Text(toolText(context, 'Gift', '送礼')),
                ),
                onTap: () => pushRoomTool(
                  context,
                  _PkContributors(roomId: roomId, player: player),
                ),
              ),
            if (state.pk.active && vm.canManage)
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (await confirmRoomTool(
                          context,
                          'PK',
                          toolText(context, 'End this PK?', '提前结束本次 PK？'),
                        )) {
                          await vm.endPk();
                        }
                      },
                child: Text(toolText(context, 'End PK', '结束 PK')),
              ),
            if (state.pk.active)
              TextButton(
                onPressed: () {
                  vm.showPk(false);
                  Navigator.pop(context);
                },
                child: Text(toolText(context, 'Minimize PK', '收起 PK')),
              ),
          ] else if (!vm.canManage)
            Text(toolText(context, 'No active PK', '当前没有进行中的 PK')),
          if (!state.pk.active && vm.canManage) ...[
            if (occupied.length < 2)
              Text(
                toolText(
                  context,
                  'At least two users must be on mic',
                  '至少需要两位用户在麦上',
                ),
              ),
            const ToolHeading('PK'),
            ToolChoices<bool>(
              values: const [true, false],
              selected: oneOnOne.value,
              label: (value) =>
                  value ? '1 v 1' : toolText(context, 'Multi-player', '多人 PK'),
              onSelected: (value) {
                oneOnOne.value = value;
                selected.value = {};
              },
            ),
            if (!oneOnOne.value)
              CheckboxListTile(
                title: Text(toolText(context, 'Select all', '全选')),
                value:
                    occupied.isNotEmpty && selected.value.containsAll(occupied),
                onChanged: busy
                    ? null
                    : (value) => selected.value = value == true ? occupied : {},
              ),
            for (final mic in seats)
              if ((mic.uid ?? 0) > 0)
                CheckboxListTile(
                  title: Text('${mic.userInfo?['nick'] ?? mic.uid}'),
                  value: selected.value.contains(mic.uid),
                  onChanged: busy
                      ? null
                      : (value) {
                          final next = {...selected.value};
                          if (value == true) {
                            if (oneOnOne.value && next.length >= 2) return;
                            next.add(mic.uid!);
                          } else {
                            next.remove(mic.uid);
                          }
                          selected.value = next;
                        },
                ),
            ToolHeading(toolText(context, 'Duration (minutes)', '时长（分钟）')),
            ToolChoices<int>(
              values: const [3, 5, 10, 20, 30, 40, 50, 60],
              selected: duration.value,
              label: (value) => '$value',
              onSelected: busy ? null : (value) => duration.value = value,
            ),
            TextButton(
              onPressed: busy || selected.value.length < 2
                  ? null
                  : () => vm.beginPk(
                      selected.value.toList(),
                      duration.value,
                      oneOnOne: oneOnOne.value,
                    ),
              child: Text(toolText(context, 'Start PK', '开始 PK')),
            ),
          ],
        ],
      ),
    );
  }
}

class _PkContributors extends StatelessWidget {
  const _PkContributors({required this.roomId, required this.player});
  final String roomId;
  final ToolJson player;
  @override
  Widget build(BuildContext context) => RoomToolPage(
    roomId: roomId,
    title: toolText(context, 'Contributors', '贡献榜'),
    child: Column(
      children: [
        for (final user in toolList(player['contributorList']))
          ListTile(
            leading: ToolImage('${user['avatar'] ?? ''}'),
            title: Text('${user['nick'] ?? user['nickName'] ?? user['uid']}'),
            onTap: toolInt(user['uid']) > 0
                ? () => context.push('/profile-homepage/${user['uid']}')
                : null,
          ),
      ],
    ),
  );
}
