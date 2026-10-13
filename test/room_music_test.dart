import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/room/music/room_music_repository.dart';
import 'package:project/classes/room/music/room_music_sheet.dart';
import 'package:project/classes/room/music/room_music_track.dart';
import 'package:project/classes/room/music/room_music_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/room_music_library.dart';
import 'package:project/model/room_music_state.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/server_response.dart';

import 'support/room_music_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomMusicFixture fixture;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fixture = RoomMusicFixture();
    await fixture.initialize();
  });
  tearDown(() => fixture.dispose());

  test(
    'shared playback publishes mixing and preserves muted recording',
    () async {
      await fixture.agora.muteMicrophone(true);
      await fixture.import();
      await fixture.music.play('canonical', fixture.music.tracks.first);
      expect(fixture.http.opens.single, {'roomId': 'canonical', 'opType': 1});
      expect(fixture.engine.loopbacks.single, isFalse);
      expect(fixture.engine.cycles.single, 1);
      expect(fixture.engine.recordingMutes.last, isTrue);
      expect(fixture.engine.streamMutes, everyElement(isFalse));
      expect(fixture.agora.state.music.status, RoomMusicPlayback.playing);
      expect(fixture.agora.state.publishing, isTrue);
    },
  );

  test('SDK callback, not start invocation, acknowledges playback', () async {
    fixture.engine.acknowledgeStart = false;
    await fixture.import();
    await fixture.music.play('canonical', fixture.music.tracks.first);
    expect(fixture.agora.state.music.status, RoomMusicPlayback.preparing);
    fixture.engine.musicState(AudioMixingStateType.audioMixingStatePlaying);
    expect(fixture.agora.state.music.status, RoomMusicPlayback.playing);
  });

  test('pause, resume, seek, local and publish volume match Agora', () async {
    await fixture.import();
    await fixture.music.play('canonical', fixture.music.tracks.first);
    await fixture.music.toggle('canonical');
    expect(fixture.agora.state.music.status, RoomMusicPlayback.paused);
    await fixture.music.toggle('canonical');
    expect(fixture.engine.resumes, 1);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(fixture.agora.state.music.duration, 60000);
    expect(fixture.agora.state.music.position, 2000);
    await fixture.music.seek('canonical', 10000);
    expect(fixture.engine.seeks.single, 10000);
    await fixture.music.volume('canonical', 73);
    expect(fixture.engine.volumes.last, 73);
    expect(fixture.engine.publishVolumes.last, 73);
  });

  test(
    '4062 requires confirmation; cancellation never forces takeover',
    () async {
      await fixture.import();
      fixture.http.openCode = 4062;
      final model = RoomMusicViewModel(
        repository: fixture.music,
        roomId: 'canonical',
      );
      addTearDown(model.dispose);
      await fixture.flush();
      await model.play(fixture.music.tracks.first);
      RoomMusicSheetState? state;
      model.addListener((value) => state = value);
      expect(state!.takeover, isTrue);
      expect(fixture.engine.starts, isEmpty);
      await model.confirmTakeover(false);
      expect(fixture.http.opens.length, 1);
      await model.play(fixture.music.tracks.first);
      fixture.http.openCode = 200;
      await model.confirmTakeover(true);
      expect(fixture.http.opens.last['opType'], 2);
      expect(fixture.engine.starts.length, 1);
    },
  );

  test('not on mic never opens a player or publishes', () async {
    await fixture.import();
    fixture.micUpdate([20]);
    await expectLater(
      fixture.music.play('canonical', fixture.music.tracks.first),
      throwsA(isA<NadyApiException>()),
    );
    expect(fixture.http.opens, isEmpty);
    expect(fixture.engine.starts, isEmpty);
  });

  test(
    'owner pushes Nady playback statuses; takeover never announces stopped for the new owner',
    () async {
      fixture.http.roomOwnerUid = 10;
      await fixture.manager.refreshRoomInfo();
      await fixture.import();
      await fixture.music.play('canonical', fixture.music.tracks.first);
      await fixture.music.toggle('canonical');
      await fixture.music.toggle('canonical');
      await fixture.flush();
      expect(fixture.http.statuses, ['playing', 'paused', 'playing']);
      fixture.socket.controller.add(
        const RoomSocketMessage(
          channel: 'global:10',
          event: 'RoomClosePlayerEvent',
          raw: {},
        ),
      );
      await fixture.flush();
      expect(fixture.http.statuses, ['playing', 'paused', 'playing']);
      expect(fixture.http.closes, isEmpty);
    },
  );

  test(
    'Keep and sheet disposal preserve music; Exit stops and closes',
    () async {
      await fixture.import();
      final model = RoomMusicViewModel(
        repository: fixture.music,
        roomId: 'canonical',
      );
      await fixture.flush();
      await model.play(fixture.music.tracks.first);
      model.dispose();
      fixture.manager.minimizeRoom();
      expect(fixture.agora.state.music.status, RoomMusicPlayback.playing);
      expect(fixture.engine.stops, 0);
      fixture.manager.restoreRoom();
      expect(fixture.agora.state.music.title, 'music-0.mp3');
      await fixture.manager.leaveRoom();
      expect(fixture.engine.stops, 1);
      expect(fixture.http.closes, ['canonical']);
      expect(fixture.agora.state.music.path, isNull);
    },
  );

  test(
    'Exit drains pending open; late successful lease is closed without playback',
    () async {
      await fixture.import();
      final gate = Completer<void>();
      fixture.http.openGate = gate;
      final playing = fixture.music.play(
        'canonical',
        fixture.music.tracks.first,
      );
      final failed = expectLater(playing, throwsA(isA<NadyApiException>()));
      await _until(() => fixture.http.opens.isNotEmpty);
      final leaving = fixture.manager.leaveRoom();
      gate.complete();
      await failed;
      await leaving;
      expect(fixture.http.closes, ['canonical']);
      expect(fixture.engine.starts, isEmpty);
    },
  );

  test(
    'Exit during SDK start drains mixing then ignores late callback',
    () async {
      await fixture.import();
      final gate = Completer<void>();
      fixture.engine.startGate = gate;
      final playing = fixture.music.play(
        'canonical',
        fixture.music.tracks.first,
      );
      await _until(() => fixture.engine.starts.isNotEmpty);
      final leaving = fixture.manager.leaveRoom();
      gate.complete();
      await playing;
      await leaving;
      fixture.engine.musicState(AudioMixingStateType.audioMixingStatePlaying);
      expect(fixture.engine.stops, 1);
      expect(fixture.agora.state.music.status, RoomMusicPlayback.stopped);
    },
  );

  test(
    'down mic and remote mic removal stop music and close the lease',
    () async {
      await fixture.import();
      await fixture.music.play('canonical', fixture.music.tracks.first);
      fixture.micUpdate([20]);
      await fixture.flush();
      expect(fixture.engine.stops, 1);
      expect(fixture.http.closes, ['canonical']);
    },
  );

  test(
    'targeted takeover stops locally without closing another player',
    () async {
      await fixture.import();
      await fixture.music.play('canonical', fixture.music.tracks.first);
      fixture.socket.controller.add(
        const RoomSocketMessage(
          channel: 'global:20',
          event: 'RoomClosePlayerEvent',
          raw: {},
        ),
      );
      await fixture.flush();
      expect(fixture.engine.stops, 0);
      fixture.socket.controller.add(
        const RoomSocketMessage(
          channel: 'global:10',
          event: 'RoomClosePlayerEvent',
          raw: {},
        ),
      );
      await fixture.flush();
      expect(fixture.engine.stops, 1);
      expect(fixture.http.closes, isEmpty);
    },
  );

  test('SDK failure closes lease and exposes a useful error', () async {
    await fixture.import();
    fixture.engine.failStart = true;
    await expectLater(
      fixture.music.play('canonical', fixture.music.tracks.first),
      throwsStateError,
    );
    await fixture.flush();
    expect(fixture.http.closes, ['canonical']);
    expect(fixture.music.automaticError, contains('start failed'));
  });

  test('music stop failure on server cannot block leaving the room', () async {
    await fixture.import();
    await fixture.music.play('canonical', fixture.music.tracks.first);
    fixture.http.failClose = true;
    await fixture.manager.leaveRoom();
    expect(fixture.manager.state.isInRoom, isFalse);
    expect(fixture.agora.state.joined, isFalse);
  });

  test(
    'library persists sandbox copies and deduplicates by file contents',
    () async {
      await fixture.import();
      await fixture.music.addAudio();
      expect(fixture.music.tracks.length, 1);
      final reloaded = RoomMusicLibrary(
        directory: () async => fixture.directory,
      );
      expect((await reloaded.load(10)).single.name, 'music-0.mp3');
      expect(await reloaded.load(20), isEmpty);
      final file = File(await reloaded.path(10, fixture.music.tracks.single));
      expect(await file.exists(), isTrue);
      await fixture.music.load();
      expect(fixture.pickerCalls, 2);
      await fixture.music.play('canonical', fixture.music.tracks.single);
      await fixture.music.remove(fixture.music.tracks.single);
      expect(fixture.engine.stops, 1);
      expect(await file.exists(), isFalse);
      expect(await reloaded.load(10), isEmpty);
    },
  );

  test('cancelled picker leaves the library untouched', () async {
    await fixture.music.addAudio();
    expect(fixture.music.tracks, isEmpty);
    expect(fixture.http.opens, isEmpty);
  });

  test(
    'a delayed filesystem result cannot start in a reentered same-ID room',
    () async {
      await fixture.import();
      final library = _DelayedLibrary(fixture.directory);
      final repository = RoomMusicRepository(
        room: fixture.room,
        library: library,
      );
      addTearDown(repository.dispose);
      await repository.load();
      final gate = Completer<void>();
      library.gate = gate;
      final playing = repository.play('canonical', repository.tracks.single);
      final failure = expectLater(playing, throwsA(isA<NadyApiException>()));
      await fixture.manager.leaveRoom();
      await fixture.manager.enterRoom(
        roomId: 'visible',
        agoraAppId: 'test-app',
      );
      await fixture.flush();
      gate.complete();
      await failure;
      expect(fixture.engine.starts, isEmpty);
    },
  );

  test('delayed stop callback cannot stop the replacement track', () async {
    await fixture.import(2);
    await fixture.music.play('canonical', fixture.music.tracks.first);
    await fixture.music.play('canonical', fixture.music.tracks.last);
    fixture.engine.musicState(
      AudioMixingStateType.audioMixingStateStopped,
      reason: AudioMixingReasonType.audioMixingReasonStoppedByUser,
    );
    expect(fixture.agora.state.music.status, RoomMusicPlayback.playing);
    expect(fixture.agora.state.music.title, 'music-1.mp3');
  });

  test('completion advances playlist even when sheet is absent', () async {
    await fixture.import(2);
    await fixture.music.play('canonical', fixture.music.tracks.first);
    fixture.engine.musicState(
      AudioMixingStateType.audioMixingStateStopped,
      reason: AudioMixingReasonType.audioMixingReasonAllLoopsCompleted,
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(fixture.engine.starts.length, 2);
    expect(fixture.agora.state.music.title, 'music-1.mp3');
    expect(fixture.http.opens.length, 1);
    fixture.music.changeMode(RoomMusicMode.single);
    fixture.engine.musicState(
      AudioMixingStateType.audioMixingStateStopped,
      reason: AudioMixingReasonType.audioMixingReasonAllLoopsCompleted,
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(fixture.agora.state.music.title, 'music-1.mp3');
  });

  for (final width in [320.0, 375.0]) {
    testWidgets('music sheet at $width is full width and fits small screens', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() => fixture.import(2));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomMusicRepositoryProvider.overrideWithValue(fixture.music),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: const [AppLocalizations.delegate],
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showRoomMusicSheet(context, 'canonical'),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('room-music-sheet'))).width,
        width,
      );
      expect(find.text('music-0.mp3'), findsOneWidget);
      await tester.tap(find.text('Single'));
      await tester.pumpAndSettle();
      expect(fixture.music.mode, RoomMusicMode.single);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

Future<void> _until(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}

class _DelayedLibrary extends RoomMusicLibrary {
  _DelayedLibrary(Directory directory)
    : super(directory: () async => directory);
  Completer<void>? gate;
  @override
  Future<String> path(int uid, RoomMusicTrack track) async {
    await gate?.future;
    return super.path(uid, track);
  }
}
