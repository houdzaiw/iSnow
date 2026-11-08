import 'home_json.dart';

enum HomeRoomTagType { pk, lucky, bigWin }

class HomeBannerItem {
  const HomeBannerItem({this.pic, this.picHash, this.smallIcon, this.routeUrl});

  final String? pic;
  final String? picHash;
  final String? smallIcon;
  final String? routeUrl;

  String? get imageUrl => pic ?? picHash ?? smallIcon;

  factory HomeBannerItem.fromJson(Map<dynamic, dynamic> json) {
    return HomeBannerItem(
      pic: homeString(json['pic']),
      picHash: homeString(json['picHash']) ?? homeString(json['pichash']),
      smallIcon: homeString(json['smallIcon']),
      routeUrl: homeString(json['routeUrl']),
    );
  }
}

class HomeRoomItem {
  const HomeRoomItem({
    required this.title,
    required this.online,
    required this.hot,
    required this.isPk,
    required this.thereOneLuckyBox,
    this.roomId,
    this.cover,
    this.countryCode,
    this.hotText,
  });

  final String? roomId;
  final String? cover;
  final String title;
  final int online;
  final int hot;
  final String? hotText;
  final String? countryCode;
  final bool isPk;
  final bool thereOneLuckyBox;

  String get onlineText {
    final text = hotText?.trim();
    if (text != null && text.isNotEmpty) return text;
    final count = hot > 0 ? hot : online;
    return '$count';
  }

  HomeRoomTagType? get tagType {
    if (isPk) return HomeRoomTagType.pk;
    if (thereOneLuckyBox) return HomeRoomTagType.lucky;
    if (hot > 0) return HomeRoomTagType.bigWin;
    return null;
  }

  factory HomeRoomItem.fromJson(Map<dynamic, dynamic> json) {
    return HomeRoomItem(
      roomId: homeString(json['roomId'] ?? json['roomID']),
      cover: homeString(json['cover']),
      title: homeString(json['title']) ?? '',
      online: homeInt(json['online']),
      hot: homeInt(json['hot']),
      hotText: homeString(json['hotStr']),
      countryCode: homeString(json['country'])?.toUpperCase(),
      isPk: json['isPk'] == true,
      thereOneLuckyBox: json['thereOneLuckyBox'] == true,
    );
  }
}
