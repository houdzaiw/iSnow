import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/classes/room/music/room_local_music_view_model.dart';
import 'package:project/classes/room/music/room_music_repository.dart';
import 'package:project/classes/room/music/room_music_track.dart';
import 'package:project/manager/room_local_music_manager.dart';
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

  test(
    'file picker partial failure keeps valid files and shares URI deduplication',
    () async {
      await fixture.addSource('song.M4A');
      fixture.room.pickedFiles = [
        PlatformFile(
          name: 'bad.exe',
          size: 4,
          path: fixture.sources.values.single.path,
        ),
        PlatformFile(
          name: 'missing.mp3',
          size: 4,
          path: '${fixture.room.directory.path}/missing',
        ),
        PlatformFile(
          name: 'song.M4A',
          size: 4,
          path: fixture.sources.values.single.path,
        ),
      ];
      final result = await fixture.room.music.addAudio();
      expect(result.addedCount, 1);
      expect(result.failedCount, 2);
      final tracks = (await fixture.room.music.scanLocalTracks()).tracks;
      expect((await fixture.room.music.addLocalTracks(tracks)).addedCount, 0);
      expect(fixture.room.music.tracks.length, 1);
      expect(await fixture.sources.values.single.exists(), isTrue);
      expect(fixture.room.engine.starts, isEmpty);
    },
  );

  test(
    'all unreadable songs show failure without claiming others were saved',
    () async {
      await fixture.addSource('missing.mp3');
      fixture.failures.add(fixture.rows.single['uri'] as String);
      final vm = RoomLocalMusicViewModel(
        repository: fixture.room.music,
        roomId: 'canonical',
      );
      addTearDown(vm.dispose);
      await fixture.flush();
      vm.select(vm.state.tracks.single.id);
      await vm.addSelected();
      expect(vm.state.errorKey, 'room.music.importFailed');
      expect(vm.state.completed, isFalse);
      expect(fixture.room.music.tracks, isEmpty);
    },
  );

  test(
    'failed persistence rolls back new copies and allows a clean retry',
    () async {
      await fixture.addSource('song.flac');
      final library = _FailingLibrary(fixture.room.directory);
      final repository = RoomMusicRepository(
        room: fixture.room.room,
        library: library,
        localMusic: RoomLocalMusicManager(supported: true),
      );
      addTearDown(repository.dispose);
      await repository.load();
      final tracks = (await repository.scanLocalTracks()).tracks;
      await expectLater(repository.addLocalTracks(tracks), throwsStateError);
      expect(repository.tracks, isEmpty);
      expect(await library.load(10), isEmpty);
      final folder = Directory('${fixture.room.directory.path}/room_music/10');
      expect(await folder.list().length, 0);
      library.fail = false;
      final result = await repository.addLocalTracks(tracks);
      expect(result.addedCount, 1);
      expect((await library.load(10)).single.name, 'song.flac');
      for (final path in fixture.temporaryFiles) {
        expect(await File(path).exists(), isFalse);
      }
    },
  );
}

class _FailingLibrary extends RoomMusicLibrary {
  _FailingLibrary(Directory directory)
    : super(directory: () async => directory);
  bool fail = true;

  @override
  Future<void> save(int uid, List<RoomMusicTrack> tracks) async {
    if (fail) throw StateError('Storage unavailable');
    await super.save(uid, tracks);
  }
}
