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
    required this.uid,
    required this.title,
    required this.user,
    this.roomId,
    this.roomAvatar,
    this.roomDesc,
    this.roomTypeValue = 0,
    this.inMicNum = 0,
    this.label,
    this.rocketSchedule,
  });

  final int type;
  final int uid;
  final String title;
  final String? roomId;
  final String? roomAvatar;
  final String? roomDesc;
  final int roomTypeValue;
  final int inMicNum;
  final int? label;
  final _HomeFriendUserInfo user;
  final _HomeFriendRocketSchedule? rocketSchedule;

  String get nick => user.nick;

  String? get avatar => roomAvatar ?? user.avatar;

  bool get hasContent {
    return uid > 0 ||
        (roomId?.isNotEmpty ?? false) ||
        title.isNotEmpty ||
        nick.isNotEmpty ||
        (avatar?.isNotEmpty ?? false);
  }

  factory _HomeFriendItem.fromJson(Map<dynamic, dynamic> json) {
    final user = _HomeFriendUserInfo.fromJson(
      _homeFeedMap(json['userBaseInfo']),
    );
    final uid = _homeFeedInt(json['uid']);
    return _HomeFriendItem(
      type: _homeFeedInt(json['type']),
      uid: uid > 0 ? uid : user.uid,
      title: _homeFeedString(json['title']) ?? '',
      roomId: _homeFeedString(json['roomId']),
      roomAvatar: _homeFeedString(json['avatar']),
      roomDesc: _homeFeedString(json['roomDesc']),
      roomTypeValue: _homeFeedInt(json['roomTypeValue']),
      inMicNum: _homeFeedInt(json['inMicNum']),
      label: _homeFeedIntOrNull(json['label']),
      user: user,
      rocketSchedule: _HomeFriendRocketSchedule.fromJsonOrNull(
        _homeFeedMapOrNull(json['rocketRoomScheduleInfoListResp']),
      ),
    );
  }

  factory _HomeFriendItem.placeholder(int index) {
    return _HomeFriendItem(
      type: index,
      uid: 0,
      title: '',
      user: const _HomeFriendUserInfo.empty(),
    );
  }
}

class _HomeFriendUserInfo {
  const _HomeFriendUserInfo({
    required this.uid,
    required this.userNo,
    required this.nick,
    this.avatar,
    this.countryCode,
    this.region,
    this.gender = 0,
    this.userLevel = const _HomeFriendUserLevel(),
  });

  const _HomeFriendUserInfo.empty()
    : uid = 0,
      userNo = 0,
      nick = '',
      avatar = null,
      countryCode = null,
      region = null,
      gender = 0,
      userLevel = const _HomeFriendUserLevel();

  final int uid;
  final int userNo;
  final String nick;
  final String? avatar;
  final String? countryCode;
  final String? region;
  final int gender;
  final _HomeFriendUserLevel userLevel;

  factory _HomeFriendUserInfo.fromJson(Map<dynamic, dynamic> json) {
    return _HomeFriendUserInfo(
      uid: _homeFeedInt(json['uid']),
      userNo: _homeFeedInt(json['userNo']),
      nick: _homeFeedString(json['nick']) ?? '',
      avatar: _homeFeedString(json['avatar']),
      countryCode: _homeFeedString(json['countryCode']),
      region: _homeFeedString(json['region']),
      gender: _homeFeedInt(json['gender']),
      userLevel: _HomeFriendUserLevel.fromJson(_homeFeedMap(json['userLevel'])),
    );
  }
}

class _HomeFriendUserLevel {
  const _HomeFriendUserLevel({
    this.activeLevel = 0,
    this.activeLevelIcon,
    this.charmLevel = 0,
    this.charmLevelIcon,
    this.wealthLevel = 0,
    this.wealthLevelIcon,
    this.vipLevel = 0,
    this.vipIcon,
  });

  final int activeLevel;
  final String? activeLevelIcon;
  final int charmLevel;
  final String? charmLevelIcon;
  final int wealthLevel;
  final String? wealthLevelIcon;
  final int vipLevel;
  final String? vipIcon;

  factory _HomeFriendUserLevel.fromJson(Map<dynamic, dynamic> json) {
    return _HomeFriendUserLevel(
      activeLevel: _homeFeedInt(json['activeLevel']),
      activeLevelIcon: _homeFeedString(json['activeLevelIcon']),
      charmLevel: _homeFeedInt(json['charmLevel']),
      charmLevelIcon: _homeFeedString(json['charmLevelIcon']),
      wealthLevel: _homeFeedInt(json['wealthLevel']),
      wealthLevelIcon: _homeFeedString(json['wealthLevelIcon']),
      vipLevel: _homeFeedInt(json['vipLevel']),
      vipIcon: _homeFeedString(json['vipIcon']),
    );
  }
}

class _HomeFriendRocketSchedule {
  const _HomeFriendRocketSchedule({
    required this.id,
    required this.roomUid,
    required this.level,
    required this.levelExp,
    required this.curExp,
    required this.progress,
    required this.status,
    required this.showStatus,
    this.roomId,
    this.countryCode,
    this.rocketUrl,
    this.prizeHisUrl,
    this.createTime,
  });

  final int id;
  final String? roomId;
  final int roomUid;
  final String? countryCode;
  final int level;
  final int levelExp;
  final int curExp;
  final double progress;
  final int status;
  final int showStatus;
  final String? rocketUrl;
  final String? prizeHisUrl;
  final String? createTime;

  factory _HomeFriendRocketSchedule.fromJson(Map<dynamic, dynamic> json) {
    return _HomeFriendRocketSchedule(
      id: _homeFeedInt(json['id']),
      roomId: _homeFeedString(json['roomId']),
      roomUid: _homeFeedInt(json['roomUid']),
      countryCode: _homeFeedString(json['countryCode']),
      level: _homeFeedInt(json['level']),
      levelExp: _homeFeedInt(json['levelExp']),
      curExp: _homeFeedInt(json['curExp']),
      progress: _homeFeedDouble(json['progress']),
      status: _homeFeedInt(json['status']),
      showStatus: _homeFeedInt(json['showStatus']),
      rocketUrl: _homeFeedString(json['rocketUrl']),
      prizeHisUrl: _homeFeedString(json['prizeHisUrl']),
      createTime: _homeFeedString(json['createTime']),
    );
  }

  static _HomeFriendRocketSchedule? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    return _HomeFriendRocketSchedule.fromJson(json);
  }
}

class _HomeRoomItem {
  const _HomeRoomItem({
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

  _HomeRoomTagType? get tagType {
    if (isPk) return _HomeRoomTagType.pk;
    if (thereOneLuckyBox) return _HomeRoomTagType.lucky;
    if (hot > 0) return _HomeRoomTagType.bigWin;
    return null;
  }

  factory _HomeRoomItem.fromJson(Map<dynamic, dynamic> json) {
    return _HomeRoomItem(
      roomId: _homeFeedString(json['roomId'] ?? json['roomID']),
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

Map<String, dynamic>? _homeFeedMapOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
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

int? _homeFeedIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _homeFeedDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
