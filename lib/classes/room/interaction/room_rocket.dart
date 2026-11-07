import 'dart:convert';

class RoomRocket {
  const RoomRocket({
    required this.roomId,
    required this.stage,
    required this.level,
    required this.progress,
    required this.countries,
    this.activity,
    this.history,
  });

  final String roomId;
  final int stage, level;
  final double progress;
  final Set<String> countries;
  final String? activity, history;

  static RoomRocket? parse(Object? value) {
    Object? decoded = value;
    if (value is String) {
      try {
        decoded = jsonDecode(value);
      } on FormatException {
        return null;
      }
    }
    if (decoded is! Map) return null;
    final nested = decoded['msg'];
    if (nested is Map || nested is String) return parse(nested);
    final roomId = decoded['roomId']?.toString().trim() ?? '';
    if (roomId.isEmpty) return null;
    final countryCodes = decoded['countryCodes'];
    final fraction = double.tryParse('${decoded['progress']}');
    return RoomRocket(
      roomId: roomId,
      stage: (int.tryParse('${decoded['showStatus']}') ?? 1).clamp(1, 3),
      level: (int.tryParse('${decoded['level']}') ?? 1).clamp(1, 6),
      progress: fraction != null && fraction.isFinite
          ? fraction.clamp(0.0, 1.0)
          : 0,
      countries: {
        if (countryCodes is List)
          for (final code in countryCodes.whereType<String>())
            if (code.trim().isNotEmpty) code.trim().toUpperCase(),
      },
      activity: decoded['rocketUrl']?.toString(),
      history: decoded['prizeHisUrl']?.toString(),
    );
  }

  bool visibleFor(String? country) =>
      countries.isEmpty ||
      country == null ||
      country.isEmpty ||
      countries.contains(country.toUpperCase());

  RoomRocket withLinksFrom(RoomRocket? old) => RoomRocket(
    roomId: roomId,
    stage: stage,
    level: level,
    progress: progress,
    countries: countries.isEmpty ? old?.countries ?? countries : countries,
    activity: activity ?? old?.activity,
    history: history ?? old?.history,
  );

  Uri? link(String language, {bool results = false}) {
    final source = results ? history : activity;
    if (source == null || source.trim().isEmpty) return null;
    final url = source
        .replaceAll(r'${roomId}', Uri.encodeComponent(roomId))
        .replaceAll(r'${language}', Uri.encodeComponent(language));
    final parsed = Uri.tryParse(url);
    if (parsed == null ||
        parsed.host.isEmpty ||
        parsed.userInfo.isNotEmpty ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      return null;
    }
    return parsed.replace(
      queryParameters: {
        ...parsed.queryParametersAll,
        'roomId': roomId,
        'language': language,
      },
    );
  }
}
