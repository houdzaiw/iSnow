import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';

import '../../manager/auth_session.dart';
import '../../manager/api_error_message.dart';
import '../../manager/http_dio_manager.dart';
import '../../model/im_models.dart';
import 'im_repository.dart';

final imRepositoryProvider = Provider<ImRepository>((ref) {
  final repository = ImRepository(HttpDioManager(), AuthSession.instance);
  ref.onDispose(repository.dispose);
  return repository;
});

final messageViewModelProvider =
    StateNotifierProvider.autoDispose<MessageViewModel, MessageListState>(
      (ref) => MessageViewModel(ref.watch(imRepositoryProvider)),
    );

class MessageListState {
  const MessageListState({
    this.conversations = const [],
    this.totalUnreadCount = 0,
    this.isLoading = true,
    this.errorMessage,
    this.connection = const ImConnectionState(),
    this.deleting = const {},
  });
  final List<V2TimConversation> conversations;
  final int totalUnreadCount;
  final bool isLoading;
  final String? errorMessage;
  final ImConnectionState connection;
  final Set<String> deleting;

  MessageListState copyWith({
    List<V2TimConversation>? conversations,
    int? totalUnreadCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    ImConnectionState? connection,
    Set<String>? deleting,
  }) => MessageListState(
    conversations: conversations ?? this.conversations,
    totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    connection: connection ?? this.connection,
    deleting: deleting ?? this.deleting,
  );
}

class MessageViewModel extends StateNotifier<MessageListState> {
  MessageViewModel(this._repository)
    : super(MessageListState(connection: _repository.session.state)) {
    _revision = _repository.session.revision;
    _repository.session.addListener(_connectionChanged);
    unawaited(load());
  }
  final ImRepository _repository;
  V2TimConversationListener? _conversationListener;
  Future<void>? _pending;
  int _request = 0, _revision = 0, _version = 0;
  final _versions = <String, int>{};

  bool _current(int request) => mounted && request == _request;

  void _connectionChanged() {
    if (!mounted) return;
    final connection = _repository.session.state;
    if (_revision != connection.revision) {
      _revision = connection.revision;
      _request++;
      _pending = null;
      _versions.clear();
      final listener = _conversationListener;
      _conversationListener = null;
      if (listener != null) _remove(listener);
      state = MessageListState(connection: connection, isLoading: false);
    } else {
      state = state.copyWith(connection: connection);
    }
    if (_pending == null && connection.status == ImConnectionStatus.connected ||
        _pending == null &&
            connection.status == ImConnectionStatus.disconnected) {
      unawaited(load());
    }
  }

  Future<void> load() {
    if (!mounted) return Future.value();
    if (_pending != null) return _pending!;
    final request = ++_request;
    return _pending = _load(request).whenComplete(() {
      if (_current(request)) _pending = null;
    });
  }

  Future<void> refresh() => load();

  Future<void> reconnect() async {
    try {
      await _repository.session.reconnect();
      if (mounted) await load();
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: userFacingErrorMessage(error),
        );
      }
    }
  }

  Future<void> _load(int request) async {
    state = state.copyWith(
      isLoading: state.conversations.isEmpty,
      clearError: true,
    );
    try {
      await _repository.ensureReady();
      if (!_current(request)) return;
      if (_conversationListener == null) {
        final listener = await _repository.addConversationListener(
          onConversationUpdated: _upsert,
          onUnreadChanged: (_) {
            if (mounted) unawaited(refresh());
          },
          onConversationDeleted: _deleteLocally,
        );
        if (!_current(request)) {
          _remove(listener);
          return;
        }
        _conversationListener = listener;
      }
      final before = Map<String, int>.of(_versions);
      final fetched = await _repository.fetchConversations();
      if (!_current(request)) return;
      final rows = <String, V2TimConversation>{
        for (final c in fetched)
          if (_versions[c.conversationID] == before[c.conversationID])
            c.conversationID: c,
        for (final c in state.conversations)
          if (_versions[c.conversationID] != before[c.conversationID])
            c.conversationID: c,
      };
      _publish(rows.values);
    } catch (error) {
      if (_current(request)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: userFacingErrorMessage(error),
        );
      }
    }
  }

  void _publish(Iterable<V2TimConversation> rows) {
    final sorted = sortImConversations(
      rows.where((c) => c.type == 1 && c.userID?.isNotEmpty == true),
    );
    state = state.copyWith(
      conversations: sorted,
      totalUnreadCount: sorted.fold<int>(
        0,
        (sum, c) => sum + (c.unreadCount ?? 0),
      ),
      isLoading: false,
      clearError: true,
    );
  }

  void _upsert(List<V2TimConversation> incoming) {
    if (!mounted) return;
    final rows = {for (final c in state.conversations) c.conversationID: c};
    for (final c in incoming) {
      _versions[c.conversationID] = ++_version;
      if (c.type == 1 && c.userID?.isNotEmpty == true) {
        rows[c.conversationID] = c;
      }
    }
    _publish(rows.values);
  }

  void _deleteLocally(List<String> ids) {
    if (!mounted) return;
    for (final id in ids) {
      _versions[id] = ++_version;
    }
    _publish(state.conversations.where((c) => !ids.contains(c.conversationID)));
  }

  Future<bool> deleteConversation(String id) async {
    if (!mounted || state.deleting.contains(id)) return false;
    final request = _request;
    state = state.copyWith(deleting: {...state.deleting, id}, clearError: true);
    try {
      await _repository.deleteConversation(id);
      if (!_current(request)) return false;
      _deleteLocally([id]);
      return true;
    } catch (error) {
      if (_current(request)) {
        state = state.copyWith(errorMessage: userFacingErrorMessage(error));
      }
      return false;
    } finally {
      if (_current(request)) {
        state = state.copyWith(deleting: {...state.deleting}..remove(id));
      }
    }
  }

  void _remove(V2TimConversationListener listener) => unawaited(
    _repository.removeConversationListener(listener).catchError((Object _) {}),
  );

  @override
  void dispose() {
    _request++;
    _repository.session.removeListener(_connectionChanged);
    final listener = _conversationListener;
    if (listener != null) _remove(listener);
    super.dispose();
  }
}
