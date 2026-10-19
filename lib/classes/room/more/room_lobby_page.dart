import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'room_treasure_gift_view_model.dart';
import 'room_tool_navigation.dart';
import 'room_tools_controller.dart';
import 'room_tools_models.dart';
import 'room_tools_widgets.dart';
import 'room_game_page.dart';

class RoomLobbyPage extends ConsumerWidget {
  const RoomLobbyPage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    final vm = ref.read(roomToolsControllerProvider(roomId).notifier);
    return RoomToolPage(
      roomId: roomId,
      title: state.lobbyType == 2
          ? toolText(context, 'Treasure', '宝藏大厅')
          : 'Win',
      child: Column(
        children: [
          if (state.lobbyType == 0)
            Text(toolText(context, 'Lobby is closed', '大厅已关闭')),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: vm.loadLobby,
                child: Text(toolText(context, 'Refresh', '刷新')),
              ),
              TextButton(
                onPressed: () {
                  vm.foldLobby();
                  Navigator.pop(context);
                },
                child: Text(toolText(context, 'Minimize', '收起')),
              ),
            ],
          ),
          if (state.treasureGifts.isNotEmpty)
            ToolHeading(toolText(context, 'Gifts', '礼物')),
          for (final gift in state.treasureGifts)
            ListTile(
              leading: ToolImage('${gift['icon'] ?? ''}'),
              title: Text('${gift['price'] ?? 0}'),
              trailing: TextButton(
                onPressed: state.busy.contains('treasureGift')
                    ? null
                    : () => vm.perform(
                        'treasureGift',
                        (_) => ref
                            .read(roomTreasureGiftProvider(roomId))
                            .send(gift),
                      ),
                child: Text(
                  toolText(
                    context,
                    'Send x${gift['defaultGiftNum'] ?? 1}',
                    '赠送 x${gift['defaultGiftNum'] ?? 1}',
                  ),
                ),
              ),
              onTap: () => openRoomToolGift(
                context,
                ref,
                roomId,
                giftId: toolInt(gift['giftId']),
              ),
            ),
          ToolHeading(toolText(context, 'Recent wins', '中奖记录')),
          if (vm.lobbyRecords.isEmpty)
            Text(toolText(context, 'No records yet', '暂无记录')),
          for (final record in vm.lobbyRecords)
            ListTile(
              leading: ToolImage('${record['avatar'] ?? ''}'),
              title: Text(
                '${record['nick'] ?? record['nickName'] ?? record['uid'] ?? ''}',
              ),
              subtitle: Text(
                '${record['win'] ?? 0} x${record['multiple'] ?? 1}',
              ),
              trailing: ToolImage('${record['icon'] ?? ''}'),
              onTap: () {
                final giftId = toolInt(record['giftId']);
                if (state.lobbyType == 2 && giftId > 0) {
                  openRoomToolGift(context, ref, roomId, giftId: giftId);
                } else if ('${record['gameUrl'] ?? ''}'.isNotEmpty) {
                  openRoomGame(
                    context,
                    ref,
                    roomId,
                    '${record['gameUrl']}',
                    '${record['nick'] ?? 'Game'}',
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
