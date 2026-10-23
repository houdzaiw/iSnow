import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../classes/room/music/room_music_track.dart';
import '../classes/room/music/room_local_music_track.dart';
import 'room_local_music_manager.dart';

class RoomMusicImportBatch {
  final List<RoomMusicTrack> tracks = [];

  /// Only files created by this batch may be rolled back after cancellation.
  final List<RoomMusicTrack> created = [];
  int failedCount = 0;
}

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

  Future<RoomMusicImportBatch> importAudio(
    int uid, {
    bool Function()? isCancelled,
  }) async {
    final files = await _pickFiles();
    final batch = RoomMusicImportBatch();
    for (final selected in files) {
      if (isCancelled?.call() == true) break;
      try {
        final source = selected.path;
        if (source == null) throw const FormatException('No audio file');
        await _importFile(uid, source, selected.name, 0, batch);
      } catch (_) {
        batch.failedCount++;
      }
    }
    return batch;
  }

  Future<RoomMusicImportBatch> importLocal(
    int uid,
    List<RoomLocalMusicTrack> tracks,
    RoomLocalMusicManager manager, {
    bool Function()? isCancelled,
  }) async {
    final batch = RoomMusicImportBatch();
    for (final track in tracks) {
      if (isCancelled?.call() == true) break;
      String? temporary;
      try {
        temporary = await manager.exportAudio(track);
        if (isCancelled?.call() == true) break;
        await _importFile(uid, temporary, track.name, track.duration, batch);
      } catch (_) {
        batch.failedCount++;
      } finally {
        if (temporary != null) {
          try {
            await File(temporary).delete();
          } on FileSystemException catch (_) {
            // A cache eviction must not turn a successful import into failure.
          }
        }
      }
    }
    return batch;
  }

  Future<void> _importFile(
    int uid,
    String source,
    String name,
    int duration,
    RoomMusicImportBatch batch,
  ) async {
    final extension = name.split('.').last.toLowerCase();
    if (!extensions.contains(extension)) {
      throw const FormatException('Unsupported audio file');
    }
    final file = File(source);
    if (await file.length() == 0) throw const FormatException('Empty audio');
    final id = (await sha256.bind(file.openRead()).first).toString();
    final track = RoomMusicTrack(
      id: id,
      name: name,
      fileName: '$id.$extension',
      duration: duration,
    );
    final target = File(await path(uid, track));
    if (!await target.exists()) {
      final staged = File('${target.path}.part');
      try {
        await file.copy(staged.path);
        await staged.rename(target.path);
        batch.created.add(track);
      } finally {
        if (await staged.exists()) await staged.delete();
      }
    }
    batch.tracks.add(track);
  }

  Future<void> discard(int uid, RoomMusicImportBatch batch) async {
    for (final track in batch.created) {
      await remove(uid, track);
    }
  }

  Future<void> save(int uid, List<RoomMusicTrack> tracks) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(
      'room_music_$uid',
      tracks.map((track) => jsonEncode(track.toJson())).toList(),
    );
    if (!saved) throw const FileSystemException('Unable to save music library');
  }

  Future<void> remove(int uid, RoomMusicTrack track) async {
    final file = File(await path(uid, track));
    if (await file.exists()) await file.delete();
  }
}
