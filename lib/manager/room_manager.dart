import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../configs/app_configs.dart';
import '../configs/app_device.dart';
import '../model/room_models.dart';
import '../model/room_socket_message.dart';
import '../model/server_response.dart';
import 'app_socket_manager.dart';
import 'auth_session.dart';
import 'http_api.dart';
import 'http_dio_manager.dart';
import 'room_agora_manager.dart';

enum RoomStatus { idle, entering, ready, leaving, error }

class RoomState {
  const RoomState({
    this.status = RoomStatus.idle,
    this.currentRoomId,
    this.isInRoom = false,
    this.isMinimized = false,
    this.enterResponse,
    this.roomInfo,
    this.micList = const [],
    this.errorMessage,
  });

  final RoomStatus status;
  final String? currentRoomId;
  final bool isInRoom;
  final bool isMinimized;
  final EnterRoomResp? enterResponse;
  final RoomInfo? roomInfo;
  final List<RoomMicModel> micList;
  final String? errorMessage;

  bool get isLoading =>
      status == RoomStatus.entering || status == RoomStatus.leaving;

  RoomState copyWith({
    RoomStatus? status,
    String? currentRoomId,
    bool? clearCurrentRoomId,
    bool? isInRoom,
    bool? isMinimized,
    EnterRoomResp? enterResponse,
    bool? clearEnterResponse,
    RoomInfo? roomInfo,
    bool? clearRoomInfo,
    List<RoomMicModel>? micList,
    Object? errorMessage = _sentinel,
  }) {
    return RoomState(
      status: status ?? this.status,
      currentRoomId: clearCurrentRoomId == true
          ? null
          : currentRoomId ?? this.currentRoomId,
      isInRoom: isInRoom ?? this.isInRoom,
      isMinimized: isMinimized ?? this.isMinimized,
      enterResponse: clearEnterResponse == true
          ? null
          : enterResponse ?? this.enterResponse,
      roomInfo: clearRoomInfo == true ? null : roomInfo ?? this.roomInfo,
      micList: micList ?? this.micList,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class RoomManager extends ChangeNotifier {
  RoomManager._() {
    _dependencyListener = notifyListeners;
    _socketMessages = _socketManager.messages.listen(_handleSocketMessage);
    _socketManager.addListener(_dependencyListener);
    _agoraManager.addListener(_dependencyListener);
  }

  static final RoomManager instance = RoomManager._();

  final _RoomApiClient _api = _RoomApiClient();
  final AppSocketManager _socketManager = AppSocketManager.instance;
  final RoomAgoraManager _agoraManager = RoomAgoraManager.instance;
  final AuthSession _authSession = AuthSession.instance;

  late final VoidCallback _dependencyListener;
  late final StreamSubscription<RoomSocketMessage> _socketMessages;
  RoomState _state = const RoomState();

  RoomState get state => _state;
  AppSocketState get socketState => _socketManager.state;
  RoomAgoraState get agoraState => _agoraManager.state;

  String get currentRoomId => _state.currentRoomId ?? '';
  bool get isInRoom => _state.isInRoom;
  bool get isMinimized => _state.isMinimized;

  Future<void> tryEnterRoom({
    required String roomId,
    String roomPassword = '',
    int followUid = 0,
    String? socketUrl,
    String? agoraAppId,
  }) {
    return enterRoom(
      roomId: roomId,
      roomPassword: roomPassword,
      followUid: followUid,
      socketUrl: socketUrl,
      agoraAppId: agoraAppId,
    );
  }

  Future<void> enterRoom({
    required String roomId,
    String roomPassword = '',
    int followUid = 0,
    String? socketUrl,
    String? agoraAppId,
  }) async {
    if (_state.isInRoom && _state.currentRoomId == roomId) {
      restoreRoom();
      return;
    }
    if (_state.isInRoom && _state.currentRoomId != roomId) {
      await leaveRoom();
    }

    EnterRoomResp? enterResponse;
    _setState(
      _state.copyWith(
        status: RoomStatus.entering,
        currentRoomId: roomId,
        isInRoom: false,
        isMinimized: false,
        clearRoomInfo: true,
        micList: const [],
        errorMessage: null,
      ),
    );

    try {
      enterResponse = await _api.enterRoom(
        roomId: roomId,
        roomPassword: roomPassword,
        followUid: followUid,
      );
      final effectiveRoomId = enterResponse.roomId.isEmpty
          ? roomId
          : enterResponse.roomId;
      _setState(
        _state.copyWith(
          currentRoomId: effectiveRoomId,
          enterResponse: enterResponse,
        ),
      );

      unawaited(
        _joinAgoraBestEffort(
          roomId: effectiveRoomId,
          enterResponse: enterResponse,
          appId: agoraAppId ?? const String.fromEnvironment('AGORA_APPID'),
        ),
      );

      await _socketManager.joinRoom(
        effectiveRoomId,
        url: socketUrl ?? _defaultSocketUrl(),
      );

      _setState(
        _state.copyWith(
          status: RoomStatus.ready,
          currentRoomId: effectiveRoomId,
          isInRoom: true,
          isMinimized: false,
          errorMessage: null,
        ),
      );
      unawaited(refreshRoomData());
    } catch (error) {
      if (enterResponse != null) {
        unawaited(_cleanupAfterEnterFailure(enterResponse.roomId));
      }
      _setState(
        _state.copyWith(
          status: RoomStatus.error,
          isInRoom: false,
          isMinimized: false,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  void minimizeRoom() {
    if (!_state.isInRoom) return;
    _setState(
      _state.copyWith(
        status: RoomStatus.ready,
        isMinimized: true,
        errorMessage: null,
      ),
    );
  }

  void restoreRoom() {
    if (!_state.isInRoom) return;
    _setState(
      _state.copyWith(
        status: RoomStatus.ready,
        isMinimized: false,
        errorMessage: null,
      ),
    );
  }

  Future<void> exitMinimizedRoom() {
    return leaveRoom();
  }

  Future<void> leaveRoom() async {
    final roomId = _state.currentRoomId;
    if (roomId == null || roomId.isEmpty) {
      await _agoraManager.leaveRoom();
      await _socketManager.disconnect();
      _setState(const RoomState());
      return;
    }

    _setState(_state.copyWith(status: RoomStatus.leaving));
    Object? leaveError;

    try {
      await _api.exitRoom(roomId);
    } catch (error) {
      leaveError = error;
      debugPrint('Room exit API failed: $error');
    }

    await Future.wait<void>([
      _agoraManager.leaveRoom(),
      _socketManager.leaveRoom(roomId).then((_) => _socketManager.disconnect()),
    ], eagerError: false);

    _setState(
      RoomState(
        status: leaveError == null ? RoomStatus.idle : RoomStatus.error,
        errorMessage: leaveError?.toString(),
      ),
    );
  }

  Future<void> refreshRoomData() async {
    await Future.wait<void>([
      refreshRoomInfo(),
      refreshMicList(),
    ], eagerError: false);
  }

  Future<void> refreshRoomInfo() async {
    final roomId = _requireCurrentRoomId();
    try {
      final roomInfo = await _api.getRoomInfo(roomId);
      _setState(_state.copyWith(roomInfo: roomInfo, errorMessage: null));
    } catch (error) {
      _setState(_state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> refreshMicList() async {
    final roomId = _requireCurrentRoomId();
    try {
      final micList = await _api.getMicList(roomId);
      _setState(_state.copyWith(micList: micList, errorMessage: null));
    } catch (error) {
      _setState(_state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<RoomMicOperateResp> upMic(int position) async {
    final roomId = _requireCurrentRoomId();
    final response = await _api.upMic(roomId: roomId, position: position);
    await _agoraManager.publish(position: position);
    unawaited(refreshMicList());
    return response;
  }

  Future<RoomMicOperateResp> downMic(int position) async {
    final roomId = _requireCurrentRoomId();
    final response = await _api.downMic(roomId: roomId, position: position);
    await _agoraManager.stopPublish(position: position);
    unawaited(refreshMicList());
    return response;
  }

  Future<RoomMicOperateResp> kickDownMic({
    required int position,
    required int targetUid,
  }) async {
    final roomId = _requireCurrentRoomId();
    final response = await _api.kickDownMic(
      roomId: roomId,
      position: position,
      targetUid: targetUid,
    );
    final uid = await _authSession.uid();
    if (uid == targetUid) {
      await _agoraManager.stopPublish(position: position);
    }
    unawaited(refreshMicList());
    return response;
  }

  Future<RoomMicOperateResp> muteMicSeat({
    required int position,
    required bool mute,
  }) async {
    final roomId = _requireCurrentRoomId();
    final response = mute
        ? await _api.muteMicSeat(roomId: roomId, position: position)
        : await _api.unmuteMicSeat(roomId: roomId, position: position);
    unawaited(refreshMicList());
    return response;
  }

  Future<RoomMicOperateResp> lockMicSeat({
    required int position,
    required bool isLock,
  }) async {
    final roomId = _requireCurrentRoomId();
    final response = await _api.lockMicSeat(
      roomId: roomId,
      position: position,
      isLock: isLock,
    );
    unawaited(refreshMicList());
    return response;
  }

  Future<void> _joinAgoraBestEffort({
    required String roomId,
    required EnterRoomResp enterResponse,
    required String appId,
  }) async {
    try {
      final uid = await _authSession.uid();
      if (uid == null) {
        throw const NadyApiException(message: 'Please log in first');
      }
      final responseToken = enterResponse.agoraToken;
      final token = responseToken == null || responseToken.isEmpty
          ? await _api.getAgoraToken(roomId)
          : responseToken;
      await _agoraManager.joinRoom(
        roomId: roomId,
        token: token,
        uid: uid,
        appId: appId,
      );
    } catch (error) {
      debugPrint('Agora join skipped or failed: $error');
    }
  }

  Future<void> _cleanupAfterEnterFailure(String roomId) async {
    try {
      if (roomId.isNotEmpty) {
        await _api.exitRoom(roomId);
        await _socketManager.leaveRoom(roomId);
      }
      await _agoraManager.leaveRoom();
    } catch (error) {
      debugPrint('Room enter cleanup failed: $error');
    }
  }

  void _handleSocketMessage(RoomSocketMessage message) {
    final roomId = _state.currentRoomId;
    if (roomId == null || roomId.isEmpty) return;
    if (message.channel != 'room:$roomId' && message.channel != 'room') return;

    switch (message.event) {
      case 'RoomMicUpdateEvent':
        final micList = _parseMicListPayload(message.payload);
        if (micList != null) {
          _setState(_state.copyWith(micList: micList));
        }
        break;
      case 'RoomConfigUpdateEvent':
      case 'RoomInfoUpdateEvent':
        unawaited(refreshRoomInfo());
        break;
      case 'RoomKickOutEvent':
        unawaited(leaveRoom());
        break;
    }
  }

  List<RoomMicModel>? _parseMicListPayload(Object? payload) {
    final decoded = _decodePayload(payload);
    Object? micListInfo;
    if (decoded is Map) {
      micListInfo =
          decoded['micListInfo'] ?? decoded['micList'] ?? decoded['list'];
    } else {
      micListInfo = decoded;
    }
    if (micListInfo is! Iterable) return null;
    return micListInfo
        .whereType<Map>()
        .map((item) => RoomMicModel.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Object? _decodePayload(Object? payload) {
    if (payload is String) {
      try {
        return _jsonDecode(payload);
      } catch (_) {
        return payload;
      }
    }
    return payload;
  }

  Object? _jsonDecode(String text) {
    return jsonDecode(text);
  }

  String _requireCurrentRoomId() {
    final roomId = _state.currentRoomId;
    if (roomId == null || roomId.isEmpty || !_state.isInRoom) {
      throw const NadyApiException(message: 'Not in room');
    }
    return roomId;
  }

  String _defaultSocketUrl() {
    final raw = AppConfig.shared.appEnv.socketHost;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.isEmpty) return raw;
    final scheme = switch (uri.scheme) {
      'http' => 'ws',
      'https' => 'wss',
      _ => uri.scheme,
    };
    final path = uri.path.isEmpty || uri.path == '/'
        ? '/connection/websocket'
        : uri.path;
    return uri.replace(scheme: scheme, path: path).toString();
  }

  void _setState(RoomState value) {
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketMessages.cancel();
    _socketManager.removeListener(_dependencyListener);
    _agoraManager.removeListener(_dependencyListener);
    super.dispose();
  }
}

class _RoomApiClient {
  final HttpDioManager _httpManager = HttpDioManager();

  Future<EnterRoomResp> enterRoom({
    required String roomId,
    required String roomPassword,
    required int followUid,
  }) async {
    final response = await _httpManager.post(
      HttpApi.roomEnter,
      data: {
        'roomId': roomId,
        'roomPasswd': roomPassword,
        'followUid': followUid,
        'appVersion': AppDevice().appVersion,
      },
    );
    return _requireData(
      response,
      (json) => EnterRoomResp.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<void> exitRoom(String roomId) async {
    final response = await _httpManager.post(
      HttpApi.roomExit,
      data: {'roomId': roomId},
    );
    _throwIfFailed(response);
  }

  Future<RoomInfo> getRoomInfo(String roomId) async {
    final response = await _httpManager.get(
      HttpApi.roomInfo,
      queryParameters: {'roomId': roomId},
    );
    return _requireData(
      response,
      (json) => RoomInfo.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<List<RoomMicModel>> getMicList(String roomId) async {
    final response = await _httpManager.get(
      HttpApi.roomMicListInfo,
      queryParameters: {'roomId': roomId},
    );
    return _requireData(response, (json) {
      final list = json is List
          ? json
          : json is Map
          ? json['micListInfo'] ?? json['micList'] ?? json['list'] ?? []
          : [];
      return (list as Iterable)
          .whereType<Map>()
          .map((item) => RoomMicModel.fromJson(item.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<RoomMicOperateResp> upMic({
    required String roomId,
    required int position,
  }) {
    return _postMicOperate(
      HttpApi.roomMicUp,
      data: {'roomId': roomId, 'position': position},
    );
  }

  Future<RoomMicOperateResp> downMic({
    required String roomId,
    required int position,
  }) {
    return _postMicOperate(
      HttpApi.roomMicDown,
      data: {'roomId': roomId, 'position': position},
    );
  }

  Future<RoomMicOperateResp> kickDownMic({
    required String roomId,
    required int position,
    required int targetUid,
  }) {
    return _postMicOperate(
      HttpApi.roomMicKickDown,
      data: {'roomId': roomId, 'position': position, 'targetUid': targetUid},
    );
  }

  Future<RoomMicOperateResp> muteMicSeat({
    required String roomId,
    required int position,
  }) {
    return _postMicOperate(
      HttpApi.roomMicMute,
      data: {'roomId': roomId, 'position': position},
    );
  }

  Future<RoomMicOperateResp> unmuteMicSeat({
    required String roomId,
    required int position,
  }) {
    return _postMicOperate(
      HttpApi.roomMicUnmute,
      data: {'roomId': roomId, 'position': position},
    );
  }

  Future<RoomMicOperateResp> lockMicSeat({
    required String roomId,
    required int position,
    required bool isLock,
  }) {
    return _postMicOperate(
      HttpApi.roomMicLock,
      data: {'roomId': roomId, 'position': position, 'isLock': isLock},
    );
  }

  Future<String> getAgoraToken(String roomId) async {
    final response = await _httpManager.get(
      HttpApi.agoraToken,
      queryParameters: {'roomId': roomId},
    );
    return _requireData(response, (json) => json?.toString() ?? '');
  }

  Future<RoomMicOperateResp> _postMicOperate(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final response = await _httpManager.post(path, data: data);
    return _requireData(response, (json) {
      if (json is Map) {
        return RoomMicOperateResp.fromJson(json.cast<String, dynamic>());
      }
      return RoomMicOperateResp(raw: {'data': json});
    });
  }

  T _requireData<T>(dynamic response, T Function(Object? json) fromJsonT) {
    final server = NadyServerResponse<T>.fromJson(_asMap(response), fromJsonT);
    if (!server.isSuccess) throw server.toException();
    final data = server.data;
    if (data == null) {
      throw const NadyApiException(message: 'Empty server data');
    }
    return data;
  }

  void _throwIfFailed(dynamic response) {
    final server = NadyServerResponse<dynamic>.fromJson(
      _asMap(response),
      (json) => json,
    );
    if (!server.isSuccess) throw server.toException();
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }
}

const Object _sentinel = Object();
