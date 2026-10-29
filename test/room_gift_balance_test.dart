import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_send_controller.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_state.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_view_model.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/manager/room_gift_manager.dart';
import 'package:project/model/server_response.dart';

const _friend = RoomGiftRecipient(uid: 20, nickname: 'Friend', seatPosition: 0);
const _gift = RoomGift(
  id: 31,
  name: 'Rose',
  icon: '',
  price: 20,
  isCombo: 1,
  tabId: 8,
);
const _catalog = RoomGiftCatalog(
  balance: 1000,
  canSendSelf: true,
  tabs: [
    RoomGiftTab(id: 8, name: 'Popular', gifts: [_gift]),
  ],
);

Future<void> _flush() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('gift panel balance', () {
    late _BalanceRepository repository;
    late RoomGiftSendController sender;
    late RoomGiftViewModel vm;
    setUp(() {
      repository = _BalanceRepository();
      sender = RoomGiftSendController(repository, 'room-1');
      vm = RoomGiftViewModel(
        repository: repository,
        roomId: 'room-1',
        sendController: sender,
      );
    });
    tearDown(() {
      if (vm.mounted) vm.dispose();
      sender.dispose();
    });

    Future<void> initialize([int balance = 1000]) async {
      final ready = vm.initialize(
        recipients: const [_friend],
        onlineCount: 1,
        currentUid: 10,
      );
      repository.reads.last.complete(balance);
      await ready;
      await _flush();
    }

    test(
      'a slow purse does not delay cached initialization or presets',
      () async {
        await vm.initialize(
          recipients: const [_friend],
          onlineCount: 1,
          currentUid: 10,
        );
        expect(repository.reads.single.isCompleted, isFalse);
        vm.applyPreset(targetUid: 20, giftId: _gift.id);
        vm.setGiftCount(8);
        repository.reads.single.complete(2000);
        await _flush();
        expect(vm.state.balance, 2000);
        expect(vm.state.selectedRecipientUids, {20});
        expect(vm.state.giftCount, 8);
      },
    );

    test(
      'cached gifts render immediately and only the balance is fetched',
      () async {
        final ready = vm.initialize(
          recipients: const [_friend],
          onlineCount: 1,
          currentUid: 10,
        );
        expect(vm.state.status, RoomGiftLoadStatus.ready);
        expect(vm.state.balance, 1000);
        vm.setGiftCount(8);
        final selected = vm.state.selectedGiftKey;
        repository.reads.single.complete(2500);
        await ready;
        await _flush();
        expect(vm.state.balance, 2500);
        expect(vm.state.giftCount, 8);
        expect(vm.state.selectedGiftKey, selected);
        expect(repository.catalogLoads, 0);
      },
    );

    test('concurrent refreshes share a single request', () async {
      await initialize();
      final a = vm.refreshBalance();
      final b = vm.refreshBalance();
      expect(repository.reads, hasLength(2));
      repository.reads.last.complete(2400);
      await Future.wait([a, b]);
      expect(vm.state.balance, 2400);
    });

    test('refresh failure preserves cached balance and ready state', () async {
      final ready = vm.initialize(
        recipients: const [_friend],
        onlineCount: 1,
        currentUid: 10,
      );
      repository.reads.single.completeError(StateError('Offline'));
      await ready;
      expect(vm.state.balance, 1000);
      expect(vm.state.status, RoomGiftLoadStatus.ready);
      expect(vm.state.issue, isNull);
    });

    test(
      'send and combo publish server balances to the still-open panel',
      () async {
        await initialize();
        expect(await vm.sendSelectedGift(), isTrue);
        expect(vm.state.balance, 980);
        repository.reads.last.complete(975);
        await _flush();
        expect(vm.state.balance, 975);
        expect(sender.snapshot.canContinue, isTrue);
        expect(await sender.continueCombo(), isTrue);
        repository.reads.last.complete(950);
        await _flush();
        expect(vm.state.balance, 950);
        expect(vm.state.selectedGiftKey, _gift.selectionKey);
        expect(vm.state.giftCount, 1);
      },
    );

    test('an older open request cannot overwrite a confirmed gift', () async {
      final ready = vm.initialize(
        recipients: const [_friend],
        onlineCount: 1,
        currentUid: 10,
      );
      expect(await vm.sendSelectedGift(), isTrue);
      expect(repository.reads, hasLength(2));
      repository.reads.first.complete(1000);
      await ready;
      expect(vm.state.balance, 980);
      repository.reads.last.complete(970);
      await _flush();
      expect(vm.state.balance, 970);
    });

    test('failed send reconciles coins without hiding its issue', () async {
      await initialize();
      repository.sendError = const NadyApiException(
        message: 'Not enough coins',
      );
      expect(await vm.sendSelectedGift(), isFalse);
      repository.reads.last.complete(0);
      await _flush();
      expect(vm.state.balance, 0);
      expect(vm.state.issue, RoomGiftIssue.requestFailed);
      expect(vm.state.issueMessage, 'Not enough coins');
    });

    test('a refreshed insufficient balance blocks sending', () async {
      await initialize(0);
      expect(await vm.sendSelectedGift(), isFalse);
      expect(repository.sends, 0);
      expect(vm.state.issue, RoomGiftIssue.notEnoughCoin);
    });

    test('disposing the panel removes its sender listener', () async {
      await initialize();
      final refresh = vm.refreshBalance();
      vm.dispose();
      repository.reads.last.complete(500);
      await refresh;
      expect(sender.hasListeners, isFalse);
    });
  });

  group('authoritative purse and singleton cache', () {
    final manager = RoomGiftManager.instance;
    late HttpDioManager http;
    late HttpClientAdapter previous;
    late _PurseAdapter adapter;
    late NadyRoomGiftRepository repository;
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'nady.pubUid': 10,
        'nady.oauthToken': 'balance-test',
      });
      manager.clear();
      await manager.getOrLoad(
        cacheKey: 'user:10',
        loader: () async => _catalog,
      );
      http = HttpDioManager();
      previous = http.getDio().httpClientAdapter;
      adapter = _PurseAdapter();
      http.getDio().httpClientAdapter = adapter;
      repository = NadyRoomGiftRepository(http);
    });
    tearDown(() {
      http.getDio().httpClientAdapter = previous;
      manager.clear();
    });

    test('purse updates cached coins without replacing gift tabs', () async {
      final tabs = manager.catalog!.tabs;
      final balance = repository.fetchBalance();
      await _flush();
      adapter.response.complete({
        'code': 200,
        'data': {'coin': 2500},
      });
      expect(await balance, 2500);
      expect(manager.catalog!.balance, 2500);
      expect(manager.catalog!.tabs, same(tabs));
    });

    test(
      'a purse response predating a paid gift cannot undo its deduction',
      () async {
        final balance = repository.fetchBalance();
        await _flush();
        manager.recordGiftSent(gift: _gift, totalCount: 1, balance: 980);
        adapter.response.complete({
          'code': 200,
          'data': {'coin': 1000},
        });
        expect(await balance, 980);
        expect(manager.catalog!.balance, 980);
      },
    );

    test('an old account response cannot update the next account', () async {
      final balance = repository.fetchBalance();
      final rejected = expectLater(balance, throwsA(isA<NadyApiException>()));
      await _flush();
      manager.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('nady.pubUid', 20);
      await manager.getOrLoad(
        cacheKey: 'user:20',
        loader: () async => _catalog.copyWith(balance: 300),
      );
      adapter.response.complete({
        'code': 200,
        'data': {'coin': 9999},
      });
      await rejected;
      expect(manager.catalog!.balance, 300);
    });

    test(
      'a relogin to the same UID still rejects an old purse response',
      () async {
        final balance = repository.fetchBalance();
        final rejected = expectLater(balance, throwsA(isA<NadyApiException>()));
        await _flush();
        manager.clear();
        await manager.getOrLoad(
          cacheKey: 'user:10',
          loader: () async => _catalog.copyWith(balance: 200),
        );
        adapter.response.complete({
          'code': 200,
          'data': {'coin': 9999},
        });
        await rejected;
        expect(manager.catalog!.balance, 200);
      },
    );

    test(
      'a late paid response cannot proceed to a new account cache',
      () async {
        final sending = repository.sendGift(
          const SendRoomGiftRequest(
            targetUids: [20],
            sendType: RoomGiftSendType.single,
            roomId: 'room-1',
            giftId: 31,
            giftCount: 1,
            giftSource: 1,
            comboId: '',
            comboCount: 1,
            price: 20,
          ),
        );
        final rejected = expectLater(sending, throwsA(isA<NadyApiException>()));
        await _flush();
        manager.clear();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('nady.pubUid', 20);
        await manager.getOrLoad(
          cacheKey: 'user:20',
          loader: () async => _catalog.copyWith(balance: 300),
        );
        adapter.response.complete({'code': 200, 'data': 'old-account-combo'});
        await rejected;
        expect(manager.catalog!.balance, 300);
      },
    );

    test('a missing coin field is not treated as a zero balance', () async {
      final balance = repository.fetchBalance();
      final rejected = expectLater(balance, throwsA(isA<NadyApiException>()));
      await _flush();
      adapter.response.complete({'code': 200, 'data': {}});
      await rejected;
      expect(manager.catalog!.balance, 1000);
    });
  });
}

class _BalanceRepository extends RoomGiftRepository {
  RoomGiftCatalog current = _catalog;
  final reads = <Completer<int>>[];
  int catalogLoads = 0, sends = 0;
  Object? sendError;
  @override
  RoomGiftCatalog get cachedCatalog => current;
  @override
  Future<RoomGiftCatalog> fetchCatalog() async {
    catalogLoads++;
    return current;
  }

  @override
  Future<int> fetchBalance() {
    final request = Completer<int>();
    reads.add(request);
    return request.future;
  }

  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async {
    sends++;
    if (sendError != null) throw sendError!;
    return const RoomGiftSendResult(comboId: 'combo-balance');
  }

  @override
  void recordGiftSent({
    required RoomGift gift,
    required int totalCount,
    required int balance,
  }) {
    current = deductGift(current, gift, totalCount, balance);
  }
}

class _PurseAdapter implements HttpClientAdapter {
  final response = Completer<Map<String, dynamic>>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => ResponseBody.fromString(
    jsonEncode(await response.future),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}
