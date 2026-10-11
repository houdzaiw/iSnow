import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/manager/room_background_audio_manager.dart';

import 'support/room_lifecycle_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'duplicate starts coalesce; background and Keep do not stop audio',
    () async {
      final calls = <String>[];
      final audio = RoomBackgroundAudioManager.forTesting(
        start: (microphone) async {
          calls.add('start:$microphone');
          return microphone;
        },
        stop: () async => calls.add('stop'),
        foreground: () => true,
      );
      final fixture = RoomLifecycleFixture(backgroundAudio: audio);
      addTearDown(fixture.dispose);
      await fixture.enter();
      await audio.start(useMicrophone: false);
      fixture.manager.minimizeRoom();
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      await audio.start(useMicrophone: false);
      expect(calls, ['start:false']);
      expect(fixture.manager.isInRoom, isTrue);
      expect(fixture.manager.isMinimized, isTrue);
      fixture.manager.restoreRoom();
      await fixture.manager.leaveRoom();
      expect(calls, ['start:false', 'stop']);
      await fixture.manager.leaveRoom();
      expect(calls, ['start:false', 'stop']);
    },
  );

  test(
    'Exit waits for a pending start then stops it without restart',
    () async {
      final calls = <String>[];
      final gate = Completer<bool>();
      final audio = RoomBackgroundAudioManager.forTesting(
        start: (microphone) {
          calls.add('start:$microphone');
          return gate.future;
        },
        stop: () async => calls.add('stop'),
        foreground: () => true,
      );
      final starting = audio.start(useMicrophone: true);
      await Future<void>.delayed(Duration.zero);
      final stopping = audio.stop();
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      gate.complete(true);
      await starting;
      await stopping;
      expect(calls, ['start:true', 'stop']);
    },
  );

  test(
    'a background start is deferred until foreground; role changes sync',
    () async {
      var foreground = false;
      final calls = <String>[];
      final audio = RoomBackgroundAudioManager.forTesting(
        start: (microphone) async {
          calls.add('start:$microphone');
          return microphone;
        },
        stop: () async => calls.add('stop'),
        foreground: () => foreground,
      );
      await audio.start(useMicrophone: false);
      expect(calls, isEmpty);
      foreground = true;
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await audio.start(useMicrophone: false);
      await audio.start(useMicrophone: true);
      foreground = false;
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      await audio.start(useMicrophone: true);
      expect(calls, ['start:false', 'start:true']);
      await audio.stop();
      expect(calls.last, 'stop');
    },
  );

  test(
    'failed start is retriable and Exit still attempts native stop',
    () async {
      var failed = true;
      final calls = <String>[];
      final audio = RoomBackgroundAudioManager.forTesting(
        start: (microphone) async {
          calls.add('start');
          if (failed) throw StateError('Android foreground restriction');
          return microphone;
        },
        stop: () async => calls.add('stop'),
        foreground: () => true,
      );
      await audio.start(useMicrophone: false);
      failed = false;
      await audio.start(useMicrophone: false);
      await audio.stop();
      expect(calls, ['start', 'start', 'stop']);
    },
  );

  test('native stop error cannot prevent room cleanup', () async {
    final audio = RoomBackgroundAudioManager.forTesting(
      start: (microphone) async => microphone,
      stop: () async => throw StateError('native stop failed'),
      foreground: () => true,
    );
    final fixture = RoomLifecycleFixture(backgroundAudio: audio);
    addTearDown(fixture.dispose);
    await fixture.enter();
    await audio.start(useMicrophone: false);
    await fixture.manager.leaveRoom();
    expect(fixture.manager.isInRoom, isFalse);
    expect(fixture.manager.currentRoomId, isEmpty);
  });
}
