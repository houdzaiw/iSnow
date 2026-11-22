import '../more/room_tools_models.dart';

class RoomPkUser {
  const RoomPkUser({
    required this.uid,
    this.name = '',
    this.avatar = '',
    this.score = 0,
    this.identity = 0,
    this.contributors = const [],
  });
  final int uid, score, identity;
  final String name, avatar;
  final List<RoomPkUser> contributors;
  factory RoomPkUser.fromJson(ToolJson json) {
    final user = json['userInfo'] == null ? json : toolMap(json['userInfo']);
    return RoomPkUser(
      uid: toolInt(user['uid']),
      name: '${user['nick'] ?? user['nickName'] ?? ''}',
      avatar: '${user['avatar'] ?? ''}',
      score: toolInt(json['pkScore']),
      identity: toolInt(json['identity']),
      contributors: toolList(
        json['contributorList'],
      ).map(RoomPkUser.fromJson).toList(),
    );
  }
}

class RoomPkData {
  const RoomPkData({
    this.id = '',
    this.event = 0,
    this.endsAt = 0,
    this.users = const [],
    this.raw = const {},
  });
  final ToolJson raw;
  final String id;
  final int event, endsAt;
  final List<RoomPkUser> users;
  bool get active => event == 1 || event == 2;
  bool get finished => event == 3 || event == 4;
  bool get doublePk => users.length == 2;
  RoomPkUser? get winner =>
      event == 4 && users.isNotEmpty && users.first.score > 0
      ? users.first
      : null;
  RoomPkUser? side(int identity) =>
      users.where((u) => u.identity == identity).firstOrNull;
  int remaining(DateTime now) =>
      ((endsAt - now.millisecondsSinceEpoch) / 1000).ceil().clamp(0, 86400);
  String time(DateTime now) {
    final seconds = remaining(now);
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  factory RoomPkData.fromJson(ToolJson json) {
    final info = toolMap(json['pkInfo']);
    return RoomPkData(
      raw: json,
      id: '${info['pkId'] ?? ''}',
      event: toolInt(json['eventType']),
      endsAt: toolInt(info['countdown']),
      users: toolList(info['pkMap']).map(RoomPkUser.fromJson).toList(),
    );
  }
}
