import '../../../model/user_profile.dart';

class ProfileHomepageInfo {
  const ProfileHomepageInfo({
    required this.user,
    required this.followingNum,
    required this.followerNum,
    required this.visitorNum,
    required this.receiveGiftValue,
    required this.photos,
    required this.honors,
    this.giftWall = ProfileHomepageGiftWall.empty,
    this.userInRoomInfo,
    this.roomId,
    this.inRoomId,
    this.userRelation,
    this.blackMagJson,
    this.roomInMicNum = 0,
  });

  final ProfileHomepageUser user;
  final int followingNum;
  final int followerNum;
  final int visitorNum;
  final int receiveGiftValue;
  final List<ProfileHomepagePhoto> photos;
  final List<ProfileHomepageHonorItem> honors;
  final ProfileHomepageGiftWall giftWall;
  final ProfileHomepageRoomInfo? userInRoomInfo;
  final String? roomId;
  final String? inRoomId;
  final Object? userRelation;
  final String? blackMagJson;
  final int roomInMicNum;

  bool get isInRoom {
    return userInRoomInfo != null ||
        _hasText(inRoomId) ||
        _hasText(roomId) ||
        _hasText(user.roomId);
  }

  ProfileHomepageInfo copyWith({
    ProfileHomepageUser? user,
    List<ProfileHomepageHonorItem>? honors,
    ProfileHomepageGiftWall? giftWall,
  }) {
    return ProfileHomepageInfo(
      user: user ?? this.user,
      followingNum: followingNum,
      followerNum: followerNum,
      visitorNum: visitorNum,
      receiveGiftValue: receiveGiftValue,
      photos: photos,
      honors: honors ?? this.honors,
      giftWall: giftWall ?? this.giftWall,
      userInRoomInfo: userInRoomInfo,
      roomId: roomId,
      inRoomId: inRoomId,
      userRelation: userRelation,
      blackMagJson: blackMagJson,
      roomInMicNum: roomInMicNum,
    );
  }

  factory ProfileHomepageInfo.fromJson(Map<String, dynamic> json) {
    final userJson = _map(
      json['userBaseInfo'] ??
          json['userBaseInfoDTO'] ??
          json['userInfo'] ??
          json,
    );
    return ProfileHomepageInfo(
      user: ProfileHomepageUser.fromJson(userJson),
      followingNum: _int(json['followingNum']) ?? 0,
      followerNum: _int(json['followerNum']) ?? 0,
      visitorNum: _int(json['visitorNum']) ?? 0,
      receiveGiftValue: _int(json['receiveGiftValue']) ?? 0,
      photos: _extractPhotos(json),
      honors: _extractHonors(userJson),
      giftWall: ProfileHomepageGiftWall.fromJsonOrEmpty(
        _mapOrNull(json['giftWall']),
      ),
      userInRoomInfo: ProfileHomepageRoomInfo.fromJsonOrNull(
        _mapOrNull(json['userInRoomInfo']),
      ),
      roomId: _string(json['roomId']),
      inRoomId: _string(json['inRoomId']),
      userRelation: json['userRelation'],
      blackMagJson: _string(json['blackMagJson']),
      roomInMicNum: _int(json['roomInMicNum']) ?? 0,
    );
  }
}

class ProfileHomepageUser {
  const ProfileHomepageUser({
    required this.uid,
    required this.userNo,
    required this.nick,
    required this.gender,
    required this.wealthLevel,
    required this.charmLevel,
    required this.vipLevel,
    required this.isFollowing,
    required this.isBlocked,
    required this.isRobot,
    required this.isOnline,
    this.avatar,
    this.region,
    this.countryCode,
    this.userDesc,
    this.birth,
    this.createTime,
    this.backgroundUrl,
    this.wealthLevelIcon,
    this.charmLevelIcon,
    this.vipIcon,
    this.activeLevelIcon,
    this.specialEffectsIcon,
    this.specialEffectsAnimationUrl,
    this.constellation,
    this.constellationIcon,
    this.friendInMic,
    this.roomId,
    this.roleType,
    this.coin,
    this.usd,
    this.agentOwnerName,
  });

  final int uid;
  final int userNo;
  final String nick;
  final int gender;
  final int wealthLevel;
  final int charmLevel;
  final int vipLevel;
  final bool isFollowing;
  final bool isBlocked;
  final bool isRobot;
  final bool isOnline;
  final String? avatar;
  final String? region;
  final String? countryCode;
  final String? userDesc;
  final int? birth;
  final int? createTime;
  final String? backgroundUrl;
  final String? wealthLevelIcon;
  final String? charmLevelIcon;
  final String? vipIcon;
  final String? activeLevelIcon;
  final String? specialEffectsIcon;
  final String? specialEffectsAnimationUrl;
  final String? constellation;
  final String? constellationIcon;
  final String? friendInMic;
  final String? roomId;
  final int? roleType;
  final int? coin;
  final int? usd;
  final String? agentOwnerName;

  ProfileHomepageUser copyWith({bool? isFollowing}) {
    return ProfileHomepageUser(
      uid: uid,
      userNo: userNo,
      nick: nick,
      gender: gender,
      wealthLevel: wealthLevel,
      charmLevel: charmLevel,
      vipLevel: vipLevel,
      isFollowing: isFollowing ?? this.isFollowing,
      isBlocked: isBlocked,
      isRobot: isRobot,
      isOnline: isOnline,
      avatar: avatar,
      region: region,
      countryCode: countryCode,
      userDesc: userDesc,
      birth: birth,
      createTime: createTime,
      backgroundUrl: backgroundUrl,
      wealthLevelIcon: wealthLevelIcon,
      charmLevelIcon: charmLevelIcon,
      vipIcon: vipIcon,
      activeLevelIcon: activeLevelIcon,
      specialEffectsIcon: specialEffectsIcon,
      specialEffectsAnimationUrl: specialEffectsAnimationUrl,
      constellation: constellation,
      constellationIcon: constellationIcon,
      friendInMic: friendInMic,
      roomId: roomId,
      roleType: roleType,
      coin: coin,
      usd: usd,
      agentOwnerName: agentOwnerName,
    );
  }

  String displayName(String fallback) => nick.trim().isEmpty ? fallback : nick;

  String displayUserId() {
    if (userNo > 0) return 'ID:$userNo';
    if (uid > 0) return 'ID:$uid';
    return 'ID:--';
  }

  String displayRegion(String fallback) {
    final displayRegion = region?.trim();
    if (displayRegion != null && displayRegion.isNotEmpty) {
      return displayRegion;
    }
    final displayCountryCode = countryCode?.trim();
    if (displayCountryCode != null && displayCountryCode.isNotEmpty) {
      return displayCountryCode;
    }
    return fallback;
  }

  factory ProfileHomepageUser.fromJson(Map<String, dynamic> json) {
    final level = _map(json['userLevel']);
    final background = _map(json['background']);
    final specialEffects = _map(json['specialEffects']);
    final agentOwnerInfo = _map(json['agentOwnerInfo']);
    return ProfileHomepageUser(
      uid: _int(json['uid']) ?? 0,
      userNo: _int(json['userNo']) ?? 0,
      nick: _string(json['nick']) ?? '',
      avatar: _string(json['avatar']),
      gender: _int(json['gender']) ?? 0,
      birth: _int(json['birth']),
      createTime: _int(json['createTime']),
      region: _string(json['region']),
      userDesc: _string(json['userDesc']),
      countryCode: _string(json['countryCode']),
      wealthLevel: _int(level['wealthLevel']) ?? 0,
      charmLevel: _int(level['charmLevel']) ?? 0,
      vipLevel: _int(level['vipLevel']) ?? 0,
      isFollowing: _isFollowing(
        json['followRelation'],
        fallback: _bool(json['isFollow']) ?? false,
      ),
      isBlocked: _bool(json['blocked']) ?? false,
      isRobot: _bool(json['isRobot']) ?? false,
      isOnline: _bool(json['isOnline']) ?? false,
      backgroundUrl:
          _string(background['icon']) ??
          _string(background['animationUrl']) ??
          _string(background['circulationUrl']),
      wealthLevelIcon: _string(level['wealthLevelIcon']),
      charmLevelIcon: _string(level['charmLevelIcon']),
      vipIcon: _string(level['vipIcon']),
      activeLevelIcon: _string(level['activeLevelIcon']),
      specialEffectsIcon: _string(specialEffects['icon']),
      specialEffectsAnimationUrl: _string(specialEffects['animationUrl']),
      constellation: _string(json['constellation']),
      constellationIcon: _string(json['constellationIcon']),
      friendInMic: _string(json['friendInMic']),
      roomId: _string(json['roomId']),
      roleType: _int(json['roleType']),
      coin: _int(json['coin']),
      usd: _int(json['usd']),
      agentOwnerName: _string(agentOwnerInfo['name']),
    );
  }

  UserData toUserData() {
    return UserData(
      uid: uid == 0 ? null : uid,
      userNo: userNo == 0 ? null : userNo,
      nick: nick,
      avatar: avatar,
      gender: gender,
      birth: birth,
      region: region,
      userDesc: userDesc,
      countryCode: countryCode,
    );
  }
}

class ProfileHomepagePhoto {
  const ProfileHomepagePhoto({
    required this.url,
    this.id = 0,
    this.uid = 0,
    this.status = 0,
    this.sort = 0,
    this.createTime,
    this.updateTime,
  });

  final String url;
  final int id;
  final int uid;
  final int status;
  final int sort;
  final String? createTime;
  final String? updateTime;

  factory ProfileHomepagePhoto.fromJson(Map<String, dynamic> json) {
    return ProfileHomepagePhoto(
      id: _int(json['id']) ?? 0,
      uid: _int(json['uid']) ?? 0,
      status: _int(json['status']) ?? 0,
      sort: _int(json['sort']) ?? 0,
      createTime: _string(json['createTime']),
      updateTime: _string(json['updateTime']),
      url:
          _string(json['photoUrl']) ??
          _string(json['url']) ??
          _string(json['pic']) ??
          _string(json['image']) ??
          '',
    );
  }
}

class ProfileHomepageHonorItem {
  const ProfileHomepageHonorItem({
    required this.id,
    required this.icon,
    required this.sortingOrder,
    this.medalType,
    this.medalNameEn,
    this.medalName,
    this.descEn,
    this.desc,
    this.animation,
    this.giftIcon,
    this.obtainTime,
    this.expireTime,
  });

  final String id;
  final String icon;
  final int sortingOrder;
  final int? medalType;
  final String? medalNameEn;
  final String? medalName;
  final String? descEn;
  final String? desc;
  final String? animation;
  final String? giftIcon;
  final String? obtainTime;
  final String? expireTime;

  String displayName({required bool isChinese}) {
    final primary = isChinese ? medalName : medalNameEn;
    final secondary = isChinese ? medalNameEn : medalName;
    final fallback = primary?.trim().isNotEmpty == true
        ? primary!.trim()
        : secondary?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return id;
  }

  factory ProfileHomepageHonorItem.fromJson(Map<String, dynamic> json) {
    return ProfileHomepageHonorItem(
      id: _string(json['id']) ?? '',
      icon:
          _string(json['icon']) ??
          _string(json['tagPic']) ??
          _string(json['medalPic']) ??
          _string(json['pic']) ??
          '',
      sortingOrder: _int(json['sortingOrder']) ?? 0,
      medalType: _int(json['medalType']),
      medalNameEn: _string(json['medalNameEn']),
      medalName: _string(json['medalName']),
      descEn: _string(json['descEn']),
      desc: _string(json['desc']),
      animation: _string(json['animation']),
      giftIcon: _string(json['giftIcon']),
      obtainTime: _string(json['obtainTime']),
      expireTime: _string(json['expireTime']),
    );
  }
}

class ProfileHomepageGiftWall {
  const ProfileHomepageGiftWall({
    required this.receive,
    required this.total,
    required this.gifts,
  });

  static const empty = ProfileHomepageGiftWall(receive: 0, total: 0, gifts: []);

  final int receive;
  final int total;
  final List<ProfileHomepageGiftWallItem> gifts;

  factory ProfileHomepageGiftWall.fromJson(Map<String, dynamic> json) {
    final giftList = json['giftDTOs'];
    return ProfileHomepageGiftWall(
      receive: _int(json['receive']) ?? 0,
      total: _int(json['total']) ?? 0,
      gifts: giftList is List
          ? giftList
                .map((item) => ProfileHomepageGiftWallItem.fromJson(_map(item)))
                .where((item) => item.icon.isNotEmpty || item.name.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }

  static ProfileHomepageGiftWall fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return empty;
    return ProfileHomepageGiftWall.fromJson(json);
  }
}

class ProfileHomepageGiftWallItem {
  const ProfileHomepageGiftWallItem({
    required this.giftId,
    required this.giftCount,
    required this.name,
    required this.icon,
    required this.price,
    this.animationUrl,
    this.createTime,
  });

  final int giftId;
  final int giftCount;
  final String name;
  final String icon;
  final int price;
  final String? animationUrl;
  final String? createTime;

  factory ProfileHomepageGiftWallItem.fromJson(Map<String, dynamic> json) {
    return ProfileHomepageGiftWallItem(
      giftId: _int(json['giftId']) ?? 0,
      giftCount: _int(json['giftCount']) ?? 0,
      name: _string(json['name']) ?? '',
      icon: _string(json['icon']) ?? '',
      price: _int(json['price']) ?? 0,
      animationUrl: _string(json['animationUrl']),
      createTime: _string(json['createTime']),
    );
  }
}

class ProfileHomepageRoomInfo {
  const ProfileHomepageRoomInfo({
    required this.roomId,
    required this.roomName,
    required this.roomAvatar,
    required this.roomType,
    required this.inMicNum,
  });

  final String roomId;
  final String roomName;
  final String? roomAvatar;
  final int roomType;
  final int inMicNum;

  factory ProfileHomepageRoomInfo.fromJson(Map<String, dynamic> json) {
    return ProfileHomepageRoomInfo(
      roomId: _string(json['roomId']) ?? '',
      roomName:
          _string(json['roomName']) ??
          _string(json['title']) ??
          _string(json['name']) ??
          '',
      roomAvatar:
          _string(json['roomAvatar']) ??
          _string(json['avatar']) ??
          _string(json['cover']),
      roomType: _int(json['roomType']) ?? _int(json['roomTypeValue']) ?? 0,
      inMicNum: _int(json['inMicNum']) ?? _int(json['roomInMicNum']) ?? 0,
    );
  }

  static ProfileHomepageRoomInfo? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    return ProfileHomepageRoomInfo.fromJson(json);
  }
}

List<ProfileHomepagePhoto> _extractPhotos(Map<String, dynamic> json) {
  final candidates = <Object?>[
    json['privatePhotoVOS'],
    json['photos'],
    json['photoList'],
    json['albums'],
    _map(json['photoInfo'])['privatePhotoVOS'],
  ];

  for (final candidate in candidates) {
    if (candidate is List) {
      return candidate
          .map((item) => ProfileHomepagePhoto.fromJson(_map(item)))
          .where((item) => item.url.isNotEmpty)
          .toList(growable: false);
    }
  }
  return const [];
}

List<ProfileHomepageHonorItem> _extractHonors(Map<String, dynamic> userJson) {
  final candidates = <Object?>[
    userJson['userWearMedalVOS'],
    userJson['tagPicInfos'],
    userJson['userIdentityAuthenticationList'],
  ];

  for (final candidate in candidates) {
    if (candidate is List) {
      final items = candidate
          .map((item) => ProfileHomepageHonorItem.fromJson(_map(item)))
          .where((item) => item.icon.isNotEmpty || item.id.isNotEmpty)
          .toList(growable: false);
      if (items.isNotEmpty) {
        return items..sort((a, b) => a.sortingOrder.compareTo(b.sortingOrder));
      }
    }
  }
  return const [];
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

Map<String, dynamic>? _mapOrNull(Object? value) {
  if (value == null) return null;
  return _map(value);
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _string(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

bool? _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value.toInt() != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == null || text.isEmpty) return null;
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return null;
}

bool _isFollowing(Object? value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value.toInt() > 0;
  final text = value.toString().toUpperCase();
  if (text == '1' || text == '2') return true;
  if (text.contains('FRIEND') || text.contains('FOLLOWING')) return true;
  if (text.contains('NONE') || text.contains('NOT')) return false;
  return fallback;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
