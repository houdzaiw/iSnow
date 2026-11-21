import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/gift/event/room_fullscreen_event_parser.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/model/room_socket_message.dart';

import 'room_gift_events_test.dart' show payload, socket;

void main() {
  late RoomGiftEventManager manager;
  setUp(() => manager = RoomGiftEventManager(roomId: '123', startTimer: false));
  tearDown(() => manager.dispose());

  RoomGiftEffectTask prize() => RoomGiftEffectTask(
    key: 'prize',
    createdAt: DateTime.now(),
    kind: RoomGiftEffectKind.prize,
    message: const RoomScreenGiftMsg(
      uid: 1,
      userInfo: RoomGiftUser(uid: 1),
      giftCount: 1,
      gift: RoomGift(
        id: -1,
        name: '',
        icon: '',
        price: 0,
        tabId: 1,
        isCombo: 0,
      ),
    ),
  );

  test(
    'prize preparation gates preemption and ignores old room results',
    () async {
      final ready = Completer<void>();
      final isolated = RoomGiftEventManager(
        roomId: '123',
        startTimer: false,
        preparePrize: (_) => ready.future,
      );
      addTearDown(isolated.dispose);
      isolated.receive(socket(payload(combo: 'full'), id: 'full'));
      isolated.enqueueFullscreen(prize());
      expect(isolated.snapshot.stopEffectKey, isNull);
      isolated.reset();
      isolated.receive(socket(payload(combo: 'new-full'), id: 'new-full'));
      ready.complete();
      await Future<void>.delayed(Duration.zero);
      expect(isolated.snapshot.effects.single.key, 'new-full');
      expect(isolated.snapshot.stopEffectKey, isNull);
    },
  );

  test('failed prize download preserves current animation', () async {
    final ready = Completer<void>();
    final isolated = RoomGiftEventManager(
      roomId: '123',
      startTimer: false,
      preparePrize: (_) => ready.future,
    );
    addTearDown(isolated.dispose);
    isolated.receive(socket(payload(combo: 'full'), id: 'full'));
    isolated.enqueueFullscreen(prize());
    ready.completeError(const FormatException('Fixture unavailable'));
    await Future<void>.delayed(Duration.zero);
    expect(isolated.snapshot.effects.single.key, 'full');
    expect(isolated.snapshot.stopEffectKey, isNull);
  });

  test(
    'Rocket validates room, country, nested payload, MVP and local level',
    () {
      final parser = RoomFullscreenEventParser();
      final now = DateTime.now();
      RoomSocketMessage event({String room = '123', DateTime? at}) =>
          RoomSocketMessage(
            channel: 'global',
            event: 'RoomBigRocketPrizeEvent',
            msgId: 'rocket',
            raw: const {},
            receivedAt: at ?? now,
            payload: {
              'msg': jsonEncode({
                'roomId': room,
                'level': 3,
                'countryCodes': ['US'],
                'winnerList': [
                  {'uid': 8, 'nick': 'MVP', 'role': 2, 'head': 'avatar'},
                ],
              }),
            },
          );
      final tasks = parser.parse(event(), '123', now, countryCode: 'us');
      expect(tasks.single.kind, RoomGiftEffectKind.prize);
      expect(tasks.single.message.userInfo.name, 'MVP');
      expect(
        tasks.single.message.gift.animationUrl,
        AppAssets.roomGiftRocketEffects[2],
      );
      expect(parser.parse(event(room: 'other'), '123', now), isEmpty);
      expect(parser.parse(event(), '123', now, countryCode: 'TR'), isEmpty);
      expect(
        parser.parse(
          event(at: now.subtract(const Duration(seconds: 11))),
          '123',
          now,
        ),
        isEmpty,
      );
    },
  );

  test(
    'full-screen waits for active numeric player release acknowledgement',
    () {
      final lucky = payload(combo: 'lucky')
        ..['isLuckyGift'] = true
        ..['totalGiftCount'] = 10;
      lucky['gift'] = {'id': 31, 'name': 'Lucky', 'icon': ''};
      manager.receive(socket(lucky, id: 'lucky'));
      expect(manager.snapshot.canPlayLucky, isTrue);
      final luckyKey = manager.snapshot.lucky.single.key;
      manager.receive(socket(payload(combo: 'full'), id: 'full'));
      expect(manager.snapshot.stopLuckyKey, luckyKey);
      expect(manager.snapshot.canPlayFullscreen, isFalse);
      manager.completeLucky('unrelated');
      expect(manager.snapshot.canPlayFullscreen, isFalse);
      manager.completeLucky(luckyKey);
      expect(manager.snapshot.canPlayFullscreen, isTrue);
      expect(manager.snapshot.effects.single.key, 'full');
    },
  );

  test('Jackpot derived from a gift keeps its original gift image slot', () {
    final value = payload(combo: 'jackpot')..['isJackpot'] = true;
    value['gift'] = {'id': 31, 'name': 'Lucky', 'icon': 'original-gift.png'};
    value['isLuckyGift'] = true;
    manager.receive(socket(value, id: 'jackpot'));
    final task = manager.snapshot.effects
        .where((task) => task.kind == RoomGiftEffectKind.prize)
        .single;
    expect(task.giftIcon, 'original-gift.png');
  });

  test('numeric queue starts only when full-screen queue is empty', () {
    manager.receive(socket(payload(combo: 'full'), id: 'full'));
    final lucky = payload(combo: 'lucky')
      ..['isLuckyGift'] = true
      ..['totalGiftCount'] = 10;
    lucky['gift'] = {'id': 31, 'name': 'Lucky', 'icon': ''};
    manager.receive(socket(lucky, id: 'lucky'));
    expect(manager.snapshot.canPlayLucky, isFalse);
    manager.completeEffect('full');
    expect(manager.snapshot.canPlayLucky, isTrue);
  });

  test(
    'entrance track and vehicle are linked without making the track full-screen',
    () {
      final event = RoomSocketMessage(
        channel: 'global',
        event: 'RoomUserPropInfoEvent',
        msgId: 'entry',
        raw: const {},
        payload: const {
          'roomId': '123',
          'userBaseInfo': {
            'uid': 20,
            'nick': 'Guest',
            'vehicle': {'animationUrl': 'https://cdn.example/car.pag'},
            'specialEffects': {
              'animationUrl': 'https://cdn.example/entry.svga',
            },
          },
        },
      );
      manager.receive(event);
      manager.receive(event);
      expect(manager.snapshot.effects, hasLength(1));
      expect(manager.snapshot.entrance, isNull);
      manager.startEntranceVehicle('entrance:entry:vehicle');
      expect(
        manager.snapshot.entrance!.trackUrl,
        'https://cdn.example/entry.svga',
      );
      final entryKey = manager.snapshot.entrance!.key;
      manager.receive(socket(payload(combo: 'gift'), id: 'gift'));
      expect(manager.snapshot.effects, hasLength(2));
      manager.completeEntranceTrack(entryKey);
      expect(manager.snapshot.entrance, isNotNull);
      manager.completeEffect(manager.snapshot.effects.first.key);
      expect(manager.snapshot.effects, hasLength(1));
      expect(manager.snapshot.entrance, isNull);
    },
  );

  test(
    'finished combo never replays full-screen for later cumulative updates',
    () {
      manager.receive(socket(payload(count: 1), id: 'one'));
      manager.completeEffect('one');
      manager.receive(socket(payload(count: 2), id: 'two'));
      expect(manager.snapshot.effects, isEmpty);
      expect(manager.snapshot.publicMessages.single.count, 2);
    },
  );
}
