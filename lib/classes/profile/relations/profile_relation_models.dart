import 'profile_relation_type.dart';

class ProfileRelationUser {
  const ProfileRelationUser({
    required this.uid,
    required this.nick,
    required this.avatar,
    required this.gender,
    required this.wealthLevel,
    required this.charmLevel,
    required this.vipLevel,
    required this.isFollowing,
    this.visitTime,
  });

  final int uid;
  final String nick;
  final String? avatar;
  final int gender;
  final int wealthLevel;
  final int charmLevel;
  final int vipLevel;
  final bool isFollowing;
  final int? visitTime;

  ProfileRelationUser copyWith({bool? isFollowing}) {
    return ProfileRelationUser(
      uid: uid,
      nick: nick,
      avatar: avatar,
      gender: gender,
      wealthLevel: wealthLevel,
      charmLevel: charmLevel,
      vipLevel: vipLevel,
      isFollowing: isFollowing ?? this.isFollowing,
      visitTime: visitTime,
    );
  }

  factory ProfileRelationUser.fromJson(
    Map<String, dynamic> json, {
    required ProfileRelationType type,
  }) {
    final base = _asMap(
      json['userBaseInfo'] ??
          json['userBase'] ??
          json['userInfo'] ??
          json['targetUser'] ??
          json['targetUserInfo'] ??
          json,
    );
    final level = _asMap(base['userLevel']);
    final followRelation =
        base['followRelation'] ?? json['followRelation'] ?? json['relation'];

    return ProfileRelationUser(
      uid: _int(base['uid']) ?? _int(json['uid']) ?? 0,
      nick: _string(base['nick']) ?? _string(json['nick']) ?? '',
      avatar: _string(base['avatar']) ?? _string(json['avatar']),
      gender: _int(base['gender']) ?? 0,
      wealthLevel: _int(level['wealthLevel']) ?? 0,
      charmLevel: _int(level['charmLevel']) ?? 0,
      vipLevel: _int(level['vipLevel']) ?? 0,
      isFollowing: _isFollowing(
        followRelation,
        defaultValue: type == ProfileRelationType.following,
      ),
      visitTime: _int(json['visitTime']) ?? _int(json['detailVisitTime']),
    );
  }
}

class ProfileRelationPageResult {
  const ProfileRelationPageResult({
    required this.items,
    required this.hasMore,
    required this.pageNum,
  });

  final List<ProfileRelationUser> items;
  final bool hasMore;
  final int pageNum;
}

Map<String, dynamic> _asMap(Object? value) {
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

bool _isFollowing(Object? value, {required bool defaultValue}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value.toInt() > 0;
  final text = value.toString().toUpperCase();
  if (text.contains('FRIEND') || text.contains('FOLLOWING')) return true;
  if (text == '1' || text == '2') return true;
  if (text.contains('NONE') || text.contains('NOT')) return false;
  return defaultValue;
}
