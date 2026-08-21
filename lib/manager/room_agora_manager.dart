import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

import '../model/server_response.dart';
import 'auth_session.dart';
import 'http_api.dart';
import 'http_dio_manager.dart';

class RoomAgoraState {
  const RoomAgoraState({
    this.initialized = false,
    this.joining = false,
    this.joined = false,
    this.roomId,
    this.clientRole = ClientRoleType.clientRoleAudience,
    this.publishing = false,
    this.mutedMicrophone = false,
    this.mutedSpeaker = false,
    this.volumeLevels = const {},
    this.upstreamQuality,
    this.downstreamQuality,
    this.errorMessage,
  });

  final bool initialized;
  final bool joining;
  final bool joined;
  final String? roomId;
  final ClientRoleType clientRole;
  final bool publishing;
  final bool mutedMicrophone;
  final bool mutedSpeaker;
  final Map<int, int> volumeLevels;
  final QualityType? upstreamQuality;
  final QualityType? downstreamQuality;
  final String? errorMessage;

  RoomAgoraState copyWith({
    bool? initialized,
    bool? joining,
    bool? joined,
    String? roomId,
    bool? clearRoomId,
    ClientRoleType? clientRole,
    bool? publishing,
    bool? mutedMicrophone,
    bool? mutedSpeaker,
    Map<int, int>? volumeLevels,
    QualityType? upstreamQuality,
    QualityType? downstreamQuality,
    Object? errorMessage = _sentinel,
  }) {
    return RoomAgoraState(
      initialized: initialized ?? this.initialized,
      joining: joining ?? this.joining,
      joined: joined ?? this.joined,
      roomId: clearRoomId == true ? null : roomId ?? this.roomId,
      clientRole: clientRole ?? this.clientRole,
      publishing: publishing ?? this.publishing,
      mutedMicrophone: mutedMicrophone ?? this.mutedMicrophone,
      mutedSpeaker: mutedSpeaker ?? this.mutedSpeaker,
      volumeLevels: volumeLevels ?? this.volumeLevels,
      upstreamQuality: upstreamQuality ?? this.upstreamQuality,
      downstreamQuality: downstreamQuality ?? this.downstreamQuality,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class RoomAgoraManager extends ChangeNotifier {
  RoomAgoraManager._();

  static final RoomAgoraManager instance = RoomAgoraManager._();

  final HttpDioManager _httpManager = HttpDioManager();
  final AuthSession _authSession = AuthSession.instance;

  RtcEngine? _engine;
  String? _appId;
  RoomAgoraState _state = const RoomAgoraState();

  RoomAgoraState get state => _state;

  Future<void> init({required String appId}) async {
    if (appId.isEmpty) {
      _setState(_state.copyWith(errorMessage: 'Missing Agora app id'));
      return;
    }
    if (_engine != null && _appId == appId) return;

    await release();
    _appId = appId;
    try {
      final engine = createAgoraRtcEngine();
      _engine = engine;
      await engine.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          audioScenario: AudioScenarioType.audioScenarioGameStreaming,
        ),
      );
      await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      await engine.enableAudio();
      await engine.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );
      await engine.enableAudioVolumeIndication(
        interval: 1000,
        smooth: 3,
        reportVad: true,
      );
      engine.registerEventHandler(_eventHandler());
      _setState(
        _state.copyWith(
          initialized: true,
          clientRole: ClientRoleType.clientRoleAudience,
          errorMessage: null,
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(initialized: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> joinRoom({
    required String roomId,
    required String token,
    required int uid,
    required String appId,
  }) async {
    await init(appId: appId);
    final engine = _engine;
    if (engine == null || !_state.initialized) return;

    _setState(
      _state.copyWith(
        joining: true,
        joined: false,
        roomId: roomId,
        errorMessage: null,
      ),
    );

    try {
      await engine.joinChannel(
        token: token,
        channelId: roomId,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleAudience,
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
          publishMicrophoneTrack: false,
          publishCameraTrack: false,
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          joining: false,
          joined: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> leaveRoom() async {
    final engine = _engine;
    if (engine == null) {
      _setState(const RoomAgoraState());
      return;
    }

    try {
      await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      await engine.leaveChannel();
    } catch (error) {
      debugPrint('Agora leave room failed: $error');
    }

    _setState(
      _state.copyWith(
        joining: false,
        joined: false,
        clearRoomId: true,
        clientRole: ClientRoleType.clientRoleAudience,
        publishing: false,
        volumeLevels: const {},
        errorMessage: null,
      ),
    );
  }

  Future<void> publish({int? position}) async {
    try {
      await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      _setState(
        _state.copyWith(
          clientRole: ClientRoleType.clientRoleBroadcaster,
          publishing: true,
          errorMessage: null,
        ),
      );
    } catch (error) {
      _setState(_state.copyWith(errorMessage: error.toString()));
      rethrow;
    }
  }

  Future<void> stopPublish({int? position}) async {
    try {
      await _engine?.setClientRole(role: ClientRoleType.clientRoleAudience);
      _setState(
        _state.copyWith(
          clientRole: ClientRoleType.clientRoleAudience,
          publishing: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      _setState(_state.copyWith(errorMessage: error.toString()));
      rethrow;
    }
  }

  Future<void> muteMicrophone(bool mute) async {
    await _engine?.muteLocalAudioStream(mute);
    _setState(_state.copyWith(mutedMicrophone: mute));
  }

  Future<void> muteSpeaker(bool mute) async {
    await _engine?.muteAllRemoteAudioStreams(mute);
    _setState(_state.copyWith(mutedSpeaker: mute));
  }

  Future<void> renewCurrentToken() async {
    final roomId = _state.roomId;
    final engine = _engine;
    if (roomId == null || engine == null) return;

    try {
      final token = await _fetchAgoraToken(roomId);
      await engine.renewToken(token);
      _setState(_state.copyWith(errorMessage: null));
    } catch (error) {
      _setState(_state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> release() async {
    final engine = _engine;
    _engine = null;
    _appId = null;
    if (engine != null) {
      try {
        await engine.leaveChannel();
        await engine.release();
      } catch (error) {
        debugPrint('Agora release failed: $error');
      }
    }
    _setState(const RoomAgoraState());
  }

  RtcEngineEventHandler _eventHandler() {
    return RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        _setState(
          _state.copyWith(
            joining: false,
            joined: true,
            roomId: connection.channelId,
            errorMessage: null,
          ),
        );
      },
      onLeaveChannel: (connection, stats) {
        _setState(
          _state.copyWith(
            joining: false,
            joined: false,
            clearRoomId: true,
            publishing: false,
            volumeLevels: const {},
          ),
        );
      },
      onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
        if (remoteUid == 0) {
          _setState(
            _state.copyWith(
              upstreamQuality: txQuality,
              downstreamQuality: rxQuality,
            ),
          );
        }
      },
      onAudioVolumeIndication:
          (connection, speakers, speakerNumber, totalVolume) async {
            final uid = await _authSession.uid();
            final nextLevels = <int, int>{};
            for (final speaker in speakers) {
              final rawUid = speaker.uid ?? 0;
              final speakerUid = rawUid == 0 ? uid : rawUid;
              final volume = speaker.volume ?? 0;
              if (speakerUid != null && volume > 0) {
                nextLevels[speakerUid] = volume;
              }
            }
            _setState(_state.copyWith(volumeLevels: nextLevels));
          },
      onAudioPublishStateChanged:
          (channel, oldState, newState, elapseSinceLastState) {
            _setState(
              _state.copyWith(
                publishing:
                    newState == StreamPublishState.pubStatePublished ||
                    newState == StreamPublishState.pubStatePublishing,
              ),
            );
          },
      onClientRoleChanged: (connection, oldRole, newRole, newRoleOptions) {
        _setState(
          _state.copyWith(
            clientRole: newRole,
            publishing: newRole == ClientRoleType.clientRoleBroadcaster,
            errorMessage: null,
          ),
        );
      },
      onClientRoleChangeFailed: (connection, reason, currentRole) {
        _setState(
          _state.copyWith(
            clientRole: currentRole,
            publishing: currentRole == ClientRoleType.clientRoleBroadcaster,
            errorMessage: reason.toString(),
          ),
        );
      },
      onRequestToken: (_) {
        unawaited(renewCurrentToken());
      },
      onTokenPrivilegeWillExpire: (_, __) {
        unawaited(renewCurrentToken());
      },
      onError: (error, message) {
        _setState(_state.copyWith(errorMessage: '$error $message'));
      },
    );
  }

  Future<String> _fetchAgoraToken(String roomId) async {
    final response = await _httpManager.get(
      HttpApi.agoraToken,
      queryParameters: {'roomId': roomId},
    );
    final server = NadyServerResponse<String>.fromJson(
      _asMap(response),
      (json) => json?.toString() ?? '',
    );
    if (!server.isSuccess) throw server.toException();
    final token = server.data;
    if (token == null || token.isEmpty) {
      throw const NadyApiException(message: 'Empty Agora token');
    }
    return token;
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }

  void _setState(RoomAgoraState value) {
    _state = value;
    notifyListeners();
  }
}

const Object _sentinel = Object();
