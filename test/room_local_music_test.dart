import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/classes/room/music/room_local_music_track.dart';
import 'package:project/classes/room/music/room_local_music_view_model.dart';
import 'package:project/classes/room/music/room_music_track.dart';
import 'package:project/classes/room/music/room_music_view_model.dart';
import 'package:project/manager/room_music_library.dart';

import 'support/room_local_music_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomLocalMusicFixture fixture;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fixture = RoomLocalMusicFixture();
    await fixture.initialize();
  });
  tearDown(() => fixture.dispose());

  RoomLocalMusicViewModel model() {
    final value = RoomLocalMusicViewModel(
      repository: fixture.room.music,
      roomId: 'canonical',
    );
    addTearDown(() {
      if (value.mounted) value.dispose();
    });
    return value;
  }

  test(
    'scan uses permission and metadata only, never exports or plays',
    () async {
      await fixture.addSource('Artist - SONG.M4A');
      final result = await fixture.room.music.scanLocalTracks(
        requestPermission: true,
      );
      expect(result.permission, RoomMusicPermission.granted);
      expect(result.tracks.single.duration, 123000);
      expect(result.tracks.single.location, 'Music/Album/');
      expect(fixture.minBytes, 102400);
      expect(fixture.permissionRequests, 1);
      expect(fixture.exports, 0);
      expect(fixture.room.http.opens, isEmpty);
    },
  );

  for (final status in ['denied', 'permanentlyDenied']) {
    test(
      '$status is distinct from an empty catalog and does not query MediaStore',
      () async {
        fixture.permission = status;
        final vm = model();
        await fixture.flush();
        expect(vm.state.permission.name, status);
        expect(vm.state.scanning, isFalse);
        expect(vm.state.errorKey, isNull);
        expect(fixture.scans, 0);
      },
    );
  }

  test(
    'return from settings checks permission and rescans once without prompting',
    () async {
      fixture.permission = 'permanentlyDenied';
      final vm = model();
      await fixture.flush();
      await vm.openSettings();
      expect(fixture.settingsCalls, 1);
      fixture.permission = 'granted';
      await fixture.addSource('Song.ogg');
      vm.onResumed();
      await fixture.flush();
      vm.onResumed();
      await fixture.flush();
      expect(vm.state.tracks.length, 1);
      expect(fixture.permissionRequests, 1);
      expect(fixture.scans, 1);
    },
  );

  test('failed scan is retryable, not an empty catalog', () async {
    fixture.failScan = true;
    final vm = model();
    await fixture.flush();
    expect(vm.state.errorKey, 'room.music.scanFailed');
    fixture.failScan = false;
    await vm.scan();
    expect(vm.state.errorKey, isNull);
    expect(vm.state.tracks, isEmpty);
    expect(vm.state.permission, RoomMusicPermission.granted);
  });

  test(
    'search ignores case, keeps selection, and refresh reconciles deleted IDs',
    () async {
      await fixture.addSource('ALPHA.mp3');
      await fixture.addSource('Beta.flac', seed: 2);
      final vm = model();
      await fixture.flush();
      vm.select(vm.state.tracks.first.id);
      vm.search(' beta ');
      expect(vm.state.visibleTracks.single.name, 'Beta.flac');
      vm.select(vm.state.visibleTracks.single.id);
      vm.search('missing');
      expect(vm.state.visibleTracks, isEmpty);
      expect(vm.state.selectedIds.length, 2);
      fixture.rows.removeAt(0);
      await vm.scan();
      expect(vm.state.selectedIds.length, 1);
      vm.search('');
      expect(vm.state.visibleTracks.single.name, 'Beta.flac');
    },
  );

  test(
    'URI import persists sandbox copies, duration, and no automatic playback',
    () async {
      await fixture.addSource('song.m4a');
      final vm = model();
      await fixture.flush();
      vm.select(vm.state.tracks.single.id);
      await vm.addSelected();
      expect(vm.state.completed, isTrue);
      expect(fixture.room.music.tracks.single.duration, 123000);
      expect(fixture.room.engine.starts, isEmpty);
      expect(fixture.room.http.opens, isEmpty);
      final library = RoomMusicLibrary(
        directory: () async => fixture.room.directory,
      );
      final tracks = await library.load(10);
      expect(tracks.single.name, 'song.m4a');
      for (final file in fixture.temporaryFiles) {
        expect(await File(file).exists(), isFalse);
      }
      await fixture.sources.values.single.delete();
      expect(
        await File(await library.path(10, tracks.single)).exists(),
        isTrue,
      );
      await fixture.room.music.play('canonical', tracks.single);
      expect(fixture.room.engine.starts.length, 1);
    },
  );

  test(
    'duplicates by content, including different extensions, leave one stored copy',
    () async {
      await fixture.addSource('same.mp3');
      await fixture.addSource('same.m4a');
      final scan = await fixture.room.music.scanLocalTracks();
      final result = await fixture.room.music.addLocalTracks(scan.tracks);
      expect(result.addedCount, 1);
      expect(result.importedCount, 2);
      expect(fixture.room.music.tracks.length, 1);
      final folder = Directory('${fixture.room.directory.path}/room_music/10');
      expect(await folder.list().length, 1);
      await fixture.room.music.addLocalTracks(scan.tracks);
      expect(await folder.list().length, 1);
      expect(fixture.room.music.tracks.length, 1);
    },
  );

  test(
    'one unreadable song preserves other songs and reports partial failure',
    () async {
      await fixture.addSource('missing.mp3');
      await fixture.addSource('readable.ogg', seed: 2);
      fixture.failures.add(fixture.rows.first['uri'] as String);
      final vm = model();
      await fixture.flush();
      for (final track in vm.state.tracks) {
        vm.select(track.id);
      }
      await vm.addSelected();
      expect(fixture.room.music.tracks.single.name, 'readable.ogg');
      expect(vm.state.failedCount, 1);
      expect(vm.state.errorKey, 'room.music.importPartial');
      expect(vm.state.completed, isFalse);
    },
  );

  test('repeated add clicks share a single import', () async {
    await fixture.addSource('one.mp3');
    final tracks = (await fixture.room.music.scanLocalTracks()).tracks;
    fixture.exportGate = Completer<void>();
    final first = fixture.room.music.addLocalTracks(tracks);
    final second = fixture.room.music.addLocalTracks(tracks);
    expect(identical(first, second), isTrue);
    await fixture.flush();
    fixture.exportGate!.complete();
    await first;
    await second;
    expect(fixture.exports, 1);
    expect(fixture.room.music.tracks.length, 1);
  });

  for (final cancellation in ['dismiss', 'exit', 'logout']) {
    test('$cancellation during export cannot commit late results', () async {
      await fixture.addSource('late.mp3');
      final vm = model();
      await fixture.flush();
      vm.select(vm.state.tracks.single.id);
      fixture.exportGate = Completer<void>();
      final adding = vm.addSelected();
      await fixture.flush();
      expect(fixture.exports, 1);
      switch (cancellation) {
        case 'dismiss':
          vm.dispose();
        case 'exit':
          await fixture.room.manager.leaveRoom();
        case 'logout':
          await fixture.room.auth.clear();
      }
      fixture.exportGate!.complete();
      await adding;
      expect(fixture.room.music.tracks, isEmpty);
      expect(await fixture.room.library.load(10), isEmpty);
      for (final file in fixture.temporaryFiles) {
        expect(await File(file).exists(), isFalse);
      }
    });
  }

  test('closing while scanning cannot mutate disposed state', () async {
    fixture.scanGate = Completer<void>();
    final vm = model();
    await fixture.flush();
    vm.dispose();
    fixture.scanGate!.complete();
    await fixture.flush();
    expect(fixture.exports, 0);
  });

  test(
    'account switch during import cannot populate either account library',
    () async {
      await fixture.addSource('late.mp3');
      final tracks = (await fixture.room.music.scanLocalTracks()).tracks;
      fixture.exportGate = Completer<void>();
      final adding = fixture.room.music.addLocalTracks(tracks);
      await fixture.flush();
      fixture.room.auth.currentUid = 20;
      fixture.room.auth.notifyListeners();
      await fixture.flush();
      fixture.exportGate!.complete();
      final result = await adding;
      expect(result.cancelled, isTrue);
      expect(await fixture.room.library.load(10), isEmpty);
      expect(await fixture.room.library.load(20), isEmpty);
      expect(fixture.room.music.tracks, isEmpty);
    },
  );

  test(
    'cancel after a completed copy discards new unreferenced files',
    () async {
      await fixture.addSource('first.mp3');
      await fixture.addSource('second.m4a', seed: 2);
      final vm = model();
      await fixture.flush();
      for (final track in vm.state.tracks) {
        vm.select(track.id);
      }
      final gate = Completer<void>();
      final handler = fixture.room.library;
      // Pause the second export after the first sandbox copy has completed.
      fixture.exportGates[2] = gate;
      final adding = vm.addSelected();
      for (var i = 0; i < 200 && fixture.exports < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(fixture.exports, 2);
      vm.dispose();
      gate.complete();
      await adding;
      expect(await handler.load(10), isEmpty);
      final folder = Directory('${fixture.room.directory.path}/room_music/10');
      expect(await folder.list().length, 0);
    },
  );

  test('legacy JSON without duration still loads', () {
    final value = RoomMusicTrack.fromJson({
      'id': 'legacy',
      'name': 'Old.mp3',
      'fileName': '${'a' * 64}.mp3',
    });
    expect(value.duration, 0);
    expect(RoomMusicTrack.fromJson(value.toJson()).duration, 0);
  });

  test(
    'player search plays by real track and does not change full-list next',
    () async {
      await fixture.room.import(3);
      final vm = RoomMusicViewModel(
        repository: fixture.room.music,
        roomId: 'canonical',
      );
      addTearDown(vm.dispose);
      await fixture.flush();
      vm.search('MUSIC-1');
      expect(vm.state.tracks.single.name, 'music-1.mp3');
      expect(vm.state.totalTracks, 3);
      await vm.play(vm.state.tracks.single);
      expect(fixture.room.agora.state.music.title, 'music-1.mp3');
      await vm.next();
      expect(fixture.room.agora.state.music.title, 'music-2.mp3');
      vm.search('missing');
      expect(vm.state.tracks, isEmpty);
      expect(vm.state.totalTracks, 3);
    },
  );
}
