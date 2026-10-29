import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/offlinePushInfo.dart';
import 'package:tencent_cloud_chat_sdk/manager/v2_tim_manager.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

import '../../manager/auth_session.dart';
import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../manager/im_session_manager.dart';
import '../../model/im_models.dart';
import '../../model/server_response.dart';
import '../../model/tim_token_data.dart';

class ImRepository {
  ImRepository(this._httpManager, this._authSession, {V2TIMManager? sdk})
    : _sdkOverride = sdk;
  final V2TIMManager? _sdkOverride;
  ImSessionManager? _session;
  ImSessionManager get session => _session ??= ImSessionManager(
    sdk: _sdkOverride ?? TencentImSDKPlugin.v2TIMManager,
    auth: _authSession,
    loadToken: _fetchTimToken,
  );
  final HttpDioManager _httpManager;
  final AuthSession _authSession;
  final _conversations = <V2TimConversationListener>{};
  final _messages = <V2TimAdvancedMsgListener>{};
  bool _disposed = false;
  V2TIMManager get _sdk => session.sdk;

  Future<void> ensureReady() => session.ensureReady();

  void _check(int revision, [bool Function()? current]) {
    if (_disposed || !session.isCurrent(revision) || current?.call() == false) {
      throw const NadyApiException(message: 'IM session changed');
    }
  }

  Future<List<V2TimConversation>> fetchConversations() async {
    await ensureReady();
    final revision = session.revision;
    final list = <V2TimConversation>[];
    final visited = <String>{};
    var next = '0';
    do {
      visited.add(next);
      final response = await _sdk.getConversationManager().getConversationList(
        nextSeq: next,
        count: 100,
      );
      _check(revision);
      _throwIfFailed(response.code, response.desc);
      final result = response.data;
      list.addAll(
        (result?.conversationList ?? []).where(
          (c) => c.type == 1 && c.userID?.isNotEmpty == true,
        ),
      );
      next = result?.nextSeq ?? '0';
      if (result?.isFinished ?? true) break;
    } while (!visited.contains(next));
    return sortImConversations(
      {for (final c in list) c.conversationID: c}.values,
    );
  }

  Future<int> fetchTotalUnreadCount() async {
    await ensureReady();
    final revision = session.revision;
    final response = await _sdk
        .getConversationManager()
        .getTotalUnreadMessageCount();
    _check(revision);
    _throwIfFailed(response.code, response.desc);
    return response.data ?? 0;
  }

  Future<void> deleteConversation(String conversationID) async {
    await ensureReady();
    final revision = session.revision;
    final response = await _sdk.getConversationManager().deleteConversation(
      conversationID: conversationID,
    );
    _check(revision);
    _throwIfFailed(response.code, response.desc);
  }

  Future<V2TimConversationListener> addConversationListener({
    required ValueChanged<List<V2TimConversation>> onConversationUpdated,
    required ValueChanged<int> onUnreadChanged,
    required ValueChanged<List<String>> onConversationDeleted,
  }) async {
    await ensureReady();
    final revision = session.revision;
    late V2TimConversationListener listener;
    bool current() =>
        !_disposed &&
        session.isCurrent(revision) &&
        _conversations.contains(listener);
    listener = V2TimConversationListener(
      onNewConversation: (items) {
        if (current()) onConversationUpdated(items);
      },
      onConversationChanged: (items) {
        if (current()) onConversationUpdated(items);
      },
      onTotalUnreadMessageCountChanged: (count) {
        if (current()) onUnreadChanged(count);
      },
      onConversationDeleted: (ids) {
        if (current()) onConversationDeleted(ids);
      },
    );
    _conversations.add(listener);
    try {
      await _sdk.getConversationManager().addConversationListener(
        listener: listener,
      );
      if (!current()) await removeConversationListener(listener);
      return listener;
    } catch (_) {
      _conversations.remove(listener);
      rethrow;
    }
  }

  Future<void> removeConversationListener(
    V2TimConversationListener listener,
  ) async {
    _conversations.remove(listener);
    await _sdk.getConversationManager().removeConversationListener(
      listener: listener,
    );
  }

  Future<ImHistoryPage> fetchHistoryPage(
    String targetUID, {
    String? cursor,
  }) async {
    await ensureReady();
    final revision = session.revision;
    final response = await _sdk.getMessageManager().getC2CHistoryMessageList(
      userID: targetUID,
      count: 20,
      lastMsgID: cursor,
    );
    _check(revision);
    _throwIfFailed(response.code, response.desc);
    final list = [...?response.data]
      ..sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
    final next = list.firstOrNull?.msgID;
    return ImHistoryPage(
      list,
      cursor: next,
      hasMore: list.length == 20 && next != null && next != cursor,
    );
  }

  Future<List<V2TimMessage>> fetchC2CHistory(String targetUID) async {
    final page = await fetchHistoryPage(targetUID);
    await markC2CRead(targetUID);
    return page.messages;
  }

  Future<void> _validateText(
    String uid,
    String text,
    int revision,
    bool Function()? current,
  ) async {
    if (isImSystemUser(uid)) {
      throw const NadyApiException(message: 'This conversation is read-only');
    }
    final profile = _data(
      await _httpManager.get(
        HttpApi.userHomepage,
        queryParameters: {'targetUid': uid},
      ),
    );
    _check(revision, current);
    final user = _map(_map(_map(profile)['info'])['userBaseInfo']);
    if (user.isEmpty) {
      throw const NadyApiException(
        message: 'Unable to verify message permission',
      );
    }
    final vip = int.tryParse('${_map(user['userLevel'])['vipLevel']}') ?? 0;
    final relation = '${user['followRelation']}';
    if (vip >= 5 && relation != 'FOLLOW_MUTUAL' && relation != '3') {
      final settings = _map(
        _data(
          await _httpManager.get(
            HttpApi.userVipSetting,
            queryParameters: {'uid': uid},
          ),
        ),
      );
      _check(revision, current);
      final open = _map(settings['noDisturb'])['open'];
      if (open is! bool) {
        throw const NadyApiException(
          message: 'Unable to verify message permission',
        );
      }
      if (open) {
        throw const NadyApiException(
          message:
              'Operation failed. The VIP user has enabled the "Do Not Disturb" mode.',
        );
      }
    }
    final approved = _data(
      await _httpManager.post(
        HttpApi.imTextAudit,
        data: {'receiveUid': uid, 'type': 'text', 'content': text},
      ),
    );
    _check(revision, current);
    if (approved != true) {
      throw const NadyApiException(
        message: 'Message did not pass content review',
      );
    }
  }

  Future<V2TimMessage> sendTextMessage({
    required String targetUID,
    required String text,
    bool Function()? isCurrent,
  }) async {
    await ensureReady();
    final revision = session.revision;
    _check(revision, isCurrent);
    await _validateText(targetUID, text, revision, isCurrent);
    final manager = _sdk.getMessageManager();
    final created = await manager.createTextMessage(text: text);
    _check(revision, isCurrent);
    _throwIfFailed(created.code, created.desc);
    final message = created.data?.messageInfo;
    if (message == null) {
      throw const NadyApiException(message: 'Failed to create IM message');
    }
    final user = await _authSession.user();
    _check(revision, isCurrent);
    final response = await manager.sendMessage(
      message: message,
      receiver: targetUID,
      groupID: '',
      offlinePushInfo: OfflinePushInfo(
        title: user?.nick ?? 'Message',
        desc: text,
        ignoreIOSBadge: true,
        ext: jsonEncode({
          'jumpUrl':
              'nady:///main/p2p-chat?target-u-i-d=${session.state.uid}&is-on-room=false',
        }),
      ),
    );
    _check(revision, isCurrent);
    _throwIfFailed(response.code, response.desc);
    if (response.data == null) {
      throw const NadyApiException(message: 'Message failed to send');
    }
    return response.data!;
  }

  Future<void> sendRoomInvitation({
    required String targetUID,
    required Map<String, dynamic> room,
  }) async {
    await ensureReady();
    final revision = session.revision;
    final manager = _sdk.getMessageManager();
    final created = await manager.createCustomMessage(
      data: jsonEncode({
        'type': 'shareRoom',
        'payload': jsonEncode({...room, 'roomPasswd': ''}),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
      desc: '[Share Room]',
      extension: '',
    );
    _check(revision);
    _throwIfFailed(created.code, created.desc);
    final message = created.data?.messageInfo;
    if (message == null) {
      throw const NadyApiException(message: 'Failed to create room invitation');
    }
    final response = await manager.sendMessage(
      message: message,
      receiver: targetUID,
      groupID: '',
    );
    _check(revision);
    _throwIfFailed(response.code, response.desc);
  }

  Future<V2TimAdvancedMsgListener> addC2CMessageListener({
    required String targetUID,
    required ValueChanged<V2TimMessage> onMessageReceived,
  }) async {
    await ensureReady();
    final revision = session.revision;
    late V2TimAdvancedMsgListener listener;
    void receive(V2TimMessage message) {
      if (!_disposed &&
          session.isCurrent(revision) &&
          _messages.contains(listener) &&
          (message.userID == targetUID || message.sender == targetUID)) {
        onMessageReceived(message);
      }
    }

    listener = V2TimAdvancedMsgListener(
      onRecvNewMessage: receive,
      onRecvMessageModified: receive,
    );
    _messages.add(listener);
    try {
      await _sdk.getMessageManager().addAdvancedMsgListener(listener: listener);
      if (_disposed || !session.isCurrent(revision)) {
        await removeC2CMessageListener(listener);
      }
      return listener;
    } catch (_) {
      _messages.remove(listener);
      rethrow;
    }
  }

  Future<void> removeC2CMessageListener(
    V2TimAdvancedMsgListener listener,
  ) async {
    _messages.remove(listener);
    await _sdk.getMessageManager().removeAdvancedMsgListener(
      listener: listener,
    );
  }

  Future<void> markC2CRead(
    String targetUID, {
    bool Function()? isCurrent,
  }) async {
    await ensureReady();
    final revision = session.revision;
    _check(revision, isCurrent);
    final response = await _sdk
        .getConversationManager()
        .cleanConversationUnreadMessageCount(
          conversationID: 'c2c_$targetUID',
          cleanTimestamp: 0,
          cleanSequence: 0,
        );
    _check(revision);
    _throwIfFailed(response.code, response.desc);
  }

  Future<TimTokenData> _fetchTimToken() async {
    final data = _data(await _httpManager.get(HttpApi.timToken));
    if (data is! Map) throw const NadyApiException(message: 'Empty IM token');
    return TimTokenData.fromJson(data.cast<String, dynamic>());
  }

  Object? _data(Object? response) {
    final server = NadyServerResponse<Object?>.fromJson(
      _map(response),
      (v) => v,
    );
    if (!server.isSuccess) throw server.toException();
    return server.data;
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : {};
  void _throwIfFailed(int code, String desc) {
    if (code != 0) {
      throw NadyApiException(
        message: desc.isEmpty ? 'IM request failed' : desc,
      );
    }
  }

  void dispose() {
    _disposed = true;
    for (final listener in [..._conversations]) {
      unawaited(removeConversationListener(listener).catchError((Object _) {}));
    }
    for (final listener in [..._messages]) {
      unawaited(removeC2CMessageListener(listener).catchError((Object _) {}));
    }
    _session?.dispose();
  }
}
