/// Share templates are public materials; resolved invitations are session data.
class RoomShareMaterial {
  const RoomShareMaterial({
    this.id = 0,
    this.imageUrl = '',
    this.copyText = '',
    required this.jumpLink,
    this.sortNo = 0,
    this.subScene = '',
    this.resolvedLanguage = '',
  });

  factory RoomShareMaterial.fromJson(Map<String, dynamic> json) =>
      RoomShareMaterial(
        id: int.tryParse('${json['id']}') ?? 0,
        imageUrl: '${json['imageUrl'] ?? ''}'.trim(),
        copyText: '${json['copyText'] ?? ''}',
        jumpLink: '${json['jumpLink'] ?? ''}'.trim(),
        sortNo: int.tryParse('${json['sortNo']}') ?? 0,
        subScene: '${json['subScene'] ?? ''}'.trim(),
        resolvedLanguage: '${json['resolvedLanguage'] ?? ''}'.trim(),
      );

  final int id, sortNo;
  final String imageUrl, copyText, jumpLink;
  final String subScene, resolvedLanguage;

  bool get hasContent =>
      imageUrl.isNotEmpty || copyText.trim().isNotEmpty || jumpLink.isNotEmpty;

  bool get needsInviteCode {
    if ('$copyText $jumpLink'.contains(r'${inviteCode}')) return true;
    try {
      return Uri.decodeFull(jumpLink).contains(r'${inviteCode}');
    } on FormatException {
      return false;
    }
  }
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

class RoomShareContactsPage {
  const RoomShareContactsPage({required this.users, required this.hasMore});
  final List<RoomShareContact> users;
  final bool hasMore;
}

enum RoomShareTab { share, recent, friends }

enum RoomShareAction {
  copy('Copy'),
  whatsapp('WhatsApp'),
  facebook('Facebook'),
  snapchat('Snapchat'),
  telegram('Telegram'),
  messenger('Messenger'),
  x('X'),
  instagram('Instagram'),
  contacts('Contacts'),
  system('Others');

  const RoomShareAction(this.channelName);
  final String channelName;

  bool get linkOnlyClipboard =>
      this == RoomShareAction.facebook || this == RoomShareAction.messenger;
}

/// Platform completion is not proof that the recipient received an invitation.
enum RoomShareOutcome {
  copied,
  opened,
  shared,
  cancelled,
  unavailable,
  failed,
  stale,
}
