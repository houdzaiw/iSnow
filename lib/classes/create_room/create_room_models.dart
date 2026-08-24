class CreateRoomDraft {
  const CreateRoomDraft({
    required this.avatar,
    required this.title,
    required this.roomDesc,
    required this.language,
  });

  final String avatar;
  final String title;
  final String roomDesc;
  final String language;

  Map<String, dynamic> toJson() {
    return {
      'avatar': avatar,
      'title': title,
      'roomDesc': roomDesc,
      'language': language,
    };
  }
}
