import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_send_controller.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_state.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_view_model.dart';

void main() {
  const recipients = [
    RoomGiftRecipient(uid: 10, nickname: 'Self', seatPosition: 0),
    RoomGiftRecipient(uid: 20, nickname: 'Friend', seatPosition: 1),
    RoomGiftRecipient(uid: 30, nickname: 'Other', seatPosition: 2),
  ];
  const gift = RoomGift(
    id: 31,
    name: 'Rose',
    icon: '',
    price: 20,
    isCombo: 1,
    tabId: 1,
  );
  const catalog = RoomGiftCatalog(
    balance: 1000,
    canSendSelf: true,
    tabs: [
      RoomGiftTab(id: 1, name: 'Popular', gifts: [gift]),
    ],
  );
  late _Repository repository;
  late RoomGiftSendController sender;
  setUp(() {
    repository = _Repository(catalog);
    sender = RoomGiftSendController(repository, '123');
  });
  tearDown(() => sender.dispose());

  SendRoomGiftRequest request({
    String combo = '',
    int comboCount = 1,
    int source = 1,
    int? backpack,
  }) => SendRoomGiftRequest(
    targetUids: const [20],
    sendType: RoomGiftSendType.single,
    roomId: '123',
    giftId: 31,
    giftCount: 2,
    giftSource: source,
    comboId: combo,
    comboCount: comboCount,
    price: source == 2 ? 0 : 20,
    userBackpackId: backpack,
  );
  RoomScreenGiftMsg echo({int count = 1, int source = 1}) => RoomScreenGiftMsg(
    gift: gift,
    uid: 10,
    userInfo: const RoomGiftUser(uid: 10),
    uids: const [20],
    roomId: '123',
    comboId: 'server-combo',
    comboCount: count,
    giftSource: source,
    giftCount: 2,
    count: 2 * count,
  );

  test(
    'HTTP success enables the confirmed combo without inventing a visual event',
    () async {
      await sender.send(
        request: request(),
        gift: gift,
        targetCount: 1,
        catalog: catalog,
      );
      expect(sender.snapshot.catalog!.balance, 960);
      expect(sender.snapshot.message, isNull);
      expect(sender.snapshot.comboId, 'server-combo');
      expect(sender.snapshot.canContinue, isTrue);
      sender.acknowledge(echo(), DateTime.now());
      expect(sender.snapshot.canContinue, isTrue);
      await sender.continueCombo();
      expect(repository.requests.last.comboId, 'server-combo');
      expect(repository.requests.last.comboCount, 1);
      expect(sender.snapshot.catalog!.balance, 920);
      expect(sender.snapshot.awaitingEcho, isFalse);
      expect(sender.snapshot.canContinue, isTrue);
      sender.acknowledge(echo(count: 2), DateTime.now());
      expect(sender.snapshot.canContinue, isTrue);
    },
  );

  test('missing HTTP combo ID can fall back to the matching echo', () async {
    repository.result = const RoomGiftSendResult();
    await sender.send(
      request: request(),
      gift: gift,
      targetCount: 1,
      catalog: catalog,
    );
    expect(sender.snapshot.canContinue, isFalse);
    sender.acknowledge(echo(), DateTime.now());
    expect(sender.snapshot.canContinue, isTrue);
  });

  test(
    'confirmed combo rejects a different echo and locks repeated taps',
    () async {
      await sender.send(
        request: request(),
        gift: gift,
        targetCount: 1,
        catalog: catalog,
      );
      sender.acknowledge(
        RoomScreenGiftMsg(
          gift: gift,
          uid: 10,
          userInfo: const RoomGiftUser(uid: 10),
          uids: const [20],
          giftCount: 2,
          comboId: 'unrelated-combo',
          roomId: '123',
        ),
        DateTime.now(),
      );
      expect(sender.snapshot.message, isNull);
      repository.pending = Completer();
      final continuation = sender.continueCombo();
      expect(sender.snapshot.isSending, isTrue);
      expect(await sender.continueCombo(), isFalse);
      repository.pending!.complete(
        const RoomGiftSendResult(comboId: 'server-combo'),
      );
      expect(await continuation, isTrue);
      expect(repository.requests, hasLength(2));
      expect(repository.requests.last.comboCount, 1);
    },
  );

  test('server echo may precede HTTP completion', () async {
    repository.pending = Completer();
    final sending = sender.send(
      request: request(),
      gift: gift,
      targetCount: 1,
      catalog: catalog,
    );
    sender.acknowledge(echo(), DateTime.now());
    expect(sender.snapshot.isSending, isTrue);
    repository.pending!.complete(const RoomGiftSendResult());
    await sending;
    expect(sender.snapshot.canContinue, isTrue);
  });

  test(
    'failure does not deduct; repeated clicks and lifecycle reset retain request lock',
    () async {
      repository.pending = Completer();
      final first = sender.send(
        request: request(),
        gift: gift,
        targetCount: 1,
        catalog: catalog,
      );
      expect(
        await sender.send(
          request: request(),
          gift: gift,
          targetCount: 1,
          catalog: catalog,
        ),
        isNull,
      );
      sender.resetCombo();
      expect(sender.snapshot.isSending, isTrue);
      expect(
        await sender.send(
          request: request(),
          gift: gift,
          targetCount: 1,
          catalog: catalog,
        ),
        isNull,
      );
      final failure = expectLater(first, throwsStateError);
      repository.pending!.completeError(StateError('failed'));
      await failure;
      expect(repository.requests, hasLength(1));
      expect(repository.recordCount, 0);
      expect(sender.snapshot.catalog!.balance, 1000);
      expect(sender.snapshot.isSending, isFalse);
    },
  );

  test(
    'backpack stock is decremented for each target, missing record ID is blocked',
    () async {
      const backpack = RoomGift(
        id: 31,
        name: 'Rose',
        icon: '',
        price: 0,
        isCombo: 1,
        tabId: RoomGiftTab.backpackId,
        userBackpackId: 99,
        amount: 5,
      );
      final stock = catalog.copyWith(
        tabs: const [
          RoomGiftTab(
            id: RoomGiftTab.backpackId,
            name: 'Bag',
            gifts: [backpack],
          ),
        ],
      );
      await sender.send(
        request: request(source: 2, backpack: 99),
        gift: backpack,
        targetCount: 1,
        catalog: stock,
      );
      expect(sender.snapshot.catalog!.tabs.single.gifts.single.amount, 3);
      sender.acknowledge(echo(source: 2), DateTime.now());
      expect(await sender.continueCombo(), isTrue);
      expect(sender.snapshot.catalog!.tabs.single.gifts.single.amount, 1);
      sender.acknowledge(echo(source: 2, count: 2), DateTime.now());
      expect(await sender.continueCombo(), isFalse);
      expect(repository.requests, hasLength(2));
      const missing = RoomGift(
        id: 31,
        name: 'Rose',
        icon: '',
        price: 0,
        isCombo: 1,
        tabId: RoomGiftTab.backpackId,
        amount: 999,
      );
      await expectLater(
        sender.send(
          request: request(source: 2),
          gift: missing,
          targetCount: 1,
          catalog: stock,
        ),
        throwsA(isA<RoomGiftSendException>()),
      );
    },
  );

  test(
    'closing the panel during a failed request does not read disposed state',
    () async {
      final vm = RoomGiftViewModel(
        repository: repository,
        roomId: '123',
        sendController: sender,
      );
      await vm.initialize(
        recipients: recipients,
        onlineCount: 3,
        currentUid: 10,
      );
      repository.pending = Completer();
      final sending = vm.sendSelectedGift();
      vm.dispose();
      repository.pending!.completeError(StateError('request failed'));

      expect(await sending, isFalse);
      expect(repository.recordCount, 0);
    },
  );

  for (final mode in RoomGiftTargetMode.values) {
    test(
      'target mode ${mode.name} has compatible type, UIDs and total price',
      () async {
        final vm = RoomGiftViewModel(
          repository: repository,
          roomId: '123',
          sendController: sender,
        );
        addTearDown(vm.dispose);
        await vm.initialize(
          recipients: recipients,
          onlineCount: 3,
          currentUid: 10,
        );
        vm.selectTargetMode(mode);
        vm.setGiftCount(2);
        expect(await vm.sendSelectedGift(), isTrue);
        final sent = repository.requests.single;
        final expectedType = switch (mode) {
          RoomGiftTargetMode.allMic => 2,
          RoomGiftTargetMode.allRoom => 3,
          RoomGiftTargetMode.room => 4,
          RoomGiftTargetMode.selected => 1,
        };
        expect(sent.sendType.value, expectedType);
        expect(
          sent.targetUids,
          mode == RoomGiftTargetMode.allRoom || mode == RoomGiftTargetMode.room
              ? isNull
              : isNotEmpty,
        );
        expect(
          vm.state.balance,
          mode == RoomGiftTargetMode.allRoom ||
                  mode == RoomGiftTargetMode.allMic
              ? 880
              : 960,
        );
      },
    );
  }

  test(
    'selected multi mode sends type 6; invalid UIDs cannot be injected',
    () async {
      final vm = RoomGiftViewModel(
        repository: repository,
        roomId: '123',
        sendController: sender,
      );
      addTearDown(vm.dispose);
      await vm.initialize(
        recipients: recipients,
        onlineCount: 3,
        currentUid: 10,
      );
      vm.selectTargetMode(RoomGiftTargetMode.selected);
      vm.toggleRecipient(20);
      vm.toggleRecipient(999);
      expect(await vm.sendSelectedGift(), isTrue);
      expect(repository.requests.single.sendType.value, 6);
      expect(repository.requests.single.targetUids, [10, 20]);
    },
  );

  test(
    'send uses live seats; unavailable rooms block both panel and combo',
    () async {
      final vm = RoomGiftViewModel(
        repository: repository,
        roomId: '123',
        sendController: sender,
      );
      addTearDown(vm.dispose);
      await vm.initialize(
        recipients: recipients,
        onlineCount: 3,
        currentUid: 10,
      );
      sender.audience = RoomGiftAudience(
        isInRoom: true,
        onlineCount: 2,
        recipients: [recipients[1]],
      );
      expect(await vm.sendSelectedGift(), isTrue);
      expect(repository.requests.single.targetUids, [20]);
      sender.audience = const RoomGiftAudience(
        isInRoom: false,
        onlineCount: 0,
        recipients: [],
      );
      expect(await vm.sendSelectedGift(), isFalse);
      expect(vm.state.issue, RoomGiftIssue.roomUnavailable);
      expect(repository.requests, hasLength(1));
    },
  );
}

class _Repository extends RoomGiftRepository {
  _Repository(this.catalog);
  final RoomGiftCatalog catalog;
  final List<SendRoomGiftRequest> requests = [];
  Completer<RoomGiftSendResult>? pending;
  RoomGiftSendResult result = const RoomGiftSendResult(comboId: 'server-combo');
  int recordCount = 0;
  @override
  Future<int> fetchBalance() async => catalog.balance;
  @override
  Future<RoomGiftCatalog> fetchCatalog() async => catalog;
  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async {
    requests.add(request);
    return pending == null ? result : await pending!.future;
  }

  @override
  void recordGiftSent({
    required RoomGift gift,
    required int totalCount,
    required int balance,
  }) {
    recordCount++;
  }
}
