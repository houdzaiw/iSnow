import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/im_models.dart';
import '../../../theme/app_theme.dart';
import '../../message/chat_content.dart';
import '../../message/message_view_model.dart';
import '../../message/im_message_formatter.dart';
import '../online/room_audience_avatar.dart';
import 'room_message_frame.dart';
import 'room_message_view_model.dart';
import 'room_private_chat_sheet.dart';

Future<void> showRoomMessageSheet(
  BuildContext context,
  WidgetRef ref,
  String roomId,
) async {
  final vm = ref.read(roomMessageViewModelProvider(roomId).notifier);
  if (!await vm.ready || !context.mounted || !vm.beginOpen()) return;
  ModalRoute<dynamic>? route;
  try {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.transparent,
      builder: (sheetContext) {
        route = ModalRoute.of(sheetContext);
        return RoomMessageSheet(roomId: roomId);
      },
    );
    await route?.completed;
  } finally {
    if (vm.mounted) vm.finishOpen();
  }
}

class RoomMessageSheet extends HookConsumerWidget {
  const RoomMessageSheet({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = messageViewModelProvider;
    final state = ref.watch(source);
    final vm = ref.read(source.notifier);
    final room = ref.read(roomMessageViewModelProvider(roomId).notifier);
    final scroll = useScrollController();
    listenRoomMessageLifetime(context, ref, roomId);
    return RoomMessageFrame(
      key: const ValueKey('room-message-sheet'),
      title: context.l10n.t('message.title'),
      child: Column(
        children: [
          if (state.isLoading ||
              state.connection.status == ImConnectionStatus.connecting)
            const LinearProgressIndicator(color: AppColors.primaryPink),
          if (state.errorMessage != null ||
              state.connection.status == ImConnectionStatus.error)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.errorMessage ??
                          state.connection.error ??
                          'Unable to connect',
                      style: AppTextStyles.roomMessageHint,
                    ),
                  ),
                  TextButton(
                    onPressed: vm.reconnect,
                    child: Text(context.l10n.t('app.retry')),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.refresh,
              color: AppColors.primaryPink,
              child: ListView.builder(
                controller: scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.conversations.isEmpty
                    ? 1
                    : state.conversations.length,
                itemBuilder: (context, index) {
                  if (state.conversations.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.section),
                      child: Center(
                        child: Text(
                          state.isLoading
                              ? ''
                              : context.l10n.t('message.empty'),
                          style: AppTextStyles.roomMessageHint,
                        ),
                      ),
                    );
                  }
                  final item = state.conversations[index];
                  return _ConversationRow(
                    conversation: item,
                    deleting: state.deleting.contains(item.conversationID),
                    onTap: () async {
                      if (!room.beginChat()) return;
                      try {
                        await showRoomPrivateChatSheet(
                          context,
                          roomId,
                          room.generation,
                          item,
                        );
                        if (context.mounted && room.valid) await vm.refresh();
                      } finally {
                        if (room.mounted) room.finishChat();
                      }
                    },
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialog) => AlertDialog(
                          backgroundColor: AppColors.roomMessagePanel,
                          title: Text(
                            context.l10n.isChinese
                                ? '删除会话？'
                                : 'Delete conversation?',
                            style: AppTextStyles.roomMessageTitle,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialog, false),
                              child: Text(context.l10n.t('app.cancel')),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dialog, true),
                              child: Text(
                                context.l10n.isChinese ? '删除' : 'Delete',
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true &&
                          context.mounted &&
                          room.valid &&
                          (ModalRoute.of(context)?.isCurrent ?? false)) {
                        await vm.deleteConversation(item.conversationID);
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
    required this.deleting,
  });
  final V2TimConversation conversation;
  final VoidCallback onTap, onDelete;
  final bool deleting;
  @override
  Widget build(BuildContext context) => Material(
    color: conversation.isPinned == true
        ? AppColors.roomMessagePinned
        : AppColors.transparent,
    child: InkWell(
      key: ValueKey('room-conversation-${conversation.userID}'),
      onTap: deleting ? null : onTap,
      onLongPress: deleting ? null : onDelete,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: AppSpacing.roomMessageRowHeight.h,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.r),
          child: Row(
            children: [
              RoomAudienceAvatar(
                url: conversation.faceUrl,
                size: AppSpacing.roomMessageAvatar.r,
              ),
              SizedBox(width: AppSpacing.lg.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            imConversationTitle(conversation),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.roomMessageTitle,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm.w),
                        if (conversation.lastMessage != null)
                          Text(
                            imDisplayTime(
                              context,
                              imMessageTime(conversation.lastMessage),
                            ),
                            style: AppTextStyles.roomMessageHint,
                          ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            imMessagePreview(conversation.lastMessage),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.roomMessageHint,
                          ),
                        ),
                        if (deleting)
                          const SizedBox.square(
                            dimension: AppSpacing.messageBadgeSize,
                            child: CircularProgressIndicator(
                              strokeWidth: AppSpacing.xxs,
                            ),
                          )
                        else if ((conversation.unreadCount ?? 0) > 0)
                          Container(
                            key: ValueKey(
                              'room-conversation-unread-${conversation.userID}',
                            ),
                            constraints: const BoxConstraints(
                              minWidth: AppSpacing.messageBadgeSize,
                            ),
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: AppRadius.fieldBorder,
                            ),
                            child: Text(
                              conversation.unreadCount! > 99
                                  ? '99+'
                                  : '${conversation.unreadCount}',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.messageUnread,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
