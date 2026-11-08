import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/interaction/room_interaction_repository.dart';
import 'package:project/classes/room/interaction/room_interaction_view_model.dart';
import 'package:project/classes/room/interaction/room_mention.dart';
import 'package:project/classes/room/interaction/room_moderation.dart';
import 'package:project/classes/room/interaction/room_public_media.dart';
import 'package:project/classes/room/interaction/room_rank_view_model.dart';
import 'package:project/classes/room/interaction/room_rocket.dart';
import 'package:project/classes/room/interaction/room_rocket_view_model.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_socket_message.dart';

import 'support/room_lifecycle_fakes.dart';

void expectRequest(
  ({String path, Map<String, dynamic> body}) actual,
  ({String path, Map<String, dynamic> body}) expected,
) {
  expect(actual.path, expected.path);
  expect(actual.body, expected.body);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomLifecycleFixture fixture;
  late RoomRepository room;
  late _InteractionApi api;
  late RoomInteractionViewModel session;

  setUp(() async {
    fixture = RoomLifecycleFixture();
    fixture.http.roomOwnerUid = 10;
    room = RoomRepository(
      roomManager: fixture.manager,
      socketManager: fixture.socket,
      agoraManager: fixture.agora,
      authSession: fixture.auth,
      httpManager: fixture.http,
    );
    api = _InteractionApi();
    await fixture.enter();
    session = RoomInteractionViewModel(room, api, (
      roomId: 'first',
      generation: room.roomGeneration,
      viewToken: Object(),
    ));
  });

  tearDown(() async {
    session.dispose();
    await fixture.dispose();
  });

  test('uses canonical room ID and follows a member, not the room', () async {
    final card = RoomUserCardViewModel(session, 20);
    addTearDown(card.dispose);
    final states = <RoomUserCardState>[];
    card.addListener(states.add);
    await fixture.flush();
    expectRequest(api.requests.single, (
      path: HttpApi.roomUserInfo,
      body: <String, dynamic>{'roomId': 'first', 'targetUid': 20},
    ));
    expect(states.last.user!.userBase.userNo, 20002);
    await card.follow(true);
    expect(states.last.following, isTrue);
    expectRequest(api.requests.last, (
      path: HttpApi.userFollow,
      body: <String, dynamic>{'targetUid': 20, 'isFollowing': true},
    ));
  });

  test('does not submit after the room generation changes', () async {
    api.userGate = Completer<void>();
    final result = session.moderate(
      20,
      RoomModerationAction.addAdmin,
      stillOpen: () => true,
    );
    await fixture.flush();
    expect(api.requests, hasLength(1));
    await room.leaveRoom();
    await fixture.enter();
    api.userGate!.complete();
    await result;
    expect(api.requests, hasLength(1));
    expect(session.active, isFalse);
  });

  test('silence uses service duration and VIP target protection', () async {
    await session.moderate(
      20,
      RoomModerationAction.silence,
      duration: 3,
      stillOpen: () => true,
    );
    expectRequest(api.requests.last, (
      path: HttpApi.roomSilence,
      body: <String, dynamic>{
        'roomId': 'first',
        'targetUid': 20,
        'type': 1,
        'timeType': 3,
      },
    ));
    api.targetVip = 6;
    await expectLater(
      session.moderate(20, RoomModerationAction.kick, stillOpen: () => true),
      throwsA(isA<Exception>()),
    );
    expect(
      api.requests.where((value) => value.path == HttpApi.roomKickOut),
      isEmpty,
    );
  });

  test(
    'manager cannot mute, silence, kick or appoint a fellow manager',
    () async {
      await room.leaveRoom();
      fixture.http.roomOwnerUid = 30;
      fixture.http.roomIdentity = 'ROOM_MANAGER';
      await fixture.enter();
      final managerSession = RoomInteractionViewModel(room, api, (
        roomId: 'first',
        generation: room.roomGeneration,
        viewToken: Object(),
      ));
      addTearDown(managerSession.dispose);
      api.targetRole = 'ROOM_MANAGER';
      for (final action in [
        RoomModerationAction.muteMic,
        RoomModerationAction.silence,
        RoomModerationAction.kick,
        RoomModerationAction.addAdmin,
      ]) {
        await expectLater(
          managerSession.moderate(20, action, stillOpen: () => true),
          throwsA(isA<Exception>()),
        );
      }
      expect(
        api.requests.every((request) => request.path == HttpApi.roomUserInfo),
        isTrue,
      );
      await managerSession.moderate(
        20,
        RoomModerationAction.inviteMic,
        stillOpen: () => true,
      );
      expect(api.requests.last.path, HttpApi.roomMicInvite);
    },
  );

  test(
    'rocket accepts scoped updates and keeps new progress while loading links',
    () async {
      fixture.http.rocketGate = Completer<void>();
      fixture.http.rocketData = {
        'roomId': 'first',
        'level': 1,
        'progress': .2,
        'rocketUrl': r'https://example.com/rocket?lang=${language}&source=room',
      };
      final vm = RoomRocketViewModel(session);
      addTearDown(vm.dispose);
      RoomRocket? rocket;
      vm.addListener((value) => rocket = value);
      await fixture.flush();
      void send(String roomId, int level) => fixture.socket.controller.add(
        RoomSocketMessage(
          channel: 'global',
          event: 'RoomBigRocketStatusEvent',
          raw: const {},
          payload: {
            'msg':
                '{"roomId":"$roomId","level":$level,"showStatus":3,"progress":0.8}',
          },
        ),
      );
      send('second', 2);
      expect(rocket, isNull);
      send('first', 3);
      expect(rocket?.level, 3);
      fixture.http.rocketGate!.complete();
      await fixture.flush();
      expect(rocket?.level, 3);
      expect(rocket?.progress, .8);
      final link = rocket!.link('en')!;
      expect(link.queryParameters, {
        'lang': 'en',
        'source': 'room',
        'roomId': 'first',
        'language': 'en',
      });
      expect(
        RoomRocket.parse({
          'roomId': 'first',
          'rocketUrl': 'file:///secret',
        })!.link('en'),
        isNull,
      );
      await room.leaveRoom();
      send('first', 4);
      expect(rocket?.level, 3);
    },
  );

  test('room ranks distinguish contribution and profit requests', () async {
    await api.rank((
      session: session.key,
      period: RoomRankPeriod.weekly,
      profit: false,
    ));
    expectRequest(api.requests.first, (
      path: HttpApi.rankCommonly,
      body: <String, dynamic>{
        'frequencyType': 4,
        'roomId': 'first',
        'size': 100,
        'rankType': 1,
        'isInRoom': true,
      },
    ));
    await api.rank((
      session: session.key,
      period: RoomRankPeriod.daily,
      profit: true,
    ));
    expectRequest(api.requests[2], (
      path: HttpApi.roomRankIncome,
      body: <String, dynamic>{
        'frequencyType': 5,
        'roomId': 'first',
        'size': 100,
      },
    ));
    expect(api.requests.last.path, HttpApi.roomRankSummary);
    expect(api.requests.last.body, {'roomId': 'first', 'type': 5});
    expect(api.requests[1].body, {'roomId': 'first', 'type': 4});
  });

  test(
    'silence from entry and scoped socket updates blocks text and emoji',
    () async {
      await room.leaveRoom();
      fixture.http.enterSilenceEndTime = DateTime.now()
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch;
      final vm = RoomViewModel(repository: room, roomId: 'first');
      addTearDown(vm.dispose);
      await vm.enterRoom();
      await fixture.flush();

      void changeSilence(String id, int uid) => fixture.socket.controller.add(
        RoomSocketMessage(
          channel: 'room:$id',
          event: 'RoomUserPublicScreenSilenceUpdate',
          payload: {'uid': uid, 'eventType': 2},
          raw: const {},
        ),
      );
      final expression = RoomExpression.fromJson({
        'id': 5,
        'type': 1,
        'staticPic': 'https://example.com/e.webp',
      });
      expect(await vm.sendMessage('blocked'), isFalse);
      expect(await vm.sendExpression(expression), isFalse);
      changeSilence('other', 10);
      changeSilence('first', 20);
      await fixture.flush();
      expect(await vm.sendMessage('still blocked'), isFalse);
      expect(fixture.http.publicMessages, isEmpty);
      changeSilence('first', 10);
      await fixture.flush();
      expect(await vm.sendExpression(expression), isTrue);
      expect(
        fixture.http.publicMessages.single['event'],
        'RoomScreenExpressionEvent',
      );
    },
  );

  test(
    'Nady sender, mention, image, expression and private Party events',
    () async {
      final vm = RoomViewModel(repository: room, roomId: 'first');
      addTearDown(vm.dispose);
      RoomPageState? state;
      vm.addListener((value) => state = value);
      await vm.enterRoom();
      await fixture.flush();

      void emit(
        String event,
        Object payload, {
        String? mode,
        List<String>? ids,
      }) => fixture.socket.controller.add(
        RoomSocketMessage(
          channel: 'room:first',
          event: event,
          raw: const {},
          payload: payload,
          toType: mode,
          ids: ids,
        ),
      );
      final mention = encodeRoomMention('hello @雪', (uid: 20, name: '雪'));
      final parts = decodeRoomMentions(mention);
      expect(parts.last.uid, 20);
      expect(parts.last.text, '@雪');

      const from = {'uid': 20, 'nick': 'Peer'};
      emit('RoomScreenMessageEvent', {'from': from, 'msg': mention});
      emit('RoomScreenImageEvent', {
        'from': from,
        'msg': 'https://example.com/a.png',
      });
      emit('RoomScreenExpressionEvent', {
        'from': from,
        'msg': '{"id":1,"dynamicPic":"https://example.com/a.gif"}',
      });
      emit(
        'RoomPartyEvent',
        '{"partyId":55,"topic":"Hidden"}',
        mode: 'EXCLUDE_OTHER',
        ids: ['21'],
      );
      emit(
        'RoomPartyEvent',
        '{"partyId":56,"topic":"Party"}',
        mode: 'EXCLUDE_OTHER',
        ids: ['10'],
      );
      final entries = state!.messages;
      expect(entries.where((entry) => entry.senderUid == 20), hasLength(3));
      expect(
        entries
            .where((entry) => entry.mediaUrl != null)
            .map((entry) => entry.mediaUrl),
        ['https://example.com/a.png', 'https://example.com/a.gif'],
      );
      expect(
        entries.where((entry) => entry.partyId != null).single.partyId,
        56,
      );
      expect(roomPublicImage('file:///etc/passwd'), isNull);
    },
  );

  test(
    'mic invitation filters target, dedupes and picks current available seat',
    () async {
      fixture.http.micList = [
        {'position': 0, 'isLock': true},
        {'position': 1},
      ];
      await room.refreshRoomData();
      final vm = RoomViewModel(repository: room, roomId: 'first');
      addTearDown(vm.dispose);
      RoomPageState? state;
      vm.addListener((value) => state = value);
      await vm.enterRoom();
      await fixture.flush();

      void invite(int target, String id) => fixture.socket.controller.add(
        RoomSocketMessage(
          channel: 'room:first',
          event: 'RoomMicInviteUpEvent',
          payload: {'uid': target, 'nick': 'Peer'},
          raw: const {},
          msgId: id,
        ),
      );
      invite(20, 'other');
      expect(state!.micInvite, isNull);
      invite(10, 'one');
      await vm.respondToMicInvite(state!.micInvite!, false);
      invite(10, 'one');
      expect(state!.micInvite, isNull);
      invite(10, 'two');
      await vm.respondToMicInvite(state!.micInvite!, true);
      expect(fixture.http.micUpRequests.single, {
        'roomId': 'first',
        'position': 1,
      });
    },
  );
}

class _InteractionApi extends RoomInteractionRepository {
  final requests = <({String path, Map<String, dynamic> body})>[];
  String targetRole = 'ROOM_AUDIENCE';
  int targetVip = 0;
  Completer<void>? userGate;

  @override
  Future<Object?> get(String path, Map<String, dynamic> query) async {
    requests.add((path: path, body: query));
    if (path == HttpApi.roomUserInfo) {
      await userGate?.future;
      return {
        'userBase': {
          'uid': query['targetUid'],
          'userNo': 20002,
          'nick': 'Peer',
          'userLevel': {'vipLevel': targetVip},
        },
        'roomIdentity': targetRole,
      };
    }
    if (path == HttpApi.roomRankSummary) return {'coinVal': 5, 'diamondVal': 3};
    return {'rankVOs': <Object>[]};
  }

  @override
  Future<Object?> post(String path, Map<String, dynamic> body) async {
    requests.add((path: path, body: body));
    return null;
  }
}
