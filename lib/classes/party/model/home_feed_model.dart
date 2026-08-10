part of '../party_page.dart';

enum _HomeRoomTagType { pk, lucky, bigWin }

class _HomeBannerItem {
  const _HomeBannerItem({
    this.pic,
    this.picHash,
    this.smallIcon,
    this.routeUrl,
  });

  final String? pic;
  final String? picHash;
  final String? smallIcon;
  final String? routeUrl;

  String? get imageUrl => pic ?? picHash ?? smallIcon;

  factory _HomeBannerItem.fromJson(Map<dynamic, dynamic> json) {
    return _HomeBannerItem(
      pic: _homeFeedString(json['pic']),
      picHash:
          _homeFeedString(json['picHash']) ?? _homeFeedString(json['pichash']),
      smallIcon: _homeFeedString(json['smallIcon']),
      routeUrl: _homeFeedString(json['routeUrl']),
    );
  }
}

class _HomeFriendItem {
  const _HomeFriendItem({
    required this.type,
    required this.title,
    required this.nick,
    this.avatar,
  });

  final int type;
  final String title;
  final String nick;
  final String? avatar;

  factory _HomeFriendItem.fromJson(Map<dynamic, dynamic> json) {
    final userInfo = _homeFeedMap(json['userBaseInfo']);
    return _HomeFriendItem(
      type: _homeFeedInt(json['type']),
      title: _homeFeedString(json['title']) ?? '',
      nick: _homeFeedString(userInfo['nick']) ?? '',
      avatar:
          _homeFeedString(json['avatar']) ??
          _homeFeedString(userInfo['avatar']),
    );
  }

  factory _HomeFriendItem.placeholder(int index) {
    return _HomeFriendItem(type: index, title: '', nick: '');
  }
}

class _HomeRoomItem {
  const _HomeRoomItem({
    required this.title,
    required this.online,
    required this.hot,
    required this.isPk,
    required this.thereOneLuckyBox,
    this.cover,
    this.countryCode,
    this.hotText,
  });

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

  _HomeRoomTagType? get tagType {
    if (isPk) return _HomeRoomTagType.pk;
    if (thereOneLuckyBox) return _HomeRoomTagType.lucky;
    if (hot > 0) return _HomeRoomTagType.bigWin;
    return null;
  }

  factory _HomeRoomItem.fromJson(Map<dynamic, dynamic> json) {
    return _HomeRoomItem(
      cover: _homeFeedString(json['cover']),
      title: _homeFeedString(json['title']) ?? '',
      online: _homeFeedInt(json['online']),
      hot: _homeFeedInt(json['hot']),
      hotText: _homeFeedString(json['hotStr']),
      countryCode: _homeFeedString(json['country'])?.toUpperCase(),
      isPk: json['isPk'] == true,
      thereOneLuckyBox: json['thereOneLuckyBox'] == true,
    );
  }
}

Map<String, dynamic> _homeFeedMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

String? _homeFeedString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _normalizeHomeCountryCode(String? countryCode) {
  final code = countryCode?.trim().toUpperCase();
  if (code == null || code.isEmpty || code == 'NULL') return null;
  return code;
}

int _homeFeedInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
