import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/models/room_lucky_animation_policy.dart';
import 'package:project/theme/app_theme.dart';

void main() {
  test('all 23 boundaries floor-match and have actual asset paths', () {
    expect(RoomLuckyNumberPolicy.levelFor(-1), 0);
    var previous = 0;
    for (final level in RoomLuckyNumberPolicy.levels) {
      expect(RoomLuckyNumberPolicy.levelFor(level - 1), previous);
      expect(RoomLuckyNumberPolicy.levelFor(level), level);
      expect(
        AppAssets.roomGiftLuckyNumbers[level],
        endsWith('luck_num$level.mp4'),
      );
      previous = level;
    }
    expect(RoomLuckyNumberPolicy.levelFor(100000), 10000);
    expect(AppAssets.roomGiftLuckyNumbers.length, 23);
  });
  test(
    'crossing several levels emits only highest and rejects repeats/regressions',
    () {
      final policy = RoomLuckyNumberPolicy();
      expect(policy.advance('a', 9), isNull);
      expect(policy.advance('a', 150), 100);
      expect(policy.advance('a', 100), isNull);
      expect(policy.advance('a', 199), isNull);
      expect(policy.advance('a', 20), isNull);
      expect(policy.advance('b', 10), 10);
      expect(policy.advance('a', 5556), 5555);
      policy.clear();
      expect(policy.advance('a', 10), 10);
    },
  );
  test(
    'bubble config supports Map/JSON, highest tier, self/other, AND/OR boundaries',
    () {
      final config = RoomLuckyBubbleConfig.parse({
        'self': {
          'small': {'count': 10, 'andMultiple': 2, 'orMultiple': 20},
          'medium': {'count': 100, 'andMultiple': 10, 'orMultiple': 50},
          'big': {'count': 1000, 'andMultiple': 20, 'orMultiple': 100},
        },
        'other': {
          'small': {'count': 500, 'andMultiple': 30, 'orMultiple': 200},
        },
      });
      RoomLuckyBubbleSize? pick(
        int amount,
        double multiple, {
        bool self = true,
      }) => config.select(isSelf: self, amount: amount, multiplier: multiple);
      expect(pick(9, 2), isNull);
      expect(pick(10, 1), isNull);
      expect(pick(10, 2), RoomLuckyBubbleSize.small);
      expect(pick(100, 10), RoomLuckyBubbleSize.medium);
      expect(pick(1000, 20), RoomLuckyBubbleSize.big);
      expect(pick(1, 100), RoomLuckyBubbleSize.big);
      expect(pick(1000, 20, self: false), isNull);
      expect(pick(500, 30, self: false), RoomLuckyBubbleSize.small);
      expect(pick(0, 1000), isNull);
      expect(pick(5000, double.nan), isNull);
      expect(
        RoomLuckyBubbleConfig.parse(
          '{"self":{"big":{"count":1,"andMultiple":1,"orMultiple":2}}}',
        ).select(isSelf: true, amount: 1, multiplier: 1),
        RoomLuckyBubbleSize.big,
      );
    },
  );
  test('missing and malformed configs never invent default thresholds', () {
    for (final raw in [
      null,
      'broken',
      [],
      {
        'self': {
          'small': {'count': -1},
        },
      },
      {'other': 3},
    ]) {
      expect(RoomLuckyBubbleConfig.parse(raw).isEmpty, isTrue);
    }
  });
}
