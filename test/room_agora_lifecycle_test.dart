import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/manager/room_agora_manager.dart';

import 'support/room_lifecycle_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Engine engine;
  late RoomAgoraManager manager;
  setUp(() {
    engine = _Engine();
    manager = RoomAgoraManager.forTesting(
      engineFactory: () => engine,
      authSession: FakeRoomAuth(),
    );
  });
  tearDown(() async {
    await manager.release();
    manager.dispose();
  });
  Future<void> join() => manager.joinRoom(
    roomId: 'first',
    token: 'test',
    uid: 10,
    appId: 'test-app',
  );

  test(
    'role reset failure still leaves the channel and clears all room state',
    () async {
      await join();
      await manager.muteMicrophone(true);
      await manager.muteSpeaker(true);
      engine.failRole = true;
      await manager.leaveRoom();
      expect(engine.leaveCalls, 1);
      expect(manager.state.joined, isFalse);
      expect(manager.state.joining, isFalse);
      expect(manager.state.roomId, isNull);
      expect(manager.state.publishing, isFalse);
      expect(manager.state.mutedMicrophone, isFalse);
      expect(manager.state.mutedSpeaker, isFalse);
      expect(manager.state.volumeLevels, isEmpty);
      expect(manager.state.errorMessage, isNull);
    },
  );

  test(
    'channel leave failure still releases engine; global manager can join again',
    () async {
      await join();
      engine.failLeave = true;
      await manager.leaveRoom();
      expect(engine.releaseCalls, 1);
      expect(manager.state.initialized, isFalse);
      expect(manager.state.roomId, isNull);
      engine.failLeave = false;
      await join();
      expect(engine.initializeCalls, 2);
      expect(manager.state.joined, isTrue);
    },
  );

  test(
    'late join/volume/publish callbacks cannot revive the exited room',
    () async {
      await join();
      final handler = engine.handler!;
      await manager.leaveRoom();
      handler.onJoinChannelSuccess!(
        const RtcConnection(channelId: 'first', localUid: 10),
        0,
      );
      handler.onAudioPublishStateChanged!(
        'first',
        StreamPublishState.pubStateIdle,
        StreamPublishState.pubStatePublished,
        0,
      );
      handler.onAudioVolumeIndication!(
        const RtcConnection(channelId: 'first', localUid: 10),
        const [AudioVolumeInfo(uid: 10, volume: 90)],
        1,
        90,
      );
      await Future<void>.delayed(Duration.zero);
      expect(manager.state.joined, isFalse);
      expect(manager.state.publishing, isFalse);
      expect(manager.state.roomId, isNull);
      expect(manager.state.volumeLevels, isEmpty);
    },
  );

  test(
    'recoverable connection loss is kept but server ban is terminal',
    () async {
      await join();
      final callback = engine.handler!.onConnectionStateChanged!;
      const connection = RtcConnection(channelId: 'first', localUid: 10);
      callback(
        connection,
        ConnectionStateType.connectionStateReconnecting,
        ConnectionChangedReasonType.connectionChangedLost,
      );
      expect(manager.state.isTerminal, isFalse);
      callback(
        connection,
        ConnectionStateType.connectionStateFailed,
        ConnectionChangedReasonType.connectionChangedBannedByServer,
      );
      expect(manager.state.isTerminal, isTrue);
    },
  );
}

class _Engine implements RtcEngine {
  RtcEngineEventHandler? handler;
  bool failLeave = false;
  bool failRole = false;
  int leaveCalls = 0;
  int releaseCalls = 0;
  int initializeCalls = 0;
  @override
  void registerEventHandler(RtcEngineEventHandler eventHandler) =>
      handler = eventHandler;
  @override
  Future<void> initialize(RtcEngineContext context) async => initializeCalls++;
  @override
  Future<void> setClientRole({
    required ClientRoleType role,
    ClientRoleOptions? options,
  }) async {
    if (failRole) throw StateError('role change failed');
  }

  @override
  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
    required ChannelMediaOptions options,
  }) async {
    handler!.onJoinChannelSuccess!(
      RtcConnection(channelId: channelId, localUid: uid),
      0,
    );
  }

  @override
  Future<void> leaveChannel({LeaveChannelOptions? options}) async {
    leaveCalls++;
    if (failLeave) throw StateError('leave failed');
  }

  @override
  Future<void> release({bool sync = false}) async => releaseCalls++;
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}
