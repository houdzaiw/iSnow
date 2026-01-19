
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../manager/app_Isar.dart';
import '../../model/chat_message.dart';
import '../../widgets/custom_scaffold.dart';

class MessagePage extends HookConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = useState<List<ChatMessage>>([]);
    final isLoading = useState(true);

    // 加载最近的消息列表
    Future<void> loadLatestMessages() async {
      try {
        final isar = await IsarDB.instance.db;
        final allMessages = await isar.chatMessages.where().sortByCreatedAtDesc().findAll();

        // 获取最新的 10 条消息作为对话列表的预览
        messages.value = allMessages.take(10).toList();
        isLoading.value = false;
      } catch (e) {
        debugPrint('Error loading messages: $e');
        isLoading.value = false;
      }
    }

    // 初始化加载
    useEffect(() {
      loadLatestMessages();
      return null;
    }, []);

    if (isLoading.value) {
      return CustomScaffold(
        title: 'Messages',
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return CustomScaffold(
      title: 'Messages',
      body: messages.value.isEmpty
          ? Center(
              child: Text(
                '暂无消息',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            )
          : ListView.builder(
              itemCount: messages.value.length,
              itemBuilder: (context, index) {
                final message = messages.value[index];
                return _buildMessageTile(context, message);
              },
            ),
    );
  }

  Widget _buildMessageTile(BuildContext context, ChatMessage message) {
    return GestureDetector(
      onTap: () {
        // 进入聊天详情页
        context.push('/chat-view');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 头像占位符
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  message.sender == 'user' ? 'U' : 'O',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 消息内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 发送者和时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        message.sender == 'user' ? 'You' : 'Contact',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 消息预览
                  Text(
                    message.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      return '昨天';
    } else {
      return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}