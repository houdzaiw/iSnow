/// Share templates are public materials; resolved invitations are session data.
class RoomShareMaterial {
  const RoomShareMaterial({
    this.id = 0,
    this.imageUrl = '',
    this.copyText = '',
    required this.jumpLink,
    this.sortNo = 0,
  });

  factory RoomShareMaterial.fromJson(Map<String, dynamic> json) =>
      RoomShareMaterial(
        id: int.tryParse('${json['id']}') ?? 0,
        imageUrl: '${json['imageUrl'] ?? ''}'.trim(),
        copyText: '${json['copyText'] ?? ''}',
        jumpLink: '${json['jumpLink'] ?? ''}'.trim(),
        sortNo: int.tryParse('${json['sortNo']}') ?? 0,
      );

  final int id, sortNo;
  final String imageUrl, copyText, jumpLink;

  bool get needsInviteCode =>
      '$copyText $jumpLink'.contains(r'${inviteCode}') ||
      Uri.decodeFull(jumpLink).contains(r'${inviteCode}');
}

class RoomShareContent {
  const RoomShareContent({required this.description, required this.link});
  final String description;
  final Uri link;
  String get text => [
    description.trim(),
    link.toString(),
  ].where((part) => part.isNotEmpty).join('\n');

  RoomShareContent withLink(Uri value) =>
      RoomShareContent(description: description, link: value);
}

class RoomShareContact {
  const RoomShareContact({
    required this.uid,
    required this.nickname,
    this.avatar = '',
  });
  final int uid;
  final String nickname, avatar;
}

enum RoomShareTab { share, recent, friends }

enum RoomShareAction { copy, system }

/// Platform completion is not proof that the recipient received an invitation.
enum RoomShareOutcome { copied, shared, cancelled, unavailable, failed, stale }
