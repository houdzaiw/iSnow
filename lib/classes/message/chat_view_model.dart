import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

import '../../manager/api_error_message.dart';
import '../../model/im_models.dart';
import 'im_repository.dart';
import 'message_view_model.dart';

final chatViewModelProvider = StateNotifierProvider.autoDispose
    .family<ChatViewModel, ChatState, String>(
      (ref, uid) => ChatViewModel(
        targetUID: uid,
        repository: ref.watch(imRepositoryProvider),
      ),
    );

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.errorMessage,
    this.loadingMore = false,
    this.hasMore = false,
    this.cursor,
  });
  final List<V2TimMessage> messages;
  final bool isLoading, isSending, loadingMore, hasMore;
  final String? errorMessage, cursor;
  ChatState copyWith({
    List<V2TimMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
    bool? loadingMore,
    bool? hasMore,
    String? cursor,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isSending: isSending ?? this.isSending,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMore: hasMore ?? this.hasMore,
    cursor: cursor ?? this.cursor,
  );
}

class ChatViewModel extends StateNotifier<ChatState> {
  ChatViewModel({
    required this.targetUID,
    required this.repository,
    this.isCurrent,
  }) : super(const ChatState()) {
    _revision = repository.session.revision;
    repository.session.addListener(_connectionChanged);
    unawaited(load());
  }
  final String targetUID;
  final ImRepository repository;
  final bool Function()? isCurrent;
  V2TimAdvancedMsgListener? _messageListener;
  int _epoch = 0, _revision = 0;
  int? _boundUid;
  bool _closed = false;
  bool _active = true;
  bool _visible = true;
  void setVisible(bool value) {
    final resumed = value && !_visible;
    _visible = value;
    if (resumed) unawaited(_markRead());
  }

  bool get _current =>
      mounted &&
      _active &&
      repository.session.revision == _revision &&
      isCurrent?.call() != false;

  void _connectionChanged() {
    if (!mounted || _closed) return;
    final connection = repository.session.state;
    if (_revision != connection.revision) {
      _revision = connection.revision;
      _active = false;
      _epoch++;
      state = const ChatState(isLoading: false);
      final listener = _messageListener;
      _messageListener = null;
      if (listener != null) _remove(listener);
    }
    if (!_active &&
        _boundUid != null &&
        connection.uid == _boundUid &&
        connection.status == ImConnectionStatus.connected &&
        isCurrent?.call() != false) {
      _active = true;
      unawaited(load());
    }
  }

  Future<void> load() async {
    if (!_current || state.isSending) return;
    final epoch = ++_epoch;
    state = state.copyWith(
      isLoading: true,
      loadingMore: false,
      clearError: true,
    );
    try {
      await repository.ensureReady();
      if (!_current || epoch != _epoch) return;
      _boundUid ??= repository.session.state.uid;
      if (_messageListener == null) {
        final listener = await repository.addC2CMessageListener(
          targetUID: targetUID,
          onMessageReceived: (message) {
            if (!_current) return;
            _merge([message]);
            if (_visible) unawaited(_markRead());
          },
        );
        if (!_current || epoch != _epoch) {
          _remove(listener);
          return;
        }
        _messageListener = listener;
      }
      final page = await repository.fetchHistoryPage(targetUID);
      if (!_current || epoch != _epoch) return;
      _merge(page.messages);
      state = state.copyWith(
        isLoading: false,
        hasMore: page.hasMore,
        cursor: page.cursor,
      );
      await _markRead();
    } catch (error) {
      if (_current && epoch == _epoch) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: userFacingErrorMessage(error),
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (!_current || state.isLoading || state.loadingMore || !state.hasMore) {
      return;
    }
    final epoch = _epoch;
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await repository.fetchHistoryPage(
        targetUID,
        cursor: state.cursor,
      );
      if (!_current || epoch != _epoch) return;
      _merge(page.messages);
      state = state.copyWith(
        loadingMore: false,
        cursor: page.cursor,
        hasMore: page.hasMore,
      );
    } catch (error) {
      if (_current && epoch == _epoch) {
        state = state.copyWith(
          loadingMore: false,
          errorMessage: userFacingErrorMessage(error),
        );
      }
    }
  }

  Future<bool> sendText(String text) async {
    final content = text.trim();
    if (!_current ||
        !_visible ||
        content.isEmpty ||
        state.isSending ||
        isImSystemUser(targetUID)) {
      return false;
    }
    final epoch = _epoch;
    bool current() => _current && epoch == _epoch;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final message = await repository.sendTextMessage(
        targetUID: targetUID,
        text: content,
        isCurrent: current,
      );
      if (!current()) return false;
      _merge([message]);
      state = state.copyWith(isSending: false, clearError: true);
      return true;
    } catch (error) {
      if (current()) {
        state = state.copyWith(
          isSending: false,
          errorMessage: userFacingErrorMessage(error),
        );
      }
      return false;
    }
  }

  Future<void> _markRead() async {
    if (!_current || !_visible) return;
    try {
      await repository.markC2CRead(
        targetUID,
        isCurrent: () => _current && _visible,
      );
    } catch (error) {
      if (_current) {
        state = state.copyWith(errorMessage: userFacingErrorMessage(error));
      }
    }
  }

  void _merge(List<V2TimMessage> incoming) {
    final rows = {
      for (final m in state.messages) _key(m): m,
      for (final m in incoming) _key(m): m,
    };
    final sorted = rows.values.toList()
      ..sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
    state = state.copyWith(messages: sorted);
  }

  String _key(V2TimMessage m) =>
      m.msgID ?? m.id ?? '${m.sender}-${m.timestamp}';
  void close() {
    _closed = true;
    _active = false;
    _epoch++;
  }

  void _remove(V2TimAdvancedMsgListener listener) => unawaited(
    repository.removeC2CMessageListener(listener).catchError((Object _) {}),
  );
  @override
  void dispose() {
    close();
    repository.session.removeListener(_connectionChanged);
    final listener = _messageListener;
    if (listener != null) _remove(listener);
    super.dispose();
  }
}
