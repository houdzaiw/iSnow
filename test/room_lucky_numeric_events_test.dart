import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'room_gift_events_test.dart' show payload, socket;

void main() {
  late RoomGiftEventManager manager;
  setUp(() => manager = RoomGiftEventManager(roomId: '123', startTimer: false));
  tearDown(() => manager.dispose());
  void count(int value, String id, {String combo = 'same', int uid = 10}) =>
      manager.receive(
        socket({
          ...payload(combo: combo, uid: uid),
          'gift': {'id': 31},
          'isLuckyGift': true,
          'totalGiftCount': value,
        }, id: id),
      );
  void bubble(String id, int multiplier) => manager.receive(
    socket(
      {
        'roomId': '123',
        'comboId': 'same',
        'userBaseInfo': {'uid': 10},
        'amount': 100,
        'multiply': multiplier,
      },
      id: id,
      event: 'LuckyGiftBigMultiple',
    ),
  );
  test(
    'missing/under-10 count has no fake numeric effect, a jump plays only highest',
    () {
      count(0, 'zero');
      count(9, 'nine');
      expect(manager.snapshot.lucky, isEmpty);
      count(150, 'jump');
      expect(manager.snapshot.lucky.single.numberLevel, 100);
      count(20, 'old');
      count(151, 'same-tier');
      expect(manager.snapshot.lucky, hasLength(1));
      manager.completeLucky(manager.snapshot.lucky.first.key);
      count(150, 'repeat');
      expect(manager.snapshot.lucky, isEmpty);
      count(10, 'new-user', uid: 20);
      expect(manager.snapshot.lucky.single.numberLevel, 10);
    },
  );
  test(
    'bubble wins take priority among waiting items; active numeric remains stable',
    () {
      count(10, 'active');
      final active = manager.snapshot.lucky.first.key;
      bubble('small', 10);
      bubble('large', 100);
      expect(manager.snapshot.lucky.first.key, active);
      manager.completeLucky(active);
      expect(manager.snapshot.lucky.first.key, 'large');
      manager.completeLucky('small');
      expect(manager.snapshot.lucky.first.key, 'large');
      manager.completeLucky('large');
      expect(manager.snapshot.lucky.single.key, 'small');
    },
  );
  test(
    'Keep updates watermark without replay; exit clears it for a new room session',
    () {
      manager.setVisible(false);
      count(100, 'hidden');
      manager.setVisible(true);
      count(100, 'visible');
      expect(manager.snapshot.lucky, isEmpty);
      count(200, 'new');
      expect(manager.snapshot.lucky.single.numberLevel, 200);
      manager.setSessionActive(false);
      manager.setSessionActive(true);
      manager.setVisible(true);
      count(10, 'new-session');
      expect(manager.snapshot.lucky.single.numberLevel, 10);
    },
  );
}
