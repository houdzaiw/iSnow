import 'base_user_model.dart';
import 'room_models.dart';

class RoomUserInfo {
  const RoomUserInfo({
    required this.userBase,
    required this.roomIdentity,
    required this.raw,
    this.silenceEndTime,
    this.identityConfirmed = false,
    this.isFollowing = false,
    this.vipLevel,
    this.appearance = const RoomUserAppearance(),
  });

  final BaseUserInfo userBase;
  final UserRoomIdentity roomIdentity;
  final int? silenceEndTime;
  final bool identityConfirmed;
  final bool isFollowing;
  final int? vipLevel;
  final RoomUserAppearance appearance;
  final Map<String, dynamic> raw;

  int get uid => userBase.uid;

  factory RoomUserInfo.fromJson(Map<String, dynamic> json) {
    final user = json['userBase'];
    if (user is! Map) {
      throw const FormatException('Missing room audience userBase');
    }
    final identity = userRoomIdentityFromJson(json['roomIdentity']);
    final relation = user['followRelation'];
    final levels = user['userLevel'];
    return RoomUserInfo(
      userBase: BaseUserInfo.fromJson(user.cast<String, dynamic>()),
      roomIdentity: identity ?? UserRoomIdentity.audience,
      identityConfirmed: identity != null,
      silenceEndTime: int.tryParse('${json['silenceEndTime']}'),
      isFollowing:
          relation == 'FOLLOW_FOLLOWING' || relation == 'FOLLOW_MUTUAL',
      vipLevel: levels is Map ? int.tryParse('${levels['vipLevel']}') : null,
      appearance: RoomUserAppearance.fromJson(user.cast<String, dynamic>()),
      raw: json,
    );
  }
}

/// Optional decorations returned by Nady's room user endpoint.
class RoomUserAppearance {
  const RoomUserAppearance({
    this.frameUrl,
    this.framePreview,
    this.badges = const [],
    this.identityBadges = const [],
    this.levels = const [],
  });
  final String? frameUrl, framePreview;
  final List<String> badges, identityBadges;
  final List<RoomUserLevelBadge> levels;

  factory RoomUserAppearance.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(Object? value) =>
        value is Map ? Map<String, dynamic>.from(value) : const {};
    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;
    final levels = map(json['userLevel']);
    final frame = map(json['avatarWidget']);
    final medals =
        (json['userWearMedalVOS'] is List
              ? (json['userWearMedalVOS'] as List).whereType<Map>().toList()
              : <Map>[])
          ..sort(
            (a, b) => (int.tryParse('${a['sortingOrder']}') ?? 0).compareTo(
              int.tryParse('${b['sortingOrder']}') ?? 0,
            ),
          );
    return RoomUserAppearance(
      frameUrl: text(frame['animationUrl']) ?? text(frame['icon']),
      framePreview: text(frame['icon']),
      levels: List.unmodifiable([
        for (final kind in RoomUserLevelKind.values)
          if (int.tryParse('${levels['${kind.name}Level']}') case final level?)
            if (text(levels['${kind.name}LevelIcon']) case final icon?)
              RoomUserLevelBadge(kind: kind, level: level, icon: icon),
      ]),
      badges: List.unmodifiable([
        if ((int.tryParse('${levels['vipLevel']}') ?? 0) > 0)
          if (text(levels['vipIcon']) case final icon?) icon,
        if ((int.tryParse('${levels['aristocracyLevel']}') ?? 0) > 0)
          if (text(levels['aristocracyIcon']) ??
                  text(levels['aristocracyEnIcon'])
              case final icon?)
            icon,
        for (final medal in medals)
          if (text(medal['icon']) case final icon?) icon,
      ]),
      identityBadges: List.unmodifiable([
        if (json['userIdentityAuthenticationList'] case final List identities)
          for (final item in identities.whereType<Map>())
            if (text(item['idCardUrl']) case final icon?) icon,
      ]),
    );
  }
}

enum RoomUserLevelKind { wealth, charm, active }

class RoomUserLevelBadge {
  const RoomUserLevelBadge({
    required this.kind,
    required this.level,
    required this.icon,
  });
  final RoomUserLevelKind kind;
  final int level;
  final String icon;
}
