import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/manager/app_socket_manager.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/user_profile.dart';

import 'room_gift_events_test.dart' show payload, socket;

void main() {
  late _RoomRepository repository;
  late RoomGiftEventManager gifts;
  late RoomViewModel model;
  late RoomPageState snapshot;
  setUp(() async {
    repository = _RoomRepository();
    gifts = RoomGiftEventManager(roomId: '123', startTimer: false);
    model = RoomViewModel(
      repository: repository,
      roomId: '123',
      giftManager: gifts,
    );
    model.addListener((state) => snapshot = state);
    await Future<void>.delayed(Duration.zero);
  });
  tearDown(() async {
    model.dispose();
    gifts.dispose();
    await repository.messages.close();
  });

  test('periodic gift updates do not resurrect retired chat entries', () {
    gifts.receive(socket(payload(), id: 'gift'));
    for (var i = 0; i < 80; i++) {
      repository.messages.add(
        socket(
          {'msg': 'Chat $i'},
          event: 'RoomScreenMessageEvent',
          id: 'chat-$i',
        ),
      );
    }
    expect(snapshot.messages, hasLength(80));
    expect(snapshot.messages.every((entry) => entry.gift == null), isTrue);
    final chatIds = snapshot.messages.map((entry) => entry.id).toList();
    gifts.expire();
    gifts.receive(socket(payload(count: 2), id: 'combo-update'));
    gifts.receive(
      socket(
        {'roomWeekVal': 123},
        event: 'RoomGiftStreamUpdateEvent',
        id: 'stream',
      ),
    );
    expect(snapshot.messages.map((entry) => entry.id), chatIds);
    expect(snapshot.roomWeekVal, 123);
    gifts.receive(socket(payload(combo: 'new'), id: 'new-gift'));
    expect(snapshot.messages.last.gift!.key, 'new');
    expect(
      snapshot.messages.where((entry) => entry.gift != null),
      hasLength(1),
    );
  });

  test('Nady combo public-screen text is not silently ignored', () {
    repository.messages.add(
      socket(
        '{"from":{"uid":10,"nick":"Sender"},"msg":"Sent Rose x1"}',
        event: 'RoomSendGiftComboPublicScreenEvent',
        id: 'combo-text',
      ),
    );
    expect(snapshot.messages.last.text, 'Sent Rose x1');
    expect(snapshot.messages.last.kind, RoomChatEntryKind.gift);
  });

  test(
    'combo public-screen updates preserve chat order and restore history',
    () async {
      gifts.receive(socket(payload(), id: 'gift'));
      repository.messages.add(
        socket({'msg': 'Hello'}, event: 'RoomScreenMessageEvent', id: 'chat'),
      );
      final ids = snapshot.messages.map((entry) => entry.id).toList();
      gifts.receive(socket(payload(count: 3), id: 'combo-update'));
      expect(snapshot.messages.map((entry) => entry.id), ids);
      expect(
        snapshot.messages
            .where((entry) => entry.gift != null)
            .single
            .gift!
            .count,
        3,
      );
      await model.enterRoom();
      expect(
        snapshot.messages
            .where((entry) => entry.gift != null)
            .single
            .gift!
            .count,
        3,
      );
    },
  );
}

class _RoomRepository implements RoomRepository {
  final messages = StreamController<RoomSocketMessage>.broadcast(sync: true);
  @override
  Stream<RoomSocketMessage> get socketMessages => messages.stream;
  @override
  RoomState get roomState => const RoomState(
    currentRoomId: '123',
    isInRoom: true,
    status: RoomStatus.ready,
  );
  @override
  AppSocketState get socketState => const AppSocketState();
  @override
  RoomAgoraState get agoraState => const RoomAgoraState();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  Future<int?> currentUid() async => 10;
  @override
  Future<UserData?> currentUser() async => null;
  @override
  Future<void> enterRoom({
    required String roomId,
    String roomPassword = '',
    int followUid = 0,
  }) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
