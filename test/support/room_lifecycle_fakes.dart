import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project/manager/app_socket_manager.dart';
import 'package:project/manager/auth_session.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_background_audio_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/room_music_state.dart';
import 'package:project/model/user_profile.dart';

class RoomLifecycleFixture {
  RoomLifecycleFixture({RoomBackgroundAudioManager? backgroundAudio}) {
    http = FakeRoomHttp(actions, auth);
    socket = FakeRoomSocket(actions);
    agora = FakeRoomAgora(actions);
    manager = RoomManager.forTesting(
      httpManager: http,
      socketManager: socket,
      agoraManager: agora,
      authSession: auth,
      backgroundAudioManager: backgroundAudio,
    );
  }
  final actions = <String>[];
  final auth = FakeRoomAuth();
  late final FakeRoomHttp http;
  late final FakeRoomSocket socket;
  late final FakeRoomAgora agora;
  late final RoomManager manager;

  Future<void> enter([String roomId = 'first']) async {
    await manager.enterRoom(roomId: roomId, agoraAppId: 'test-app');
    await flush();
  }

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  Future<void> dispose() async {
    await manager.leaveRoom();
    manager.dispose();
    await socket.controller.close();
    socket.dispose();
    agora.dispose();
    auth.dispose();
  }
}

class FakeRoomAuth extends ChangeNotifier implements AuthSession {
  bool loggedIn = true;
  int currentUid = 10;
  @override
  Future<int?> uid() async => loggedIn ? currentUid : null;
  @override
  Future<UserData?> user() async => null;
  @override
  Future<String?> token() async => loggedIn ? 'test-token' : null;
  @override
  Future<bool> isLoggedIn() async => loggedIn;
  @override
  Future<void> clear() async {
    loggedIn = false;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoomHttp implements HttpDioManager {
  FakeRoomHttp(this.actions, this.auth);
  final List<String> actions;
  final FakeRoomAuth auth;
  bool failExit = false;
  bool failLogout = false;
  Completer<void>? enterGate;
  Completer<void>? exitGate;
  Completer<void>? infoGate;
  Completer<void>? followGate;
  Completer<void>? clearMessagesGate;
  final clearMessagesRequests = <Map<String, dynamic>>[];
  Map<String, dynamic> clearMessagesResponse = const {'code': 200};
  String? roomIdentity;
  bool? roomIsFollowed;
  int? roomOwnerUid;
  int infoCalls = 0;
  final followRequests = <Map<String, dynamic>>[];
  Map<String, dynamic> followResponse = const {'code': 200, 'msg': 'success'};
  Completer<void>? audienceGate;
  List<Map<String, dynamic>> audience = [];
  bool failAudience = false;
  final audienceRequests = <Map<String, dynamic>>[];
  String? canonicalRoomId;

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == HttpApi.roomChatClean) {
      clearMessagesRequests.add(Map<String, dynamic>.from(data as Map));
      final response = clearMessagesResponse;
      await clearMessagesGate?.future;
      return response;
    }
    if (path == HttpApi.roomFollow) {
      followRequests.add(Map<String, dynamic>.from(data as Map));
      final response = followResponse;
      await followGate?.future;
      return response;
    }
    if (path == HttpApi.roomEnter) {
      actions.add('enter:${data['roomId']}');
      await enterGate?.future;
      return {
        'code': 200,
        'data': {
          'roomId': canonicalRoomId ?? data['roomId'],
          'agoraToken': 'agora-token',
          if (roomIdentity != null) 'identity': roomIdentity,
        },
      };
    }
    if (path == HttpApi.roomExit) {
      actions.add('exit:${data['roomId']}:${await auth.token()}');
      await exitGate?.future;
      if (failExit) throw StateError('HTTP exit failed');
    } else if (path == HttpApi.logout || path == HttpApi.logoff) {
      actions.add('logout:${await auth.token()}');
      if (failLogout) return {'code': 1003, 'message': 'Server error'};
    } else {
      throw StateError('Unexpected POST $path');
    }
    return {'code': 200};
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == HttpApi.roomAudienceList) {
      audienceRequests.add(Map<String, dynamic>.from(queryParameters!));
      final users = List<Map<String, dynamic>>.of(audience);
      final fail = failAudience;
      await audienceGate?.future;
      if (fail) return {'code': 1003, 'message': 'Audience unavailable'};
      return {'code': 200, 'data': users};
    }
    if (path == HttpApi.roomInfo) {
      infoCalls++;
      final roomInfo = {
        'roomId': queryParameters!['roomId'],
        'title': 'Test room',
        if (roomIsFollowed != null) 'isFollow': roomIsFollowed,
        if (roomOwnerUid != null) 'roomUid': roomOwnerUid,
      };
      await infoGate?.future;
      return {'code': 200, 'data': roomInfo};
    }
    if (path == HttpApi.roomMicListInfo) {
      return {
        'code': 200,
        'data': [
          {'position': 0, 'uid': 10},
        ],
      };
    }
    if (path == HttpApi.agoraToken) return {'code': 200, 'data': 'token'};
    throw StateError('Unexpected GET $path');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoomSocket extends ChangeNotifier implements AppSocketManager {
  @override
  Future<void> subscribeRoomTools(int uid) async {}
  FakeRoomSocket(this.actions);
  final List<String> actions;
  final controller = StreamController<RoomSocketMessage>.broadcast(sync: true);
  AppSocketState value = const AppSocketState();
  bool failLeave = false;
  bool failDisconnect = false;
  Completer<void>? joinGate;

  @override
  AppSocketState get state => value;
  @override
  Stream<RoomSocketMessage> get messages => controller.stream;
  @override
  Future<void> subscribeRoomMusicControl(int uid) async {
    actions.add('music-control:$uid');
  }

  @override
  Future<void> joinRoom(String roomId, {String? url}) async {
    actions.add('socket-join:$roomId');
    await joinGate?.future;
    setState(
      AppSocketState(
        status: AppSocketStatus.ready,
        roomId: roomId,
        roomChannelSubscribed: true,
      ),
    );
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    actions.add('socket-leave:$roomId');
    if (failLeave) throw StateError('unsubscribe failed');
    setState(const AppSocketState(status: AppSocketStatus.connected));
  }

  @override
  Future<void> disconnect() async {
    actions.add('socket-disconnect');
    setState(const AppSocketState(status: AppSocketStatus.disconnected));
    if (failDisconnect) throw StateError('disconnect failed');
  }

  void setState(AppSocketState next) {
    value = next;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoomAgora extends ChangeNotifier implements RoomAgoraManager {
  FakeRoomAgora(this.actions);
  final List<String> actions;
  RoomAgoraState value = const RoomAgoraState();
  bool failLeave = false;
  Completer<void>? joinGate;
  @override
  RoomAgoraState get state => value;
  @override
  Future<void> stopMusic() async {
    if (value.music.path == null) return;
    actions.add('music-stop');
    setState(value.copyWith(music: const RoomMusicPlaybackState()));
  }

  @override
  Future<void> joinRoom({
    required String roomId,
    required String token,
    required int uid,
    required String appId,
  }) async {
    actions.add('agora-join:$roomId');
    await joinGate?.future;
    setState(RoomAgoraState(initialized: true, joined: true, roomId: roomId));
  }

  @override
  Future<void> leaveRoom() async {
    actions.add('agora-leave');
    setState(const RoomAgoraState(initialized: true));
    if (failLeave) throw StateError('Agora leave failed');
  }

  void setState(RoomAgoraState next) {
    value = next;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
