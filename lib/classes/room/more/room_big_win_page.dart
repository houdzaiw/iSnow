import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/http_api.dart';
import 'room_game_page.dart';
import 'room_share_page.dart';
import 'room_tools_controller.dart';
import 'room_tools_models.dart';
import 'room_tools_repository.dart';
import 'room_tools_widgets.dart';

final roomBigWinRankProvider = FutureProvider.autoDispose
    .family<ToolJson, (String, String, int)>(
      (ref, key) async => toolMap(
        await ref.read(roomToolsRepositoryProvider).post(
          HttpApi.gameBigWinRank,
          {'gameBigWinId': int.tryParse(key.$2) ?? key.$2, 'round': key.$3},
        ),
      ),
    );

class RoomBigWinPage extends HookConsumerWidget {
  const RoomBigWinPage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    final vm = ref.read(roomToolsControllerProvider(roomId).notifier);
    final round = useState<int?>(null);
    useEffect(() {
      Future.microtask(vm.refreshBigWin);
      return null;
    }, [roomId]);
    final info = toolMap(state.bigWin['gameBigWinInfoVO']);
    final id = '${info['gameBigWinId'] ?? ''}';
    final stage = toolInt(state.bigWin['status']);
    final total = toolInt(info['winRoundCount']);
    final chosen = (round.value ?? toolInt(info['curRound'], 1)).clamp(
      1,
      total < 1 ? 1 : total,
    );
    final rankKey = (roomId, id, chosen);
    final rank = stage >= 2 && total > 0 && id.isNotEmpty
        ? ref.watch(roomBigWinRankProvider(rankKey))
        : null;
    return RoomToolPage(
      roomId: roomId,
      title: toolText(context, 'Game Big Win', '游戏大奖'),
      child: Column(
        children: [
          ToolHeading('${info['gameName'] ?? ''}'),
          ToolImage('${info['gameIcon'] ?? ''}'),
          Text('${info['bigWinTotalCoins'] ?? 0}'),
          if (stage == 0 || stage == 4)
            Text(toolText(context, 'No active draw', '当前没有进行中的抽奖')),
          if (stage == 1)
            Text('${info['afterRound'] ?? ''} / ${info['afterMinutes'] ?? ''}'),
          if (rank != null) ...[
            ToolChoices<int>(
              values: List.generate(total, (index) => index + 1),
              selected: chosen,
              label: (value) => '$value',
              onSelected: (value) => round.value = value,
            ),
            rank.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => TextButton(
                onPressed: () =>
                    ref.invalidate(roomBigWinRankProvider(rankKey)),
                child: Text('$error'),
              ),
              data: (data) => Column(
                children: [
                  if (toolList(data['winUserList']).isEmpty)
                    ToolHeading(toolText(context, 'No winners yet', '暂无获奖用户')),
                  for (final user in [
                    if (toolMap(data['bigWinUserVO']).isNotEmpty)
                      toolMap(data['bigWinUserVO']),
                    ...toolList(data['winUserList']),
                  ])
                    ListTile(
                      leading: ToolImage('${user['avatar'] ?? ''}'),
                      title: Text('${user['nick'] ?? ''}'),
                      subtitle: Text(
                        '${user['gameWinCoins'] ?? 0} + ${user['bigWinCoins'] ?? 0}',
                      ),
                    ),
                ],
              ),
            ),
          ],
          if ('${info['gameUrl'] ?? ''}'.isNotEmpty)
            TextButton(
              onPressed: () => openRoomGame(
                context,
                ref,
                roomId,
                '${info['gameUrl']}',
                '${info['gameName'] ?? 'Game'}',
              ),
              child: Text(toolText(context, 'Play', '进入游戏')),
            ),
          TextButton(
            onPressed: () =>
                pushRoomTool(context, RoomSharePage(roomId: roomId)),
            child: Text(toolText(context, 'Invite friends', '邀请好友')),
          ),
        ],
      ),
    );
  }
}
