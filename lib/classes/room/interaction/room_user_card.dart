import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../manager/api_error_message.dart';
import '../../../theme/app_theme.dart';
import '../more/room_tools_widgets.dart';
import 'room_interaction_frame.dart';
import 'room_interaction_view_model.dart';
import 'room_member_card_content.dart';
import 'room_moderation.dart';
import 'room_profile_widgets.dart';

enum RoomUserCardAction { profile, message, gift, mention }

typedef RoomUserCardSelection = ({
  RoomUserCardAction action,
  String nickname,
  String? avatar,
});

class RoomUserCard extends ConsumerWidget {
  const RoomUserCard({
    super.key,
    required this.target,
    required this.currentUid,
  });
  final RoomUserCardKey target;
  final int? currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomUserCardProvider(target);
    final vm = ref.read(provider.notifier);
    final state = ref.watch(provider);
    listenRoomInteractionLifetime(
      context,
      ref,
      target.session,
      onClose: vm.close,
    );
    final data = state.user?.userBase;
    final own = currentUid == null || currentUid == target.uid;
    final actions = state.user == null || own
        ? <RoomModerationAction>{}
        : vm.actions(currentUid, state.user!);
    void choose(RoomUserCardAction action) {
      if (data == null || !vm.active) return;
      Navigator.of(
        context,
      ).pop((action: action, nickname: data.nick, avatar: data.avatar));
    }

    Future<void> follow() async {
      if (state.following &&
          !await confirmRoomAction(
            context,
            toolText(context, 'Unfollow this user?', '取消关注该用户？'),
            session: target.session,
          )) {
        return;
      }
      if (context.mounted) await vm.follow(!state.following);
    }

    final moderation = RoomUserModerationButtons(
      vm: vm,
      session: target.session,
      actions: actions,
      busy: state.saving,
    );
    return PopScope<RoomUserCardSelection>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) vm.close();
      },
      child: RoomMemberCardContent(
        user: state.user,
        own: own,
        following: state.following,
        loading: state.loading,
        saving: state.saving,
        error: state.error,
        onProfile: () => choose(RoomUserCardAction.profile),
        onMessage: () => choose(RoomUserCardAction.message),
        onGift: () => choose(RoomUserCardAction.gift),
        onMention: () => choose(RoomUserCardAction.mention),
        onCopy: () => copyRoomIdentifier(context, '${data?.userNo ?? ''}'),
        onFollow: follow,
        onRetry: vm.load,
        managementMenu: actions.isEmpty
            ? null
            : PopupMenuButton<RoomModerationAction>(
                tooltip: toolText(context, 'Manage member', '管理成员'),
                color: RoomProfileTheme.surface,
                enabled: !state.saving,
                onSelected: (action) => moderation._select(context, action),
                itemBuilder: (_) => [
                  for (final action in actions)
                    PopupMenuItem(
                      value: action,
                      child: _ModerationMenuLabel(
                        session: target.session,
                        label: roomModerationLabel(context, action),
                      ),
                    ),
                ],
                child: SizedBox.square(
                  dimension: RoomProfileTheme.touch.r,
                  child: Center(
                    child: RoomProfileAsset(
                      asset: AppAssets.lanhuRoomBottomMore,
                      color: RoomProfileTheme.ink,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ModerationMenuLabel extends ConsumerWidget {
  const _ModerationMenuLabel({required this.session, required this.label});
  final RoomInteractionKey session;
  final String label;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenRoomInteractionLifetime(context, ref, session);
    return Text(label, style: RoomProfileTheme.description);
  }
}

Future<void> copyRoomIdentifier(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(toolText(context, 'Copied', '已复制'))));
}

Future<bool> confirmRoomAction(
  BuildContext context,
  String title, {
  RoomInteractionKey? session,
  String? confirmLabel,
  String? cancelLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          if (session != null) {
            listenRoomInteractionLifetime(context, ref, session);
          }
          return AlertDialog(
            title: Text(title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(cancelLabel ?? toolText(context, 'Cancel', '取消')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel ?? toolText(context, 'Confirm', '确认')),
              ),
            ],
          );
        },
      ),
    ) ??
    false;

class RoomUserModerationButtons extends StatelessWidget {
  const RoomUserModerationButtons({
    super.key,
    required this.vm,
    required this.session,
    required this.actions,
    required this.busy,
  });

  final RoomUserCardViewModel vm;
  final RoomInteractionKey session;
  final Set<RoomModerationAction> actions;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        const Divider(color: AppColors.roomMessageHandle),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm.w,
          children: [
            for (final action in actions)
              TextButton(
                onPressed: busy ? null : () => _select(context, action),
                child: Text(roomModerationLabel(context, action)),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _select(
    BuildContext context,
    RoomModerationAction action,
  ) async {
    final label = roomModerationLabel(context, action);
    final messenger = ScaffoldMessenger.of(context);
    int? duration;
    if (action == RoomModerationAction.silence) {
      duration = await showRoomInteractionSheet<int>(
        context,
        (_) => _SilenceOptionSheet(session: session, vm: vm),
      );
      if (duration == null) return;
    } else if (action != RoomModerationAction.inviteMic &&
        !await confirmRoomAction(context, label, session: session)) {
      return;
    }
    if (!context.mounted || !vm.active) return;
    final success = await vm.moderate(action, duration: duration);
    if (!context.mounted || !success) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          action == RoomModerationAction.inviteMic
              ? toolText(context, 'Invite sent', '已发送上麦邀请')
              : toolText(context, 'Saved', '已保存'),
        ),
      ),
    );
    if (action == RoomModerationAction.kick ||
        action == RoomModerationAction.block) {
      Navigator.of(context).pop();
    }
  }
}

class _SilenceOptionSheet extends HookConsumerWidget {
  const _SilenceOptionSheet({required this.session, required this.vm});
  final RoomInteractionKey session;
  final RoomUserCardViewModel vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenRoomInteractionLifetime(context, ref, session);
    final language = Localizations.localeOf(context).languageCode;
    final options = useMemoized(() => vm.silenceOptions(language), [
      vm,
      language,
    ]);
    return RoomInteractionFrame(
      title: toolText(context, 'Silence duration', '禁言时长'),
      child: FutureBuilder(
        future: options,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          return ListView(
            children: [
              if (snapshot.hasError || items.isEmpty)
                Text(
                  snapshot.hasError
                      ? userFacingErrorMessage(snapshot.error)
                      : toolText(context, 'No durations available', '暂无禁言时长'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.roomMessageHint,
                ),
              for (final item in items)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(item.type),
                  child: Text(item.label.isEmpty ? '${item.type}' : item.label),
                ),
            ],
          );
        },
      ),
    );
  }
}

String roomModerationLabel(
  BuildContext context,
  RoomModerationAction action,
) => switch (action) {
  RoomModerationAction.addAdmin => toolText(context, 'Set as Admin', '设为管理员'),
  RoomModerationAction.removeAdmin => toolText(
    context,
    'Remove Admin',
    '取消管理员',
  ),
  RoomModerationAction.silence => toolText(context, 'Silence', '禁言'),
  RoomModerationAction.unsilence => toolText(context, 'Unsilence', '解除禁言'),
  RoomModerationAction.inviteMic => toolText(context, 'Invite to mic', '邀请上麦'),
  RoomModerationAction.kickMic => context.l10n.t('room.kickDownMic'),
  RoomModerationAction.muteMic => context.l10n.t('room.muteMic'),
  RoomModerationAction.unmuteMic => context.l10n.t('room.unmuteMic'),
  RoomModerationAction.lockMic => context.l10n.t('room.lockMic'),
  RoomModerationAction.unlockMic => context.l10n.t('room.unlockMic'),
  RoomModerationAction.kick => toolText(context, 'Kick out', '踢出房间'),
  RoomModerationAction.block => toolText(context, 'Kick and block', '踢出并拉黑'),
  RoomModerationAction.unblock => toolText(
    context,
    'Remove from block list',
    '移出黑名单',
  ),
};
