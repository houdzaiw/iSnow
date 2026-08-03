class BaseUserInfo {
  final int uid;
  final int? userNo;
  final String nick;
  final String? avatar;
  final int gender;
  final bool? hasPrettyNo;
  final int? birth;
  final int? defUserValue;
  final String? region;
  final String? userDesc;
  final int? createTime;
  final int? lastLoginTime;
  final String? lastLoginIp;
  final String? countryCode;
  final String? appLanguage;
  final bool? newBie;
  final String? areaCode;
  final String? roomId;
  final bool? isCoinDealer;
  final bool? blocked;
  final String? coinDealerTag;
  final bool? bdFlag;
  final String? mood;
  final String? constellation;
  final String? constellationIcon;
  final String? friendInMic;
  final int? roleType;
  final bool? isCoiner;
  final bool? isBd;

  BaseUserInfo({
    required this.uid,
    required this.userNo,
    required this.nick,
    required this.avatar,
    required this.gender,
    required this.hasPrettyNo,
    required this.birth,
    required this.defUserValue,
    required this.region,
    required this.userDesc,
    required this.createTime,
    required this.lastLoginTime,
    required this.lastLoginIp,
    required this.countryCode,
    required this.appLanguage,
    required this.newBie,
    required this.areaCode,
    required this.roomId,
    required this.isCoinDealer,
    required this.blocked,
    required this.coinDealerTag,
    required this.bdFlag,
    required this.mood,
    required this.constellation,
    required this.constellationIcon,
    required this.friendInMic,
    required this.roleType,
    required this.isCoiner,
    required this.isBd,
  });

  factory BaseUserInfo.fromJson(Map<String, dynamic> json) {
    return BaseUserInfo(
      uid: json['uid'] ?? 0,
      userNo: json['userNo'],
      nick: json['nick'] ?? '',
      avatar: json['avatar'],
      gender: json['gender'] ?? 0,
      hasPrettyNo: json['hasPrettyNo'],
      birth: json['birth'],
      defUserValue: json['defUserValue'],
      region: json['region'],
      userDesc: json['userDesc'],
      createTime: json['createTime'],
      lastLoginTime: json['lastLoginTime'],
      lastLoginIp: json['lastLoginIp'],
      countryCode: json['countryCode'],
      appLanguage: json['appLanguage'],
      newBie: json['newBie'],
      areaCode: json['areaCode'],
      roomId: json['roomId'],
      isCoinDealer: json['isCoinDealer'],
      blocked: json['blocked'],
      coinDealerTag: json['coinDealerTag'],
      bdFlag: json['bdFlag'],
      mood: json['mood'],
      constellation: json['constellation'],
      constellationIcon: json['constellationIcon'],
      friendInMic: json['friendInMic'],
      roleType: json['roleType'],
      isCoiner: json['isCoiner'],
      isBd: json['isBd'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userNo': userNo,
      'nick': nick,
      'avatar': avatar,
      'gender': gender,
      'hasPrettyNo': hasPrettyNo,
      'birth': birth,
      'defUserValue': defUserValue,
      'region': region,
      'userDesc': userDesc,
      'createTime': createTime,
      'lastLoginTime': lastLoginTime,
      'lastLoginIp': lastLoginIp,
      'countryCode': countryCode,
      'appLanguage': appLanguage,
      'newBie': newBie,
      'areaCode': areaCode,
      'roomId': roomId,
      'isCoinDealer': isCoinDealer,
      'blocked': blocked,
      'coinDealerTag': coinDealerTag,
      'bdFlag': bdFlag,
      'mood': mood,
      'constellation': constellation,
      'constellationIcon': constellationIcon,
      'friendInMic': friendInMic,
      'roleType': roleType,
      'isCoiner': isCoiner,
      'isBd': isBd,
    };
  }
}