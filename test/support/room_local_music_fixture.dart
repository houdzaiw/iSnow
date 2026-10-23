import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/manager/room_local_music_manager.dart';
import 'package:room_music_scan/room_music_scan.dart';

import 'room_music_fixture.dart';

class RoomLocalMusicFixture {
  static const channel = MethodChannel('isnow/room_music_scan');
  late final RoomMusicFixture room;
  String permission = 'granted';
  bool failScan = false;
  int settingsCalls = 0;
  int permissionRequests = 0;
  int scans = 0;
  int exports = 0;
  Completer<void>? exportGate;
  Completer<void>? scanGate;
  final exportGates = <int, Completer<void>>{};
  final failures = <String>{};
  final rows = <Map<String, dynamic>>[];
  final sources = <String, File>{};
  final temporaryFiles = <String>[];
  int? minBytes;

  Future<void> initialize() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, _handle);
    room = RoomMusicFixture(
      localMusic: RoomLocalMusicManager(
        scanner: const RoomMusicScan(),
        supported: true,
      ),
    );
    await room.initialize();
  }

  Future<void> addSource(String name, {int seed = 1}) async {
    final uri = 'content://media/external/audio/media/${rows.length + 1}';
    final file = File('${room.directory.path}/source-${rows.length}');
    await file.writeAsBytes([seed, 2, 3, 4]);
    sources[uri] = file;
    rows.add({
      'id': uri,
      'uri': uri,
      'name': name,
      'duration': 123000,
      'location': 'Music/Album/',
      'size': 200000,
    });
  }

  Future<dynamic> _handle(MethodCall call) async {
    switch (call.method) {
      case 'requestPermission':
        permissionRequests++;
        return permission;
      case 'permission':
        return permission;
      case 'scan':
        scans++;
        minBytes = (call.arguments as Map)['minBytes'] as int;
        await scanGate?.future;
        if (failScan) throw PlatformException(code: 'AUDIO_IO_FAILED');
        return rows;
      case 'openSettings':
        settingsCalls++;
        return null;
      case 'exportAudio':
        exports++;
        await exportGates[exports]?.future;
        final uri = (call.arguments as Map)['uri'] as String;
        await exportGate?.future;
        if (failures.contains(uri)) {
          throw PlatformException(code: 'AUDIO_IO_FAILED');
        }
        final target = '${room.directory.path}/temporary-$exports';
        await sources[uri]!.copy(target);
        temporaryFiles.add(target);
        return target;
    }
    throw MissingPluginException(call.method);
  }

  Future<void> flush() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> dispose() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await room.dispose();
  }
}
