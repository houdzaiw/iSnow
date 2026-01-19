
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../manager/app_Isar.dart';
import '../../model/chat_message.dart';
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
        final loadedMessages = await isar.chatMessages.where().sortByCreatedAtDesc().findAll();
        // 反转顺序，使最新消息在下方
        messages.value = loadedMessages.reversed.toList();
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
        final newMessage = ChatMessage.create(
          message: text,
          sender: 'user',
        );
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
          margin: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFFFBF69F) : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.message,
                style: TextStyle(
                  fontSize: 15,
                  color: isUser ? const Color(0xFF262626) : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScaffold(
      title: 'Chat',
      rightIconPath: 'assets/base/more_button.png',
      onRightIconTap: () {
        // 更多选项逻辑
      },
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: messages.value.isEmpty
                ? const Center(
                    child: Text(
                      '暂无消息',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: messages.value.length,
                    itemBuilder: (context, index) {
                      return buildMessageBubble(messages.value[index]);
                    },
                  ),
          ),
          // 底部输入框和发送按钮
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 43,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF5EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: 'Say hi...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 发送按钮
                GestureDetector(
                  onTap: sendMessage,
                  child: Image.asset(
                    'assets/message/send_button.png',
                    width: 36,
                    height: 36,
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
    final messageDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}