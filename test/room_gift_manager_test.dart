import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/manager/room_gift_manager.dart';

void main() {
  final manager = RoomGiftManager.instance;

  setUp(manager.clear);
  tearDown(manager.clear);

  test('reuses the catalog after the first successful load', () async {
    var loadCount = 0;

    Future<RoomGiftCatalog> loader() async {
      loadCount += 1;
      return _catalog();
    }

    final first = await manager.getOrLoad(cacheKey: 'user:10', loader: loader);
    final second = await manager.getOrLoad(cacheKey: 'user:10', loader: loader);

    expect(loadCount, 1);
    expect(identical(first, second), isTrue);
    expect(manager.catalog, same(first));
  });

  test('coalesces concurrent loads for the same user', () async {
    final completer = Completer<RoomGiftCatalog>();
    var loadCount = 0;

    Future<RoomGiftCatalog> loader() {
      loadCount += 1;
      return completer.future;
    }

    final first = manager.getOrLoad(cacheKey: 'user:10', loader: loader);
    final second = manager.getOrLoad(cacheKey: 'user:10', loader: loader);
    completer.complete(_catalog());

    await Future.wait([first, second]);
    expect(loadCount, 1);
  });

  test('does not retain an empty catalog', () async {
    var loadCount = 0;

    Future<RoomGiftCatalog> loader() async {
      loadCount += 1;
      if (loadCount == 1) {
        return const RoomGiftCatalog(balance: 0, canSendSelf: true, tabs: []);
      }
      return _catalog();
    }

    await manager.getOrLoad(cacheKey: 'user:10', loader: loader);
    expect(manager.catalog, isNull);

    await manager.getOrLoad(cacheKey: 'user:10', loader: loader);
    expect(loadCount, 2);
    expect(manager.catalog, isNotNull);
  });

  test('updates cached balance and backpack amount after sending', () async {
    final catalog = await manager.getOrLoad(
      cacheKey: 'user:10',
      loader: () async => _catalog(),
    );
    final backpackGift = catalog.tabs.last.gifts.single;

    manager.recordGiftSent(gift: backpackGift, totalCount: 2, balance: 80);

    expect(manager.catalog?.balance, 80);
    expect(manager.catalog?.tabs.last.gifts.single.amount, 1);
  });
}

RoomGiftCatalog _catalog() {
  return const RoomGiftCatalog(
    balance: 100,
    canSendSelf: true,
    tabs: [
      RoomGiftTab(
        id: 8,
        name: 'Popular',
        gifts: [
          RoomGift(
            id: 31,
            name: 'Rose',
            icon: '',
            price: 20,
            isCombo: 1,
            tabId: 8,
          ),
        ],
      ),
      RoomGiftTab(
        id: RoomGiftTab.backpackId,
        name: 'Backpack',
        gifts: [
          RoomGift(
            id: 32,
            name: 'Backpack Rose',
            icon: '',
            price: 0,
            isCombo: 0,
            tabId: RoomGiftTab.backpackId,
            amount: 3,
            userBackpackId: 99,
          ),
        ],
      ),
    ],
  );
}
