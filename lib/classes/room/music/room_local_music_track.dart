enum RoomMusicPermission { granted, denied, permanentlyDenied }

class RoomLocalMusicTrack {
  const RoomLocalMusicTrack({
    required this.id,
    required this.uri,
    required this.name,
    this.location = '',
    this.size = 0,
    this.duration = 0,
  });

  final String id;
  final String uri;
  final String name;
  final String location;
  final int size;
  final int duration;

  factory RoomLocalMusicTrack.fromJson(Map<String, dynamic> json) =>
      RoomLocalMusicTrack(
        id: json['id'] as String,
        uri: json['uri'] as String,
        name: json['name'] as String,
        location: json['location'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        duration: (json['duration'] as num?)?.toInt() ?? 0,
      );
}

class RoomLocalMusicScanResult {
  const RoomLocalMusicScanResult(this.permission, [this.tracks = const []]);
  final RoomMusicPermission permission;
  final List<RoomLocalMusicTrack> tracks;
}

class RoomMusicImportResult {
  const RoomMusicImportResult({
    this.addedCount = 0,
    this.importedCount = 0,
    this.failedCount = 0,
    this.cancelled = false,
  });
  final int addedCount;
  final int importedCount;
  final int failedCount;
  final bool cancelled;
}
