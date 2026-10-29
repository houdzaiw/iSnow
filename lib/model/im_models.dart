import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

enum ImConnectionStatus { disconnected, connecting, connected, error }

class ImConnectionState {
  const ImConnectionState({
    this.status = ImConnectionStatus.disconnected,
    this.uid,
    this.revision = 0,
    this.error,
  });
  final ImConnectionStatus status;
  final int? uid;
  final int revision;
  final String? error;
}

class ImHistoryPage {
  const ImHistoryPage(this.messages, {this.cursor, this.hasMore = false});
  final List<V2TimMessage> messages;
  final String? cursor;
  final bool hasMore;
}

const imSystemNames = {
  '10000': 'System',
  '10001': 'Wallet Assistant',
  '10002': 'Friend Assistant',
  '10003': 'Interaction Notification',
};

bool isImSystemUser(String uid) => imSystemNames.containsKey(uid);

String imConversationTitle(V2TimConversation conversation) =>
    imSystemNames[conversation.userID] ??
    (conversation.showName?.trim().isNotEmpty == true
        ? conversation.showName!.trim()
        : conversation.userID ?? 'Message');

List<V2TimConversation> sortImConversations(
  Iterable<V2TimConversation> source,
) => source.toList()
  ..sort((a, b) {
    if ((a.isPinned ?? false) != (b.isPinned ?? false)) {
      return b.isPinned == true ? 1 : -1;
    }
    return (b.lastMessage?.timestamp ?? b.orderkey ?? 0).compareTo(
      a.lastMessage?.timestamp ?? a.orderkey ?? 0,
    );
  });
