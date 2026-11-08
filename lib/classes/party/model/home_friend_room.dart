import 'home_json.dart';

enum HomeFriendBadge { hall, mining, rocket, voice }

class HomeFriendRoom {
  const HomeFriendRoom({
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
  final HomeFriendUserInfo user;
  final HomeFriendRocketSchedule? rocketSchedule;

  String get nick => user.nick;

  String? get avatar => roomAvatar ?? user.avatar;

  HomeFriendBadge? get badge {
    if (label == 1) return HomeFriendBadge.hall;
    if (label == 2) return HomeFriendBadge.mining;
    if (rocketSchedule case final rocket?) {
      if (rocket.showStatus == 2 || rocket.showStatus == 3) {
        return HomeFriendBadge.rocket;
      }
    }
    return inMicNum > 0 ? HomeFriendBadge.voice : null;
  }

  String get relationKey => switch (type) {
    1 => 'home.friendRoom',
    2 => 'home.followedRoom',
    3 => 'home.myRoom',
    _ => 'home.myFollowing',
  };

  bool get hasContent {
    return uid > 0 ||
        (roomId?.isNotEmpty ?? false) ||
        title.isNotEmpty ||
        nick.isNotEmpty ||
        (avatar?.isNotEmpty ?? false);
  }

  factory HomeFriendRoom.fromJson(Map<dynamic, dynamic> json) {
    final user = HomeFriendUserInfo.fromJson(homeMap(json['userBaseInfo']));
    final uid = homeInt(json['uid']);
    return HomeFriendRoom(
      type: homeInt(json['type']),
      uid: uid > 0 ? uid : user.uid,
      title: homeString(json['title']) ?? '',
      roomId: homeString(json['roomId']),
      roomAvatar: homeString(json['avatar']),
      roomDesc: homeString(json['roomDesc']),
      roomTypeValue: homeInt(json['roomTypeValue']),
      inMicNum: homeInt(json['inMicNum']),
      label: homeIntOrNull(json['label']),
      user: user,
      rocketSchedule: HomeFriendRocketSchedule.fromJsonOrNull(
        homeMapOrNull(json['rocketRoomScheduleInfoListResp']),
      ),
    );
  }
}

class HomeFriendUserInfo {
  const HomeFriendUserInfo({
    required this.uid,
    required this.userNo,
    required this.nick,
    this.avatar,
    this.countryCode,
    this.region,
    this.gender = 0,
    this.userLevel = const HomeFriendUserLevel(),
  });

  const HomeFriendUserInfo.empty()
    : uid = 0,
      userNo = 0,
      nick = '',
      avatar = null,
      countryCode = null,
      region = null,
      gender = 0,
      userLevel = const HomeFriendUserLevel();

  final int uid;
  final int userNo;
  final String nick;
  final String? avatar;
  final String? countryCode;
  final String? region;
  final int gender;
  final HomeFriendUserLevel userLevel;

  factory HomeFriendUserInfo.fromJson(Map<dynamic, dynamic> json) {
    return HomeFriendUserInfo(
      uid: homeInt(json['uid']),
      userNo: homeInt(json['userNo']),
      nick: homeString(json['nick']) ?? '',
      avatar: homeString(json['avatar']),
      countryCode: homeString(json['countryCode']),
      region: homeString(json['region']),
      gender: homeInt(json['gender']),
      userLevel: HomeFriendUserLevel.fromJson(homeMap(json['userLevel'])),
    );
  }
}

class HomeFriendUserLevel {
  const HomeFriendUserLevel({
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

  factory HomeFriendUserLevel.fromJson(Map<dynamic, dynamic> json) {
    return HomeFriendUserLevel(
      activeLevel: homeInt(json['activeLevel']),
      activeLevelIcon: homeString(json['activeLevelIcon']),
      charmLevel: homeInt(json['charmLevel']),
      charmLevelIcon: homeString(json['charmLevelIcon']),
      wealthLevel: homeInt(json['wealthLevel']),
      wealthLevelIcon: homeString(json['wealthLevelIcon']),
      vipLevel: homeInt(json['vipLevel']),
      vipIcon: homeString(json['vipIcon']),
    );
  }
}

class HomeFriendRocketSchedule {
  const HomeFriendRocketSchedule({
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

  factory HomeFriendRocketSchedule.fromJson(Map<dynamic, dynamic> json) {
    return HomeFriendRocketSchedule(
      id: homeInt(json['id']),
      roomId: homeString(json['roomId']),
      roomUid: homeInt(json['roomUid']),
      countryCode: homeString(json['countryCode']),
      level: homeInt(json['level']),
      levelExp: homeInt(json['levelExp']),
      curExp: homeInt(json['curExp']),
      progress: homeDouble(json['progress']),
      status: homeInt(json['status']),
      showStatus: homeInt(json['showStatus']),
      rocketUrl: homeString(json['rocketUrl']),
      prizeHisUrl: homeString(json['prizeHisUrl']),
      createTime: homeString(json['createTime']),
    );
  }

  static HomeFriendRocketSchedule? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    return HomeFriendRocketSchedule.fromJson(json);
  }
}
