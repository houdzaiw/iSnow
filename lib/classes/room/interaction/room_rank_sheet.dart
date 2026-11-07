import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../../../theme/app_theme.dart';
import '../more/room_tools_widgets.dart';
import '../online/room_audience_avatar.dart';
import 'room_interaction_frame.dart';
import 'room_interaction_view_model.dart';
import 'room_rank_view_model.dart';

class RoomRankSheet extends HookConsumerWidget {
  const RoomRankSheet({
    super.key,
    required this.session,
    this.initialProfit = false,
  });
  final RoomInteractionKey session;
  final bool initialProfit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profit = useState(initialProfit);
    final period = useState(RoomRankPeriod.weekly);
    final provider = roomRankBoardProvider((
      session: session,
      period: period.value,
      profit: profit.value,
    ));
    final state = ref.watch(provider);
    listenRoomInteractionLifetime(context, ref, session);
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.roomInteractionRankBackground),
          fit: BoxFit.cover,
        ),
        borderRadius: AppRadius.sheetBorder,
      ),
      child: RoomInteractionFrame(
        heightRatio: AppSpacing.roomInteractionRankHeight,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => profit.value = false,
                    child: Text(
                      toolText(context, 'Contribution Rank', '贡献榜'),
                      style: profit.value
                          ? AppTextStyles.roomMessageHint
                          : AppTextStyles.roomMessageBody,
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => profit.value = true,
                    child: Text(
                      toolText(context, 'Profit Rank', '收益榜'),
                      style: profit.value
                          ? AppTextStyles.roomMessageBody
                          : AppTextStyles.roomMessageHint,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: toolText(context, 'Rank rules', '榜单规则'),
                  icon: Image.asset(
                    AppAssets.roomInteractionRankHelp,
                    width: AppSpacing.iconSizeMd.r,
                  ),
                  onPressed: () => showRoomInteractionSheet<void>(
                    context,
                    (_) => _RankRules(session: session, profit: profit.value),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                for (final range in RoomRankPeriod.values)
                  Expanded(
                    child: TextButton(
                      onPressed: () => period.value = range,
                      child: Text(
                        switch (range) {
                          RoomRankPeriod.daily => toolText(
                            context,
                            'Daily',
                            '日榜',
                          ),
                          RoomRankPeriod.weekly => toolText(
                            context,
                            'Weekly',
                            '周榜',
                          ),
                          RoomRankPeriod.monthly => toolText(
                            context,
                            'Monthly',
                            '月榜',
                          ),
                        },
                        style: period.value == range
                            ? AppTextStyles.roomMessageBody
                            : AppTextStyles.roomMessageHint,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userFacingErrorMessage(error),
                      style: AppTextStyles.roomMessageHint,
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(provider),
                      child: Text(toolText(context, 'Retry', '重试')),
                    ),
                  ],
                ),
                data: (board) {
                  if (board == null) return const SizedBox.shrink();
                  return Column(
                    children: [
                      if (board.total != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              profit.value
                                  ? AppAssets.roomInteractionProfit
                                  : AppAssets.roomInteractionRank,
                              width: AppSpacing.iconSizeMd.r,
                            ),
                            SizedBox(width: AppSpacing.xs.w),
                            Text(
                              '${board.total}',
                              style: AppTextStyles.roomMessageBody,
                            ),
                          ],
                        ),
                      if (board.endsAt case final end?)
                        _RankCountdown(
                          end: end,
                          onEnd: () => ref.invalidate(provider),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => ref.refresh(provider.future),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              if (board.rows.isEmpty)
                                Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg.r),
                                  child: Text(
                                    toolText(
                                      context,
                                      'No ranked users',
                                      '暂无上榜用户',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.roomMessageHint,
                                  ),
                                ),
                              for (final entry in board.rows)
                                _RankRow(row: entry),
                            ],
                          ),
                        ),
                      ),
                      if (board.me case final me?)
                        _RankRow(row: me, isMe: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.row, this.isMe = false});
  final RoomRankRow row;
  final bool isMe;
  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: isMe ? AppColors.roomMessageBubble : AppColors.transparent,
    onTap: row.uid > 0 && !isMe
        ? () => context.push('/profile-homepage/${row.uid}')
        : null,
    leading: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          row.position <= 0 ? '—' : '${row.position}',
          style: AppTextStyles.roomMessageBody,
        ),
        SizedBox(width: AppSpacing.sm.w),
        RoomAudienceAvatar(
          url: row.avatar,
          size: AppSpacing.roomMessageAvatar.r,
        ),
      ],
    ),
    title: Text(
      row.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.roomMessageBody,
    ),
    trailing: Text('${row.amount}', style: AppTextStyles.giftEffectTitle),
  );
}

class _RankRules extends ConsumerWidget {
  const _RankRules({required this.session, required this.profit});
  final RoomInteractionKey session;
  final bool profit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenRoomInteractionLifetime(context, ref, session);
    return RoomInteractionFrame(
      title: toolText(context, 'Rank rules', '榜单规则'),
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.lg.r),
        children: [
          Text(
            profit
                ? toolText(
                    context,
                    'Ranked by diamonds received in this room.',
                    '按在本房间收到的钻石排名。',
                  )
                : toolText(
                    context,
                    'Ranked by coins spent on gifts in this room.',
                    '按在本房间送礼花费的金币排名。',
                  ),
            style: AppTextStyles.roomMessageBody,
          ),
          Text(
            toolText(context, 'Ranking periods use UTC.', '统计周期以 UTC 为准。'),
            style: AppTextStyles.roomMessageHint,
          ),
        ],
      ),
    );
  }
}

class _RankCountdown extends HookWidget {
  const _RankCountdown({required this.end, required this.onEnd});
  final DateTime end;
  final VoidCallback onEnd;
  @override
  Widget build(BuildContext context) {
    final now = useState(DateTime.now());
    final callback = useRef(onEnd)..value = onEnd;
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        now.value = DateTime.now();
        if (!now.value.isBefore(end)) {
          timer.cancel();
          callback.value();
        }
      });
      return timer.cancel;
    }, [end]);
    final seconds = end.difference(now.value).inSeconds.clamp(0, 2147483647);
    final rest = Duration(seconds: seconds);
    String pad(int v) => v.toString().padLeft(2, '0');
    return Text(
      '${rest.inDays}d ${pad(rest.inHours % 24)}:${pad(rest.inMinutes % 60)}:${pad(rest.inSeconds % 60)}',
      style: AppTextStyles.roomMessageTitle,
    );
  }
}
