import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_state.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_view_model.dart';

void main() {
  const self = RoomGiftRecipient(uid: 10, nickname: 'Self', seatPosition: 0);
  const friend = RoomGiftRecipient(
    uid: 20,
    nickname: 'Friend',
    seatPosition: 1,
  );

  test(
    'initialization removes self when server disallows self gifting',
    () async {
      final repository = _FakeGiftRepository(
        catalog: _catalog(canSendSelf: false),
      );
      final viewModel = RoomGiftViewModel(
        repository: repository,
        roomId: 'room-1',
      );

      await viewModel.initialize(
        recipients: const [self, friend],
        onlineCount: 2,
        currentUid: self.uid,
      );

      expect(viewModel.state.status, RoomGiftLoadStatus.ready);
      expect(viewModel.state.recipients.map((item) => item.uid), [friend.uid]);
      expect(viewModel.state.targetMode, RoomGiftTargetMode.allMic);
      expect(viewModel.state.selectedRecipientUids, {friend.uid});
    },
  );

  test('initialization uses cached catalog without fetching again', () async {
    final catalog = _catalog();
    final repository = _FakeGiftRepository(
      catalog: catalog,
      cachedCatalogValue: catalog,
    );
    final viewModel = RoomGiftViewModel(
      repository: repository,
      roomId: 'room-1',
    );

    await viewModel.initialize(
      recipients: const [friend],
      onlineCount: 1,
      currentUid: self.uid,
    );

    expect(repository.fetchCatalogCalls, 0);
    expect(viewModel.state.status, RoomGiftLoadStatus.ready);
    expect(viewModel.state.selectedGift?.name, 'Rose');
  });

  test('single selected recipient maps to sendType single', () async {
    final repository = _FakeGiftRepository(catalog: _catalog());
    final viewModel = RoomGiftViewModel(
      repository: repository,
      roomId: 'room-1',
    );
    await viewModel.initialize(
      recipients: const [self, friend],
      onlineCount: 2,
      currentUid: self.uid,
    );

    viewModel.selectTargetMode(RoomGiftTargetMode.selected);
    final sent = await viewModel.sendSelectedGift();

    expect(sent, isTrue);
    expect(repository.sentRequests, hasLength(1));
    expect(repository.sentRequests.single.targetUids, [self.uid]);
    expect(repository.sentRequests.single.sendType, RoomGiftSendType.single);
    expect(repository.sentRequests.single.giftSource, 1);
  });

  test('insufficient balance blocks the request', () async {
    final repository = _FakeGiftRepository(catalog: _catalog(balance: 1));
    final viewModel = RoomGiftViewModel(
      repository: repository,
      roomId: 'room-1',
    );
    await viewModel.initialize(
      recipients: const [friend],
      onlineCount: 1,
      currentUid: self.uid,
    );

    final sent = await viewModel.sendSelectedGift();

    expect(sent, isFalse);
    expect(viewModel.state.issue, RoomGiftIssue.notEnoughCoin);
    expect(repository.sentRequests, isEmpty);
  });

  test('backpack gift sends source 2 and its record id', () async {
    const backpackGift = RoomGift(
      id: 77,
      name: 'Backpack Rose',
      icon: '',
      price: 0,
      isCombo: 0,
      tabId: RoomGiftTab.backpackId,
      amount: 3,
      userBackpackId: 900,
    );
    final repository = _FakeGiftRepository(
      catalog: RoomGiftCatalog(
        balance: 0,
        canSendSelf: true,
        tabs: const [
          RoomGiftTab(
            id: RoomGiftTab.backpackId,
            name: 'Backpack',
            gifts: [backpackGift],
          ),
        ],
      ),
    );
    final viewModel = RoomGiftViewModel(
      repository: repository,
      roomId: 'room-1',
    );
    await viewModel.initialize(
      recipients: const [friend],
      onlineCount: 1,
      currentUid: self.uid,
    );

    final sent = await viewModel.sendSelectedGift();

    expect(sent, isTrue);
    expect(repository.sentRequests.single.giftSource, 2);
    expect(repository.sentRequests.single.userBackpackId, 900);
    expect(repository.recordedBalance, 0);
    expect(repository.recordedTotalCount, 1);
  });
}

RoomGiftCatalog _catalog({int balance = 1000, bool canSendSelf = true}) {
  const gift = RoomGift(
    id: 31,
    name: 'Rose',
    icon: '',
    price: 20,
    isCombo: 1,
    tabId: 8,
  );
  return RoomGiftCatalog(
    balance: balance,
    canSendSelf: canSendSelf,
    tabs: const [
      RoomGiftTab(id: 8, name: 'Popular', gifts: [gift]),
    ],
  );
}

class _FakeGiftRepository implements RoomGiftRepository {
  _FakeGiftRepository({required this.catalog, this.cachedCatalogValue});

  final RoomGiftCatalog catalog;
  final RoomGiftCatalog? cachedCatalogValue;
  final List<SendRoomGiftRequest> sentRequests = [];
  int fetchCatalogCalls = 0;
  int? recordedBalance;
  int? recordedTotalCount;

  @override
  RoomGiftCatalog? get cachedCatalog => cachedCatalogValue;

  @override
  Future<RoomGiftCatalog> fetchCatalog() async {
    fetchCatalogCalls += 1;
    return catalog;
  }

  @override
  Future<int> fetchBalance() async => catalog.balance;

  @override
  void recordGiftSent({
    required RoomGift gift,
    required int totalCount,
    required int balance,
  }) {
    recordedBalance = balance;
    recordedTotalCount = totalCount;
  }

  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async {
    sentRequests.add(request);
    return const RoomGiftSendResult(comboId: 'combo-1');
  }
}
