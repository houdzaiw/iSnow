enum NadyLoginStatus {
  none,
  normal,
  logoff,
  incompleteInformation,
  needPassword,
  unknown,
}

NadyLoginStatus nadyLoginStatusFromJson(Object? value) {
  return switch (value?.toString()) {
    'USER_STATUS_NONE' => NadyLoginStatus.none,
    'USER_STATUS_NORMAL' => NadyLoginStatus.normal,
    'USER_STATUS_LOGOFF' => NadyLoginStatus.logoff,
    'USER_STATUS_NEED_COMPLETE' => NadyLoginStatus.incompleteInformation,
    'USER_STATUS_NEED_PASSWORD' => NadyLoginStatus.needPassword,
    _ => NadyLoginStatus.unknown,
  };
}

String nadyLoginStatusToJson(NadyLoginStatus value) {
  return switch (value) {
    NadyLoginStatus.none => 'USER_STATUS_NONE',
    NadyLoginStatus.normal => 'USER_STATUS_NORMAL',
    NadyLoginStatus.logoff => 'USER_STATUS_LOGOFF',
    NadyLoginStatus.incompleteInformation => 'USER_STATUS_NEED_COMPLETE',
    NadyLoginStatus.needPassword => 'USER_STATUS_NEED_PASSWORD',
    NadyLoginStatus.unknown => 'USER_STATUS_UNKNOWN',
  };
}

class HasUserResponse {
  const HasUserResponse({required this.hasUser, required this.status});

  final bool hasUser;
  final NadyLoginStatus status;

  factory HasUserResponse.fromJson(Map<String, dynamic> json) {
    return HasUserResponse(
      hasUser: json['hasUser'] == true,
      status: nadyLoginStatusFromJson(json['status']),
    );
  }
}

class UserData {
  const UserData({
    this.uid,
    this.userNo,
    this.nick,
    this.avatar,
    this.gender = 0,
    this.birth,
    this.region,
    this.userDesc,
    this.countryCode,
    this.areaCode,
    this.phone,
    this.roomId,
    this.userStatus,
  });

  final int? uid;
  final int? userNo;
  final String? nick;
  final String? avatar;
  final int gender;
  final int? birth;
  final String? region;
  final String? userDesc;
  final String? countryCode;
  final String? areaCode;
  final String? phone;
  final String? roomId;
  final NadyLoginStatus? userStatus;

  String? get userId => uid?.toString();
  String? get email => null;
  String? get nickname => nick;

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      uid: (json['uid'] as num?)?.toInt(),
      userNo: (json['userNo'] as num?)?.toInt(),
      nick: json['nick']?.toString(),
      avatar: json['avatar']?.toString(),
      gender: (json['gender'] as num?)?.toInt() ?? 0,
      birth: (json['birth'] as num?)?.toInt(),
      region: json['region']?.toString(),
      userDesc: json['userDesc']?.toString(),
      countryCode: json['countryCode']?.toString(),
      areaCode: json['areaCode']?.toString(),
      phone: json['phone']?.toString(),
      roomId: json['roomId']?.toString(),
      userStatus: nadyLoginStatusFromJson(json['userStatus']),
    );
  }

  UserData copyWith({
    int? uid,
    int? userNo,
    String? nick,
    String? avatar,
    int? gender,
    int? birth,
    String? region,
    String? userDesc,
    String? countryCode,
    String? areaCode,
    String? phone,
    String? roomId,
    NadyLoginStatus? userStatus,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      userNo: userNo ?? this.userNo,
      nick: nick ?? this.nick,
      avatar: avatar ?? this.avatar,
      gender: gender ?? this.gender,
      birth: birth ?? this.birth,
      region: region ?? this.region,
      userDesc: userDesc ?? this.userDesc,
      countryCode: countryCode ?? this.countryCode,
      areaCode: areaCode ?? this.areaCode,
      phone: phone ?? this.phone,
      roomId: roomId ?? this.roomId,
      userStatus: userStatus ?? this.userStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userNo': userNo,
      'nick': nick,
      'avatar': avatar,
      'gender': gender,
      'birth': birth,
      'region': region,
      'userDesc': userDesc,
      'countryCode': countryCode,
      'areaCode': areaCode,
      'phone': phone,
      'roomId': roomId,
      'userStatus': userStatus == null
          ? null
          : nadyLoginStatusToJson(userStatus!),
    };
  }
}

class MeModel {
  const MeModel({
    required this.followingNum,
    required this.followerNum,
    required this.visitorNum,
    required this.receiveGiftValue,
    required this.userBaseInfo,
  });

  final int followingNum;
  final int followerNum;
  final int visitorNum;
  final int receiveGiftValue;
  final UserData userBaseInfo;

  factory MeModel.fromJson(Map<String, dynamic> json) {
    return MeModel(
      followingNum: (json['followingNum'] as num?)?.toInt() ?? 0,
      followerNum: (json['followerNum'] as num?)?.toInt() ?? 0,
      visitorNum: (json['visitorNum'] as num?)?.toInt() ?? 0,
      receiveGiftValue: (json['receiveGiftValue'] as num?)?.toInt() ?? 0,
      userBaseInfo: UserData.fromJson(
        (json['userBaseInfo'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
