import 'dart:async';
import 'dart:ui';

import 'package:project/classes/message/im_repository.dart';
import 'package:project/classes/room/more/room_tools_config.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_share_manager.dart';
import 'package:project/model/room_share_models.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';

import 'room_tools_fakes.dart';
import 'im_fakes.dart';
import 'package:project/manager/im_session_manager.dart';
import 'package:project/model/tim_token_data.dart';

class ShareConfigFake extends RoomToolsConfig {
  String base = 'https://share.example/simi';
  String? invite;
  bool allowHttp = false;
  String scheme = '';
  @override
  String get apiBase => base;
  @override
  String get inviteBase => invite ?? '${Uri.parse(base).origin}/h5/invite';
  @override
  bool get allowHttpShare => allowHttp;
  @override
  String get shareScheme => scheme;
}

class ShareImFake implements ImRepository {
  @override
  late final session = ImSessionManager(
    sdk: ImSdkFake(),
    auth: ImAuthFake(),
    loadToken: () async => const TimTokenData(appId: 123, token: 'test'),
  );
  @override
  Future<void> ensureReady() async {}
  List<V2TimConversation> conversations = [
    V2TimConversation(
      conversationID: 'c2c_20',
      type: 1,
      userID: '20',
      showName: 'Friend',
    ),
  ];
  final sent = <({String uid, Map<String, dynamic> card})>[];
  Object? failure;
  Completer<List<V2TimConversation>>? gate;
  @override
  Future<List<V2TimConversation>> fetchConversations() async =>
      gate == null ? conversations : gate!.future;
  @override
  Future<void> sendRoomInvitation({
    required String targetUID,
    required Map<String, dynamic> room,
  }) async {
    if (failure != null) throw failure!;
    sent.add((uid: targetUID, card: room));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SharePlatformFake extends RoomShareManager {
  final copied = <String>[];
  final shares = <({String text, Rect origin})>[];
  final opened = <({RoomShareAction action, RoomShareContent content})>[];
  bool opens = true;
  Completer<void>? copyGate;
  Completer<bool>? openGate;
  RoomShareOutcome outcome = RoomShareOutcome.shared;
  Object? failure;
  Completer<RoomShareOutcome>? gate;
  @override
  Future<void> copyText(String text) async {
    if (failure != null) throw failure!;
    copied.add(text);
    await copyGate?.future;
  }

  @override
  Future<bool> openChannel(
    RoomShareAction action,
    RoomShareContent content,
  ) async {
    opened.add((action: action, content: content));
    return openGate == null ? opens : openGate!.future;
  }

  @override
  Future<RoomShareOutcome> shareText({
    required String text,
    required Rect origin,
  }) async {
    if (failure != null) throw failure!;
    shares.add((text: text, origin: origin));
    return gate == null ? outcome : gate!.future;
  }
}

ToolsApiFake shareApiFake() => ToolsApiFake()
  ..responses.addAll({
    HttpApi.roomShareMaterials: [shareMaterialJson(1), shareMaterialJson(2)],
    HttpApi.roomInviteInfo: {'inviteCode': 'INVITE'},
    HttpApi.userFriends: [
      {
        'userBaseInfo': {'uid': 20, 'nick': 'Friend'},
      },
    ],
    HttpApi.roomShareShortLinks: [
      {'shortUrl': 'https://share.example/s/abc'},
    ],
    HttpApi.roomShareReport: true,
  });

Map<String, dynamic> shareMaterialJson(int id) => {
  'id': id,
  'sortNo': id,
  'copyText': 'Join \${nickname} $id',
  'imageUrl': '',
  'jumpLink':
      r'nady://voice-room?roomId=${shareRoomId}&uid=${shareUid}&code=${inviteCode}',
};
