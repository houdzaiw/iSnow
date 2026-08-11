part of '../rank_page.dart';

enum _RankCategory {
  wealth(rankType: 1),
  charm(rankType: 2),
  room(rankType: 3);

  const _RankCategory({required this.rankType});

  final int rankType;

  String label(BuildContext context) {
    return switch (this) {
      _RankCategory.wealth => context.l10n.t('rank.wealth'),
      _RankCategory.charm => context.l10n.t('rank.charm'),
      _RankCategory.room => context.l10n.t('rank.room'),
    };
  }
}

enum _RankPeriod {
  daily(frequencyType: 5),
  weekly(frequencyType: 4),
  total(frequencyType: 3);

  const _RankPeriod({required this.frequencyType});

  final int frequencyType;

  String label(BuildContext context) {
    return switch (this) {
      _RankPeriod.daily => context.l10n.t('rank.daily'),
      _RankPeriod.weekly => context.l10n.t('rank.weekly'),
      _RankPeriod.total => context.l10n.t('rank.total'),
    };
  }
}

class _RankBoard {
  const _RankBoard({required this.entries, required this.countdown, this.me});

  final List<_RankEntry> entries;
  final _RankEntry? me;
  final int countdown;
}

class _RankEntry {
  const _RankEntry({
    required this.uid,
    required this.userNo,
    required this.name,
    required this.rankValue,
    required this.seqNo,
    this.avatar,
    this.country,
    this.roomId,
    this.userLevel,
    this.tagPics = const <String>[],
  });

  final int uid;
  final int userNo;
  final String name;
  final int rankValue;
  final int seqNo;
  final String? avatar;
  final String? country;
  final String? roomId;
  final _RankUserLevel? userLevel;
  final List<String> tagPics;

  String get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'DUMO 001' : trimmed;
  }

  String get valueText {
    if (rankValue >= 1000000) {
      return '${(rankValue / 1000000).toStringAsFixed(2)}M';
    }
    if (rankValue >= 1000) {
      return '${(rankValue / 1000).toStringAsFixed(1)}K';
    }
    return '$rankValue';
  }

  factory _RankEntry.fromUserJson(Map<dynamic, dynamic> json) {
    return _RankEntry(
      uid: _rankInt(json['uid']),
      userNo: _rankInt(json['userNo']),
      name: _rankString(json['nick']) ?? '',
      rankValue: _rankInt(json['rankVal']),
      seqNo: _rankInt(json['seqNo']),
      avatar: _rankString(json['avatar']),
      country: _rankString(json['country']),
      userLevel: _RankUserLevel.fromJson(_rankMapOrNull(json['userLevel'])),
      tagPics: _rankStringList(json['tagPic']),
    );
  }

  factory _RankEntry.fromRoomJson(Map<dynamic, dynamic> json) {
    return _RankEntry(
      uid: _rankInt(json['uid']),
      userNo: _rankInt(json['userNo']),
      name: _rankString(json['title']) ?? '',
      rankValue: _rankInt(json['rankVal']),
      seqNo: _rankInt(json['seqNo']),
      avatar: _rankString(json['avatar']),
      country: _rankString(json['country']),
      roomId: _rankString(json['roomId']),
    );
  }
}

class _RankUserLevel {
  const _RankUserLevel({
    this.activeLevel,
    this.activeLevelIcon,
    this.charmLevel,
    this.charmLevelIcon,
    this.wealthLevel,
    this.wealthLevelIcon,
    this.vipLevel,
    this.vipIcon,
  });

  final int? activeLevel;
  final String? activeLevelIcon;
  final int? charmLevel;
  final String? charmLevelIcon;
  final int? wealthLevel;
  final String? wealthLevelIcon;
  final int? vipLevel;
  final String? vipIcon;

  int? levelFor(_RankCategory category) {
    return switch (category) {
      _RankCategory.wealth => wealthLevel ?? vipLevel,
      _RankCategory.charm => charmLevel ?? vipLevel,
      _RankCategory.room => activeLevel ?? vipLevel,
    };
  }

  String? iconFor(_RankCategory category) {
    return switch (category) {
      _RankCategory.wealth => wealthLevelIcon ?? vipIcon,
      _RankCategory.charm => charmLevelIcon ?? vipIcon,
      _RankCategory.room => activeLevelIcon ?? vipIcon,
    };
  }

  factory _RankUserLevel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const _RankUserLevel();
    return _RankUserLevel(
      activeLevel: _rankIntOrNull(json['activeLevel']),
      activeLevelIcon: _rankString(json['activeLevelIcon']),
      charmLevel: _rankIntOrNull(json['charmLevel']),
      charmLevelIcon: _rankString(json['charmLevelIcon']),
      wealthLevel: _rankIntOrNull(json['wealthLevel']),
      wealthLevelIcon: _rankString(json['wealthLevelIcon']),
      vipLevel: _rankIntOrNull(json['vipLevel']),
      vipIcon: _rankString(json['vipIcon']),
    );
  }
}

Map<String, dynamic> _rankMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

Map<String, dynamic>? _rankMapOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

String? _rankString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _rankInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _rankIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

List<String> _rankStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => _rankString(item))
      .whereType<String>()
      .toList(growable: false);
}
