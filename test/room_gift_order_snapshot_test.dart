import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_send_controller.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_state.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_view_model.dart';

void main() {
  const gift = RoomGift(
    id: 31,
    name: 'Gift',
    icon: '',
    price: 1,
    isCombo: 1,
    tabId: 1,
  );
  late _Repository repo;
  late RoomGiftSendController sender;
  SendRoomGiftRequest request({
    List<int>? targets = const [20],
    RoomGiftSendType type = RoomGiftSendType.single,
    int count = 1,
  }) => SendRoomGiftRequest(
    targetUids: targets,
    sendType: type,
    roomId: '123',
    giftId: 31,
    giftCount: count,
    giftSource: 1,
    comboId: '',
    comboCount: 1,
    price: 1,
  );
  setUp(() {
    repo = _Repository(gift);
    sender = RoomGiftSendController(repo, '123');
  });
  tearDown(() => sender.dispose());

  test(
    'original mutable recipient list cannot change the paid snapshot',
    () async {
      final targets = [20];
      await sender.send(
        request: request(targets: targets),
        gift: gift,
        targetCount: 1,
        catalog: repo.catalog,
      );
      targets[0] = 30;
      expect(sender.snapshot.request!.targetUids, [20]);
      expect(repo.requests.single.targetUids, [20]);
      expect(
        () => sender.snapshot.request!.targetUids!.add(40),
        throwsUnsupportedError,
      );
      expect(await sender.continueCombo(), isTrue);
      expect(repo.requests.last.targetUids, [20]);
      expect(repo.requests.last.price, 1);
    },
  );

  test('price changes end the combo without another request', () async {
    await sender.send(
      request: request(),
      gift: gift,
      targetCount: 1,
      catalog: repo.catalog,
    );
    repo.catalog = RoomGiftCatalog(
      balance: 100,
      canSendSelf: true,
      tabs: [
        const RoomGiftTab(
          id: 1,
          name: 'Gifts',
          gifts: [
            RoomGift(
              id: 31,
              name: 'Gift',
              icon: '',
              price: 2,
              isCombo: 1,
              tabId: 1,
            ),
          ],
        ),
      ],
    );
    expect(await sender.continueCombo(), isFalse);
    expect(repo.requests, hasLength(1));
    expect(sender.snapshot.issue, 'comboChanged');
    expect(sender.snapshot.canContinue, isFalse);
  });

  test(
    'same-size all-room member replacement cannot silently change recipients',
    () async {
      sender.audience = const RoomGiftAudience(
        isInRoom: true,
        onlineCount: 2,
        onlineUids: {10, 20},
        recipients: [],
      );
      await sender.send(
        request: request(targets: null, type: RoomGiftSendType.onRoom),
        gift: gift,
        targetCount: 2,
        catalog: repo.catalog,
      );
      sender.audience = const RoomGiftAudience(
        isInRoom: true,
        onlineCount: 2,
        onlineUids: {10, 30},
        recipients: [],
      );
      expect(await sender.continueCombo(), isFalse);
      expect(repo.requests, hasLength(1));
    },
  );

  test(
    'off-mic selected user leaving ends combo, not retargeted to a mic occupant',
    () async {
      sender.audience = const RoomGiftAudience(
        isInRoom: true,
        onlineCount: 2,
        onlineUids: {10, 20},
        recipients: [],
      );
      await sender.send(
        request: request(),
        gift: gift,
        targetCount: 1,
        catalog: repo.catalog,
      );
      sender.audience = const RoomGiftAudience(
        isInRoom: true,
        onlineCount: 2,
        onlineUids: {10, 30},
        recipients: [
          RoomGiftRecipient(uid: 30, nickname: 'New', seatPosition: 1),
        ],
      );
      expect(await sender.continueCombo(), isFalse);
      expect(repo.requests, hasLength(1));
    },
  );

  test(
    'defensive quantity limits reject zero and five digits before API',
    () async {
      for (final count in [0, -1, 10000]) {
        await expectLater(
          sender.send(
            request: request(count: count),
            gift: gift,
            targetCount: 1,
            catalog: repo.catalog,
          ),
          throwsA(
            isA<RoomGiftSendException>().having(
              (e) => e.issue,
              'issue',
              RoomGiftIssue.invalidCount,
            ),
          ),
        );
      }
      expect(repo.requests, isEmpty);
    },
  );

  test(
    'reselecting the same gift keeps quantity; changing gift restores default',
    () async {
      final vm = RoomGiftViewModel(
        repository: repo,
        roomId: '123',
        sendController: sender,
      );
      addTearDown(vm.dispose);
      await vm.initialize(recipients: const [], onlineCount: 1, currentUid: 10);
      vm.setGiftCount(18);
      vm.selectGift(gift);
      expect(vm.state.giftCount, 18);
      vm.setGiftCount(10000);
      expect(vm.state.giftCount, 18);
      vm.selectGift(
        const RoomGift(
          id: 32,
          name: 'Other',
          icon: '',
          price: 1,
          isCombo: 1,
          tabId: 1,
          defaultGiftNum: 8,
        ),
      );
      expect(vm.state.giftCount, 8);
    },
  );
}

class _Repository extends RoomGiftRepository {
  _Repository(RoomGift gift)
    : catalog = RoomGiftCatalog(
        balance: 100,
        canSendSelf: true,
        tabs: [
          RoomGiftTab(id: 1, name: 'Gifts', gifts: [gift]),
        ],
      );
  RoomGiftCatalog catalog;
  final requests = <SendRoomGiftRequest>[];
  @override
  RoomGiftCatalog get cachedCatalog => catalog;
  @override
  Future<RoomGiftCatalog> fetchCatalog() async => catalog;
  @override
  Future<int> fetchBalance() async => catalog.balance;
  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async {
    requests.add(request);
    return const RoomGiftSendResult(comboId: 'receipt');
  }

  @override
  void recordGiftSent({
    required RoomGift gift,
    required int totalCount,
    required int balance,
  }) {
    catalog = catalog.copyWith(balance: balance);
  }
}
