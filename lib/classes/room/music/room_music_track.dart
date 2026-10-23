class RoomMusicTrack {
  const RoomMusicTrack({
    required this.id,
    required this.name,
    required this.fileName,
    this.duration = 0,
  });

  final String id;
  final String name;
  final String fileName;
  final int duration;

  factory RoomMusicTrack.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final fileName = json['fileName'];
    if (id is! String ||
        name is! String ||
        fileName is! String ||
        !RegExp(r'^[a-f0-9]{64}\.[a-z0-9]+$').hasMatch(fileName)) {
      throw const FormatException('Invalid music track');
    }
    return RoomMusicTrack(
      id: id,
      name: name,
      fileName: fileName,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fileName': fileName,
    'duration': duration,
  };
}

enum RoomMusicMode { loop, single, shuffle }
