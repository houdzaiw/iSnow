import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

import '../../configs/consts.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';
import 'chat_view_model.dart';
import 'im_message_formatter.dart';

class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key, required this.targetUID, this.title});

  final String targetUID;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final scrollController = useScrollController();

    if (targetUID.trim().isEmpty) {
      return CustomScaffold(
        title: context.l10n.t('chat.title'),
        body: Center(child: Text(context.l10n.t('chat.targetMissing'))),
      );
    }

    final state = ref.watch(chatViewModelProvider(targetUID));

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      });
      return null;
    }, [state.messages.length]);

    Future<void> sendMessage() async {
      final text = messageController.text.trim();
      if (text.isEmpty) return;
      await ref.read(chatViewModelProvider(targetUID).notifier).sendText(text);
      final latestError = ref
          .read(chatViewModelProvider(targetUID))
          .errorMessage;
      if (latestError == null) {
        messageController.clear();
      }
    }

    return CustomScaffold(
      title: title?.trim().isNotEmpty == true ? title!.trim() : targetUID,
      rightIconPath: AppAssets.moreButton,
      onRightIconTap: () {
        showUserActionOptions(context, includeDelete: false);
      },
      body: Column(
        children: [
          if (state.errorMessage != null)
            _ChatErrorBanner(
              message: state.errorMessage!,
              onRetry: () =>
                  ref.read(chatViewModelProvider(targetUID).notifier).load(),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty
                ? _EmptyChatView(text: context.l10n.t('message.empty'))
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.xl,
                    ),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      return _MessageBubble(message: state.messages[index]);
                    },
                  ),
          ),
          _ChatInputBar(
            controller: messageController,
            isSending: state.isSending,
            onSend: sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final V2TimMessage message;

  @override
  Widget build(BuildContext context) {
    final isSelf = message.isSelf == true;
    final content = imMessagePreview(message);
    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.74,
        ),
        decoration: BoxDecoration(
          color: isSelf ? AppColors.primaryPinkLight : AppColors.cardBackground,
          borderRadius: isSelf
              ? const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(6),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
          boxShadow: isSelf ? null : AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: isSelf
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              content.isEmpty
                  ? context.l10n.t('message.emptyPreview')
                  : content,
              style: AppTextStyles.body.copyWith(
                color: isSelf ? AppColors.textInverse : AppColors.textBody,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(context, imMessageTime(message)),
              style: AppTextStyles.timeTiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 5),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 5,
      ),
      decoration: const BoxDecoration(color: AppColors.transparent),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 43,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: AppRadius.fieldBorder,
              ),
              child: TextField(
                controller: controller,
                enabled: !isSending,
                decoration: InputDecoration(
                  filled: false,
                  hintText: context.l10n.t('chat.inputHint'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  hintStyle: AppTextStyles.hint,
                ),
                style: AppTextStyles.bodyStrongSmall,
                maxLines: 1,
                maxLength: 1000,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 43,
              height: 43,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.sendButton,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textInverse,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: AppColors.textInverse,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatErrorBanner extends StatelessWidget {
  const _ChatErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.danger.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: AppColors.danger),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.t('app.retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: AppColors.primaryPink,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(text, style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }
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
    return '${AppLocalizations.of(context).t('message.yesterday')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  } else {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
