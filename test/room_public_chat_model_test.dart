import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/event/room_gift_event_parser.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/room_user_info.dart';

import 'support/room_lifecycle_fakes.dart';

Map<String, dynamic> _sender() => {
  'uid': 20,
  'nick': 'Peer',
  'gender': '1',
  'countryCode': 'tr',
  'avatarWidget': {
    'icon': 'https://example.com/frame.png',
    'animationUrl': 'https://example.com/frame.svga',
  },
  'userLevel': {
    'wealthLevel': '80',
    'wealthLevelIcon': 'https://example.com/wealth.png',
    'charmLevel': 10,
    'charmLevelIcon': 'https://example.com/charm.png',
    'activeLevel': 20,
    'activeLevelIcon': 'https://example.com/active.png',
    'vipLevel': 4,
    'vipIcon': 'vip-icon',
    'vipMedal': 'vip-medal',
    'aristocracyLevel': 3,
    'aristocracyEnIcon': 'noble-en',
    'aristocracyArIcon': 'noble-ar',
    'plaqueEn': 'plaque-en',
    'plaqueTr': 'plaque-tr',
  },
  'userWearMedalVOS': [
    {'icon': 'second', 'sortingOrder': 2},
    {'icon': 'first', 'sortingOrder': 1},
  ],
  'tagPicInfos': [
    {'tagPic': 'tag'},
  ],
  'userIdentityAuthenticationList': [
    {'idCardUrl': 'identity'},
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'real sender decorations preserve levels, medal order and locale fallback',
    () {
      final data = _sender();
      final appearance = RoomUserAppearance.fromJson(data);
      expect(appearance.gender, 1);
      expect(appearance.countryCode, 'TR');
      expect(appearance.frameUrl, endsWith('.svga'));
      expect(appearance.framePreview, endsWith('.png'));
      expect(appearance.levels.map((e) => e.kind), RoomUserLevelKind.values);
      expect(appearance.levels.map((e) => e.level), [80, 10, 20]);
      expect(appearance.publicBadges.map((e) => e.iconForLanguage('ar')), [
        'noble-ar',
        'vip-medal',
        'plaque-en',
        'tag',
        'first',
        'second',
        'identity',
      ]);
      expect(appearance.publicBadges[0].iconForLanguage('id-ID'), 'noble-en');
      expect(appearance.publicBadges[2].iconForLanguage('tr_TR'), 'plaque-tr');
      expect((data['userWearMedalVOS'] as List).first['icon'], 'second');
    },
  );

  test(
    'old or malformed metadata does not invent ownership or sample badges',
    () {
      final old = RoomUserAppearance.fromJson({});
      expect(old.levels, isEmpty);
      expect(old.publicBadges, isEmpty);
      expect(old.frameUrl, isNull);
      final broken = RoomUserAppearance.fromJson({
        'gender': 8,
        'countryCode': 'UNKNOWN',
        'avatarWidget': '[',
        'userLevel': {
          'wealthLevel': -1,
          'charmLevel': 'bad',
          'activeLevel': 0,
          'vipLevel': 0,
          'vipMedal': 'unowned',
        },
        'userWearMedalVOS': [
          null,
          1,
          {},
          {'icon': 1},
        ],
      });
      expect(broken.levels, isEmpty);
      expect(broken.publicBadges, isEmpty);
      expect(broken.gender, isNull);
      expect(broken.countryCode, isNull);
      final owned = RoomUserAppearance.fromJson({
        'userLevel': {'wealthLevel': 3},
      });
      expect(owned.levels.single.level, 3);
      expect(
        owned.levels.single.icon,
        isEmpty,
      ); // Owned, but unavailable artwork.
    },
  );

  test(
    'encoded submodels and gift users keep the same optional appearance',
    () {
      final json = _sender();
      json['userLevel'] = jsonEncode(json['userLevel']);
      json['avatarWidget'] = jsonEncode(json['avatarWidget']);
      final gift = RoomGiftUser.fromJson(json);
      expect(gift.appearance.levels.first.level, 80);
      expect(gift.appearance.frameUrl, endsWith('.svga'));
      expect(gift.appearance.publicBadges[1].icon, 'vip-medal');
      expect(const RoomGiftUser(uid: 1).appearance.publicBadges, isEmpty);
      final event = RoomGiftEventParser().parse(
        RoomSocketMessage(
          channel: 'room:123',
          event: 'RoomSendGiftComboPublicScreenEvent',
          raw: const {},
          msgId: 'gift',
          payload: {
            'from': json,
            'msg': jsonEncode({
              'giftId': 31,
              'giftName': 'Rose',
              'giftNum': 2,
              'sendType': 2,
              'winAmount': 150,
            }),
          },
        ),
        '123',
        DateTime(2026, 11, 13),
      );
      expect(event!.publicMessage!.sender.appearance.levels.first.level, 80);
      expect(event.publicMessage!.winAmount, 150);
    },
  );

  test(
    'socket author metadata reaches all typed message kinds without HTTP user lookups',
    () async {
      final fixture = RoomLifecycleFixture();
      final model = RoomViewModel(
        roomId: 'first',
        repository: RoomRepository(
          roomManager: fixture.manager,
          socketManager: fixture.socket,
          agoraManager: fixture.agora,
          authSession: fixture.auth,
          httpManager: fixture.http,
        ),
      );
      addTearDown(() async {
        model.dispose();
        await fixture.dispose();
      });
      late RoomPageState state;
      model.addListener((s) => state = s);
      await model.enterRoom();
      await fixture.flush();
      for (final entry in {
        'RoomScreenMessageEvent': 'Hello',
        'RoomScreenEnterRoomMessageEvent': 'entered',
        'RoomScreenImageEvent': 'https://example.com/image.png',
        'RoomScreenExpressionEvent': jsonEncode({
          'id': 1,
          'staticPic': 'https://example.com/face.png',
        }),
        'RoomPartyEvent': jsonEncode({'partyId': 1, 'topic': 'Party'}),
      }.entries) {
        fixture.socket.controller.add(
          RoomSocketMessage(
            channel: 'room:first',
            event: entry.key,
            raw: const {},
            msgId: entry.key,
            payload: jsonEncode({
              'from': jsonEncode(_sender()),
              'msg': entry.value,
            }),
          ),
        );
      }
      await fixture.flush();
      final messages = state.messages.where((e) => e.senderUid == 20).toList();
      expect(messages, hasLength(5));
      for (final message in messages) {
        expect(message.senderAppearance.levels.first.level, 80);
        expect(
          message.senderAppearance.publicBadges.first.iconForLanguage('ar'),
          'noble-ar',
        );
      }
    },
  );
}
