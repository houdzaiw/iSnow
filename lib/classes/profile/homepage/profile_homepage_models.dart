import '../../../model/user_profile.dart';

class ProfileHomepageInfo {
  const ProfileHomepageInfo({
    required this.user,
    required this.followingNum,
    required this.followerNum,
    required this.visitorNum,
    required this.receiveGiftValue,
    required this.photos,
  });

  final ProfileHomepageUser user;
  final int followingNum;
  final int followerNum;
  final int visitorNum;
  final int receiveGiftValue;
  final List<ProfileHomepagePhoto> photos;

  ProfileHomepageInfo copyWith({ProfileHomepageUser? user}) {
    return ProfileHomepageInfo(
      user: user ?? this.user,
      followingNum: followingNum,
      followerNum: followerNum,
      visitorNum: visitorNum,
      receiveGiftValue: receiveGiftValue,
      photos: photos,
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
  });

  final int uid;
  final int userNo;
  final String nick;
  final int gender;
  final int wealthLevel;
  final int charmLevel;
  final int vipLevel;
  final bool isFollowing;
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
      isFollowing: _isFollowing(json['followRelation']),
      backgroundUrl:
          _string(background['icon']) ??
          _string(background['animationUrl']) ??
          _string(background['circulationUrl']),
      wealthLevelIcon: _string(level['wealthLevelIcon']),
      charmLevelIcon: _string(level['charmLevelIcon']),
      vipIcon: _string(level['vipIcon']),
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
  const ProfileHomepagePhoto({required this.url});

  final String url;

  factory ProfileHomepagePhoto.fromJson(Map<String, dynamic> json) {
    return ProfileHomepagePhoto(
      url:
          _string(json['photoUrl']) ??
          _string(json['url']) ??
          _string(json['pic']) ??
          _string(json['image']) ??
          '',
    );
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

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
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

bool _isFollowing(Object? value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value.toInt() > 0;
  final text = value.toString().toUpperCase();
  if (text == '1' || text == '2') return true;
  if (text.contains('FRIEND') || text.contains('FOLLOWING')) return true;
  if (text.contains('NONE') || text.contains('NOT')) return false;
  return false;
}
