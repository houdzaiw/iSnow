import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../configs/consts.dart';
import '../../manager/app_Isar.dart';
import '../../model/chat_message.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';

class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final messages = useState<List<ChatMessage>>([]);

    // 加载消息列表
    Future<void> loadMessages() async {
      try {
        final isar = await IsarDB.instance.db;
        final loadedMessages = await isar.chatMessages
            .where()
            .sortByCreatedAt()
            .findAll();
        // 使最新消息在下方
        messages.value = loadedMessages.toList();
      } catch (e) {
        // 错误处理，不显示调试信息
        debugPrint('Error loading messages: $e');
      }
    }

    // 初始化时加载消息
    useEffect(() {
      loadMessages();
      return null;
    }, []);

    // 发送消息
    Future<void> sendMessage() async {
      final text = messageController.text.trim();
      if (text.isEmpty) return;

      try {
        final isar = await IsarDB.instance.db;
        final newMessage = ChatMessage.create(message: text, sender: 'user');
        await isar.writeTxn(() async {
          await isar.chatMessages.put(newMessage);
        });

        messageController.clear();
        // 重新加载消息列表
        await loadMessages();
      } catch (e) {
        debugPrint('Error sending message: $e');
      }
    }

    Widget buildMessageBubble(ChatMessage message) {
      final isUser = message.sender == 'user';
      return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.primaryPinkLight
                : AppColors.cardBackground,
            borderRadius: isUser
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
            boxShadow: isUser ? null : AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.message,
                style: AppTextStyles.body.copyWith(
                  color: isUser ? AppColors.textInverse : AppColors.textBody,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: AppTextStyles.timeTiny,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScaffold(
      title: '聊天',
      rightIconPath: AppAssets.moreButton,
      onRightIconTap: () {
        // 更多选项逻辑
        showUserActionOptions(
          context,
          includeDelete: true,
          onDeleteSelected: () async {
            final isar = await IsarDB.instance.db;
            await isar.writeTxn(() async {
              await isar.chatMessages.clear();
            });
            await loadMessages();
          },
        );
      },
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: messages.value.isEmpty
                ? Center(
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
                        const Text('暂无消息', style: AppTextStyles.bodyStrong),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: messages.value.length,
                    itemBuilder: (context, index) {
                      return buildMessageBubble(messages.value[index]);
                    },
                  ),
          ),
          // 底部输入框和发送按钮
          Container(
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
                      controller: messageController,
                      decoration: const InputDecoration(
                        filled: false,
                        hintText: '说点什么...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                        hintStyle: AppTextStyles.hint,
                      ),
                      style: AppTextStyles.bodyStrongSmall,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 发送按钮
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.sendButton,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: AppColors.textInverse,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
