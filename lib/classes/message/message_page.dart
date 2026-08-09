import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/custom_scaffold.dart';
import 'delete_message_dialog.dart';
import 'im_message_formatter.dart';
import 'message_view_model.dart';

class MessagePage extends HookConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messageViewModelProvider);
    final overlayEntry = useState<OverlayEntry?>(null);

    return CustomScaffold(
      title: context.l10n.t('message.title'),
      showBackButton: false,
      body: RefreshIndicator(
        color: AppColors.primaryPink,
        onRefresh: () => ref.read(messageViewModelProvider.notifier).refresh(),
        child: _MessageBody(state: state, overlayEntry: overlayEntry),
      ),
    );
  }
}

class _MessageBody extends ConsumerWidget {
  const _MessageBody({required this.state, required this.overlayEntry});

  final MessageListState state;
  final ValueNotifier<OverlayEntry?> overlayEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = state.errorMessage;
    if (errorMessage != null && state.conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
          _MessageStateView(
            icon: Icons.error_outline_rounded,
            text: context.l10n.t('message.loadFailed'),
            detail: errorMessage,
            actionLabel: context.l10n.t('app.retry'),
            onAction: () => ref.read(messageViewModelProvider.notifier).load(),
          ),
        ],
      );
    }

    if (state.conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
          _MessageStateView(
            icon: Icons.chat_bubble_outline_rounded,
            text: context.l10n.t('message.empty'),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: state.conversations.length,
      itemBuilder: (context, index) {
        final conversation = state.conversations[index];
        return _ConversationTile(
          conversation: conversation,
          overlayEntry: overlayEntry,
        );
      },
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.conversation,
    required this.overlayEntry,
  });

  final V2TimConversation conversation;
  final ValueNotifier<OverlayEntry?> overlayEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetUID = conversation.userID;
    final title = _conversationTitle(context, conversation);
    final preview = imMessagePreview(conversation.lastMessage);
    final time = _formatTime(context, imMessageTime(conversation.lastMessage));
    final unreadCount = conversation.unreadCount ?? 0;

    return GestureDetector(
      onTap: targetUID == null || targetUID.isEmpty
          ? null
          : () {
              context.push(
                Uri(
                  path: '/chat-view',
                  queryParameters: {'targetUID': targetUID, 'title': title},
                ).toString(),
              );
            },
      onLongPress: () {
        _showDeleteDialog(context, overlayEntry, () async {
          await ref
              .read(messageViewModelProvider.notifier)
              .deleteConversation(conversation.conversationID);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: AppRadius.cardBorder,
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            _ConversationAvatar(url: conversation.faceUrl),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyStrong,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(time, style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview.isEmpty
                              ? context.l10n.t('message.emptyPreview')
                              : preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _UnreadBadge(count: unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _conversationTitle(
    BuildContext context,
    V2TimConversation conversation,
  ) {
    final showName = conversation.showName?.trim();
    if (showName != null && showName.isNotEmpty) return showName;
    final userID = conversation.userID?.trim();
    if (userID == '10000') return 'System';
    if (userID != null && userID.isNotEmpty) return userID;
    return context.l10n.t('message.contact');
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl != null && imageUrl.startsWith('http')) {
      return AppNetworkImage(
        url: imageUrl,
        width: 50,
        height: 50,
        radius: 25,
        placeholder: const _AvatarPlaceholder(),
        errorWidget: const _AvatarPlaceholder(),
      );
    }
    return const _AvatarPlaceholder();
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: AppColors.avatarPlaceholder,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.textInverse,
        size: 25,
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.danger,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MessageStateView extends StatelessWidget {
  const _MessageStateView({
    required this.icon,
    required this.text,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: Icon(icon, color: AppColors.primaryPink, size: 34),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong,
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _showDeleteDialog(
  BuildContext context,
  ValueNotifier<OverlayEntry?> overlayEntry,
  Future<void> Function() onConfirm,
) {
  if (overlayEntry.value != null) return Future.value();

  overlayEntry.value = OverlayEntry(
    builder: (overlayContext) => Positioned.fill(
      child: DeleteMessageDialog(
        onCancel: () {
          overlayEntry.value?.remove();
          overlayEntry.value = null;
        },
        onConfirm: () async {
          await onConfirm();
          overlayEntry.value?.remove();
          overlayEntry.value = null;
        },
      ),
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(overlayEntry.value!);

  final completer = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    completer.complete();
  });
  return completer.future;
}

String _formatTime(BuildContext context, DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

  if (messageDate.isAtSameMomentAs(today)) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  } else if (messageDate.isAtSameMomentAs(yesterday)) {
    return context.l10n.t('message.yesterday');
  } else {
    return '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }
}
