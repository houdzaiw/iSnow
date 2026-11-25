import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../party/friends_activity/home_activity_navigation.dart';
import '../../room/more/room_entry_flow.dart';
import '../../create_room/create_room_sheet.dart';
import '../tools/profile_tools_widgets.dart';
import 'daily_reward_models.dart';
import 'daily_reward_view_model.dart';

class DailyRewardPage extends ConsumerStatefulWidget {
  const DailyRewardPage({super.key});
  @override
  ConsumerState<DailyRewardPage> createState() => _DailyRewardPageState();
}

class _DailyRewardPageState extends ConsumerState<DailyRewardPage> {
  bool _opening = false;
  Future<void> _claim({int? id}) async {
    try {
      final result = await ref
          .read(dailyRewardProvider.notifier)
          .submit(missionId: id);
      if (!mounted || result == null) return;
      profileToolsNotice(
        context,
        null,
        key: result.refreshed ? 'tools.success' : 'tools.refreshFailed',
      );
      if (result.rewards.isNotEmpty) {
        await showDialog<void>(
          context: context,
          useRootNavigator: true,
          builder: (c) => AlertDialog(
            title: Text(c.l10n.t('tools.rewards')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final reward in result.rewards)
                    ListTile(
                      leading: MembershipImage(reward.icon),
                      title: Text(reward.name),
                      trailing: Text('×${reward.amount}'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(c.l10n.t('tools.close')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) profileToolsNotice(context, e);
    }
  }

  Future<void> _go(DailyTask task) async {
    if (_opening) return;
    _opening = true;
    try {
      final destination = await ref
          .read(dailyRewardProvider.notifier)
          .destination(task);
      if (!mounted || destination == null) return;
      if (destination.kind == DailyDestinationKind.binding) {
        await context.push('/account-binding');
      } else {
        var target = destination.room;
        if (destination.kind == DailyDestinationKind.createRoom) {
          final roomId = await showCreateRoomSheet(context);
          if (roomId == null || roomId.isEmpty) return;
          target = DailyRoomTarget(roomId, 0);
        }
        if (!mounted) return;
        if (target == null) {
          profileToolsNotice(context, null, key: 'tools.unavailable');
          return;
        }
        await enterSharedRoomChecked(
          context,
          ref,
          target.roomId,
          followUid: target.uid,
          requestedLobby: destination.lobbyType,
          isCurrent: () => mounted,
        );
      }
      if (mounted) await ref.read(dailyRewardProvider.notifier).refresh();
    } catch (e) {
      if (mounted) profileToolsNotice(context, e);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    listenHomeSessionRoute(context, ref);
    final state = ref.watch(dailyRewardProvider);
    final model = ref.read(dailyRewardProvider.notifier);
    return ProfileToolsScaffold(
      title: context.l10n.t('tools.daily'),
      child: RefreshIndicator(
        onRefresh: model.refresh,
        child: ListView(
          padding: ProfileToolsTheme.padding,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (state.loadingSign) const LinearProgressIndicator(),
            if (state.signError != null)
              ProfileToolsError(error: state.signError, retry: model.loadSign),
            if (state.sign case final info?) ...[
              Text(
                context.l10n.t('tools.continuous', {'days': '${info.days}'}),
                style: ProfileToolsTheme.title,
              ),
              ProfileToolsTheme.gap,
              Wrap(
                spacing: ProfileToolsTheme.gridSpacing,
                runSpacing: ProfileToolsTheme.gridSpacing,
                children: [
                  for (final day in info.items)
                    Chip(
                      avatar: day.rewards.isEmpty
                          ? null
                          : MembershipImage(day.rewards.first.icon),
                      label: Text(
                        '${day.day} · ${day.signed ? context.l10n.t('tools.checkedIn') : day.rewards.map((r) => '×${r.amount}').join(' ')}',
                      ),
                    ),
                ],
              ),
              ElevatedButton(
                onPressed: state.busy || state.loadingSign || !state.canSign
                    ? null
                    : _claim,
                child: Text(
                  context.l10n.t(
                    state.canSign ? 'tools.checkIn' : 'tools.checkedIn',
                  ),
                ),
              ),
              if (info.nobleReward case final reward?)
                ListTile(
                  leading: MembershipImage(reward.icon),
                  title: Text(context.l10n.t('tools.nobleReward')),
                  subtitle: Text('${reward.name} ×${reward.amount}'),
                ),
              TextButton(
                onPressed: () => context.push('/noble'),
                child: Text(context.l10n.t('tools.openNoble')),
              ),
            ],
            if (state.loadingTasks) const LinearProgressIndicator(),
            if (state.taskError != null)
              ProfileToolsError(error: state.taskError, retry: model.loadTasks),
            for (final group in state.groups) ...[
              ProfileToolsTheme.gap,
              Text(group.title, style: ProfileToolsTheme.title),
              for (final task in group.items)
                Card(
                  child: Padding(
                    padding: ProfileToolsTheme.smallPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            MembershipImage(task.icon),
                            ProfileToolsTheme.space,
                            Expanded(
                              child: Text(
                                task.name,
                                style: ProfileToolsTheme.label,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${task.description} (${task.progress}/${task.total})',
                          style: ProfileToolsTheme.body,
                        ),
                        for (final reward in task.rewards)
                          Text(
                            '${reward.name} ×${reward.amount}',
                            style: ProfileToolsTheme.caption,
                          ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed:
                                state.busy ||
                                    state.loadingTasks ||
                                    state.locallyClaimed.contains(task.id) ||
                                    !{1, 2}.contains(task.status)
                                ? null
                                : () => task.status == 2
                                      ? _claim(id: task.id)
                                      : _go(task),
                            child: Text(
                              context.l10n.t(
                                task.status == 2 &&
                                        !state.locallyClaimed.contains(task.id)
                                    ? 'tools.claim'
                                    : task.status == 1
                                    ? 'tools.go'
                                    : 'tools.claimed',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
