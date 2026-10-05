import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/auth_session.dart';
import '../../../manager/http_api.dart';
import '../../../manager/http_dio_manager.dart';
import '../../../manager/room_gift_manager.dart';
import '../../../model/server_response.dart';
import 'models/room_gift_models.dart';

final roomGiftRepositoryProvider = Provider<RoomGiftRepository>((ref) {
  return NadyRoomGiftRepository(
    HttpDioManager(),
    authSession: AuthSession.instance,
    giftManager: RoomGiftManager.instance,
  );
});

abstract class RoomGiftRepository {
  RoomGiftCatalog? get cachedCatalog => null;

  Future<RoomGiftCatalog> fetchCatalog();

  Future<int> fetchBalance();

  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request);

  void recordGiftSent({
    required RoomGift gift,
    required int totalCount,
    required int balance,
  }) {}
}

class NadyRoomGiftRepository implements RoomGiftRepository {
  NadyRoomGiftRepository(
    this._httpManager, {
    AuthSession? authSession,
    RoomGiftManager? giftManager,
  }) : _authSession = authSession ?? AuthSession.instance,
       _giftManager = giftManager ?? RoomGiftManager.instance;

  final HttpDioManager _httpManager;
  final AuthSession _authSession;
  final RoomGiftManager _giftManager;

  @override
  RoomGiftCatalog? get cachedCatalog => _giftManager.catalog;

  @override
  Future<RoomGiftCatalog> fetchCatalog() async {
    final uid = await _authSession.uid();
    return _giftManager.getOrLoad(
      cacheKey: 'user:${uid ?? 0}',
      loader: _fetchCatalogFromNetwork,
    );
  }

  Future<RoomGiftCatalog> _fetchCatalogFromNetwork() async {
    final tabFuture = _fetchGiftTabs();
    final backpackFuture = _fetchBackpackSafely();
    final balanceFuture = _fetchBalanceSafely();
    final canSendSelfFuture = _fetchCanSendSelfSafely();

    final tabResult = await tabFuture;
    final backpack = await backpackFuture;
    final purseBalance = await balanceFuture;
    final canSendSelf = await canSendSelfFuture;
    final tabs = <RoomGiftTab>[
      ...tabResult.tabs.where((tab) => tab.gifts.isNotEmpty),
      if (backpack != null && backpack.gifts.isNotEmpty) backpack,
    ];

    return RoomGiftCatalog(
      balance: purseBalance ?? tabResult.balance,
      canSendSelf: canSendSelf,
      tabs: tabs,
    );
  }

  @override
  void recordGiftSent({
    required RoomGift gift,
    required int totalCount,
    required int balance,
  }) {
    _giftManager.recordGiftSent(
      gift: gift,
      totalCount: totalCount,
      balance: balance,
    );
  }

  @override
  Future<int> fetchBalance() async {
    final response = await _httpManager.get(HttpApi.walletPurse);
    final server = NadyServerResponse<int>.fromJson(
      _asMap(response),
      (json) => _intValue(_asMap(json)['coin']),
    );
    if (!server.isSuccess || server.data == null) throw server.toException();
    return server.data!;
  }

  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async {
    final response = await _httpManager.post(
      HttpApi.giftSend,
      data: request.toJson(),
    );
    final server = NadyServerResponse<RoomGiftSendResult>.fromJson(
      _asMap(response),
      (json) => RoomGiftSendResult(comboId: json?.toString()),
    );
    if (!server.isSuccess) throw server.toException();
    return server.data ?? const RoomGiftSendResult();
  }

  Future<_GiftTabResult> _fetchGiftTabs() async {
    final response = await _httpManager.get(HttpApi.giftTabList);
    final server = NadyServerResponse<_GiftTabResult>.fromJson(
      _asMap(response),
      (json) {
        final data = _asMap(json);
        return _GiftTabResult(
          balance: _intValue(data['gold']),
          tabs: _mapList(
            data['tabGiftInfos'],
          ).map(RoomGiftTab.fromJson).toList(growable: false),
        );
      },
    );
    if (!server.isSuccess || server.data == null) throw server.toException();
    return server.data!;
  }

  Future<RoomGiftTab?> _fetchBackpackSafely() async {
    try {
      final response = await _httpManager.get(HttpApi.giftBackpack);
      final server = NadyServerResponse<RoomGiftTab>.fromJson(
        _asMap(response),
        (json) {
          final data = _asMap(json);
          final gifts = _mapList(data['giftInfoDTOS'])
              .map(
                (item) => RoomGift.fromJson(<String, dynamic>{
                  ...item,
                  'tabId': RoomGiftTab.backpackId,
                }, fallbackTabId: RoomGiftTab.backpackId),
              )
              .where((gift) => gift.id != 0)
              .toList(growable: false);
          return RoomGiftTab(
            id: RoomGiftTab.backpackId,
            name: 'Backpack',
            gifts: gifts,
          );
        },
      );
      if (!server.isSuccess) return null;
      return server.data;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _fetchBalanceSafely() async {
    try {
      return await fetchBalance();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _fetchCanSendSelfSafely() async {
    try {
      final response = await _httpManager.post(
        HttpApi.giftCanSendSelf,
        data: const <String, dynamic>{},
      );
      final server = NadyServerResponse<bool>.fromJson(
        _asMap(response),
        _boolValue,
      );
      return server.isSuccess ? server.data ?? true : true;
    } catch (_) {
      return true;
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }

  List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  int _intValue(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _boolValue(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }
}

class _GiftTabResult {
  const _GiftTabResult({required this.balance, required this.tabs});

  final int balance;
  final List<RoomGiftTab> tabs;
}

Future<void> preloadRoomGiftCatalog() async {
  if (!await AuthSession.instance.isLoggedIn()) return;
  try {
    await NadyRoomGiftRepository(HttpDioManager()).fetchCatalog();
  } catch (_) {
    // Opening the gift panel retries whenever the singleton cache is empty.
  }
}
