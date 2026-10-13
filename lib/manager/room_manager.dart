import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../configs/app_configs.dart';
import '../configs/app_device.dart';
import '../model/room_models.dart';
import '../model/room_socket_message.dart';
import '../model/room_user_info.dart';
import '../model/room_music_state.dart';
import '../model/server_response.dart';
import 'app_socket_manager.dart';
import 'auth_session.dart';
import 'http_api.dart';
import 'http_dio_manager.dart';
import 'room_agora_manager.dart';
import 'room_background_audio_manager.dart';

part 'room_manager_music.dart';

enum RoomStatus { idle, entering, ready, leaving, error }

class RoomState {
  const RoomState({
    this.status = RoomStatus.idle,
    this.currentRoomId,
    this.isInRoom = false,
    this.isMinimized = false,
    this.isFollowed = false,
    this.isFollowingRoom = false,
    this.enterResponse,
    this.roomInfo,
    this.micList = const [],
    this.audience = const [],
    this.audienceLoaded = false,
    this.loadingAudience = false,
    this.audienceError,
    this.errorMessage,
  });

  final RoomStatus status;
  final String? currentRoomId;
  final bool isInRoom;
  final bool isMinimized;
  final bool isFollowed;
  final bool isFollowingRoom;
  final EnterRoomResp? enterResponse;
  final RoomInfo? roomInfo;
  final List<RoomMicModel> micList;
  final List<RoomUserInfo> audience;
  final bool audienceLoaded;
  final bool loadingAudience;
  final String? audienceError;
  final String? errorMessage;

  int get onlineCount =>
      audienceLoaded ? audience.length : roomInfo?.audienceCount ?? 0;

  bool get isLoading =>
      status == RoomStatus.entering || status == RoomStatus.leaving;

  RoomState copyWith({
    RoomStatus? status,
    String? currentRoomId,
    bool? clearCurrentRoomId,
    bool? isInRoom,
    bool? isMinimized,
    bool? isFollowed,
    bool? isFollowingRoom,
    EnterRoomResp? enterResponse,
    bool? clearEnterResponse,
    RoomInfo? roomInfo,
    bool? clearRoomInfo,
    List<RoomMicModel>? micList,
    List<RoomUserInfo>? audience,
    bool? audienceLoaded,
    bool? loadingAudience,
    Object? audienceError = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return RoomState(
      status: status ?? this.status,
      currentRoomId: clearCurrentRoomId == true
          ? null
          : currentRoomId ?? this.currentRoomId,
      isInRoom: isInRoom ?? this.isInRoom,
      isMinimized: isMinimized ?? this.isMinimized,
      isFollowed: isFollowed ?? this.isFollowed,
      isFollowingRoom: isFollowingRoom ?? this.isFollowingRoom,
      enterResponse: clearEnterResponse == true
          ? null
          : enterResponse ?? this.enterResponse,
      roomInfo: clearRoomInfo == true ? null : roomInfo ?? this.roomInfo,
      micList: micList ?? this.micList,
      audience: audience ?? this.audience,
      audienceLoaded: audienceLoaded ?? this.audienceLoaded,
      loadingAudience: loadingAudience ?? this.loadingAudience,
      audienceError: identical(audienceError, _sentinel)
          ? this.audienceError
          : audienceError as String?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class RoomManager extends ChangeNotifier {
  RoomManager._({
    HttpDioManager? httpManager,
    AppSocketManager? socketManager,
    RoomAgoraManager? agoraManager,
    AuthSession? authSession,
    RoomBackgroundAudioManager? backgroundAudioManager,
  }) : _api = _RoomApiClient(httpManager ?? HttpDioManager()),
       _socketManager = socketManager ?? AppSocketManager.instance,
       _agoraManager = agoraManager ?? RoomAgoraManager.instance,
       _authSession = authSession ?? AuthSession.instance,
       _backgroundAudio =
           backgroundAudioManager ?? RoomBackgroundAudioManager.instance {
    _dependencyListener = _onDependencyChanged;
    _socketMessages = _socketManager.messages.listen(_handleSocketMessage);
    _socketManager.addListener(_dependencyListener);
    _agoraManager.addListener(_dependencyListener);
  }

  static final RoomManager instance = RoomManager._();

  @visibleForTesting
  factory RoomManager.forTesting({
    required HttpDioManager httpManager,
    required AppSocketManager socketManager,
    required RoomAgoraManager agoraManager,
    required AuthSession authSession,
    RoomBackgroundAudioManager? backgroundAudioManager,
  }) => RoomManager._(
    httpManager: httpManager,
    socketManager: socketManager,
    agoraManager: agoraManager,
    authSession: authSession,
    backgroundAudioManager: backgroundAudioManager,
  );

  final _RoomApiClient _api;
  final AppSocketManager _socketManager;
  final RoomAgoraManager _agoraManager;
  final AuthSession _authSession;
  final RoomBackgroundAudioManager _backgroundAudio;

  late final VoidCallback _dependencyListener;
  late final StreamSubscription<RoomSocketMessage> _socketMessages;
  RoomState _state = const RoomState();
  Future<void>? _enterTask;
  Future<void>? _leaveTask;
  Future<void>? _joinTask;
  Future<void>? _agoraJoinTask;
  Future<void>? _followTask;
  Future<void>? _audienceTask;
  bool _audienceRefreshQueued = false;
  String? _requestedRoomId;
  String? _serverRoomId;
  int _generation = 0;
  Future<void>? _musicQueue;
  Future<void>? _musicStatusQueue;
  String? _musicPlayerRoomId;
  int? _musicUid;
  int _musicEpoch = 0;
  bool _musicLeaseRevoked = false;
  RoomMusicPlayback _lastMusicStatus = RoomMusicPlayback.stopped;

  RoomState get state => _state;
  AppSocketState get socketState => _socketManager.state;
  RoomAgoraState get agoraState => _agoraManager.state;

  String get currentRoomId => _state.currentRoomId ?? '';
  bool get isInRoom => _state.isInRoom;
  bool get isMinimized => _state.isMinimized;
  int get sessionGeneration => _generation;

  Future<void> playMusic({
    required String roomId,
    required String path,
    required String title,
    bool force = false,
  }) => _playMusic(roomId: roomId, path: path, title: title, force: force);
  Future<void> pauseMusic(String roomId) =>
      _controlMusic(roomId, _agoraManager.pauseMusic);
  Future<void> resumeMusic(String roomId) =>
      _controlMusic(roomId, _agoraManager.resumeMusic);
  Future<void> seekMusic(String roomId, int position) =>
      _controlMusic(roomId, () => _agoraManager.seekMusic(position));
  Future<void> setMusicVolume(String roomId, int volume) => _controlMusic(
    roomId,
    () => _agoraManager.setMusicVolume(volume),
    requirePlayer: false,
  );
  Future<void> stopMusic() => _queueMusic(() => _closeMusicPlayer());

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
    final leaving = _leaveTask;
    if (leaving != null) await leaving;
    if (_enterTask != null && _requestedRoomId == roomId) {
      return _enterTask;
    }
    if (_state.status == RoomStatus.ready &&
        _state.isInRoom &&
        _state.currentRoomId == roomId) {
      restoreRoom();
      return;
    }
    if (_state.currentRoomId != null || _enterTask != null) {
      await leaveRoom();
    }

    final completion = Completer<void>();
    _enterTask = completion.future;
    _requestedRoomId = roomId;
    final generation = ++_generation;
    unawaited(() async {
      try {
        await _enterRoom(
          roomId: roomId,
          roomPassword: roomPassword,
          followUid: followUid,
          socketUrl: socketUrl,
          agoraAppId: agoraAppId,
          generation: generation,
        );
        completion.complete();
      } catch (error, stack) {
        completion.completeError(error, stack);
      } finally {
        if (identical(_enterTask, completion.future)) _enterTask = null;
      }
    }());
    return completion.future;
  }

  Future<void> _enterRoom({
    required String roomId,
    required String roomPassword,
    required int followUid,
    required int generation,
    String? socketUrl,
    String? agoraAppId,
  }) async {
    EnterRoomResp? enterResponse;
    _setState(
      _state.copyWith(
        status: RoomStatus.entering,
        currentRoomId: roomId,
        isInRoom: false,
        isMinimized: false,
        isFollowed: false,
        isFollowingRoom: false,
        clearRoomInfo: true,
        clearEnterResponse: true,
        micList: const [],
        audience: const [],
        audienceLoaded: false,
        loadingAudience: false,
        audienceError: null,
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
      // Exit waits for this request so even a late canonical ID is exited.
      _serverRoomId = effectiveRoomId;
      if (generation != _generation) return;
      _setState(
        _state.copyWith(
          currentRoomId: effectiveRoomId,
          enterResponse: enterResponse,
        ),
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
      if (generation != _generation) return;
      _agoraJoinTask = _joinAgoraBestEffort(
        roomId: effectiveRoomId,
        enterResponse: enterResponse,
        generation: generation,
        appId: agoraAppId ?? AppConfig.shared.appEnv.agoraAppId,
      );
      _joinTask = Future.wait<void>([
        _agoraJoinTask!,
        _joinSocketBestEffort(roomId: effectiveRoomId, url: socketUrl),
      ]).then((_) {});
      unawaited(_joinTask!);
      unawaited(refreshRoomData());
    } catch (error) {
      if (generation != _generation) return;
      _setState(
        _state.copyWith(
          status: RoomStatus.error,
          isInRoom: false,
          isMinimized: false,
          errorMessage: error.toString(),
        ),
      );
      // Run after the enter task settles; leaveRoom also drains pending joins.
      unawaited(Future<void>.microtask(() => leaveRoom()));
      rethrow;
    }
  }

  void minimizeRoom() {
    if (!_state.isInRoom || _state.status != RoomStatus.ready) return;
    _setState(
      _state.copyWith(
        status: RoomStatus.ready,
        isMinimized: true,
        errorMessage: null,
      ),
    );
  }

  void restoreRoom() {
    if (!_state.isInRoom || _state.status != RoomStatus.ready) return;
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

  Future<void> leaveRoom() {
    if (_leaveTask != null) return _leaveTask!;
    if (_state.status == RoomStatus.idle && _enterTask == null) {
      return Future<void>.value();
    }
    final completion = Completer<void>();
    _leaveTask = completion.future;
    _generation += 1;
    _setState(_state.copyWith(status: RoomStatus.leaving, isMinimized: false));
    unawaited(() async {
      try {
        // Drain in-flight work before teardown so it cannot rejoin after Exit.
        final entering = _enterTask;
        if (entering != null) {
          await _cleanupStep('pending enter', () => entering);
        }
        final joining = _joinTask;
        if (joining != null) await _cleanupStep('pending joins', () => joining);
        final roomId = _serverRoomId ?? _state.currentRoomId;
        await _cleanupStep('music player close', stopMusic);
        await _cleanupStep(
          'pending music status',
          () => _musicStatusQueue ?? Future<void>.value(),
        );
        if (roomId != null && roomId.isNotEmpty) {
          await _cleanupStep('exit API', () => _api.exitRoom(roomId));
        }
        await _cleanupStep('Agora leave', _agoraManager.leaveRoom);
        if (roomId != null && roomId.isNotEmpty) {
          await _cleanupStep(
            'Socket leave',
            () => _socketManager.leaveRoom(roomId),
          );
        }
        await _cleanupStep('Socket disconnect', _socketManager.disconnect);
        await _cleanupStep('background audio stop', _backgroundAudio.stop);
      } finally {
        _serverRoomId = null;
        _requestedRoomId = null;
        _joinTask = null;
        _agoraJoinTask = null;
        _followTask = null;
        _audienceTask = null;
        _audienceRefreshQueued = false;
        _musicUid = null;
        _musicLeaseRevoked = false;
        _musicEpoch++;
        _lastMusicStatus = RoomMusicPlayback.stopped;
        _setState(const RoomState());
        _leaveTask = null;
        completion.complete();
      }
    }());
    return completion.future;
  }

  Future<void> _cleanupStep(String name, Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      debugPrint('[RoomExit] $name failed: $error\n$stack');
    }
  }

  bool _isCurrentSession(String roomId, int generation) =>
      generation == _generation &&
      _state.status == RoomStatus.ready &&
      _state.isInRoom &&
      _state.currentRoomId == roomId;

  void _onDependencyChanged() {
    _notifyMusicStatus();
    if (_musicPlayerRoomId != null &&
        _agoraManager.state.music.status == RoomMusicPlayback.failed) {
      unawaited(
        _cleanupStep(
          'failed music player close',
          () => _queueMusic(() async {
            if (_agoraManager.state.music.status == RoomMusicPlayback.failed) {
              await _closeMusicPlayer();
            }
          }),
        ),
      );
    }
    if (_state.status == RoomStatus.ready &&
        (_socketManager.state.isTerminal || _agoraManager.state.isTerminal)) {
      unawaited(leaveRoom());
    }
    if (_state.status == RoomStatus.ready &&
        (_agoraManager.state.joining || _agoraManager.state.joined)) {
      unawaited(
        _backgroundAudio.start(useMicrophone: _agoraManager.state.publishing),
      );
    }
    notifyListeners();
  }

  Future<void> refreshRoomData() async {
    await Future.wait<void>([
      refreshRoomInfo(),
      refreshMicList(),
      refreshAudience(),
    ], eagerError: false);
  }

  Future<void> refreshRoomInfo() async {
    final roomId = _requireCurrentRoomId();
    final generation = _generation;
    try {
      final roomInfo = await _api.getRoomInfo(roomId);
      if (!_isCurrentSession(roomId, generation)) return;
      _setState(
        _state.copyWith(
          roomInfo: roomInfo,
          // A stale detail response must not undo a successful follow.
          isFollowed: _state.isFollowed || roomInfo.isFollow == true,
          errorMessage: null,
        ),
      );
    } catch (error) {
      if (!_isCurrentSession(roomId, generation)) return;
      _setState(_state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> refreshMicList() async {
    final roomId = _requireCurrentRoomId();
    final generation = _generation;
    try {
      final micList = await _api.getMicList(roomId);
      if (!_isCurrentSession(roomId, generation)) return;
      _setState(_state.copyWith(micList: micList, errorMessage: null));
    } catch (error) {
      if (!_isCurrentSession(roomId, generation)) return;
      _setState(_state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> refreshAudience() {
    final roomId = _requireCurrentRoomId();
    final pending = _audienceTask;
    if (pending != null) return pending;
    final generation = _generation;
    final completion = Completer<void>();
    _audienceTask = completion.future;
    _setState(_state.copyWith(loadingAudience: true, audienceError: null));
    unawaited(() async {
      try {
        final audience = await _api.getAudience(roomId);
        if (_isCurrentSession(roomId, generation)) {
          _setState(
            _state.copyWith(
              audience: audience,
              audienceLoaded: true,
              loadingAudience: false,
              audienceError: null,
            ),
          );
        }
      } catch (error) {
        if (_isCurrentSession(roomId, generation)) {
          _setState(
            _state.copyWith(
              loadingAudience: false,
              audienceError: error.toString(),
            ),
          );
        }
      } finally {
        if (identical(_audienceTask, completion.future)) {
          _audienceTask = null;
          final refreshAgain = _audienceRefreshQueued;
          _audienceRefreshQueued = false;
          if (refreshAgain && _isCurrentSession(roomId, generation)) {
            unawaited(refreshAudience());
          }
        }
        completion.complete();
      }
    }());
    return completion.future;
  }

  /// Follow the current canonical room; retain the result through Keep/restore.
  Future<void> followRoom() {
    final roomId = _requireCurrentRoomId();
    if (_state.isFollowed || _state.roomInfo?.isFollow == true) {
      return Future<void>.value();
    }
    final pending = _followTask;
    if (pending != null) return pending;

    final generation = _generation;
    final completion = Completer<void>();
    _followTask = completion.future;
    _setState(_state.copyWith(isFollowingRoom: true, errorMessage: null));
    unawaited(() async {
      try {
        await _api.followRoom(roomId);
        if (_isCurrentSession(roomId, generation)) {
          _setState(
            _state.copyWith(
              isFollowed: true,
              isFollowingRoom: false,
              errorMessage: null,
            ),
          );
          if (_isCurrentSession(roomId, generation)) {
            unawaited(refreshRoomInfo());
          }
        }
        completion.complete();
      } catch (error, stack) {
        if (_isCurrentSession(roomId, generation)) {
          _setState(
            _state.copyWith(
              isFollowingRoom: false,
              errorMessage: error.toString(),
            ),
          );
        }
        completion.completeError(error, stack);
      } finally {
        if (identical(_followTask, completion.future)) _followTask = null;
      }
    }());
    return completion.future;
  }

  Future<RoomMicOperateResp> upMic(int position) async {
    final roomId = _requireCurrentRoomId();
    final generation = _generation;
    final response = await _api.upMic(roomId: roomId, position: position);
    if (!_isCurrentSession(roomId, generation)) return response;
    _applyMicOperateResponse(response);
    await _agoraJoinTask;
    if (!_isCurrentSession(roomId, generation)) return response;
    await _agoraManager.publish(position: position);
    if (_isCurrentSession(roomId, generation)) unawaited(refreshMicList());
    return response;
  }

  Future<RoomMicOperateResp> downMic(int position) async {
    final roomId = _requireCurrentRoomId();
    final generation = _generation;
    final response = await _api.downMic(roomId: roomId, position: position);
    if (!_isCurrentSession(roomId, generation)) return response;
    _applyMicOperateResponse(response);
    await _cleanupStep('music after down mic', stopMusic);
    if (!_isCurrentSession(roomId, generation)) return response;
    await _agoraManager.stopPublish(position: position);
    if (_isCurrentSession(roomId, generation)) unawaited(refreshMicList());
    return response;
  }

  Future<void> muteLocalMicrophone(bool mute) async {
    final roomId = _requireCurrentRoomId();
    final generation = _generation;
    await _agoraJoinTask;
    if (!_isCurrentSession(roomId, generation)) return;
    await _agoraManager.muteMicrophone(mute);
  }

  Future<RoomMicOperateResp> kickDownMic({
    required int position,
    required int targetUid,
  }) async {
    final roomId = _requireCurrentRoomId();
    final generation = _generation;
    final response = await _api.kickDownMic(
      roomId: roomId,
      position: position,
      targetUid: targetUid,
    );
    if (!_isCurrentSession(roomId, generation)) return response;
    _applyMicOperateResponse(response);
    final uid = await _authSession.uid();
    if (uid == targetUid && _isCurrentSession(roomId, generation)) {
      await _cleanupStep('music after kick down', stopMusic);
      await _agoraManager.stopPublish(position: position);
    }
    if (_isCurrentSession(roomId, generation)) unawaited(refreshMicList());
    return response;
  }

  Future<RoomMicOperateResp> muteMicSeat({
    required int position,
    required bool mute,
  }) async {
    final roomId = _requireCurrentRoomId();
    final generation = _generation;
    final response = mute
        ? await _api.muteMicSeat(roomId: roomId, position: position)
        : await _api.unmuteMicSeat(roomId: roomId, position: position);
    if (!_isCurrentSession(roomId, generation)) return response;
    _applyMicOperateResponse(response);
    unawaited(refreshMicList());
    return response;
  }

  Future<RoomMicOperateResp> lockMicSeat({
    required int position,
    required bool isLock,
  }) async {
    final roomId = _requireCurrentRoomId();
    final generation = _generation;
    final response = await _api.lockMicSeat(
      roomId: roomId,
      position: position,
      isLock: isLock,
    );
    if (!_isCurrentSession(roomId, generation)) return response;
    _applyMicOperateResponse(response);
    unawaited(refreshMicList());
    return response;
  }

  Future<void> _joinAgoraBestEffort({
    required String roomId,
    required EnterRoomResp enterResponse,
    required String appId,
    required int generation,
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
      if (!_isCurrentSession(roomId, generation)) return;
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

  Future<void> _joinSocketBestEffort({
    required String roomId,
    String? url,
  }) async {
    try {
      await _socketManager.joinRoom(roomId, url: url);
    } catch (error) {
      debugPrint('Room socket join skipped or failed: $error');
    }
  }

  void _handleSocketMessage(RoomSocketMessage message) {
    final roomId = _state.currentRoomId;
    if (roomId == null || roomId.isEmpty || _state.status != RoomStatus.ready) {
      return;
    }
    if (message.event == 'RoomClosePlayerEvent' &&
        (message.channel == 'global:$_musicUid' ||
            message.channel == 'room:$roomId')) {
      // A forced takeover revoked this lease. Never close the new owner's lock.
      _musicEpoch++;
      _musicLeaseRevoked = true;
      unawaited(
        _cleanupStep(
          'revoked music player',
          () => _queueMusic(() => _closeMusicPlayer(revoked: true)),
        ),
      );
      return;
    }
    if (message.channel != 'room:$roomId' && message.channel != 'room') return;

    switch (message.event) {
      case 'RoomAudienceUpdateEvent':
        // This event only contains top users, never the complete audience.
        if (_audienceTask != null) {
          _audienceRefreshQueued = true;
        } else {
          unawaited(refreshAudience());
        }
        break;
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
        unawaited(_handleKickOut(roomId, message.payload));
        break;
    }
  }

  Future<void> _handleKickOut(String roomId, Object? payload) async {
    final generation = _generation;
    final decoded = _decodePayload(payload);
    if (decoded is! Map) return;
    if (decoded['roomId']?.toString() != roomId) return;
    final from = decoded['from'];
    final targetUid = from is Map ? from['uid'] : decoded['uid'];
    final uid = await _authSession.uid();
    if (uid != null &&
        targetUid?.toString() == uid.toString() &&
        _isCurrentSession(roomId, generation)) {
      await leaveRoom();
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

  void _applyMicOperateResponse(RoomMicOperateResp response) {
    final micList = _extractMicListFromOperateResponse(response);
    if (micList == null) return;
    _setState(_state.copyWith(micList: micList, errorMessage: null));
  }

  List<RoomMicModel>? _extractMicListFromOperateResponse(
    RoomMicOperateResp response,
  ) {
    final directMicList = _parseMicListPayload(response.raw);
    if (directMicList != null) return directMicList;

    final messageList = response.raw['messageList'];
    if (messageList is! Iterable) return null;

    for (final group in messageList) {
      if (group is! Map) continue;
      final messages = group['message'];
      if (messages is! Iterable) continue;
      for (final message in messages) {
        if (message is! Map) continue;
        if (message['event'] != 'RoomMicUpdateEvent') continue;
        final micList = _parseMicListPayload(message['payload']);
        if (micList != null) return micList;
      }
    }

    return null;
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
    if (roomId == null ||
        roomId.isEmpty ||
        !_state.isInRoom ||
        _state.status != RoomStatus.ready) {
      throw const NadyApiException(message: 'Not in room');
    }
    return roomId;
  }

  void _setState(RoomState value) {
    final micChanged = !identical(_state.micList, value.micList);
    _state = value;
    if (micChanged &&
        _musicPlayerRoomId != null &&
        !_state.micList.any((mic) => mic.uid == _musicUid)) {
      _musicEpoch++;
      unawaited(_cleanupStep('music after down mic', stopMusic));
    }
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
  _RoomApiClient(this._httpManager);
  final HttpDioManager _httpManager;

  Future<void> openPlayer(String roomId, {required bool force}) async {
    _throwIfFailed(
      await _httpManager.post(
        HttpApi.roomOpenPlayer,
        data: {'roomId': roomId, 'opType': force ? 2 : 1},
      ),
    );
  }

  Future<void> closePlayer(String roomId) async {
    _throwIfFailed(
      await _httpManager.post(
        HttpApi.roomClosePlayer,
        data: {'roomId': roomId},
      ),
    );
  }

  Future<void> musicStatus(String roomId, String status) async {
    _throwIfFailed(
      await _httpManager.post(
        HttpApi.roomMsgPush,
        data: {
          'event': 'RoomMusicPlaybackStatusEvent',
          'roomId': roomId,
          'data': status,
        },
      ),
    );
  }

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

  Future<void> followRoom(String roomId) async {
    final response = await _httpManager.post(
      HttpApi.roomFollow,
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

  Future<List<RoomUserInfo>> getAudience(String roomId) async {
    final response = await _httpManager.get(
      HttpApi.roomAudienceList,
      queryParameters: {'roomId': roomId},
    );
    return _requireData(response, (json) {
      if (json is! List) {
        throw const FormatException('Invalid room audience list');
      }
      final users = <int, RoomUserInfo>{};
      for (final item in json) {
        if (item is! Map) {
          throw const FormatException('Invalid room audience user');
        }
        final user = RoomUserInfo.fromJson(item.cast<String, dynamic>());
        if (user.uid > 0) users.putIfAbsent(user.uid, () => user);
      }
      return List.unmodifiable(users.values);
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
