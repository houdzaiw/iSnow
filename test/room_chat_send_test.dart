import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/interaction/room_mention.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/model/room_socket_message.dart';

import 'support/room_lifecycle_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomLifecycleFixture fixture;
  late RoomViewModel model;
  late RoomPageState state;
  setUp(() async {
    fixture = RoomLifecycleFixture();
    fixture.http.canonicalRoomId = 'canonical';
    fixture.http.roomOwnerUid = 10;
    model = RoomViewModel(
      roomId: 'alias',
      repository: RoomRepository(
        roomManager: fixture.manager,
        socketManager: fixture.socket,
        agoraManager: fixture.agora,
        authSession: fixture.auth,
        httpManager: fixture.http,
      ),
    );
    model.addListener((value) => state = value);
    await model.enterRoom();
    await fixture.flush();
  });
  tearDown(() async {
    if (model.mounted) model.dispose();
    await fixture.dispose();
  });

  List<RoomChatEntry> chats() =>
      state.messages.where((e) => e.kind == RoomChatEntryKind.chat).toList();
  void receive(
    String text, {
    String? id = 'server-1',
    int uid = 10,
    String channel = 'room:canonical',
    String? payloadId,
    bool json = false,
  }) {
    final payload = {
      'from': {'uid': uid, 'nick': 'Sender $uid'},
      'msg': text,
      if (payloadId != null) 'msgID': payloadId,
    };
    fixture.socket.controller.add(
      RoomSocketMessage(
        channel: channel,
        event: 'RoomScreenMessageEvent',
        msgId: id,
        payload: json ? jsonEncode(payload) : payload,
        raw: const {},
      ),
    );
  }

  for (final echoFirst in [true, false]) {
    test(
      'own text appears once when Socket arrives ${echoFirst ? 'before' : 'after'} HTTP',
      () async {
        fixture.http.publicMessageGate = Completer<void>();
        final send = model.sendMessage('  Hello  ');
        expect(state.sendingMessage, isTrue);
        expect(chats(), isEmpty);
        if (echoFirst) receive('Hello');
        fixture.http.publicMessageGate!.complete();
        expect(await send, isTrue);
        if (!echoFirst) {
          expect(chats(), isEmpty);
          receive('Hello');
        }
        expect(fixture.http.publicMessages.single, {
          'event': 'RoomScreenMessageEvent',
          'roomId': 'canonical',
          'data': 'Hello',
        });
        expect(chats(), hasLength(1));
        expect(chats().single.senderUid, 10);
        expect(chats().single.isLocal, isFalse);
        for (final filter in [RoomChatFilter.all, RoomChatFilter.chat]) {
          expect(
            state
                .copyWith(chatFilter: filter)
                .visibleMessages
                .where((e) => e.text == 'Hello'),
            hasLength(1),
          );
        }
        expect(state.sendingMessage, isFalse);
      },
    );
  }

  test('replay across room channels is ignored for own and other users', () {
    for (final uid in [10, 20]) {
      receive('Message $uid', id: 'server-$uid', uid: uid);
      receive('Message $uid', id: 'server-$uid', uid: uid, channel: 'room');
      receive('Message $uid', id: 'server-$uid', uid: uid);
    }
    expect(chats().map((e) => e.senderUid), [10, 20]);
  });

  test(
    'two sends with identical content stay separate, including the peer message',
    () async {
      expect(await model.sendMessage('Hello'), isTrue);
      receive('Hello', id: 'first');
      expect(await model.sendMessage('Hello'), isTrue);
      receive('Hello', id: 'second');
      receive('Hello', id: 'peer', uid: 20);
      expect(fixture.http.publicMessages, hasLength(2));
      expect(chats().map((e) => e.id), ['first', 'second', 'peer']);
    },
  );

  test(
    'payload IDs and JSON are supported; missing IDs do not collapse repeated text',
    () {
      receive('With payload ID', id: ' ', payloadId: 'payload-1', json: true);
      receive('With payload ID', id: null, payloadId: 'payload-1');
      expect(chats(), hasLength(1));
      expect(chats().single.id, 'payload-1');
      receive('No ID', id: null);
      receive('No ID', id: ' ');
      expect(chats().where((e) => e.text == 'No ID'), hasLength(2));
    },
  );

  test(
    'failed submission adds no public row and uses server msg; retry remains possible',
    () async {
      fixture.http.publicMessageResponse = {
        'code': 1003,
        'message': 'Fallback',
        'msg': 'Cannot send now',
      };
      expect(await model.sendMessage('Failed'), isFalse);
      expect(chats(), isEmpty);
      expect(state.errorMessage, 'Cannot send now');
      expect(state.sendingMessage, isFalse);
      fixture.http.publicMessageResponse = {'code': 200, 'data': 1};
      expect(await model.sendMessage('Failed'), isTrue);
      receive('Failed');
      expect(chats(), hasLength(1));
    },
  );

  test(
    'a timeout cannot roll back an already received broadcast or a peer message',
    () async {
      fixture.http.publicMessageGate = Completer<void>();
      final send = model.sendMessage('Delivered');
      receive('Delivered');
      receive('Peer', id: 'peer', uid: 20);
      fixture.http.publicMessageGate!.completeError(StateError('Timeout'));
      expect(await send, isFalse);
      expect(chats().map((e) => e.text), ['Delivered', 'Peer']);
      expect(state.sendingMessage, isFalse);
    },
  );

  test(
    'duplicate taps issue one request; mentions are echoed without another local copy',
    () async {
      fixture.http.publicMessageGate = Completer<void>();
      const RoomMentionTarget mention = (uid: 20, name: 'Friend');
      final send = model.sendMessage('@Friend Hi', mention: mention);
      expect(await model.sendMessage('@Friend Hi', mention: mention), isFalse);
      expect(fixture.http.publicMessages, hasLength(1));
      final text = fixture.http.publicMessages.single['data'] as String;
      receive(text);
      fixture.http.publicMessageGate!.complete();
      expect(await send, isTrue);
      expect(chats(), hasLength(1));
      expect(chats().single.text, text);
    },
  );

  test('clear during submission is not undone by HTTP completion', () async {
    fixture.http.publicMessageGate = Completer<void>();
    final send = model.sendMessage('Before clear');
    receive('Before clear');
    await model.clearMessages();
    fixture.http.publicMessageGate!.complete();
    expect(await send, isTrue);
    expect(state.messages, isEmpty);
    receive('After clear', id: 'after');
    expect(chats().single.text, 'After clear');
  });

  test('late submission cannot change a re-entered same-ID room', () async {
    fixture.http.publicMessageGate = Completer<void>();
    final send = model.sendMessage('Old session');
    await model.leaveRoom();
    await model.enterRoom();
    receive('New session', id: 'new');
    final messages = state.messages;
    fixture.http.publicMessageGate!.complete();
    expect(await send, isFalse);
    expect(state.messages, same(messages));
    expect(state.sendingMessage, isFalse);
  });

  test(
    'a disposed page ignores late failures and releases the socket listener',
    () async {
      fixture.http.publicMessageGate = Completer<void>();
      final send = model.sendMessage('Pending');
      model.dispose();
      fixture.http.publicMessageGate!.completeError(StateError('Late failure'));
      expect(await send, isFalse);
    },
  );

  test('wrong room and excluded broadcasts are not appended', () {
    receive('Wrong room', channel: 'room:other');
    fixture.socket.controller.add(
      const RoomSocketMessage(
        channel: 'room:canonical',
        event: 'RoomScreenMessageEvent',
        payload: {
          'from': {'uid': 10},
          'msg': 'Excluded',
        },
        toType: 'EXCLUDE_ONESELF',
        from: '10',
        msgId: 'excluded',
        raw: {},
      ),
    );
    expect(chats(), isEmpty);
  });
}
