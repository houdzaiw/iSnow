import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/configs/app_enum.dart';
import 'package:project/manager/room_agora_manager.dart';

import 'support/room_lifecycle_fakes.dart';
import 'support/room_microphone_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomMicrophoneEngine engine;
  late RoomAgoraManager manager;
  setUp(() {
    engine = RoomMicrophoneEngine();
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
    token: 'test-token',
    uid: 10,
    appId: 'test-app',
  );

  test('environments use Nady App IDs unless a build override is supplied', () {
    const override = String.fromEnvironment('AGORA_APPID');
    expect(
      AppEnv.dev.agoraAppId,
      override.isNotEmpty ? override : 'd5167c704aa4448c867a77f5989fdc66',
    );
    expect(AppEnv.qa.agoraAppId, AppEnv.dev.agoraAppId);
    expect(
      AppEnv.product.agoraAppId,
      override.isNotEmpty ? override : 'f4dffe3fe2564e50b4cd897a9aa9a781',
    );
  });

  test(
    'up mic enables the track; mute only affects recording, not music',
    () async {
      await join();
      expect(engine.mediaOptions.single.publishMicrophoneTrack, isFalse);
      await manager.publish(position: 0);
      expect(engine.mediaOptions.last.publishMicrophoneTrack, isTrue);
      expect(engine.roles.last, ClientRoleType.clientRoleBroadcaster);
      expect(manager.state.publishing, isTrue);

      await manager.muteMicrophone(true);
      expect(manager.state.mutedMicrophone, isTrue);
      expect(engine.recordingMutes.last, isTrue);
      expect(manager.state.publishing, isTrue);
      await manager.muteMicrophone(false);
      expect(manager.state.mutedMicrophone, isFalse);
      expect(engine.recordingMutes, [false, true, false]);
      expect(engine.streamMutes, everyElement(isFalse));
      expect(engine.mediaOptions.last.publishMicrophoneTrack, isTrue);
    },
  );

  test(
    'down/up mic preserves the preference; Exit clears it on the engine',
    () async {
      await join();
      await manager.publish();
      await manager.muteMicrophone(true);
      await manager.stopPublish();
      expect(engine.mediaOptions.last.publishMicrophoneTrack, isFalse);
      expect(manager.state.publishing, isFalse);
      expect(manager.state.mutedMicrophone, isTrue);
      await manager.publish();
      expect(engine.recordingMutes.last, isTrue);
      expect(engine.mediaOptions.last.publishMicrophoneTrack, isTrue);
      await manager.leaveRoom();
      expect(engine.recordingMutes.last, isFalse);
      expect(manager.state.mutedMicrophone, isFalse);
      await join();
      await manager.publish();
      expect(engine.recordingMutes.last, isFalse);
    },
  );

  test('publication waits for the actual SDK join callback', () async {
    engine.autoJoin = false;
    await join();
    final publishing = manager.publish();
    await Future<void>.delayed(Duration.zero);
    expect(manager.state.joining, isTrue);
    expect(engine.mediaOptions, hasLength(1));
    expect(manager.state.publishing, isFalse);
    engine.completeJoin();
    await publishing;
    expect(manager.state.publishing, isTrue);
    expect(engine.mediaOptions.last.publishMicrophoneTrack, isTrue);
  });

  test('mute waits for SDK join and Exit cancels the wait', () async {
    engine.autoJoin = false;
    await join();
    final muting = manager.muteMicrophone(true);
    await Future<void>.delayed(Duration.zero);
    expect(engine.recordingMutes, isEmpty);
    engine.completeJoin();
    await muting;
    expect(manager.state.mutedMicrophone, isTrue);
    await manager.leaveRoom();
    await join();
    final cancelledMute = manager.muteMicrophone(true);
    await Future<void>.delayed(Duration.zero);
    await manager.leaveRoom();
    await cancelledMute;
    expect(manager.state.mutedMicrophone, isFalse);
    expect(manager.state.roomId, isNull);
  });

  test('SDK errors do not falsely flip the microphone state', () async {
    await join();
    engine.failMicrophone = true;
    await expectLater(manager.muteMicrophone(true), throwsStateError);
    expect(manager.state.mutedMicrophone, isFalse);
    expect(manager.state.errorMessage, contains('recording mute failed'));
    engine.failMicrophone = false;
    await manager.muteMicrophone(true);
    expect(manager.state.mutedMicrophone, isTrue);
    expect(manager.state.errorMessage, isNull);
  });

  test(
    'failed track publication is reported rather than marked successful',
    () async {
      await join();
      engine.failMediaOptions = true;
      await expectLater(manager.publish(), throwsStateError);
      expect(manager.state.publishing, isFalse);
      expect(manager.state.errorMessage, contains('track update failed'));
    },
  );

  test(
    'missing initialization reports an error instead of silently returning',
    () async {
      await manager.joinRoom(
        roomId: 'first',
        token: 'test',
        uid: 10,
        appId: '',
      );
      await expectLater(manager.muteMicrophone(true), throwsStateError);
      expect(manager.state.errorMessage, 'Missing Agora app id');
      expect(manager.state.mutedMicrophone, isFalse);
    },
  );

  test(
    'a late mute cannot update a rejoined channel with the same room ID',
    () async {
      await join();
      final gate = Completer<void>();
      engine.microphoneGate = gate;
      final muting = manager.muteMicrophone(true);
      await Future<void>.delayed(Duration.zero);
      await manager.leaveRoom();
      await join();
      engine.microphoneGate = null;
      gate.complete();
      await muting;
      expect(manager.state.joined, isTrue);
      expect(manager.state.mutedMicrophone, isFalse);
    },
  );

  test('failed initialization can be retried after leaving the room', () async {
    engine.failInitialize = true;
    await join();
    expect(manager.state.initialized, isFalse);
    await manager.leaveRoom();
    expect(manager.state.initialized, isFalse);
    engine.failInitialize = false;
    await join();
    await manager.muteMicrophone(true);
    expect(manager.state.joined, isTrue);
    expect(manager.state.mutedMicrophone, isTrue);
  });

  testWidgets(
    'missing SDK join callback times out instead of hanging the toggle',
    (tester) async {
      engine.autoJoin = false;
      await join();
      final failure = expectLater(
        manager.muteMicrophone(true),
        throwsStateError,
      );
      await tester.pump(const Duration(seconds: 15));
      await failure;
      expect(manager.state.mutedMicrophone, isFalse);
      expect(manager.state.errorMessage, contains('has not connected yet'));
    },
  );
}
