import '../more/room_tools_models.dart';

class RoomLuckyBoxAmount {
  const RoomLuckyBoxAmount(this.gold, this.people);
  final int gold;
  final List<int> people;
}

class RoomLuckyBoxMode {
  const RoomLuckyBoxMode(this.amounts, this.countdowns);
  final List<RoomLuckyBoxAmount> amounts;
  final List<int> countdowns;
  factory RoomLuckyBoxMode.fromJson(ToolJson json) => RoomLuckyBoxMode([
    for (final item in toolList(json['configuration']))
      if (toolInt(item['goldQuantiry']) > 0)
        RoomLuckyBoxAmount(
          toolInt(item['goldQuantiry']),
          _ints(item['numberOfRecipients'], positive: true),
        ),
  ], _ints(json['countdown']));
}

List<int> _ints(Object? raw, {bool positive = false}) => raw is List
    ? raw.map(toolInt).where((n) => positive ? n > 0 : n >= 0).toSet().toList()
    : [];

class RoomLuckyBoxConfig {
  const RoomLuckyBoxConfig({
    required this.room,
    required this.world,
    this.rulesEn = '',
    this.rulesAr = '',
  });
  final RoomLuckyBoxMode room, world;
  final String rulesEn, rulesAr;
  factory RoomLuckyBoxConfig.fromJson(ToolJson json) => RoomLuckyBoxConfig(
    room: RoomLuckyBoxMode.fromJson(toolMap(json['room'])),
    world: RoomLuckyBoxMode.fromJson(toolMap(json['world'])),
    rulesEn: '${json['rulesUrlEn'] ?? ''}',
    rulesAr: '${json['rulesUrlAr'] ?? ''}',
  );
  String rules(String language) {
    final value = language == 'ar' && rulesAr.isNotEmpty ? rulesAr : rulesEn;
    final uri = Uri.tryParse(value);
    return uri != null &&
            ['http', 'https'].contains(uri.scheme) &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri.toString()
        : '';
  }

  bool rulesAreImage(String language) {
    final uri = Uri.tryParse(rules(language));
    return uri != null &&
        RegExp(
          r'\.(jpe?g|png|webp|gif)$',
          caseSensitive: false,
        ).hasMatch(uri.path);
  }
}

class RoomLuckyBoxResult {
  const RoomLuckyBoxResult(this.count, this.icon, {this.raw = const {}});
  final ToolJson raw;
  final int count;
  final String icon;
  factory RoomLuckyBoxResult.fromJson(ToolJson json) => RoomLuckyBoxResult(
    toolInt(json['count']),
    '${json['icon'] ?? ''}',
    raw: json,
  );
}
