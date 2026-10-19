import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../manager/app_socket_manager.dart';
import '../../manager/auth_session.dart';
import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../manager/room_agora_manager.dart';
import '../../manager/room_manager.dart';
import '../../model/room_models.dart';
import '../../model/room_socket_message.dart';
import '../../model/server_response.dart';
import '../../model/user_profile.dart';
import 'gift/models/room_gift_models.dart';

final roomRepositoryProvider = Provider<RoomRepository>(
  (ref) => RoomRepository(),
);

class RoomRepository {
  RoomRepository({
    RoomManager? roomManager,
    AppSocketManager? socketManager,
    RoomAgoraManager? agoraManager,
    HttpDioManager? httpManager,
    AuthSession? authSession,
  }) : _roomManager = roomManager ?? RoomManager.instance,
       _socketManager = socketManager ?? AppSocketManager.instance,
       _agoraManager = agoraManager ?? RoomAgoraManager.instance,
       _httpManager = httpManager ?? HttpDioManager(),
       _authSession = authSession ?? AuthSession.instance;

  final RoomManager _roomManager;
  final AppSocketManager _socketManager;
  final RoomAgoraManager _agoraManager;
  final HttpDioManager _httpManager;
  final AuthSession _authSession;

  RoomState get roomState => _roomManager.state;
  int get roomGeneration => _roomManager.sessionGeneration;
  AppSocketState get socketState => _roomManager.socketState;
  RoomAgoraState get agoraState => _roomManager.agoraState;
  Stream<RoomSocketMessage> get socketMessages => _socketManager.messages;
  Future<void> acquireGame(String consumer, int uid) =>
      _socketManager.acquireRoomGame(consumer, uid);
  Future<void> releaseGame(String consumer) =>
      _socketManager.releaseRoomGame(consumer);
  Future<void> subscribeTools(int uid) =>
      _socketManager.subscribeRoomTools(uid);

  RoomGiftAudience giftAudience(String roomId) => RoomGiftAudience(
    isInRoom: roomState.isInRoom && roomState.currentRoomId == roomId,
    onlineCount: roomState.onlineCount,
    recipients: [
      for (final mic in roomState.micList)
        if ((mic.uid ?? 0) > 0)
          RoomGiftRecipient(
            uid: mic.uid!,
            seatPosition: mic.position,
            nickname:
                '${mic.userInfo?['nick'] ?? mic.userInfo?['nickname'] ?? ''}',
            avatar: mic.userInfo?['avatar']?.toString(),
          ),
    ],
  );

  void addListener(VoidCallback listener) {
    _roomManager.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    _roomManager.removeListener(listener);
  }

  Future<int?> currentUid() {
    return _authSession.uid();
  }

  Future<bool> isLoggedIn() => _authSession.isLoggedIn();

  void addAuthListener(VoidCallback listener) =>
      _authSession.addListener(listener);

  void removeAuthListener(VoidCallback listener) =>
      _authSession.removeListener(listener);

  Future<UserData?> currentUser() {
    return _authSession.user();
  }

  Future<void> enterRoom({
    required String roomId,
    String roomPassword = '',
    int followUid = 0,
  }) {
    return _roomManager.enterRoom(
      roomId: roomId,
      roomPassword: roomPassword,
      followUid: followUid,
    );
  }

  Future<void> leaveRoom() {
    return _roomManager.leaveRoom();
  }

  void minimizeRoom() {
    _roomManager.minimizeRoom();
  }

  void restoreRoom() {
    _roomManager.restoreRoom();
  }

  Future<void> exitMinimizedRoom() {
    return _roomManager.exitMinimizedRoom();
  }

  Future<void> refreshRoomData() {
    return _roomManager.refreshRoomData();
  }

  Future<void> followRoom() {
    return _roomManager.followRoom();
  }

  Future<void> refreshAudience() {
    return _roomManager.refreshAudience();
  }

  Future<RoomMicOperateResp> upMic(int position) {
    return _roomManager.upMic(position);
  }

  Future<RoomMicOperateResp> downMic(int position) {
    return _roomManager.downMic(position);
  }

  Future<RoomMicOperateResp> kickDownMic({
    required int position,
    required int targetUid,
  }) {
    return _roomManager.kickDownMic(position: position, targetUid: targetUid);
  }

  Future<RoomMicOperateResp> muteMicSeat({
    required int position,
    required bool mute,
  }) {
    return _roomManager.muteMicSeat(position: position, mute: mute);
  }

  Future<RoomMicOperateResp> lockMicSeat({
    required int position,
    required bool isLock,
  }) {
    return _roomManager.lockMicSeat(position: position, isLock: isLock);
  }

  Future<void> muteLocalMicrophone(bool mute) {
    return _roomManager.muteLocalMicrophone(mute);
  }

  Future<void> muteSpeaker(bool mute) {
    return _agoraManager.muteSpeaker(mute);
  }

  Future<void> playMusic({
    required String roomId,
    required String path,
    required String title,
    bool force = false,
  }) => _roomManager.playMusic(
    roomId: roomId,
    path: path,
    title: title,
    force: force,
  );
  Future<void> pauseMusic(String roomId) => _roomManager.pauseMusic(roomId);
  Future<void> resumeMusic(String roomId) => _roomManager.resumeMusic(roomId);
  Future<void> stopMusic() => _roomManager.stopMusic();
  Future<void> seekMusic(String roomId, int position) =>
      _roomManager.seekMusic(roomId, position);
  Future<void> setMusicVolume(String roomId, int volume) =>
      _roomManager.setMusicVolume(roomId, volume);

  Future<int?> sendTextMessage({required String roomId, required String text}) {
    return sendRoomMessage(
      event: 'RoomScreenMessageEvent',
      roomId: roomId,
      data: text,
    );
  }

  Future<void> clearMessages(String roomId) async {
    final response = await _httpManager.post(
      HttpApi.roomChatClean,
      data: {'roomId': roomId},
    );
    final server = NadyServerResponse<void>.fromJson(_asMap(response), null);
    if (!server.isSuccess) throw server.toException();
  }

  Future<int?> sendRoomMessage({
    required String event,
    required String roomId,
    required String data,
  }) async {
    final response = await _httpManager.post(
      HttpApi.roomMsgPush,
      data: {'event': event, 'roomId': roomId, 'data': data},
    );
    final server = NadyServerResponse<int?>.fromJson(
      _asMap(response),
      _nullableIntFromJson,
    );
    if (!server.isSuccess) throw server.toException();
    return server.data;
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }

  int? _nullableIntFromJson(Object? json) {
    if (json is int) return json;
    if (json is num) return json.toInt();
    return int.tryParse(json?.toString() ?? '');
  }
}
