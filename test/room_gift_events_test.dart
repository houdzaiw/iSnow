import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/model/room_socket_message.dart';

void main() {
  final start = DateTime(2026, 10, 5, 12);
  late DateTime now;
  late RoomGiftEventManager manager;
  setUp(() {
    now = start;
    manager = RoomGiftEventManager(
      roomId: '123',
      now: () => now,
      startTimer: false,
    )..currentUid = 10;
  });
  tearDown(() => manager.dispose());

  test('typed model accepts defaults and numeric strings', () {
    final gift = RoomScreenGiftMsg.fromJson(payload());
    expect(gift.gift.direction, 2);
    expect(gift.gift.videoMode, 3);
    expect(gift.targetUsers, isNull);
    expect(gift.isHideLuckyGift, isFalse);
    expect(gift.isJackpot, isFalse);
    expect(gift.totalCoinCount, 0);
    expect(gift.targetUids, [20, 30]);
    expect(
      RoomScreenGiftMsg.fromJson({
        ...payload(),
        'newComboId': 'ui-key',
      }).comboId,
      'combo',
    );
  });

  test(
    'guest-only queue keeps the latest two even with identical timestamps',
    () {
      manager.receive(socket(payload(uid: 90, combo: 'a'), id: 'a'));
      manager.receive(socket(payload(uid: 91, combo: 'b'), id: 'b'));
      manager.receive(socket(payload(uid: 92, combo: 'c'), id: 'c'));
      expect(manager.state.slots.map((slot) => slot!.message.uid).toSet(), {
        91,
        92,
      });
      manager.receive(socket(payload(uid: 93, combo: 'd'), id: 'd'));
      expect(manager.state.slots.map((slot) => slot!.message.uid).toSet(), {
        92,
        93,
      });
    },
  );

  test('non-combo full-screen events remain independent', () {
    manager.receive(socket(payload(uid: 90, combo: ''), id: 'one'));
    manager.receive(socket(payload(combo: '', count: 2), id: 'two'));
    manager.receive(socket(payload(combo: '', count: 3), id: 'three'));
    expect(manager.state.effects.map((task) => task.key), [
      'one',
      'two',
      'three',
    ]);
    expect(manager.state.effects.map((task) => task.message.displayCount), [
      1,
      2,
      3,
    ]);
  });

  test('broadcast fans out once; combo updates preserve one public entry', () {
    final first = socket(payload(), id: 'one');
    manager.receive(first);
    manager.receive(first);
    expect(manager.state.publicMessages, hasLength(1));
    expect(manager.state.flights, hasLength(1));
    expect(manager.state.effects, hasLength(1));
    manager.receive(socket(payload(count: 2), id: 'two'));
    expect(manager.state.publicMessages, hasLength(1));
    expect(manager.state.publicMessages.single.count, 2);
    expect(manager.state.effects, hasLength(1));
    expect(manager.state.slots.whereType<Object>(), hasLength(1));
  });

  test('self pins the second slot; guests never cover it', () {
    manager.receive(socket(payload(uid: 90, combo: 'guest-1'), id: '1'));
    manager.receive(socket(payload(), id: '2'));
    for (var i = 0; i < 100; i++) {
      manager.receive(
        socket(
          payload(uid: 90 + i, combo: 'guest-$i'),
          id: 'guest-$i',
        ),
      );
    }
    expect(manager.state.slots[1]!.message.uid, 10);
    expect(manager.state.slots[0]!.message.uid, 189);
    expect(manager.state.publicMessages, hasLength(80));
    expect(manager.state.effects, hasLength(12));
    expect(manager.state.effects.first.key, '1');
    now = start.add(const Duration(seconds: 6));
    manager.expire();
    expect(manager.state.slots, [null, null]);
    expect(manager.state.flights, isEmpty);
  });

  test('same combo retains its slot and ignores lower cumulative versions', () {
    manager.receive(socket(payload(count: 3), id: 'latest'));
    manager.receive(socket(payload(count: 2), id: 'older'));
    expect(manager.state.slots[0]!.message.displayCount, 3);
    now = now.add(const Duration(seconds: 4));
    manager.receive(socket(payload(count: 4), id: 'newest'));
    now = now.add(const Duration(seconds: 2));
    manager.expire();
    expect(manager.state.slots[0]!.message.displayCount, 4);
  });

  test('malformed, wrong-room and ambiguous global payloads are discarded', () {
    manager.receive(socket('not json', id: 'invalid'));
    manager.receive(socket({...payload(), 'roomId': 'other'}, id: 'other'));
    manager.receive(
      socket(payload()..remove('roomId'), channel: 'room', id: 'global'),
    );
    manager.receive(socket({'gift': {}}, id: 'missing'));
    expect(manager.state.publicMessages, isEmpty);
    manager.receive(socket(payload(), id: 'valid'));
    expect(manager.state.publicMessages, hasLength(1));
  });

  test('nested Nady final-combo payload updates public screen only', () {
    manager.receive(socket(payload(), id: 'initial'));
    final end = jsonEncode({
      'msg': jsonEncode({
        'giftId': 31,
        'giftName': 'Rose',
        'giftIcon': '',
        'giftNum': 18,
        'comboId': 'combo',
        'comboTimes': 18,
        'sendType': 1,
        'isCombo': 1,
        'isLucky': false,
        'winAmount': 20,
        'receivingGiftsPeople': 2,
      }),
    });
    manager.receive(
      socket(end, event: 'RoomSendGiftPublicScreenEvent', id: 'end'),
    );
    expect(manager.state.publicMessages.single.count, 18);
    expect(manager.state.publicMessages.single.sender.name, 'Sender');
    expect(manager.state.publicMessages.single.isFinal, isTrue);
    expect(manager.state.effects, hasLength(1));
    manager.receive(socket(payload(count: 20), id: 'late'));
    expect(manager.state.publicMessages.single.count, 18);
  });

  test('lucky results use cumulative deltas and honor hidden effects', () {
    manager.receive(
      socket({
        ...payload(),
        'isLuckyGift': true,
        'playWinGoldCount': true,
        'totalCoinCount': 100,
      }, id: 'lucky-1'),
    );
    expect(manager.state.lucky.single.amount, 100);
    manager.completeLucky(manager.state.lucky.single.key);
    manager.receive(
      socket({
        ...payload(count: 3),
        'isLuckyGift': true,
        'playWinGoldCount': true,
        'totalCoinCount': 150,
      }, id: 'lucky-2'),
    );
    expect(manager.state.lucky.single.amount, 50);
    expect(manager.state.lucky.single.giftCount, 2);
    manager.receive(
      socket({
        ...payload(combo: 'hidden'),
        'isLuckyGift': true,
        'isHideLuckyGift': true,
        'totalCoinCount': 500,
      }, id: 'hidden'),
    );
    expect(manager.state.lucky, hasLength(1));
    expect(manager.state.slots.whereType<Object>(), hasLength(1));
  });

  test('banner, stream and jackpot are independent lanes', () {
    manager.receive(
      socket(
        {'roomId': '123', 'roomWeekVal': '1234'},
        event: 'RoomGiftStreamUpdateEvent',
        id: 'stream',
      ),
    );
    manager.receive(
      socket(
        {
          'roomId': '123',
          'sendUserInfo': {'uid': 10},
          'giftId': 31,
          'giftName': 'Rose',
          'giftPic': '',
          'giftNum': 8,
          'bannerContentObj': {'en': 'Gift banner'},
          'upperEffect': 'https://cdn.test/a.pag',
        },
        event: 'RoomGiftSendBannerEvent',
        id: 'banner',
      ),
    );
    manager.receive(
      socket(
        {
          'roomId': '123',
          'userBaseInfo': {'uid': 10},
          'amount': 1000,
        },
        event: 'LuckyGiftJackpotSuperMode',
        id: 'jackpot',
      ),
    );
    expect(manager.state.roomWeekVal, 1234);
    expect(manager.state.banners, hasLength(1));
    expect(manager.state.effects, hasLength(2));
    expect(manager.state.lucky.single.isJackpot, isTrue);
    final active = manager.state.effects.first.key;
    manager.completeEffect(active);
    expect(manager.state.effects.single.key, 'special-jackpot');
  });

  test(
    'background and reset discard historical replays without stopping stream updates',
    () {
      manager.receive(socket(payload(), id: 'old'));
      manager.setVisible(false);
      manager.receive(
        socket(
          payload(combo: 'background'),
          id: 'background',
          time: now,
        ),
      );
      manager.receive(
        socket(
          {'roomId': '123', 'roomWeekVal': 99},
          event: 'RoomGiftStreamUpdateEvent',
          id: 'stream',
        ),
      );
      expect(manager.state.roomWeekVal, 99);
      now = now.add(const Duration(seconds: 8));
      manager.setVisible(true);
      manager.receive(
        socket(
          payload(combo: 'replay'),
          id: 'replay',
          time: start,
        ),
      );
      manager.receive(socket(payload(), id: 'old'));
      expect(manager.state.effects, isEmpty);
      manager.receive(
        socket(
          payload(combo: 'new'),
          id: 'new',
          time: now,
        ),
      );
      expect(manager.state.effects, hasLength(1));
      manager.reset(clearHistory: true);
      expect(manager.state.publicMessages, isEmpty);
      expect(manager.state.effects, isEmpty);
    },
  );
}

Map<String, dynamic> payload({
  int uid = 10,
  int count = 1,
  String combo = 'combo',
}) => {
  'roomId': '123',
  'uid': uid,
  'userInfo': {'uid': uid, 'nick': 'Sender'},
  'gift': {
    'id': 31,
    'name': 'Rose',
    'icon': '',
    'price': 20,
    'isCombo': 1,
    'animationUrl': 'https://cdn.test/rose.svga',
    'direction': '2',
    'videoMode': 3,
  },
  'count': count,
  'giftCount': 1,
  'comboCount': count,
  'giftSource': 1,
  'sendType': 6,
  'uids': ['20', 30, 30],
  'comboId': combo,
};

RoomSocketMessage socket(
  Object data, {
  String id = 'id',
  String channel = 'room:123',
  String event = 'roomScreenSendGiftComboEvent',
  DateTime? time,
}) => RoomSocketMessage(
  channel: channel,
  event: event,
  payload: data,
  raw: const {},
  msgId: id,
  timestamp: time?.millisecondsSinceEpoch,
);
