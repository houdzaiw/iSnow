import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/manager/auth_session.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/manager/room_gift_manager.dart';
import 'package:project/model/server_response.dart';

void main() {
  late _Http http;
  late _Session session;
  late NadyRoomGiftRepository repository;
  late DateTime now;
  setUp(() {
    RoomGiftManager.instance.clear();
    http = _Http();
    session = _Session();
    now = DateTime(2026, 11, 15);
    repository = NadyRoomGiftRepository(
      http,
      authSession: session,
      now: () => now,
    );
  });
  tearDown(RoomGiftManager.instance.clear);

  test(
    'existing purse response supplies first eligibility without an extra read',
    () async {
      http.first = true;
      await repository.fetchCatalog();
      expect(repository.firstRechargeEligibility, isTrue);
      expect(http.purseCalls, 1);
      http.first = false;
      await repository.fetchBalance();
      expect(repository.firstRechargeEligibility, isFalse);
      http.first = null;
      await repository.fetchBalance();
      expect(repository.firstRechargeEligibility, isNull);
    },
  );

  test('account clear removes first-recharge eligibility', () async {
    http.first = true;
    await repository.fetchCatalog();
    RoomGiftManager.instance.clear();
    expect(repository.firstRechargeEligibility, isNull);
  });

  test(
    'catalog uses Nady POST config contract and clamps zero flight limit to one',
    () async {
      final catalog = await repository.fetchCatalog();
      expect(catalog.flightLimit, 1);
      expect(catalog.copyWith(balance: 12).flightLimit, 1);
      expect(http.posts[HttpApi.systemConfigById], {
        'configId': 'send_gif_max_num',
      });
    },
  );

  test(
    'snapshot parameters, concurrent merge, TTL and typed parsing',
    () async {
      http.pending = Completer();
      final one = repository.fetchLuckySnapshots(31);
      final two = repository.fetchLuckySnapshots(31);
      await Future<void>.delayed(Duration.zero);
      expect(http.snapshotCalls, 1);
      expect(http.lastQuery, {'giftId': 31});
      http.pending!.complete(_Http.success(http.records));
      final values = await Future.wait([one, two]);
      expect(values.first.single.senderName, 'Winner');
      expect(values.first.single.giftId, 31);
      http.pending = null;
      await repository.fetchLuckySnapshots(31);
      expect(http.snapshotCalls, 1);
      now = now.add(const Duration(seconds: 61));
      await repository.fetchLuckySnapshots(31);
      expect(http.snapshotCalls, 2);
    },
  );

  test('empty and failed records can retry; msg wins over message', () async {
    http.records = [];
    expect(await repository.fetchLuckySnapshots(31), isEmpty);
    await repository.fetchLuckySnapshots(31);
    expect(http.snapshotCalls, 2);
    http.failure = true;
    await expectLater(
      repository.fetchLuckySnapshots(31),
      throwsA(
        isA<NadyApiException>().having(
          (error) => error.message,
          'message',
          'Server msg',
        ),
      ),
    );
    http.failure = false;
    await repository.fetchLuckySnapshots(31);
    expect(http.snapshotCalls, 4);
  });

  test(
    'account switch rejects in-flight result and does not reuse old cached request',
    () async {
      http.pending = Completer();
      final old = repository.fetchLuckySnapshots(31);
      await Future<void>.delayed(Duration.zero);
      session.value = 20;
      RoomGiftManager.instance.clear();
      http.pending!.complete(_Http.success(http.records));
      await expectLater(old, throwsA(isA<NadyApiException>()));
      http.pending = null;
      final fresh = await repository.fetchLuckySnapshots(31);
      expect(fresh, hasLength(1));
      expect(http.snapshotCalls, 2);
    },
  );
}

class _Session implements AuthSession {
  int? value = 10;
  @override
  Future<int?> uid() async => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Http implements HttpDioManager {
  bool? first;
  int purseCalls = 0;
  int snapshotCalls = 0;
  bool failure = false;
  Completer<Object?>? pending;
  Map<String, dynamic>? lastQuery;
  final posts = <String, Object?>{};
  List<Map<String, dynamic>> records = [
    {'senderUid': 20, 'senderNick': 'Winner', 'multiple': 10, 'winAmount': 100},
  ];
  static Map<String, dynamic> success(Object? data) => {
    'code': 200,
    'data': data,
  };
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == HttpApi.giftLuckySnapshots) {
      snapshotCalls++;
      lastQuery = queryParameters;
      if (failure) {
        return {'code': 1003, 'msg': 'Server msg', 'message': 'Other message'};
      }
      return pending == null ? success(records) : pending!.future;
    }
    if (path == HttpApi.walletPurse) {
      purseCalls++;
      return success({'coin': 100, if (first != null) 'isFirst': first});
    }
    if (path == HttpApi.giftBackpack) return success({'giftInfoDTOS': []});
    if (path == HttpApi.giftTabList) {
      return success({
        'gold': 100,
        'tabGiftInfos': [
          {
            'tabId': 1,
            'tab': 'Gifts',
            'giftInfoDTOS': [
              {'id': 31, 'name': 'Gift', 'price': 1, 'isCombo': 1},
            ],
          },
        ],
      });
    }
    throw StateError('Unexpected read: $path');
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    posts[path] = data;
    if (path == HttpApi.systemConfigById) return success('0');
    if (path == HttpApi.giftCanSendSelf) return success(true);
    throw StateError('Unexpected write: $path');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
