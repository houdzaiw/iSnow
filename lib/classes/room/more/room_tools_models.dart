import 'dart:convert';

typedef ToolJson = Map<String, dynamic>;

Object? toolDecode(Object? value) {
  if (value is! String) return value;
  try {
    return jsonDecode(value);
  } on FormatException {
    return value;
  }
}

ToolJson toolMap(Object? value) {
  final decoded = toolDecode(value);
  return decoded is Map
      ? decoded.map((key, value) => MapEntry(key.toString(), value))
      : <String, dynamic>{};
}

List<ToolJson> toolList(Object? value) {
  final decoded = toolDecode(value);
  if (decoded is List) return decoded.whereType<Map>().map(toolMap).toList();
  final map = toolMap(decoded);
  for (final key in ['list', 'records', 'rows', 'items']) {
    if (map[key] is List) return toolList(map[key]);
  }
  return const [];
}

int toolInt(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
bool toolBool(Object? value) => value == true || value == 1 || value == 'true';

class RoomFunctionConfig {
  const RoomFunctionConfig(this.items);
  final List<ToolJson> items;
  bool enabled(int type, int position) => items.any(
    (item) =>
        toolInt(item['type']) == type &&
        toolList(
          item['list'],
        ).any((entry) => toolInt(entry['position']) == position),
  );
  List<int> get moreModes => [0, if (enabled(1, 7)) 1, if (enabled(2, 7)) 2];
}

class RoomEffectPreferences {
  const RoomEffectPreferences({
    this.car = true,
    this.gift = true,
    this.bigGift = true,
    this.sound = true,
    this.screen = true,
  });
  final bool car, gift, bigGift, sound, screen;
  bool get all => car && gift && bigGift && sound && screen;
  ToolJson toJson() => {
    'car_effect': car,
    'gift_effect': gift,
    'gift_big_effect': bigGift,
    'sound_effect': sound,
    'screen_top_effect': screen,
  };
  factory RoomEffectPreferences.fromJson(ToolJson json) =>
      RoomEffectPreferences(
        car: json['car_effect'] != false,
        gift: json['gift_effect'] != false,
        bigGift: json['gift_big_effect'] != false,
        sound: json['sound_effect'] != false,
        screen: json['screen_top_effect'] != false,
      );
  RoomEffectPreferences change(String key, bool value) =>
      RoomEffectPreferences.fromJson({
        for (final entry in toJson().entries)
          entry.key: key == 'all_effect' || key == entry.key
              ? value
              : entry.value,
      });
}

class RoomPkSnapshot {
  const RoomPkSnapshot(this.raw);
  final ToolJson raw;
  ToolJson get info => toolMap(raw['pkInfo']);
  String get id => '${info['pkId'] ?? ''}';
  int get eventType => toolInt(raw['eventType']);
  bool get active => eventType == 1 || eventType == 2;
  bool get terminal => eventType == 3 || eventType == 4;
  List<ToolJson> get users => toolList(info['pkMap']);
  int secondsLeft(DateTime now) =>
      ((toolInt(info['countdown']) - now.millisecondsSinceEpoch) / 1000)
          .ceil()
          .clamp(0, 3600);
}

class RoomLuckyBag {
  const RoomLuckyBag(this.raw, this.readyAt);
  final ToolJson raw;
  final DateTime readyAt;
  String get id => '${raw['id'] ?? ''}';
  int remaining(DateTime now) =>
      (readyAt.difference(now).inMilliseconds / 1000).ceil().clamp(0, 86400);
  factory RoomLuckyBag.parse(ToolJson json, DateTime now) => RoomLuckyBag(
    json,
    now.add(
      Duration(seconds: toolInt(json['remainingTime'], 86400).clamp(0, 86400)),
    ),
  );
}

class RoomToolsState {
  const RoomToolsState({
    this.loading = false,
    this.busy = const {},
    this.error,
    this.config = const RoomFunctionConfig([]),
    this.effects = const RoomEffectPreferences(),
    this.preferencesReady = false,
    this.charmEnabled = false,
    this.currency = 0,
    this.lobbyType = 0,
    this.lobbyVisible = false,
    this.lobbyRecords = const [],
    this.lobbyAwards = const [],
    this.vehicleEffects = const [],
    this.musicStatus = 'STOPPED',
    this.treasureGifts = const [],
    this.pk = const RoomPkSnapshot({}),
    this.pkVisible = true,
    this.luckyConfig = const {},
    this.bags = const [],
    this.luckyMessages = const [],
    this.worldBanners = const [],
    this.bigWin = const {},
    this.prize = const {},
    this.balance = 0,
    this.revision = 0,
    this.sessionActive = false,
  });
  final bool loading,
      preferencesReady,
      charmEnabled,
      lobbyVisible,
      pkVisible,
      sessionActive;
  final Set<String> busy;
  final String? error;
  final RoomFunctionConfig config;
  final RoomEffectPreferences effects;
  final int currency, lobbyType, balance, revision;
  final List<ToolJson> lobbyRecords, treasureGifts, luckyMessages, worldBanners;
  final List<ToolJson> lobbyAwards;
  final List<ToolJson> vehicleEffects;
  final String musicStatus;
  final List<RoomLuckyBag> bags;
  final RoomPkSnapshot pk;
  final ToolJson luckyConfig, bigWin, prize;

  RoomToolsState copy({
    bool? loading,
    Set<String>? busy,
    String? error,
    bool clearError = false,
    RoomFunctionConfig? config,
    RoomEffectPreferences? effects,
    bool? preferencesReady,
    bool? charmEnabled,
    int? currency,
    int? lobbyType,
    bool? lobbyVisible,
    List<ToolJson>? lobbyRecords,
    List<ToolJson>? lobbyAwards,
    List<ToolJson>? vehicleEffects,
    String? musicStatus,
    List<ToolJson>? treasureGifts,
    RoomPkSnapshot? pk,
    bool? pkVisible,
    ToolJson? luckyConfig,
    List<RoomLuckyBag>? bags,
    List<ToolJson>? luckyMessages,
    List<ToolJson>? worldBanners,
    ToolJson? bigWin,
    ToolJson? prize,
    int? balance,
    bool? sessionActive,
  }) => RoomToolsState(
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
    config: config ?? this.config,
    effects: effects ?? this.effects,
    preferencesReady: preferencesReady ?? this.preferencesReady,
    charmEnabled: charmEnabled ?? this.charmEnabled,
    currency: currency ?? this.currency,
    lobbyType: lobbyType ?? this.lobbyType,
    lobbyVisible: lobbyVisible ?? this.lobbyVisible,
    lobbyRecords: lobbyRecords ?? this.lobbyRecords,
    lobbyAwards: lobbyAwards ?? this.lobbyAwards,
    vehicleEffects: vehicleEffects ?? this.vehicleEffects,
    musicStatus: musicStatus ?? this.musicStatus,
    treasureGifts: treasureGifts ?? this.treasureGifts,
    pk: pk ?? this.pk,
    pkVisible: pkVisible ?? this.pkVisible,
    luckyConfig: luckyConfig ?? this.luckyConfig,
    bags: bags ?? this.bags,
    luckyMessages: luckyMessages ?? this.luckyMessages,
    worldBanners: worldBanners ?? this.worldBanners,
    bigWin: bigWin ?? this.bigWin,
    prize: prize ?? this.prize,
    balance: balance ?? this.balance,
    revision: revision + 1,
    sessionActive: sessionActive ?? this.sessionActive,
  );
}
