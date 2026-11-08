import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../more/room_tools_widgets.dart';
import 'room_interaction_frame.dart';
import 'room_interaction_view_model.dart';
import 'room_rank_view_model.dart';
import 'room_rank_board_view.dart';
import 'room_rank_tab_navigation.dart';

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
    final tabs = useTabController(
      initialLength: 2,
      initialIndex: initialProfit ? 1 : 0,
    );
    useListenable(tabs);
    final contributionPeriods = useTabController(
      initialLength: 3,
      initialIndex: 1,
    );
    final profitPeriods = useTabController(initialLength: 3, initialIndex: 1);
    final navigation = useMemoized(
      () => RoomRankTabNavigation(
        categories: tabs,
        periods: [contributionPeriods, profitPeriods],
      ),
      [tabs, contributionPeriods, profitPeriods],
    );
    useEffect(() => navigation.dispose, [navigation]);
    final showingRules = useState(false);
    listenRoomInteractionLifetime(context, ref, session);
    return DecoratedBox(
      key: const ValueKey('room-rank-sheet'),
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
                  child: ExtendedTabBar(
                    key: const ValueKey('room-rank-tabs'),
                    controller: tabs,
                    onTap: navigation.onCategoryTap,
                    labelColor: AppColors.textInverse,
                    unselectedLabelColor: AppColors.roomMessageMuted,
                    labelStyle: AppTextStyles.roomMessageBody,
                    unselectedLabelStyle: AppTextStyles.roomMessageHint,
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs.w,
                    ),
                    dividerColor: AppColors.transparent,
                    indicator: const BoxDecoration(
                      color: AppColors.transparent,
                    ),
                    tabs: [
                      for (final title in [
                        toolText(context, 'Contribution Rank', '贡献榜'),
                        toolText(context, 'Profit Rank', '收益榜'),
                      ])
                        Tab(
                          height: AppSpacing.controlHeightLg.h,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: toolText(context, 'Rank rules', '榜单规则'),
                  icon: Image.asset(
                    AppAssets.roomInteractionRankHelp,
                    width: AppSpacing.iconSizeMd.r,
                  ),
                  onPressed: showingRules.value
                      ? null
                      : () async {
                          if (showingRules.value) return;
                          showingRules.value = true;
                          try {
                            await _showRankRulesDialog(
                              context,
                              session: session,
                              profit: tabs.index == 1,
                            );
                          } finally {
                            if (context.mounted) showingRules.value = false;
                          }
                        },
                ),
              ],
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: navigation.onScroll,
                child: ExtendedTabBarView(
                  key: const ValueKey('room-rank-pages'),
                  controller: tabs,
                  link: true,
                  children: [
                    for (final profit in [false, true])
                      _RankCategoryPage(
                        key: ValueKey(profit),
                        session: session,
                        profit: profit,
                        active: tabs.index == (profit ? 1 : 0),
                        periods: profit ? profitPeriods : contributionPeriods,
                        onPeriodTap: (index) =>
                            navigation.onPeriodTap(profit ? 1 : 0, index),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankCategoryPage extends HookWidget {
  const _RankCategoryPage({
    super.key,
    required this.session,
    required this.profit,
    required this.active,
    required this.periods,
    required this.onPeriodTap,
  });
  final RoomInteractionKey session;
  final bool profit, active;
  final TabController periods;
  final ValueChanged<int> onPeriodTap;

  @override
  Widget build(BuildContext context) {
    useAutomaticKeepAlive();
    useListenable(periods);
    return Column(
      children: [
        ExtendedTabBar(
          key: ValueKey('room-rank-period-tabs-$profit'),
          controller: periods,
          onTap: onPeriodTap,
          labelColor: AppColors.textInverse,
          unselectedLabelColor: AppColors.roomMessageMuted,
          labelStyle: AppTextStyles.roomMessageBody,
          unselectedLabelStyle: AppTextStyles.roomMessageHint,
          labelPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
          dividerColor: AppColors.transparent,
          indicator: const BoxDecoration(color: AppColors.transparent),
          tabs: [
            for (final period in RoomRankPeriod.values)
              Tab(
                height: AppSpacing.controlHeightLg.h,
                text: switch (period) {
                  RoomRankPeriod.daily => toolText(context, 'Daily', '日榜'),
                  RoomRankPeriod.weekly => toolText(context, 'Weekly', '周榜'),
                  RoomRankPeriod.monthly => toolText(context, 'Monthly', '月榜'),
                },
              ),
          ],
        ),
        Expanded(
          child: ExtendedTabBarView(
            key: ValueKey('room-rank-period-pages-$profit'),
            controller: periods,
            link: true,
            children: [
              for (final period in RoomRankPeriod.values)
                TickerMode(
                  key: ValueKey(period),
                  enabled: active && periods.index == period.index,
                  child: RoomRankBoardView(
                    session: session,
                    period: period,
                    profit: profit,
                    active: active && periods.index == period.index,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _showRankRulesDialog(
  BuildContext context, {
  required RoomInteractionKey session,
  required bool profit,
}) async {
  final sheet = context.findRenderObject();
  final overlay = Navigator.of(
    context,
    rootNavigator: true,
  ).overlay?.context.findRenderObject();
  if (sheet is! RenderBox || overlay is! RenderBox || !sheet.hasSize) return;
  final bounds =
      sheet.localToGlobal(Offset.zero, ancestor: overlay) & sheet.size;
  ModalRoute<void>? route;
  await showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.modalScrimStrong,
    pageBuilder: (context, _, __) {
      final current = ModalRoute.of(context);
      if (current is ModalRoute<void>) route = current;
      return Stack(
        children: [
          Positioned.fromRect(
            rect: bounds,
            child: _RankRulesDialog(session: session, profit: profit),
          ),
        ],
      );
    },
  );
  await route?.completed;
}

class _RankRulesDialog extends ConsumerWidget {
  const _RankRulesDialog({required this.session, required this.profit});
  final RoomInteractionKey session;
  final bool profit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenRoomInteractionLifetime(context, ref, session);
    return Dialog(
      key: const ValueKey('room-rank-rules-dialog'),
      backgroundColor: AppColors.roomMessageSurface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      constraints: BoxConstraints(maxWidth: AppSpacing.roomRankRulesMaxWidth.w),
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl.w,
        vertical: AppSpacing.xl.h,
      ),
      child: Padding(
        key: const ValueKey('room-rank-rules-card'),
        padding: EdgeInsets.all(AppSpacing.xxxl.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              toolText(context, 'Rank rules', '榜单规则'),
              textAlign: TextAlign.center,
              style: AppTextStyles.roomMessageTitle,
            ),
            SizedBox(height: AppSpacing.lg.h),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      toolText(
                        context,
                        'Ranking periods use UTC.',
                        '统计周期以 UTC 为准。',
                      ),
                      style: AppTextStyles.roomMessageHint,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            TextButton(
              key: const ValueKey('room-rank-rules-close'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                toolText(context, 'Close', '关闭'),
                style: AppTextStyles.roomMessageBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
