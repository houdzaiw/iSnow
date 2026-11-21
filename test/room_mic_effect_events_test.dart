import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/room_socket_message.dart';
import 'room_gift_events_test.dart' show payload, socket;

void main() {
  late RoomGiftEventManager manager;
  var now = DateTime(2026, 11, 16);
  setUp(() {
    now = DateTime(2026, 11, 16);
    manager = RoomGiftEventManager(
      roomId: '123',
      startTimer: false,
      now: () => now,
    );
    manager.syncMicOccupants({0: 20, 1: 30});
  });
  tearDown(() => manager.dispose());
  RoomSocketMessage face(String key, {int uid = 20, String room = '123'}) =>
      RoomSocketMessage(
        channel: 'room:$room',
        event: 'RoomScreenExpressionEvent',
        raw: const {},
        msgId: key,
        receivedAt: now,
        payload: {
          'roomId': room,
          'from': {'uid': uid},
          'msg': jsonEncode({
            'dynamicPic': 'https://cdn.example/face.svga',
            'type': 1,
          }),
        },
      );
  test(
    'magic and expression replace the same layer; stale completion cannot remove new one',
    () {
      manager.receive(
        socket(
          {
            ...payload(),
            'gift': {
              'id': 20,
              'giftType': 2,
              'animationUrl': 'https://cdn.example/magic.pag',
            },
          },
          id: 'magic',
          time: now,
        ),
      );
      expect(manager.snapshot.effects, isEmpty);
      expect(manager.snapshot.micEffects.keys, containsAll([0, 1]));
      final old = manager.snapshot.micEffects[0]!.key;
      manager.receive(face('face'));
      expect(manager.snapshot.micEffects[0]!.key, 'mic-expression:face');
      manager.completeMicEffect(0, old);
      expect(manager.snapshot.micEffects[0]!.key, 'mic-expression:face');
      manager.completeMicEffect(0, 'mic-expression:face');
      expect(manager.snapshot.micEffects.keys, [1]);
    },
  );
  test(
    'off-mic/wrong room/replayed expressions are ignored; moving seats clears old layer',
    () {
      manager.receive(face('off', uid: 99));
      manager.receive(face('other', room: '9'));
      expect(manager.snapshot.micEffects, isEmpty);
      manager.receive(face('one'));
      manager.receive(face('two'));
      manager.receive(face('one'));
      expect(manager.snapshot.micEffects[0]!.key, 'mic-expression:two');
      manager.syncMicOccupants({1: 20});
      expect(manager.snapshot.micEffects, isEmpty);
      manager.receive(face('three'));
      expect(manager.snapshot.micEffects.keys, [1]);
      now = now.add(const Duration(seconds: 8));
      manager.expire();
      expect(manager.snapshot.micEffects, isEmpty);
    },
  );
  test('Keep and room exit clear effects and reject hidden arrivals', () {
    manager.receive(face('before'));
    manager.setVisible(false);
    manager.receive(face('hidden'));
    expect(manager.snapshot.micEffects, isEmpty);
    manager.setVisible(true);
    expect(manager.snapshot.micEffects, isEmpty);
    manager.receive(face('fresh'));
    expect(manager.snapshot.micEffects, isNotEmpty);
    manager.setSessionActive(false);
    expect(manager.snapshot.micEffects, isEmpty);
  });
  test(
    'mic appearance reads actual user decoration, absent data stays absent',
    () {
      final seat = RoomSeatViewData.fromMic(
        RoomMicModel.fromJson({
          'position': 0,
          'uid': 20,
          'userBaseInfo': {
            'uid': 20,
            'avatarWidget': {'animationUrl': 'frame.svga', 'icon': 'frame.png'},
          },
        }),
        position: 0,
      );
      expect(seat.appearance.frameUrl, 'frame.svga');
      expect(seat.appearance.framePreview, 'frame.png');
      expect(RoomSeatViewData.empty(0).appearance.frameUrl, isNull);
    },
  );
}
