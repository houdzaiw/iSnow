import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/room/music/room_music_view_model.dart';
import 'package:project/manager/room_system_volume_manager.dart';
import 'package:project/model/room_music_state.dart';
import 'package:project/model/room_socket_message.dart';

import 'support/room_music_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomMusicFixture fixture;
  final models = <RoomMusicViewModel>[];
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fixture = RoomMusicFixture();
    await fixture.initialize();
  });
  tearDown(() async {
    for (final model in models) {
      model.dispose();
    }
    models.clear();
    await fixture.dispose();
  });

  RoomMusicViewModel model([String roomId = 'canonical']) {
    final value = RoomMusicViewModel(
      repository: fixture.music,
      roomId: roomId,
      systemVolume: _SystemVolume(),
    );
    models.add(value);
    return value;
  }

  Future<void> enter([String roomId = 'canonical']) async {
    fixture.http.canonicalRoomId = roomId;
    await fixture.manager.enterRoom(roomId: roomId, agoraAppId: 'test-app');
    await fixture.flush();
  }

  test('initialization and another room cannot activate the box', () async {
    final vm = model();
    await vm.initialize();
    expect(vm.state.isOpened, isFalse);
    final other = model('other');
    other.expand();
    expect(other.state.expanded, isFalse);
    expect(vm.state.isOpened, isFalse);
    vm.expand();
    expect(vm.state.isOpened, isTrue);
    expect(other.state.isOpened, isFalse);
    expect(fixture.http.opens, isEmpty);
    expect(fixture.engine.starts, isEmpty);
  });

  test('stopping playback does not close or deactivate the box', () async {
    await fixture.import();
    final vm = model()..expand();
    await vm.initialize();
    await vm.toggle();
    await vm.stop();
    expect(vm.state.playback.status, RoomMusicPlayback.stopped);
    expect(vm.state.expanded, isTrue);
    expect(vm.state.isOpened, isTrue);
    vm.collapse();
    expect(vm.state.expanded, isFalse);
    expect(vm.state.isOpened, isTrue);
  });

  test(
    'Keep and page disposal retain activation, restore stays collapsed',
    () async {
      await fixture.import();
      final vm = model()..expand();
      await vm.initialize();
      await vm.toggle();
      fixture.manager.minimizeRoom();
      vm.dispose();
      models.remove(vm);
      expect(fixture.music.isOpened('canonical'), isTrue);
      fixture.manager.restoreRoom();
      final restored = model();
      expect(restored.state.expanded, isFalse);
      expect(restored.state.isOpened, isTrue);
      expect(restored.state.playback.status, RoomMusicPlayback.playing);
      expect(fixture.engine.stops, 0);
      restored.expand();
      expect(restored.state.expanded, isTrue);
      expect(fixture.http.opens.length, 1);
    },
  );

  test(
    'Exit resets activation immediately, including same-ID reentry',
    () async {
      final vm = model()..expand();
      await vm.initialize();
      final leaving = fixture.manager.leaveRoom();
      expect(vm.state.isOpened, isFalse);
      expect(vm.state.expanded, isFalse);
      await leaving;
      await enter();
      expect(model().state.isOpened, isFalse);
    },
  );

  test(
    'switching rooms resets activation and rejects stale mutations',
    () async {
      final old = model()..expand();
      await old.initialize();
      final generation = fixture.music.sessionGeneration;
      await enter('second');
      final current = model('second');
      expect(current.state.isOpened, isFalse);
      fixture.music.setBoxOpened('second', true, generation: generation);
      expect(current.state.isOpened, isFalse);
      current.expand();
      fixture.music.setBoxOpened('second', false, generation: generation);
      await old.close();
      expect(current.state.isOpened, isTrue);
      expect(current.state.expanded, isTrue);
      expect(old.state.isOpened, isFalse);
    },
  );

  test('stale same-ID close cannot deactivate or stop a new session', () async {
    await fixture.import();
    final old = model()..expand();
    await old.initialize();
    await fixture.manager.leaveRoom();
    await enter();
    final current = model()..expand();
    await current.initialize();
    await current.toggle();
    final stops = fixture.engine.stops;
    final closes = fixture.http.closes.length;
    await old.close();
    expect(current.state.isOpened, isTrue);
    expect(current.state.expanded, isTrue);
    expect(current.state.playback.status, RoomMusicPlayback.playing);
    expect(fixture.engine.stops, stops);
    expect(fixture.http.closes.length, closes);
  });

  test('kick clears activation before a subsequent visit', () async {
    final vm = model()..expand();
    await vm.initialize();
    fixture.socket.controller.add(
      const RoomSocketMessage(
        channel: 'room:canonical',
        event: 'RoomKickOutEvent',
        raw: {},
        payload: {
          'roomId': 'canonical',
          'from': {'uid': 10},
        },
      ),
    );
    for (var i = 0; i < 10 && fixture.manager.state.isInRoom; i++) {
      await fixture.flush();
    }
    expect(vm.state.isOpened, isFalse);
    await fixture.manager.leaveRoom();
    await enter();
    expect(model().state.isOpened, isFalse);
  });

  test('logout and account switch do not persist activation', () async {
    final vm = model()..expand();
    await vm.initialize();
    await fixture.auth.clear();
    expect(vm.state.isOpened, isFalse);
    await fixture.manager.leaveRoom();
    fixture.auth.currentUid = 20;
    fixture.auth.loggedIn = true;
    await enter();
    final current = model();
    await current.initialize();
    expect(current.state.isOpened, isFalse);
    expect(current.state.tracks, isEmpty);
  });
}

class _SystemVolume implements RoomSystemVolumeManager {
  @override
  Stream<double> get changes => Stream<double>.value(.6);
  @override
  Future<void> setVolume(double value) async {}
  @override
  Future<void> dispose() async {}
}
