import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../classes/room/music/room_music_track.dart';

class RoomMusicLibrary {
  RoomMusicLibrary({
    Future<Directory> Function()? directory,
    Future<List<PlatformFile>> Function()? pickFiles,
  }) : _directory = directory ?? getApplicationDocumentsDirectory,
       _pickFiles = pickFiles ?? _pickAudio;

  final Future<Directory> Function() _directory;
  final Future<List<PlatformFile>> Function() _pickFiles;
  static const extensions = ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac', 'mp4'];

  static Future<List<PlatformFile>> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: true,
    );
    return result?.files ?? [];
  }

  Future<Directory> _folder(int uid) async {
    final root = await _directory();
    return Directory('${root.path}/room_music/$uid').create(recursive: true);
  }

  Future<List<RoomMusicTrack>> load(int uid) async {
    final preferences = await SharedPreferences.getInstance();
    final data = preferences.getStringList('room_music_$uid') ?? [];
    final tracks = <RoomMusicTrack>[];
    for (final item in data) {
      try {
        final track = RoomMusicTrack.fromJson(
          (jsonDecode(item) as Map).cast<String, dynamic>(),
        );
        if (await File(await path(uid, track)).exists()) tracks.add(track);
      } catch (_) {
        // Skip individual invalid records without losing the rest of the library.
      }
    }
    return tracks;
  }

  Future<String> path(int uid, RoomMusicTrack track) async =>
      '${(await _folder(uid)).path}/${track.fileName}';

  Future<List<RoomMusicTrack>> importAudio(int uid) async {
    final files = await _pickFiles();
    final tracks = <RoomMusicTrack>[];
    for (final selected in files) {
      final source = selected.path;
      final extension = selected.extension?.toLowerCase();
      if (source == null || !extensions.contains(extension)) {
        throw const FormatException('Unsupported audio file');
      }
      final file = File(source);
      final id = (await sha256.bind(file.openRead()).first).toString();
      final track = RoomMusicTrack(
        id: id,
        name: selected.name,
        fileName: '$id.$extension',
      );
      final target = await path(uid, track);
      if (!await File(target).exists()) await file.copy(target);
      tracks.add(track);
    }
    return tracks;
  }

  Future<void> save(int uid, List<RoomMusicTrack> tracks) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      'room_music_$uid',
      tracks.map((track) => jsonEncode(track.toJson())).toList(),
    );
  }

  Future<void> remove(int uid, RoomMusicTrack track) async {
    final file = File(await path(uid, track));
    if (await file.exists()) await file.delete();
  }
}
