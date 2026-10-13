import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project/classes/room/music/room_music_repository.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_background_audio_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/manager/room_music_library.dart';
import 'package:project/model/room_socket_message.dart';

import 'room_lifecycle_fakes.dart';
import 'room_music_engine.dart';

class RoomMusicFixture {
  final actions = <String>[];
  final auth = FakeRoomAuth();
  final socket = FakeRoomSocket([]);
  final engine = RoomMusicEngine();
  late final MusicHttp http;
  late final RoomAgoraManager agora;
  late final RoomManager manager;
  late final RoomRepository room;
  late final RoomMusicRepository music;
  late final RoomMusicLibrary library;
  late final Directory directory;
  int pickerCalls = 0;
  List<PlatformFile> pickedFiles = [];

  Future<void> initialize() async {
    directory = await Directory.systemTemp.createTemp('isnow-music-test-');
    http = MusicHttp(actions, auth)..canonicalRoomId = 'canonical';
    agora = RoomAgoraManager.forTesting(
      engineFactory: () => engine,
      authSession: auth,
    );
    manager = RoomManager.forTesting(
      httpManager: http,
      socketManager: socket,
      agoraManager: agora,
      authSession: auth,
      backgroundAudioManager: RoomBackgroundAudioManager.forTesting(
        start: (_) async => true,
        stop: () async {},
        foreground: () => true,
      ),
    );
    room = RoomRepository(
      roomManager: manager,
      socketManager: socket,
      agoraManager: agora,
      httpManager: http,
      authSession: auth,
    );
    library = RoomMusicLibrary(
      directory: () async => directory,
      pickFiles: () async {
        pickerCalls++;
        return pickedFiles;
      },
    );
    music = RoomMusicRepository(room: room, library: library);
    await manager.enterRoom(roomId: 'visible', agoraAppId: 'test-app');
    await flush();
    await music.load();
  }

  Future<void> import([int count = 1]) async {
    pickedFiles = [];
    for (var i = 0; i < count; i++) {
      final file = File('${directory.path}/music-$i.mp3');
      await file.writeAsBytes([1, 2, 3, i]);
      pickedFiles.add(
        PlatformFile(name: 'music-$i.mp3', size: 4, path: file.path),
      );
    }
    await music.addAudio();
  }

  void micUpdate(List<int> uids) => socket.controller.add(
    RoomSocketMessage(
      channel: 'room:canonical',
      event: 'RoomMicUpdateEvent',
      raw: const {},
      payload: [
        for (final (position, uid) in uids.indexed)
          {'uid': uid, 'position': position},
      ],
    ),
  );
  Future<void> flush() => Future<void>.delayed(Duration.zero);
  Future<void> dispose() async {
    await manager.leaveRoom();
    music.dispose();
    manager.dispose();
    await agora.release();
    agora.dispose();
    await socket.controller.close();
    socket.dispose();
    auth.dispose();
    await directory.delete(recursive: true);
  }
}

class MusicHttp extends FakeRoomHttp {
  MusicHttp(super.actions, super.auth);
  int openCode = 200;
  bool failClose = false;
  Completer<void>? openGate;
  final opens = <Map<String, dynamic>>[];
  final closes = <String>[];
  final statuses = <String>[];

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == HttpApi.roomOpenPlayer) {
      opens.add(Map<String, dynamic>.from(data));
      final code = openCode;
      await openGate?.future;
      return {
        'code': code,
        'message': code == 4062 ? 'Player is occupied' : 'success',
      };
    }
    if (path == HttpApi.roomClosePlayer) {
      closes.add(data['roomId']);
      if (failClose) throw StateError('close failed');
      return {'code': 200};
    }
    if (path == HttpApi.roomMsgPush) {
      statuses.add(data['data']);
      return {'code': 200};
    }
    if (path == HttpApi.roomMicDown) {
      return {
        'code': 200,
        'data': {'micListInfo': []},
      };
    }
    return super.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
