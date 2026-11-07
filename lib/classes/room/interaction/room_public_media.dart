import 'dart:convert';

import '../../../manager/http_api.dart';
import 'room_interaction_repository.dart';

String? roomMediaUrl(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty &&
          (uri.scheme == 'http' || uri.scheme == 'https')
      ? uri.toString()
      : null;
}

Map<String, dynamic> _decode(Object? source) {
  if (source is Map) return roomInteractionMap(source);
  if (source is! String) return const {};
  try {
    return roomInteractionMap(jsonDecode(source));
  } on FormatException {
    return const {};
  }
}

String? roomPublicImage(Object? source) {
  final data = _decode(source);
  return roomMediaUrl(source) ??
      roomMediaUrl(data['url'] ?? data['imageUrl'] ?? data['picUrl']);
}

class RoomExpression {
  const RoomExpression({
    required this.id,
    required this.preview,
    required this.media,
    required this.allowed,
    required this.type,
    required this.payload,
  });

  factory RoomExpression.fromJson(Map<String, dynamic> json) {
    final dynamicPic = roomMediaUrl(json['dynamicPic']);
    final ext = Uri.tryParse(dynamicPic ?? '')?.path.toLowerCase() ?? '';
    final preview = roomMediaUrl(json['staticPic']);
    final type = int.tryParse('${json['type']}') ?? 1;
    final rank = roomInteractionMap(json['aristocracyInfo']);
    final allowed =
        rank.isEmpty ||
        (int.tryParse('${rank['userCurAristocracyLevel']}') ?? 0) >=
            (int.tryParse('${rank['aristocracyLevel']}') ?? 1);
    return RoomExpression(
      id: int.tryParse('${json['id']}') ?? 0,
      preview: preview,
      media:
          [
            '.gif',
            '.webp',
            '.png',
            '.jpg',
            '.jpeg',
            '.svga',
            '.pag',
            '.mp4',
            '.vap',
          ].any(ext.endsWith)
          ? dynamicPic
          : (roomMediaUrl(json['endPic']) ?? preview),
      allowed: allowed,
      type: type,
      payload: Map.unmodifiable(json),
    );
  }
  final int id, type;
  final String? preview, media;
  final bool allowed;
  final Map<String, dynamic> payload;

  String encode() => jsonEncode(payload);
  static RoomExpression parse(Object? source) =>
      RoomExpression.fromJson(_decode(source));
}

class RoomExpressionPack {
  const RoomExpressionPack(this.cover, this.items);
  final String? cover;
  final List<RoomExpression> items;
}

extension RoomPublicMediaRepository on RoomInteractionRepository {
  Future<List<RoomExpressionPack>> expressions() async {
    final data = await get(HttpApi.roomExpressions, {});
    if (data is! List) return const [];
    return [
      for (final item in data.whereType<Map>())
        if (item['expressionInfoDTOS'] case final List faces)
          RoomExpressionPack(
            roomMediaUrl(item['pic']),
            faces
                .whereType<Map>()
                .map((e) => RoomExpression.fromJson(roomInteractionMap(e)))
                .where((e) => e.id > 0)
                .toList(growable: false),
          ),
    ];
  }
}
