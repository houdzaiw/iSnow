import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/manager/app_socket_manager.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/user_profile.dart';

class ToolsRoomFake extends ChangeNotifier implements RoomRepository {
  ToolsRoomFake() {
    setRole(UserRoomIdentity.owner);
  }
  RoomState current = const RoomState(
    status: RoomStatus.ready,
    currentRoomId: '123',
    isInRoom: true,
  );
  int generation = 1;
  bool speaker = false;
  Map<int, int> volumes = {};
  int leaves = 0, subscriptions = 0;
  final events = StreamController<RoomSocketMessage>.broadcast(sync: true);
  @override
  RoomState get roomState => current;
  @override
  int get roomGeneration => generation;
  @override
  AppSocketState get socketState =>
      const AppSocketState(status: AppSocketStatus.ready);
  @override
  RoomAgoraState get agoraState =>
      RoomAgoraState(mutedSpeaker: speaker, volumeLevels: volumes);
  @override
  Stream<RoomSocketMessage> get socketMessages => events.stream;
  @override
  Future<int?> currentUid() async => 10;
  @override
  Future<UserData?> currentUser() async =>
      const UserData(uid: 10, userNo: 987, nick: 'Tester');
  @override
  Future<void> subscribeTools(int uid) async {
    subscriptions++;
  }

  @override
  RoomGiftAudience giftAudience(String roomId) => RoomGiftAudience(
    isInRoom: current.isInRoom && current.currentRoomId == roomId,
    onlineCount: 1,
    recipients: const [],
  );
  void emitState() => notifyListeners();
  @override
  Future<void> refreshRoomData() async {}

  @override
  Future<void> muteSpeaker(bool mute) async {
    speaker = mute;
  }

  @override
  Future<void> leaveRoom() async {
    leaves++;
    current = const RoomState();
    generation++;
    notifyListeners();
  }

  @override
  void minimizeRoom() {
    current = current.copyWith(isMinimized: true);
    notifyListeners();
  }

  @override
  void restoreRoom() {
    current = current.copyWith(isMinimized: false);
    notifyListeners();
  }

  void setRole(UserRoomIdentity identity) {
    current = current.copyWith(
      enterResponse: EnterRoomResp(
        roomId: '123',
        identity: identity,
        raw: const {'digitalCurrency': 1},
      ),
    );
    notifyListeners();
  }

  void event(
    String event,
    Object? payload, {
    String id = 'message',
    String channel = 'room:123',
  }) => events.add(
    RoomSocketMessage(
      channel: channel,
      event: event,
      payload: payload,
      msgId: id,
      raw: const {},
    ),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  void dispose() {
    events.close();
    super.dispose();
  }
}

class ToolsApiFake extends RoomToolsRepository {
  final calls = <({String method, String path, ToolJson body})>[];
  final responses = <String, Object?>{
    HttpApi.roomFunctions: [
      {
        'type': 1,
        'list': [
          {'position': 7},
        ],
      },
      {
        'type': 2,
        'list': [
          {'position': 7},
        ],
      },
    ],
    HttpApi.roomCharmEnabled: true,
    HttpApi.userHomepage: {
      'info': {
        'userBaseInfo': {
          'uid': 20,
          'userLevel': {'vipLevel': 0},
        },
      },
    },
    HttpApi.roomPkInfo: {'eventType': 0},
    HttpApi.roomLobbyRecords: <Object>[],
    HttpApi.roomTreasureRecords: {'giftIocs': [], 'playTos': []},
    HttpApi.roomLuckyList: <Object>[],
    HttpApi.walletPurse: {'coin': 1000},
    HttpApi.roomLuckyConfig: {
      'visible': false,
      'room': {
        'configuration': [
          {
            'goldQuantiry': 100,
            'numberOfRecipients': [1, 5],
          },
        ],
        'countdown': [0, 30],
      },
      'world': {
        'configuration': [
          {
            'goldQuantiry': 200,
            'numberOfRecipients': [2],
          },
        ],
        'countdown': [60],
      },
    },
  };
  String? failingPath, heldPath;
  Completer<Object?>? gate;
  bool confirmation = false;
  RoomEffectPreferences stored = const RoomEffectPreferences();
  @override
  Future<Object?> get(String path, [ToolJson? query]) async {
    calls.add((method: 'GET', path: path, body: query ?? {}));
    if (path == failingPath) throw StateError('Server failed');
    if (path == heldPath) return gate!.future;
    return responses[path];
  }

  @override
  Future<Object?> post(String path, ToolJson body) async {
    calls.add((method: 'POST', path: path, body: body));
    if (path == failingPath) throw StateError('Server failed');
    if (path == heldPath) return gate!.future;
    return responses[path];
  }

  @override
  Future<RoomEffectPreferences> effects(int uid) async => stored;
  @override
  Future<void> saveEffects(int uid, RoomEffectPreferences effects) async {
    stored = effects;
  }

  @override
  Future<bool> speakerMuted(int uid, String roomId) async => false;
  @override
  Future<void> saveSpeaker(int uid, String roomId, bool muted) async {}
  @override
  Future<bool> luckyConfirmed(int uid) async => confirmation;
  @override
  Future<void> confirmLucky(int uid) async {
    confirmation = true;
  }

  int count(String path) => calls.where((call) => call.path == path).length;
}

Future<void> flushTools() async {
  for (var count = 0; count < 12; count++) {
    await Future<void>.delayed(Duration.zero);
  }
}
