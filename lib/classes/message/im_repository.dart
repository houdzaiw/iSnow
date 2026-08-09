import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/conversation_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/log_level_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/offlinePushInfo.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

import '../../manager/auth_session.dart';
import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../model/server_response.dart';
import '../../model/tim_token_data.dart';

class ImRepository {
  ImRepository(this._httpManager, this._authSession);

  final HttpDioManager _httpManager;
  final AuthSession _authSession;

  bool _loggedIn = false;
  Future<void>? _loginFuture;

  Future<void> ensureReady() async {
    if (_loggedIn) return;
    _loginFuture ??= _login();
    try {
      await _loginFuture;
    } finally {
      _loginFuture = null;
    }
  }

  Future<List<V2TimConversation>> fetchConversations() async {
    await ensureReady();
    final manager = TencentImSDKPlugin.v2TIMManager.getConversationManager();
    final conversations = <V2TimConversation>[];
    var nextSeq = '0';

    do {
      final response = await manager.getConversationList(
        nextSeq: nextSeq,
        count: 100,
      );
      _throwIfFailed(response.code, response.desc);
      final result = response.data;
      conversations.addAll(
        (result?.conversationList ?? const []).where(_isC2CConversation),
      );
      nextSeq = result?.nextSeq ?? '0';
      if (result?.isFinished ?? true) break;
    } while (nextSeq != '0');

    return _sortConversations(conversations);
  }

  Future<int> fetchTotalUnreadCount() async {
    await ensureReady();
    final response = await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .getTotalUnreadMessageCount();
    _throwIfFailed(response.code, response.desc);
    return response.data ?? 0;
  }

  Future<void> deleteConversation(String conversationID) async {
    await ensureReady();
    final response = await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .deleteConversation(conversationID: conversationID);
    _throwIfFailed(response.code, response.desc);
  }

  Future<V2TimConversationListener> addConversationListener({
    required ValueChanged<List<V2TimConversation>> onConversationUpdated,
    required ValueChanged<int> onUnreadChanged,
    required ValueChanged<List<String>> onConversationDeleted,
  }) async {
    await ensureReady();
    final listener = V2TimConversationListener(
      onNewConversation: onConversationUpdated,
      onConversationChanged: onConversationUpdated,
      onTotalUnreadMessageCountChanged: onUnreadChanged,
      onConversationDeleted: onConversationDeleted,
    );
    await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .addConversationListener(listener: listener);
    return listener;
  }

  Future<void> removeConversationListener(
    V2TimConversationListener listener,
  ) async {
    await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .removeConversationListener(listener: listener);
  }

  Future<List<V2TimMessage>> fetchC2CHistory(String targetUID) async {
    await ensureReady();
    final response = await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .getC2CHistoryMessageList(userID: targetUID, count: 20);
    _throwIfFailed(response.code, response.desc);
    await markC2CRead(targetUID);
    return _sortMessages(response.data ?? const []);
  }

  Future<V2TimMessage> sendTextMessage({
    required String targetUID,
    required String text,
  }) async {
    await ensureReady();
    final messageManager = TencentImSDKPlugin.v2TIMManager.getMessageManager();
    final createResponse = await messageManager.createTextMessage(text: text);
    _throwIfFailed(createResponse.code, createResponse.desc);

    final created = createResponse.data;
    if (created?.messageInfo == null) {
      throw const NadyApiException(message: 'Failed to create IM message');
    }

    final currentUser = await _authSession.user();
    final pushTitle = currentUser?.nick?.trim().isNotEmpty == true
        ? currentUser!.nick!
        : 'Message';
    final currentUid = await _authSession.uid();

    final sendResponse = await messageManager.sendMessage(
      message: created!.messageInfo,
      receiver: targetUID,
      groupID: '',
      offlinePushInfo: OfflinePushInfo(
        title: pushTitle,
        desc: text,
        ignoreIOSBadge: true,
        ext: jsonEncode({
          'jumpUrl':
              'nady:///main/p2p-chat?target-u-i-d=$currentUid'
              '&is-on-room=false',
        }),
      ),
    );
    _throwIfFailed(sendResponse.code, sendResponse.desc);
    return sendResponse.data ?? created.messageInfo!;
  }

  Future<V2TimAdvancedMsgListener> addC2CMessageListener({
    required String targetUID,
    required ValueChanged<V2TimMessage> onMessageReceived,
  }) async {
    await ensureReady();
    final listener = V2TimAdvancedMsgListener(
      onRecvNewMessage: (message) {
        if (message.userID == targetUID || message.sender == targetUID) {
          onMessageReceived(message);
          unawaited(markC2CRead(targetUID));
        }
      },
      onRecvMessageModified: (message) {
        if (message.userID == targetUID || message.sender == targetUID) {
          onMessageReceived(message);
        }
      },
    );
    await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .addAdvancedMsgListener(listener: listener);
    await markC2CRead(targetUID);
    return listener;
  }

  Future<void> removeC2CMessageListener(
    V2TimAdvancedMsgListener listener,
  ) async {
    await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .removeAdvancedMsgListener(listener: listener);
  }

  Future<void> markC2CRead(String targetUID) async {
    final response = await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .cleanConversationUnreadMessageCount(
          conversationID: 'c2c_$targetUID',
          cleanTimestamp: 0,
          cleanSequence: 0,
        );
    if (response.code != 0) {
      debugPrint('markC2CMessageAsRead failed: ${response.desc}');
    }
  }

  Future<void> _login() async {
    final uid = await _authSession.uid();
    if (uid == null) {
      throw const NadyApiException(message: 'Please log in first');
    }

    final token = await _fetchTimToken();
    if (token.appId <= 0 || token.token.isEmpty) {
      throw const NadyApiException(message: 'Invalid IM token');
    }

    final sdkListener = V2TimSDKListener(
      onKickedOffline: () {
        _loggedIn = false;
        debugPrint('Tencent IM kicked offline');
      },
      onUserSigExpired: () {
        _loggedIn = false;
        debugPrint('Tencent IM userSig expired');
      },
      onConnectFailed: (code, error) {
        debugPrint('Tencent IM connect failed: $code $error');
      },
      onConnecting: () {
        debugPrint('Tencent IM connecting');
      },
      onConnectSuccess: () {
        debugPrint('Tencent IM connected');
      },
    );

    final initResponse = await TencentImSDKPlugin.v2TIMManager.initSDK(
      sdkAppID: token.appId,
      loglevel: kReleaseMode
          ? LogLevelEnum.V2TIM_LOG_WARN
          : LogLevelEnum.V2TIM_LOG_DEBUG,
      listener: sdkListener,
    );
    _throwIfFailed(initResponse.code, initResponse.desc);

    final loginResponse = await TencentImSDKPlugin.v2TIMManager.login(
      userID: uid.toString(),
      userSig: token.token,
    );
    _throwIfFailed(loginResponse.code, loginResponse.desc);
    _loggedIn = true;
  }

  Future<TimTokenData> _fetchTimToken() async {
    final response = await _httpManager.get(HttpApi.timToken);
    final server = NadyServerResponse<TimTokenData>.fromJson(
      _asMap(response),
      (json) => TimTokenData.fromJson((json as Map).cast<String, dynamic>()),
    );
    if (!server.isSuccess) throw server.toException();
    final token = server.data;
    if (token == null) {
      throw const NadyApiException(message: 'Empty IM token');
    }
    return token;
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }

  void _throwIfFailed(int code, String desc) {
    if (code != 0) {
      throw NadyApiException(
        message: desc.isEmpty ? 'IM request failed' : desc,
      );
    }
  }

  bool _isC2CConversation(V2TimConversation conversation) {
    return conversation.type == ConversationType.V2TIM_C2C &&
        conversation.userID != null &&
        conversation.userID!.isNotEmpty;
  }

  List<V2TimConversation> _sortConversations(
    Iterable<V2TimConversation> conversations,
  ) {
    final list = conversations.toList();
    list.sort((a, b) {
      if ((a.isPinned ?? false) != (b.isPinned ?? false)) {
        return (b.isPinned ?? false) ? 1 : -1;
      }
      final aTime = a.lastMessage?.timestamp ?? a.orderkey ?? 0;
      final bTime = b.lastMessage?.timestamp ?? b.orderkey ?? 0;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  List<V2TimMessage> _sortMessages(Iterable<V2TimMessage> messages) {
    final list = messages.toList();
    list.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
    return list;
  }
}
