import '../classes/room/gift/models/room_gift_models.dart';

typedef RoomGiftBalanceToken = ({
  String? cacheKey,
  int generation,
  int revision,
});

/// App-wide in-memory gift catalog cache.
///
/// The cache is scoped to the authenticated user key and also coalesces
/// concurrent loads, so app warm-up and opening the gift panel cannot issue
/// duplicate catalog requests.
class RoomGiftManager {
  RoomGiftManager._();

  static final RoomGiftManager instance = RoomGiftManager._();

  RoomGiftCatalog? _catalog;
  String? _cacheKey;
  Future<RoomGiftCatalog>? _loading;
  String? _loadingKey;
  int _generation = 0;
  int _balanceRevision = 0;

  RoomGiftCatalog? get catalog => hasCatalog ? _catalog : null;
  bool get hasCatalog => _hasData(_catalog);
  RoomGiftBalanceToken get balanceToken => (
    cacheKey: _cacheKey,
    generation: _generation,
    revision: _balanceRevision,
  );

  /// Reject a purse response that predates an account change or a paid gift.
  bool updateBalance(int balance, {required RoomGiftBalanceToken token}) {
    if (token != balanceToken) return false;
    final current = _catalog;
    if (current != null) {
      _catalog = current.copyWith(balance: balance);
      _balanceRevision++;
    }
    return true;
  }

  Future<RoomGiftCatalog> getOrLoad({
    required String cacheKey,
    required Future<RoomGiftCatalog> Function() loader,
  }) {
    if (_cacheKey == cacheKey && hasCatalog) {
      return Future<RoomGiftCatalog>.value(_catalog!);
    }
    if (_loadingKey == cacheKey && _loading != null) return _loading!;

    if (_cacheKey != cacheKey) {
      _generation++;
      _cacheKey = cacheKey;
      _catalog = null;
    }

    final generation = _generation;
    late final Future<RoomGiftCatalog> request;
    request = Future<RoomGiftCatalog>.sync(loader)
        .then((catalog) {
          if (_generation == generation && _cacheKey == cacheKey) {
            _catalog = _hasData(catalog) ? catalog : null;
          }
          return catalog;
        })
        .whenComplete(() {
          if (identical(_loading, request)) {
            _loading = null;
            _loadingKey = null;
          }
        });
    _loading = request;
    _loadingKey = cacheKey;
    return request;
  }

  void recordGiftSent({
    required RoomGift gift,
    required int totalCount,
    required int balance,
  }) {
    _balanceRevision++;
    final current = _catalog;
    if (current == null) return;

    var tabs = current.tabs;
    if (gift.isBackpack) {
      tabs = [
        for (final tab in current.tabs)
          tab.id == gift.tabId
              ? tab.copyWith(
                  gifts: [
                    for (final item in tab.gifts)
                      item.selectionKey == gift.selectionKey
                          ? item.copyWith(
                              amount: _remainingAmount(item.amount, totalCount),
                            )
                          : item,
                  ],
                )
              : tab,
      ];
    }
    _catalog = current.copyWith(balance: balance, tabs: tabs);
  }

  int _remainingAmount(int? amount, int sentCount) {
    final remaining = (amount ?? 0) - sentCount;
    return remaining > 0 ? remaining : 0;
  }

  bool _hasData(RoomGiftCatalog? catalog) {
    return catalog != null && catalog.tabs.any((tab) => tab.gifts.isNotEmpty);
  }

  void clear() {
    _generation += 1;
    _catalog = null;
    _cacheKey = null;
    _loading = null;
    _loadingKey = null;
  }
}
