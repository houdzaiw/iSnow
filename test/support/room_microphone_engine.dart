import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class RoomMicrophoneEngine implements RtcEngine {
  RtcEngineEventHandler? handler;
  String? appId;
  String? channelId;
  bool autoJoin = true;
  bool failInitialize = false;
  bool failMicrophone = false;
  bool failMediaOptions = false;
  Completer<void>? initializeGate;
  Completer<void>? microphoneGate;
  final roles = <ClientRoleType>[];
  final mediaOptions = <ChannelMediaOptions>[];
  final streamMutes = <bool>[];
  final recordingMutes = <bool>[];

  @override
  Future<void> initialize(RtcEngineContext context) async {
    appId = context.appId;
    await initializeGate?.future;
    if (failInitialize) throw StateError('initialize failed');
  }

  @override
  void registerEventHandler(RtcEngineEventHandler eventHandler) =>
      handler = eventHandler;

  @override
  Future<void> setClientRole({
    required ClientRoleType role,
    ClientRoleOptions? options,
  }) async => roles.add(role);

  @override
  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
    required ChannelMediaOptions options,
  }) async {
    this.channelId = channelId;
    mediaOptions.add(options);
    if (autoJoin) completeJoin();
  }

  void completeJoin() => handler!.onJoinChannelSuccess!(
    RtcConnection(channelId: channelId, localUid: 10),
    0,
  );

  @override
  Future<void> updateChannelMediaOptions(ChannelMediaOptions options) async {
    if (failMediaOptions) throw StateError('track update failed');
    mediaOptions.add(options);
  }

  @override
  Future<void> muteLocalAudioStream(bool mute) async => streamMutes.add(mute);

  @override
  Future<void> muteRecordingSignal(bool mute) async {
    recordingMutes.add(mute);
    if (mute) await microphoneGate?.future;
    if (failMicrophone) throw StateError('recording mute failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}
