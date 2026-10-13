import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/model/room_socket_message.dart';

import 'support/room_lifecycle_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomLifecycleFixture fixture;
  late RoomRepository repository;
  late RoomViewModel model;
  late RoomPageState state;
  setUp(() async {
    fixture = RoomLifecycleFixture();
    fixture.http.roomOwnerUid = 10;
    repository = RoomRepository(
      roomManager: fixture.manager,
      socketManager: fixture.socket,
      agoraManager: fixture.agora,
      authSession: fixture.auth,
      httpManager: fixture.http,
    );
    model = RoomViewModel(repository: repository, roomId: 'alias');
    model.addListener((value) => state = value);
    fixture.http.canonicalRoomId = 'canonical';
    await model.enterRoom();
    await fixture.flush();
  });
  tearDown(() async {
    if (model.mounted) model.dispose();
    await fixture.dispose();
  });

  RoomSocketMessage emit(
    String event,
    Object payload, {
    String roomId = 'canonical',
  }) {
    final message = RoomSocketMessage(
      channel: 'room:$roomId',
      event: event,
      payload: payload,
      raw: const {},
      msgId: '$event-${DateTime.now().microsecondsSinceEpoch}',
    );
    fixture.socket.controller.add(message);
    return message;
  }

  test(
    'owner clears all filters using canonical ID, even without data',
    () async {
      emit('RoomScreenMessageEvent', {'msg': 'chat'});
      emit('RoomScreenSystemNoticeEvent', {'msg': 'notice'});
      emit('RoomScreenLuckyBagSendEvent', {'msg': 'gift'});
      final before = state;
      final connections = [...fixture.actions];
      model.setChatFilter(RoomChatFilter.gift);
      await model.clearMessages();
      expect(fixture.http.clearMessagesRequests, [
        {'roomId': 'canonical'},
      ]);
      expect(state.messages, isEmpty);
      for (final filter in RoomChatFilter.values) {
        expect(state.copyWith(chatFilter: filter).visibleMessages, isEmpty);
      }
      expect(state.chatFilter, RoomChatFilter.gift);
      expect(state.clearingMessages, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isReady, isTrue);
      expect(state.seats, same(before.seats));
      expect(state.audience, same(before.audience));
      expect(state.agoraState, same(before.agoraState));
      expect(state.socketReady, before.socketReady);
      expect(fixture.actions, connections);
      emit('RoomScreenMessageEvent', {'msg': 'new chat'});
      expect(state.messages.single.text, 'new chat');
    },
  );

  test('admin can clear but ordinary audience cannot call the API', () async {
    fixture.http.roomOwnerUid = 20;
    await model.refresh();
    expect(state.isOwnerOrManager, isFalse);
    final messages = state.messages;
    await model.clearMessages();
    expect(fixture.http.clearMessagesRequests, isEmpty);
    expect(state.messages, same(messages));

    await model.leaveRoom();
    fixture.http.roomIdentity = 'ROOM_MANAGER';
    await model.enterRoom();
    expect(state.isOwnerOrManager, isTrue);
    await model.clearMessages();
    expect(fixture.http.clearMessagesRequests, hasLength(1));
    expect(state.messages, isEmpty);
  });

  test('API failure preserves messages and permits a retry', () async {
    emit('RoomScreenMessageEvent', {'msg': 'keep me'});
    final messages = state.messages;
    fixture.http.clearMessagesResponse = const {
      'code': 1003,
      'message': 'Server error',
      'traceId': 'clear-error',
    };
    await model.clearMessages();
    expect(state.messages, same(messages));
    expect(state.clearingMessages, isFalse);
    expect(state.errorMessage, contains('clear-error'));
    fixture.http.clearMessagesResponse = const {'code': 200, 'data': null};
    await model.clearMessages();
    expect(state.messages, isEmpty);
    expect(state.errorMessage, isNull);
  });

  test(
    'network failure preserves messages and releases the pending flag',
    () async {
      final messages = state.messages;
      fixture.http.clearMessagesGate = Completer<void>();
      final pending = model.clearMessages();
      fixture.http.clearMessagesGate!.completeError(
        StateError('Network unavailable'),
      );
      await pending;
      expect(state.messages, same(messages));
      expect(state.clearingMessages, isFalse);
      expect(state.errorMessage, contains('Network unavailable'));
    },
  );

  test(
    'pending request is single-flight and never re-clears after broadcast',
    () async {
      fixture.http.clearMessagesGate = Completer<void>();
      final pending = model.clearMessages();
      await model.clearMessages();
      expect(state.clearingMessages, isTrue);
      expect(fixture.http.clearMessagesRequests, hasLength(1));
      emit('RoomScreenSystemClear', {});
      expect(state.messages.single.text, 'Screen has been cleared.');
      emit('RoomScreenMessageEvent', {'msg': 'after clear'});
      fixture.http.clearMessagesGate!.complete();
      await pending;
      expect(state.messages.map((entry) => entry.text), [
        'Screen has been cleared.',
        'after clear',
      ]);
      expect(state.clearingMessages, isFalse);
    },
  );

  test('another room cannot clear this public screen', () {
    final messages = state.messages;
    emit('RoomScreenSystemClear', {}, roomId: 'other');
    expect(state.messages, same(messages));
  });

  test('late response cannot clear a re-entered same-ID session', () async {
    fixture.http.clearMessagesGate = Completer<void>();
    final pending = model.clearMessages();
    await model.leaveRoom();
    await model.enterRoom();
    emit('RoomScreenMessageEvent', {'msg': 'new session'});
    final messages = state.messages;
    fixture.http.clearMessagesGate!.complete();
    await pending;
    expect(state.messages, same(messages));
    expect(state.clearingMessages, isFalse);
    expect(state.errorMessage, isNull);
  });

  test('late failure after disposal cannot update the next page', () async {
    fixture.http.clearMessagesGate = Completer<void>();
    final pending = model.clearMessages();
    model.dispose();
    fixture.http.clearMessagesGate!.completeError(StateError('late failure'));
    await pending;
  });

  test(
    'clear broadcast preserves gift lanes and Combo but removes history',
    () async {
      final ended = <String>[];
      final gifts = RoomGiftEventManager(
        roomId: 'canonical',
        messages: fixture.socket.messages,
        startTimer: false,
        onComboEnd: ended.add,
      );
      addTearDown(gifts.dispose);
      model.bindGiftManager(gifts);
      final giftPayload = {
        'roomId': 'canonical',
        'uid': 10,
        'userInfo': {'uid': 10, 'nick': 'Sender'},
        'gift': {
          'id': 31,
          'name': 'Rose',
          'isCombo': 1,
          'price': 20,
          'animationUrl': 'https://cdn.test/rose.svga',
        },
        'count': 1,
        'giftCount': 1,
        'comboCount': 1,
        'giftSource': 1,
        'sendType': 6,
        'uids': [20],
        'comboId': 'combo',
        'roomWeekVal': 80,
      };
      final firstGift = emit('roomScreenSendGiftComboEvent', giftPayload);
      expect(state.messages.where((entry) => entry.isGift), hasLength(1));
      final before = gifts.snapshot;
      expect(before.flights, isNotEmpty);
      expect(before.effects, isNotEmpty);
      expect(before.slots.whereType<Object>(), isNotEmpty);

      await model.clearMessages();
      expect(state.messages, isEmpty);
      expect(gifts.snapshot.publicMessages, isEmpty);
      emit('RoomScreenSystemClear', {});
      expect(state.messages, hasLength(1));
      expect(gifts.snapshot.publicMessages, isEmpty);
      expect(gifts.snapshot.slots, same(before.slots));
      expect(gifts.snapshot.flights, same(before.flights));
      expect(gifts.snapshot.effects, same(before.effects));
      expect(gifts.snapshot.banners, same(before.banners));
      expect(gifts.snapshot.lucky, same(before.lucky));
      expect(gifts.snapshot.roomWeekVal, before.roomWeekVal);
      expect(ended, isEmpty);
      fixture.socket.controller.add(firstGift);
      expect(gifts.snapshot.publicMessages, isEmpty);
      gifts.expire();
      expect(state.messages.where((entry) => entry.isGift), isEmpty);
      emit('roomScreenSendGiftComboEvent', {...giftPayload, 'comboId': 'new'});
      expect(state.messages.where((entry) => entry.isGift), hasLength(1));

      // Keep disposes the page model, but the gift runtime still receives clears.
      model.dispose();
      emit('RoomScreenSystemClear', {}, roomId: 'other');
      expect(gifts.snapshot.publicMessages, hasLength(1));
      emit('RoomScreenSystemClear', {});
      expect(gifts.snapshot.publicMessages, isEmpty);
    },
  );
}
