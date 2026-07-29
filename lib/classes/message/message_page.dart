import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../manager/app_Isar.dart';
import '../../model/chat_message.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';
import 'delete_message_dialog.dart';

class MessagePage extends HookConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = useState<List<ChatMessage>>([]);
    final isLoading = useState(true);
    final overlayEntry = useState<OverlayEntry?>(null);

    // 加载最近的消息列表
    Future<void> loadLatestMessages() async {
      try {
        final isar = await IsarDB.instance.db;
        final allMessages = await isar.chatMessages
            .where()
            .sortByCreatedAtDesc()
            .findAll();

        // 获取最新的 10 条消息作为对话列表的预览
        messages.value = allMessages.take(1).toList();
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
        title: '消息',
        showBackButton: false,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return CustomScaffold(
      title: '消息',
      showBackButton: false,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: messages.value.isEmpty
            ? Center(
                child: Text(
                  '暂无消息',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: messages.value.length,
                itemBuilder: (context, index) {
                  final message = messages.value[index];
                  return _buildMessageTile(context, message, overlayEntry);
                },
              ),
      ),
    );
  }

  Widget _buildMessageTile(
    BuildContext context,
    ChatMessage message,
    ValueNotifier<OverlayEntry?> overlayEntry,
  ) {
    return GestureDetector(
      onTap: () {
        // 进入聊天详情页
        context.push('/chat-view');
      },
      // 长按
      onLongPress: () {
        // 显示删除对话选项
        _showDialogAsync(context, overlayEntry);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: AppRadius.cardBorder,
        ),
        child: Row(
          children: [
            // 头像占位符
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.avatarPlaceholder,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  message.sender == 'user' ? 'U' : 'O',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                        message.sender == 'user' ? '我' : '联系人',
                        style: AppTextStyles.bodyStrong,
                      ),
                      Text(
                        _formatTime(message.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
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
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
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

  Future<void> _showDialogAsync(
    BuildContext context,
    ValueNotifier<OverlayEntry?> overlayEntry,
  ) {
    if (overlayEntry.value != null) return Future.value();

    overlayEntry.value = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: DeleteMessageDialog(
          onCancel: () {
            overlayEntry.value?.remove();
            overlayEntry.value = null;
          },
          onConfirm: () {
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
