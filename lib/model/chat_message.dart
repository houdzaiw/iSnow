import 'package:isar/isar.dart';

part 'chat_message.g.dart';

@collection
class ChatMessage {
  Id id = Isar.autoIncrement;

  late String message; // 消息内容
  late DateTime createdAt; // 创建时间
  late String sender; // 发送者标识（'user' 或 'other'）

  ChatMessage();

  ChatMessage.create({
    required this.message,
    required this.sender,
  }) {
    createdAt = DateTime.now();
  }
}

