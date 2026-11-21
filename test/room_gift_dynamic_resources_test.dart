import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/effects/room_gift_asset_resolver.dart';
import 'package:project/classes/room/gift/models/room_gift_effect_task.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/models/room_lucky_animation_policy.dart';

void main() {
  test(
    '23 real number VAPs replace nickname, not a flattened text overlay',
    () async {
      for (final level in RoomLuckyNumberPolicy.levels) {
        final resolver = _LuckyResolver();
        final resource = await resolver.resolveLucky(
          RoomLuckyGiftResult(
            key: 'number-$level',
            sender: const RoomGiftUser(uid: 10, name: 'Lucky sender'),
            amount: 0,
            numberLevel: level,
          ),
          config: const RoomLuckyBubbleConfig(),
          currentUid: 10,
        );
        expect(resource!.replacements, {'text': 'Lucky sender'});
        expect(resource.file!.path, endsWith('luck_num$level.mp4'));
      }
    },
  );
  test(
    'three bubble VAPs use only actual declared Avatar/Win/Times slots',
    () async {
      for (final (size, multiple) in [
        ('small', 10),
        ('medium', 100),
        ('big', 1000),
      ]) {
        final resolver = _LuckyResolver();
        final resource = await resolver.resolveLucky(
          const RoomLuckyGiftResult(
            key: 'bubble',
            sender: RoomGiftUser(uid: 10, avatar: 'avatar.png'),
            amount: 1234,
            multiplier: 10,
          ),
          config: RoomLuckyBubbleConfig.parse({
            'self': {
              size: {'count': 1, 'andMultiple': 1, 'orMultiple': multiple},
            },
          }),
          currentUid: 10,
        );
        expect(resource!.file!.path, endsWith('luck_win_$size.mp4'));
        expect(resource.replacements, {
          'Avatar': '/local/avatar.png',
          'Win': 'Win 1234',
          'Times': '10 times',
        });
      }
    },
  );
  RoomGiftEffectTask task({String? giftIcon}) => RoomGiftEffectTask(
    key: 'prize',
    createdAt: DateTime(2026),
    giftIcon: giftIcon,
    kind: RoomGiftEffectKind.prize,
    message: const RoomScreenGiftMsg(
      uid: 10,
      userInfo: RoomGiftUser(uid: 10, name: 'Winner', avatar: 'avatar.png'),
      gift: RoomGift(
        id: -1,
        name: '',
        icon: 'effect.png',
        price: 0,
        tabId: -1,
        isCombo: 0,
      ),
      giftCount: 1,
    ),
  );
  test('actual Rocket VAP declares name and user slots only', () async {
    final resolver = _Resolver('assets/room_gift/big_rocket_fly_lv1.mp4');
    final result = await resolver.resolveTask(task());
    expect(result.replacements, {
      'name': 'Winner',
      'user': '/local/avatar.png',
    });
    expect(resolver.images, ['avatar.png']);
  });
  test(
    'actual SUPER VAP uses original gift image, not animation artwork',
    () async {
      final resolver = _Resolver(
        'assets/room_gift/jackpot_full_screen_anim.mp4',
      );
      final result = await resolver.resolveTask(
        task(giftIcon: 'actual-gift.png'),
      );
      expect(result.replacements, {'gift': '/local/actual-gift.png'});
      expect(resolver.images, ['actual-gift.png']);
    },
  );
  test(
    'VAP without slots does not download unrelated avatars or gifts',
    () async {
      final resolver = _Resolver(
        'assets/room_gift/jackpot_gift_panel_anim.mp4',
      );
      final result = await resolver.resolveTask(task());
      expect(result.replacements, isEmpty);
      expect(resolver.images, isEmpty);
    },
  );
  test('plain MP4 is not probed for VAP replacements', () async {
    final resolver = _Resolver(
      'missing.mp4',
      format: RoomGiftAnimationFormat.mp4,
    );
    final result = await resolver.resolveTask(task());
    expect(result.replacements, isEmpty);
  });
}

class _LuckyResolver extends RoomGiftAssetResolver {
  @override
  Future<RoomGiftAnimationResource> resolveSource(
    String source, {
    required RoomGiftAnimationFormat format,
    int mode = 1,
  }) async => RoomGiftAnimationResource(
    format: format,
    videoMode: mode,
    file: File(source),
  );
  @override
  Future<File> resolveImage(String source) async => File('/local/$source');
}

class _Resolver extends RoomGiftAssetResolver {
  _Resolver(this.path, {this.format = RoomGiftAnimationFormat.vap});
  final String path;
  final RoomGiftAnimationFormat format;
  final List<String> images = [];
  @override
  Future<RoomGiftAnimationResource> resolve(RoomGift gift) async =>
      RoomGiftAnimationResource(format: format, videoMode: 1, file: File(path));
  @override
  Future<File> resolveImage(String source) async {
    images.add(source);
    return File('/local/$source');
  }
}
