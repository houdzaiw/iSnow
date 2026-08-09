import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

import 'im_repository.dart';
import 'message_view_model.dart';

final chatViewModelProvider = StateNotifierProvider.autoDispose
    .family<ChatViewModel, ChatState, String>((ref, targetUID) {
      return ChatViewModel(
        targetUID: targetUID,
        repository: ref.watch(imRepositoryProvider),
      );
    });

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.errorMessage,
  });

  final List<V2TimMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;

  ChatState copyWith({
    List<V2TimMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ChatViewModel extends StateNotifier<ChatState> {
  ChatViewModel({required this.targetUID, required this.repository})
    : super(const ChatState()) {
    unawaited(load());
  }

  final String targetUID;
  final ImRepository repository;
  V2TimAdvancedMsgListener? _messageListener;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final messages = await repository.fetchC2CHistory(targetUID);
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        clearError: true,
      );
      await _ensureListener();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '$e');
    }
  }

  Future<void> sendText(String text) async {
    final content = text.trim();
    if (content.isEmpty || state.isSending) return;

    state = state.copyWith(isSending: true, clearError: true);
    try {
      final message = await repository.sendTextMessage(
        targetUID: targetUID,
        text: content,
      );
      _upsertMessage(message);
      state = state.copyWith(isSending: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isSending: false, errorMessage: '$e');
    }
  }

  Future<void> _ensureListener() async {
    if (_messageListener != null) return;
    _messageListener = await repository.addC2CMessageListener(
      targetUID: targetUID,
      onMessageReceived: _upsertMessage,
    );
  }

  void _upsertMessage(V2TimMessage message) {
    final key = _messageKey(message);
    final messages = [...state.messages];
    final index = messages.indexWhere((item) => _messageKey(item) == key);
    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.add(message);
    }
    messages.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
    state = state.copyWith(messages: messages, clearError: true);
  }

  String _messageKey(V2TimMessage message) {
    return message.msgID ??
        message.id ??
        '${message.sender}-${message.timestamp}';
  }

  @override
  void dispose() {
    final listener = _messageListener;
    if (listener != null) {
      unawaited(repository.removeC2CMessageListener(listener));
    }
    super.dispose();
  }
}
