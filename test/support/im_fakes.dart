import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/manager/v2_tim_manager.dart';
import 'package:tencent_cloud_chat_sdk/manager/v2_tim_conversation_manager.dart';
import 'package:tencent_cloud_chat_sdk/manager/v2_tim_message_manager.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_text_elem.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_msg_create_info_result.dart';

import 'package:project/manager/auth_session.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/user_profile.dart';

V2TimValueCallback<T> imOk<T>(T value) =>
    V2TimValueCallback(code: 0, desc: 'ok', data: value);
V2TimCallback imAck() => V2TimCallback(code: 0, desc: 'ok');
V2TimMessage imText(
  String id, {
  String uid = '20',
  bool self = false,
  int time = 1700000000,
}) =>
    V2TimMessage.fromJson({
        'message_msg_id': id,
        'message_conv_type': 1,
        'message_conv_id': uid,
        'message_sender': uid,
        'message_client_time': time,
        'message_is_from_self': self,
        'elem_type': 1,
        'message_risk_type_identified': 0,
      })
      ..textElem = V2TimTextElem(text: 'Message $id')
      ..elemType = 1;
V2TimConversation imConversation(
  String uid, {
  int unread = 0,
  bool pinned = false,
  String? name,
  int time = 1700000000,
}) => V2TimConversation(
  conversationID: 'c2c_$uid',
  type: 1,
  userID: uid,
  showName: name ?? 'Friend $uid',
  unreadCount: unread,
  isPinned: pinned,
  lastMessage: imText('last-$uid', uid: uid, time: time),
);

class ImAuthFake extends ChangeNotifier implements AuthSession {
  int? currentUid = 10;
  @override
  Future<int?> uid() async => currentUid;
  @override
  Future<UserData?> user() async =>
      UserData(uid: currentUid, nick: 'Test user');
  void change(int? uid) {
    currentUid = uid;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ImHttpAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool audit = true, noDisturb = false;
  int vip = 0;
  String relation = 'FOLLOW_NONE';
  Map<String, dynamic>? auditError;
  Completer<void>? auditGate, tokenGate;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    Object? data;
    switch (options.path) {
      case HttpApi.timToken:
        await tokenGate?.future;
        data = {'appID': 123, 'token': 'fake-im-secret'};
      case HttpApi.userHomepage:
        data = {
          'info': {
            'userBaseInfo': {
              'uid': 20,
              'followRelation': relation,
              'userLevel': {'vipLevel': vip},
            },
          },
        };
      case HttpApi.userVipSetting:
        data = {
          'noDisturb': {'open': noDisturb},
        };
      case HttpApi.imTextAudit:
        await auditGate?.future;
        if (auditError != null) return _body(auditError!);
        data = audit;
      default:
        throw StateError('Unexpected HTTP request ${options.path}');
    }
    return _body({'code': 200, 'data': data});
  }

  ResponseBody _body(Map<String, dynamic> body) => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}

class ImSdkFake implements V2TIMManager {
  final conversations = ImConversationsFake();
  final messages = ImMessagesFake();
  final logins = <String>[];
  int inits = 0, logouts = 0;
  V2TimSDKListener? listener;
  Completer<void>? loginGate;
  @override
  V2TIMConversationManager getConversationManager() => conversations;
  @override
  V2TIMMessageManager getMessageManager() => messages;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #initSDK:
        listener = invocation.namedArguments[#listener] as V2TimSDKListener;
        inits++;
        return Future.value(imOk(true));
      case #login:
        logins.add(invocation.namedArguments[#userID] as String);
        return () async {
          await loginGate?.future;
          return imAck();
        }();
      case #logout:
        logouts++;
        return Future.value(imAck());
      case #unInitSDK:
        return Future.value(imAck());
    }
    throw StateError('Unexpected SDK call ${invocation.memberName}');
  }
}

class ImConversationsFake implements V2TIMConversationManager {
  List<V2TimConversation> rows = [
    imConversation('20', unread: 2),
    imConversation('10000'),
  ];
  final listeners = <V2TimConversationListener>[];
  final reads = <String>[];
  final deleted = <String>[];
  int fetches = 0;
  bool failDelete = false;
  Completer<List<V2TimConversation>>? fetchGate;
  Completer<void>? listenGate;
  void emit(List<V2TimConversation> incoming) {
    rows = {
      for (final c in rows) c.conversationID: c,
      for (final c in incoming) c.conversationID: c,
    }.values.toList();
    for (final l in [...listeners]) {
      l.onConversationChanged(incoming);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final args = invocation.namedArguments;
    switch (invocation.memberName) {
      case #getConversationList:
        fetches++;
        return (() async => imOk(
          V2TimConversationResult(
            nextSeq: '0',
            isFinished: true,
            conversationList: await (fetchGate?.future ?? Future.value(rows)),
          ),
        ))();
      case #getTotalUnreadMessageCount:
        return Future.value(
          imOk(rows.fold<int>(0, (s, c) => s + (c.unreadCount ?? 0))),
        );
      case #addConversationListener:
        final listener = args[#listener] as V2TimConversationListener;
        listeners.add(listener);
        return () async {
          await listenGate?.future;
        }();
      case #removeConversationListener:
        listeners.remove(args[#listener]);
        return Future<void>.value();
      case #cleanConversationUnreadMessageCount:
        final id = args[#conversationID] as String;
        reads.add(id);
        final row = rows.where((c) => c.conversationID == id).firstOrNull;
        if (row != null) {
          row.unreadCount = 0;
          emit([row]);
        }
        return Future.value(imAck());
      case #deleteConversation:
        final id = args[#conversationID] as String;
        if (failDelete) {
          return Future.value(V2TimCallback(code: 1, desc: 'Delete rejected'));
        }
        deleted.add(id);
        rows.removeWhere((c) => c.conversationID == id);
        return Future.value(imAck());
    }
    throw StateError('Unexpected conversation call ${invocation.memberName}');
  }
}

class ImMessagesFake implements V2TIMMessageManager {
  final listeners = <V2TimAdvancedMsgListener>[];
  final sent = <V2TimMessage>[];
  final cursors = <String?>[];
  List<V2TimMessage> history = [imText('old')];
  List<V2TimMessage> older = [];
  Completer<List<V2TimMessage>>? historyGate;
  Completer<void>? listenerGate;
  int creates = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final args = invocation.namedArguments;
    switch (invocation.memberName) {
      case #getC2CHistoryMessageList:
        final cursor = args[#lastMsgID] as String?;
        cursors.add(cursor);
        return (() async => imOk(
          await (historyGate?.future ??
              Future.value(cursor == null ? history : older)),
        ))();
      case #addAdvancedMsgListener:
        listeners.add(args[#listener] as V2TimAdvancedMsgListener);
        return () async {
          await listenerGate?.future;
        }();
      case #removeAdvancedMsgListener:
        listeners.remove(args[#listener]);
        return Future<void>.value();
      case #createTextMessage:
        creates++;
        final message = imText('sent-$creates', self: true, time: 1800000000);
        message.textElem!.text = args[#text] as String;
        return Future.value(
          imOk(V2TimMsgCreateInfoResult(messageInfo: message)),
        );
      case #sendMessage:
        final message = args[#message] as V2TimMessage;
        sent.add(message);
        return Future.value(imOk(message));
    }
    throw StateError('Unexpected message call ${invocation.memberName}');
  }
}
