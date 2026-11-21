import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/barrage/room_barrage_models.dart';
import 'package:project/classes/room/barrage/room_barrage_parser.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/model/room_socket_message.dart';

final barrageNow = DateTime(2026, 11, 20, 10);
RoomSocketMessage barrageMessage(
  String event,
  Map<String, dynamic> data, {
  String channel = 'room',
  String? id = 'event',
  DateTime? time,
}) => RoomSocketMessage(
  channel: channel,
  event: event,
  payload: data,
  msgId: id,
  raw: const {},
  receivedAt: time ?? barrageNow,
);
Map<String, dynamic> giftBanner({String room = '123', int uid = 20}) => {
  'roomId': room,
  'sendUserInfo': {'uid': uid, 'nick': 'Sender'},
  'giftId': 31,
  'giftPic': '',
  'giftName': 'Rose',
  'giftNum': 8,
  'bannerContentObj': jsonEncode({'en': 'Sender sent Rose', 'ar': 'هدية'}),
};
void main() {
  final parser = RoomBarrageParser();
  RoomBarrageTask? parse(
    RoomSocketMessage message, {
    String? country = 'US',
    RoomScreenGiftMsg? Function(int)? active,
  }) => parser.parse(
    message,
    now: barrageNow,
    uid: 10,
    currentRoomId: '123',
    countryCode: country,
    activeJackpotGift: active,
  );
  test('ordinary/lucky gift fields and Map/JSON content use Nady contract', () {
    final ordinary = parse(
      barrageMessage('RoomGiftSendBannerEvent', giftBanner()),
    )!;
    expect(ordinary.kind, RoomBarrageKind.gift);
    expect(ordinary.sender.uid, 20);
    expect(ordinary.giftId, 31);
    expect(ordinary.text('ar'), 'هدية');
    expect(ordinary.text('tr'), 'Sender sent Rose');
    expect(ordinary.action('123').kind, RoomBarrageActionKind.none);
    expect(ordinary.action('other').roomId, '123');
    final lucky = parse(
      barrageMessage('RoomLuckGiftSendBannerEvent', {
        'roomId': '123',
        'userBaseInfo': {'uid': 22, 'nick': 'Winner'},
        'giftInfo': {'id': 31, 'price': 10},
        'multiply': 100,
        'amount': 1000,
      }),
    )!;
    expect(lucky.kind, RoomBarrageKind.lucky);
    expect(lucky.amount, 1000);
    expect(lucky.multiplier, 100);
  });
  test(
    'cross-channel IDs and canonical fallback deduplicate without collapsing distinct IDs',
    () {
      final data = giftBanner();
      final room = parse(
        barrageMessage('RoomGiftSendBannerEvent', data, channel: 'room:123'),
      )!;
      final global = parse(barrageMessage('RoomGiftSendBannerEvent', data))!;
      expect(room.key, global.key);
      expect(
        parse(
          barrageMessage('RoomGiftSendBannerEvent', data, id: 'second'),
        )!.key,
        isNot(room.key),
      );
      final noId = parse(
        barrageMessage('RoomGiftSendBannerEvent', data, id: null),
      )!;
      expect(
        noId.key,
        parse(
          barrageMessage(
            'RoomGiftSendBannerEvent',
            Map.fromEntries(data.entries.toList().reversed),
            id: null,
          ),
        )!.key,
      );
    },
  );
  test(
    'channels, other account, room binding, TTL and country constraints',
    () {
      expect(
        parse(
          barrageMessage(
            'RoomGiftSendBannerEvent',
            giftBanner(),
            channel: 'global:11',
          ),
        ),
        isNull,
      );
      expect(
        parse(
          barrageMessage(
            'RoomGiftSendBannerEvent',
            giftBanner(room: '999'),
            channel: 'room:123',
          ),
        ),
        isNull,
      );
      expect(
        parse(
          barrageMessage('RoomGiftSendBannerEvent', giftBanner(room: '999')),
        )!.roomId,
        '999',
      );
      expect(
        parse(
          barrageMessage('RoomGiftSendBannerEvent', {
            ...giftBanner(),
            'countryCodes': ['TR'],
          }),
        ),
        isNull,
      );
      expect(
        parse(
          barrageMessage('RoomGiftSendBannerEvent', {
            ...giftBanner(),
            'countryCodes': ['us'],
          }),
        ),
        isNotNull,
      );
      expect(
        parse(
          barrageMessage(
            'RoomGiftSendBannerEvent',
            giftBanner(),
            time: barrageNow.subtract(const Duration(seconds: 11)),
          ),
        ),
        isNull,
      );
    },
  );
  test(
    'noble login/upgrade and resource actions use actual fields and safe links',
    () {
      for (final event in [
        'GlobalAristocracyOnlineEvent',
        'RoomAristocracyUpgradeEvent',
      ]) {
        final task = parse(
          barrageMessage(event, {
            'userInfo': {'uid': 42},
            'enMsg': 'Noble online',
            'arMsg': 'نبيل',
            'aristocracyIcon': 'noble.png',
          }, channel: 'global'),
        )!;
        expect(task.text('tr'), 'Noble online');
        expect(task.action(null).kind, RoomBarrageActionKind.profile);
        expect(task.action(null).uid, 42);
      }
      final resource = parse(
        barrageMessage('RoomResourceFloatScreenEvent', {
          'userInfo': {'uid': 42},
          'copywriting': {'en': 'Reward'},
          'rewardInfo': {'goodsImg': 'gift.png', 'showNumStr': '8'},
          'jumpLink': 'https://example.test/event?a=1',
        }, channel: 'global'),
      )!;
      expect(resource.action(null).kind, RoomBarrageActionKind.web);
      for (final url in [
        'javascript:alert(1)',
        'file:///etc/passwd',
        'nady://pay',
        'https://u:p@example.test',
      ]) {
        expect(roomBarrageWebLink(url), isNull);
      }
    },
  );
  test(
    'Rocket nested payload, MVP head/avatar and level resource; same room does nothing',
    () {
      final task = parse(
        barrageMessage('RoomBigRocketPrizeEvent', {
          'msg': jsonEncode({
            'roomId': '123',
            'level': 6,
            'winnerList': [
              {'uid': 20, 'role': 2, 'nick': 'MVP', 'head': 'avatar.png'},
            ],
          }),
        }, channel: 'global'),
      )!;
      expect(task.sender.avatar, 'avatar.png');
      expect(task.fullscreen, isNotNull);
      expect(
        task.fullscreen!.message.gift.animationUrl,
        endsWith('big_rocket_fly_lv6.mp4'),
      );
      expect(task.action('123').kind, RoomBarrageActionKind.none);
      expect(task.action('999').kind, RoomBarrageActionKind.enterRoom);
    },
  );
  test(
    'SUPER requires mode and active same-gift combo; only gift location is exposed',
    () {
      const active = RoomScreenGiftMsg(
        uid: 10,
        userInfo: RoomGiftUser(uid: 10),
        giftCount: 1,
        gift: RoomGift(
          id: 31,
          name: 'Lucky',
          icon: 'gift.png',
          price: 1,
          isCombo: 1,
          tabId: 0,
        ),
      );
      final event = barrageMessage('LuckyGiftJackpotSuperMode', {
        'roomId': '123',
        'giftId': 31,
        'mode': 'SUPER',
        'amount': 500,
      });
      expect(parse(event), isNull);
      expect(parse(event, active: (_) => active)!.action('123').giftId, 31);
      expect(
        parse(
          barrageMessage('LuckyGiftJackpotSuperMode', {
            'roomId': '123',
            'giftId': 31,
            'mode': 'NORMAL',
          }),
          active: (_) => active,
        ),
        isNull,
      );
    },
  );
  test(
    'game prize preserves requirement for missing fullscreen, opens local typed prize only',
    () {
      final task = parse(
        barrageMessage('RoomLobbyBigWinPrizeEvent', {
          'gameBigWinId': '42',
          'userWinCoins': 88,
          'gameName': 'Game',
        }, channel: 'global:10'),
      )!;
      expect(task.prize!.amount, 88);
      expect(task.prize!.activityId, '42');
      expect(task.action('123').kind, RoomBarrageActionKind.prize);
      expect(task.fullscreen, isNull); // Asset is still explicitly outstanding.
      expect(
        parse(
          barrageMessage('RoomLobbyBigWinStatusEvent', {
            'userWinCoins': 88,
            'showScreen': false,
          }, channel: 'global_lobby'),
        ),
        isNull,
      );
    },
  );

  test(
    'pool announcement is not misreported as personal winnings; repeated award relays merge by ID/round',
    () {
      final data = {
        'gameBigWinId': '42',
        'curRound': 2,
        'showScreen': true,
        'bigWinTotalCoins': 1000,
        'status': 2,
        'gameName': 'Game',
      };
      final pool = parse(
        barrageMessage(
          'RoomLobbyBigWinStatusEvent',
          data,
          channel: 'global_lobby',
        ),
      )!;
      expect(pool.prize!.amount, 0);
      expect(pool.prize!.pool, 1000);
      final personal = {...data, 'userWinCoins': 88};
      expect(
        parse(
          barrageMessage(
            'RoomLobbyBigWinStatusEvent',
            personal,
            channel: 'global_lobby',
          ),
        )!.key,
        parse(
          barrageMessage(
            'RoomLobbyBigWinPrizeEvent',
            personal,
            channel: 'global:10',
            id: 'personal',
          ),
        )!.key,
      );
    },
  );
  test(
    'localized gift names never leak encoded JSON, and own global SUPER can omit roomId',
    () {
      final name = parse(
        barrageMessage('RoomGiftSendBannerEvent', {
          ...giftBanner(),
          'giftName': '{"en":"Rose"}',
          'bannerContentObj': null,
        }),
      )!;
      expect(name.title, 'Rose');
      expect(name.text('en'), contains('Rose'));
      expect(name.text('en'), isNot(contains('{')));
      const active = RoomScreenGiftMsg(
        uid: 10,
        userInfo: RoomGiftUser(uid: 10),
        roomId: '123',
        comboId: 'combo',
        gift: RoomGift(
          id: 31,
          name: 'Lucky',
          icon: '',
          price: 1,
          isCombo: 1,
          tabId: 0,
        ),
      );
      final superMode = parse(
        barrageMessage('LuckyGiftJackpotSuperMode', {
          'giftId': 31,
          'mode': 'SUPER',
          'amount': 8,
        }),
        active: (_) => active,
      );
      expect(superMode!.roomId, '123');
      expect(superMode.comboId, 'combo');
    },
  );

  test('numeric backend room and activity IDs remain exact identifiers', () {
    final task = parse(
      barrageMessage('RoomGiftSendBannerEvent', {
        ...giftBanner(),
        'roomId': 123,
      }),
    )!;
    expect(task.roomId, '123');
    final prize = parse(
      barrageMessage('RoomLobbyBigWinPrizeEvent', {
        'gameBigWinId': 42,
        'curRound': 2,
        'userWinCoins': 88,
      }, channel: 'global:10'),
    )!;
    expect(prize.prize!.activityId, '42');
  });
}
