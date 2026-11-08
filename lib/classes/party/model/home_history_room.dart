import 'home_json.dart';

class HomeHistoryRoom {
  const HomeHistoryRoom({
    required this.roomId,
    required this.uid,
    required this.title,
    this.cover,
    this.inMicNum = 0,
  });
  final String roomId, title;
  final int uid, inMicNum;
  final String? cover;

  factory HomeHistoryRoom.fromJson(Map<dynamic, dynamic> json) =>
      HomeHistoryRoom(
        roomId: homeString(json['roomId']) ?? '',
        uid: homeInt(json['uid']),
        title: homeString(json['title']) ?? '',
        cover: homeString(json['cover']),
        inMicNum: homeInt(json['inMicNum']),
      );
}
