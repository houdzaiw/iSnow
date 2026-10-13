class RoomMusicTrack {
  const RoomMusicTrack({
    required this.id,
    required this.name,
    required this.fileName,
  });

  final String id;
  final String name;
  final String fileName;

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
    return RoomMusicTrack(id: id, name: name, fileName: fileName);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fileName': fileName,
  };
}

enum RoomMusicMode { loop, single, shuffle }
