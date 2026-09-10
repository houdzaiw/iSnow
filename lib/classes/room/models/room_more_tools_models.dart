enum RoomMoreBannerPosition {
  game(5),
  additionalTool(7);

  const RoomMoreBannerPosition(this.value);

  final int value;
}

enum RoomLobbyToolType {
  gameDefault(1, 'room.more.mode.gameHall'),
  gameMining(2, 'room.more.mode.mining'),
  gameSquare(7, 'room.more.mode.gameSquare'),
  gameGrandPrize(8, 'room.more.mode.grandPrize'),
  gameMenu(11, 'room.more.mode.gameMenu'),
  mapSocial(12, 'room.more.mode.mapSocial');

  const RoomLobbyToolType(this.value, this.labelKey);

  final int value;
  final String labelKey;
}

class RoomToolBanner {
  const RoomToolBanner({
    required this.raw,
    this.id,
    this.name,
    this.pic,
    this.routeUrl,
    this.smallIcon,
    this.picHash,
    this.routeType,
    this.tagList = const [],
  });

  final int? id;
  final String? name;
  final String? pic;
  final String? routeUrl;
  final String? smallIcon;
  final String? picHash;
  final int? routeType;
  final List<String> tagList;
  final Map<String, dynamic> raw;

  String get displayName {
    final value = name?.trim();
    return value == null || value.isEmpty ? 'Tool' : value;
  }

  String get iconUrl => _firstNonEmpty([smallIcon, pic, picHash]) ?? '';

  bool get hasRouteUrl => routeUrl != null && routeUrl!.trim().isNotEmpty;

  String resolvedRouteUrl({
    required String roomId,
    required String languageCode,
  }) {
    final rawUrl = routeUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return '';

    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme.isEmpty) return rawUrl;

    final queryParameters = Map<String, String>.from(uri.queryParameters);
    if (languageCode.trim().isNotEmpty) {
      queryParameters['language'] = languageCode.trim();
    }
    if (roomId.trim().isNotEmpty) {
      queryParameters['roomId'] = roomId.trim();
    }
    return uri.replace(queryParameters: queryParameters).toString();
  }

  factory RoomToolBanner.fromJson(Map<String, dynamic> json) {
    return RoomToolBanner(
      id: _intValue(json['id']),
      name: _stringValue(json['name'] ?? json['title']),
      pic: _stringValue(json['pic'] ?? json['image'] ?? json['icon']),
      routeUrl: _stringValue(
        json['routeUrl'] ?? json['routeURL'] ?? json['url'],
      ),
      smallIcon: _stringValue(json['smallIcon'] ?? json['small_icon']),
      picHash: _stringValue(json['pichash'] ?? json['picHash']),
      routeType: _intValue(json['routeType']),
      tagList: _stringList(json['tagList'] ?? json['tags']),
      raw: json,
    );
  }
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

String? _stringValue(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}
