import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';

import '../../manager/auth_session.dart';
import '../../manager/http_dio_manager.dart';
import 'im_repository.dart';

final imRepositoryProvider = Provider<ImRepository>((ref) {
  return ImRepository(HttpDioManager(), AuthSession.instance);
});

final messageViewModelProvider =
    StateNotifierProvider.autoDispose<MessageViewModel, MessageListState>((
      ref,
    ) {
      return MessageViewModel(ref.watch(imRepositoryProvider));
    });

class MessageListState {
  const MessageListState({
    this.conversations = const [],
    this.totalUnreadCount = 0,
    this.isLoading = true,
    this.errorMessage,
  });

  final List<V2TimConversation> conversations;
  final int totalUnreadCount;
  final bool isLoading;
  final String? errorMessage;

  MessageListState copyWith({
    List<V2TimConversation>? conversations,
    int? totalUnreadCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MessageListState(
      conversations: conversations ?? this.conversations,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class MessageViewModel extends StateNotifier<MessageListState> {
  MessageViewModel(this._repository) : super(const MessageListState()) {
    unawaited(load());
  }

  final ImRepository _repository;
  V2TimConversationListener? _conversationListener;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final conversations = await _repository.fetchConversations();
      final totalUnreadCount = await _repository.fetchTotalUnreadCount();
      state = state.copyWith(
        conversations: conversations,
        totalUnreadCount: totalUnreadCount,
        isLoading: false,
        clearError: true,
      );
      await _ensureListener();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '$e');
    }
  }

  Future<void> refresh() async {
    try {
      final conversations = await _repository.fetchConversations();
      final totalUnreadCount = await _repository.fetchTotalUnreadCount();
      state = state.copyWith(
        conversations: conversations,
        totalUnreadCount: totalUnreadCount,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '$e');
    }
  }

  Future<void> deleteConversation(String conversationID) async {
    await _repository.deleteConversation(conversationID);
    final next = state.conversations
        .where((item) => item.conversationID != conversationID)
        .toList();
    state = state.copyWith(conversations: next);
  }

  Future<void> _ensureListener() async {
    if (_conversationListener != null) return;

    _conversationListener = await _repository.addConversationListener(
      onConversationUpdated: _upsertConversations,
      onUnreadChanged: (count) {
        state = state.copyWith(totalUnreadCount: count);
      },
      onConversationDeleted: (ids) {
        final removed = ids.toSet();
        state = state.copyWith(
          conversations: state.conversations
              .where((item) => !removed.contains(item.conversationID))
              .toList(),
        );
      },
    );
  }

  void _upsertConversations(List<V2TimConversation> incoming) {
    final byId = {
      for (final conversation in state.conversations)
        conversation.conversationID: conversation,
    };
    for (final conversation in incoming) {
      final userID = conversation.userID;
      if (userID == null || userID.isEmpty) continue;
      byId[conversation.conversationID] = conversation;
    }
    final conversations = byId.values.toList()
      ..sort((a, b) {
        if ((a.isPinned ?? false) != (b.isPinned ?? false)) {
          return (b.isPinned ?? false) ? 1 : -1;
        }
        final aTime = a.lastMessage?.timestamp ?? a.orderkey ?? 0;
        final bTime = b.lastMessage?.timestamp ?? b.orderkey ?? 0;
        return bTime.compareTo(aTime);
      });
    state = state.copyWith(conversations: conversations, clearError: true);
  }

  @override
  void dispose() {
    final listener = _conversationListener;
    if (listener != null) {
      unawaited(_repository.removeConversationListener(listener));
    }
    super.dispose();
  }
}
