import 'dart:convert';

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
    this.gender,
    this.countryCode,
    this.badges = const [],
    this.identityBadges = const [],
    this.levels = const [],
    this.publicBadges = const [],
  });
  final String? frameUrl, framePreview;
  final int? gender;
  final String? countryCode;
  final List<String> badges, identityBadges;
  final List<RoomUserLevelBadge> levels;
  final List<RoomUserChatBadge> publicBadges;

  factory RoomUserAppearance.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(Object? value) {
      if (value is String) {
        try {
          value = jsonDecode(value);
        } on FormatException {
          return const {};
        }
      }
      return value is Map
          ? {
              for (final entry in value.entries)
                if (entry.key is String) entry.key as String: entry.value,
            }
          : const {};
    }

    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;
    final levels = map(json['userLevel']);
    final frame = map(json['avatarWidget']);
    final gender = int.tryParse('${json['gender']}');
    final country = text(json['countryCode'])?.toUpperCase();
    Map<String, String> localized(
      Map<String, dynamic> source,
      String prefix, {
      String suffix = '',
    }) => {
      for (final language in const {
        'en': 'En',
        'ar': 'Ar',
        'tr': 'Tr',
        'id': 'Id',
      }.entries)
        if (text(source['$prefix${language.value}$suffix']) case final url?)
          language.key: url,
    };
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
      gender: gender == 1 || gender == 2 ? gender : null,
      countryCode: country != null && RegExp(r'^[A-Z]{2}$').hasMatch(country)
          ? country
          : null,
      levels: List.unmodifiable([
        for (final kind in RoomUserLevelKind.values)
          if (int.tryParse('${levels['${kind.name}Level']}') case final level?)
            if (level > 0)
              RoomUserLevelBadge(
                kind: kind,
                level: level,
                icon: text(levels['${kind.name}LevelIcon']) ?? '',
              ),
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
      publicBadges: List.unmodifiable([
        if ((int.tryParse('${levels['aristocracyLevel']}') ?? 0) > 0)
          RoomUserChatBadge(
            kind: RoomUserChatBadgeKind.noble,
            icon: text(levels['aristocracyIcon']) ?? '',
            localizedIcons: localized(levels, 'aristocracy', suffix: 'Icon'),
          ),
        if ((int.tryParse('${levels['vipLevel']}') ?? 0) > 0)
          RoomUserChatBadge(
            kind: RoomUserChatBadgeKind.vip,
            icon: text(levels['vipMedal']) ?? text(levels['vipIcon']) ?? '',
          ),
        if (localized(levels, 'plaque').isNotEmpty)
          RoomUserChatBadge(
            kind: RoomUserChatBadgeKind.plaque,
            localizedIcons: localized(levels, 'plaque'),
          ),
        if (json['tagPicInfos'] case final List tags)
          for (final tag in tags.whereType<Map>())
            if (text(tag['tagPic']) case final icon?)
              RoomUserChatBadge(kind: RoomUserChatBadgeKind.tag, icon: icon),
        for (final medal in medals)
          if (text(medal['icon']) case final icon?)
            RoomUserChatBadge(kind: RoomUserChatBadgeKind.medal, icon: icon),
        if (json['userIdentityAuthenticationList'] case final List identities)
          for (final item in identities.whereType<Map>())
            if (text(item['idCardUrl']) case final icon?)
              RoomUserChatBadge(
                kind: RoomUserChatBadgeKind.identity,
                icon: icon,
              ),
      ]),
    );
  }
}

enum RoomUserChatBadgeKind { noble, vip, plaque, tag, medal, identity }

/// Images belong to the sender; Lanhu's sample badges never supply user data.
class RoomUserChatBadge {
  const RoomUserChatBadge({
    required this.kind,
    this.icon = '',
    this.localizedIcons = const {},
  });
  final RoomUserChatBadgeKind kind;
  final String icon;
  final Map<String, String> localizedIcons;

  String iconForLanguage(String language) =>
      localizedIcons[language.toLowerCase().split(RegExp('[-_]')).first] ??
      localizedIcons['en'] ??
      icon;
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
