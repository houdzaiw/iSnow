import 'dart:convert';

enum RoomLuckyBubbleSize { small, medium, big }

/// Nady's 23 cumulative thresholds. Crossing several plays only the highest.
class RoomLuckyNumberPolicy {
  static const levels = [
    10,
    20,
    30,
    50,
    66,
    88,
    100,
    200,
    300,
    400,
    500,
    1000,
    2000,
    5000,
    5555,
    6000,
    6666,
    7000,
    7777,
    8000,
    8888,
    9000,
    10000,
  ];
  final _history = <String, int>{};

  static int levelFor(int count) =>
      levels.where((level) => level <= count).lastOrNull ?? 0;

  int? advance(String identity, int count) {
    final level = levelFor(count);
    final old = _history[identity] ?? 0;
    if (level <= old) return null;
    _history[identity] = level;
    while (_history.length > 300) {
      _history.remove(_history.keys.first);
    }
    return level;
  }

  void clear() => _history.clear();
}

class RoomLuckyBubbleRule {
  const RoomLuckyBubbleRule(this.count, this.andMultiple, this.orMultiple);
  final int count, andMultiple, orMultiple;

  static RoomLuckyBubbleRule? parse(Object? raw) {
    if (raw is! Map) return null;
    int? read(String key) => int.tryParse('${raw[key]}');
    final count = read('count');
    final and = read('andMultiple');
    final or = read('orMultiple');
    if (count == null ||
        and == null ||
        or == null ||
        count < 0 ||
        and < 0 ||
        or < 0) {
      return null;
    }
    return RoomLuckyBubbleRule(count, and, or);
  }

  bool matches(int amount, double multiple) =>
      amount >= count && multiple.toInt() >= andMultiple ||
      multiple.toInt() >= orMultiple;
}

/// `gift_award_bubble_config`, with independent self/other thresholds.
class RoomLuckyBubbleConfig {
  const RoomLuckyBubbleConfig({this.self = const {}, this.other = const {}});
  final Map<RoomLuckyBubbleSize, RoomLuckyBubbleRule> self, other;

  factory RoomLuckyBubbleConfig.parse(Object? raw) {
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        return const RoomLuckyBubbleConfig();
      }
    }
    if (raw is! Map) return const RoomLuckyBubbleConfig();
    Map<RoomLuckyBubbleSize, RoomLuckyBubbleRule> rules(Object? value) => {
      if (value is Map)
        for (final size in RoomLuckyBubbleSize.values)
          if (RoomLuckyBubbleRule.parse(value[size.name]) case final rule?)
            size: rule,
    };
    return RoomLuckyBubbleConfig(
      self: Map.unmodifiable(rules(raw['self'])),
      other: Map.unmodifiable(rules(raw['other'])),
    );
  }

  bool get isEmpty => self.isEmpty && other.isEmpty;
  RoomLuckyBubbleSize? select({
    required bool isSelf,
    required int amount,
    required double multiplier,
  }) {
    if (amount <= 0 || !multiplier.isFinite || multiplier < 0) return null;
    final rules = isSelf ? self : other;
    for (final size in RoomLuckyBubbleSize.values.reversed) {
      if (rules[size]?.matches(amount, multiplier) == true) return size;
    }
    return null;
  }
}
