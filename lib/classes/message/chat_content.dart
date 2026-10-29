import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

import '../../localization/app_localizations.dart';
import '../../model/im_models.dart';
import '../../theme/app_theme.dart';
import '../room/more/room_entry_flow.dart';
import '../room/more/room_invitation_card.dart';
import 'chat_view_model.dart';
import 'im_message_formatter.dart';
import 'message_view_model.dart';

class ChatContent extends HookConsumerWidget {
  const ChatContent({
    super.key,
    required this.targetUID,
    this.dark = false,
    this.provider,
  });
  final String targetUID;
  final bool dark;
  final AutoDisposeStateNotifierProvider<ChatViewModel, ChatState>? provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = provider ?? chatViewModelProvider(targetUID);
    final state = ref.watch(source);
    final vm = ref.read(source.notifier);
    final connection = ref.watch(
      messageViewModelProvider.select((s) => s.connection),
    );
    final input = useTextEditingController();
    final scroll = useScrollController();
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    useEffect(() {
      vm.setVisible(visible);
      return null;
    }, [visible, vm]);
    useEffect(() {
      void more() {
        if (scroll.hasClients &&
            scroll.position.pixels >=
                scroll.position.maxScrollExtent -
                    AppSpacing.messageHistoryThreshold) {
          unawaited(vm.loadMore());
        }
      }

      scroll.addListener(more);
      return () => scroll.removeListener(more);
    }, [scroll, vm]);
    final latest = state.messages.lastOrNull;
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted &&
            scroll.hasClients &&
            (scroll.offset < AppSpacing.messageHistoryThreshold ||
                latest?.isSelf == true)) {
          scroll.jumpTo(0);
        }
      });
      return null;
    }, [latest?.msgID ?? latest?.id]);
    final bodyStyle = dark ? AppTextStyles.roomMessageBody : AppTextStyles.body;
    Future<void> send() async {
      final text = input.text;
      if (text.trim().isEmpty) return;
      final success = await vm.sendText(text);
      if (context.mounted && success && input.text == text) input.clear();
    }

    return Column(
      children: [
        if (connection.status == ImConnectionStatus.error)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    connection.error ?? 'Unable to connect',
                    style: dark
                        ? AppTextStyles.roomMessageHint
                        : AppTextStyles.caption,
                  ),
                ),
                TextButton(
                  onPressed: ref
                      .read(messageViewModelProvider.notifier)
                      .reconnect,
                  child: Text(context.l10n.t('app.retry')),
                ),
              ],
            ),
          ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: dark
                        ? AppTextStyles.roomMessageHint
                        : AppTextStyles.caption,
                  ),
                ),
                TextButton(
                  onPressed: state.isLoading ? null : vm.load,
                  child: Text(context.l10n.t('app.retry')),
                ),
              ],
            ),
          ),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.messages.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.t('message.empty'),
                    style: bodyStyle,
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('private-chat-history'),
                  controller: scroll,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  itemCount: state.messages.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.messages.length) {
                      return Center(
                        child: state.loadingMore
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: vm.loadMore,
                                child: Text(
                                  context.l10n.isChinese
                                      ? '加载更早的消息'
                                      : 'Load earlier messages',
                                ),
                              ),
                      );
                    }
                    return _ChatBubble(
                      message:
                          state.messages[state.messages.length - index - 1],
                      dark: dark,
                    );
                  },
                ),
        ),
        if (!isImSystemUser(targetUID))
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('private-chat-input'),
                    controller: input,
                    enabled: !state.isSending,
                    style: bodyStyle,
                    maxLines: 1,
                    maxLength: 1000,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    decoration: InputDecoration(
                      hintText: context.l10n.t('chat.inputHint'),
                      hintStyle: dark
                          ? AppTextStyles.roomMessageHint
                          : AppTextStyles.hint,
                      filled: true,
                      fillColor: dark
                          ? AppColors.roomMessageBubble
                          : AppColors.cardBackground,
                      border: const OutlineInputBorder(
                        borderRadius: AppRadius.fieldBorder,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => send(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox.square(
                  dimension: AppSpacing.messageInputHeight,
                  child: state.isSending
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: CircularProgressIndicator(),
                        )
                      : IconButton(
                          key: const ValueKey('private-chat-send'),
                          tooltip: context.l10n.isChinese ? '发送' : 'Send',
                          onPressed: send,
                          icon: Image.asset(AppAssets.messageSendButton),
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.dark});
  final V2TimMessage message;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final self = message.isSelf == true;
    final text = imMessagePreview(message);
    return Align(
      alignment: self
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.sizeOf(context).width *
              AppSpacing.messageBubbleMaxRatio,
        ),
        decoration: BoxDecoration(
          color: self
              ? AppColors.primaryPink
              : dark
              ? AppColors.roomMessageBubble
              : AppColors.cardBackground,
          borderRadius: AppRadius.fieldBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (decodeRoomInvitation(message.customElem?.data)
                case final invitation?)
              RoomInvitationCard(room: invitation)
            else
              Text(
                text.isEmpty ? context.l10n.t('message.emptyPreview') : text,
                style: self || dark
                    ? AppTextStyles.roomMessageBody
                    : AppTextStyles.body,
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              imDisplayTime(context, imMessageTime(message)),
              style: self || dark
                  ? AppTextStyles.roomMessageHint
                  : AppTextStyles.timeTiny,
            ),
          ],
        ),
      ),
    );
  }
}

String imDisplayTime(BuildContext context, DateTime time) {
  final now = DateTime.now();
  final clock =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  if (now.year == time.year && now.month == time.month && now.day == time.day) {
    return clock;
  }
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} $clock';
}
