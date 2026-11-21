import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/room_lucky_config_repository.dart';
import 'package:project/manager/auth_session.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/manager/room_gift_manager.dart';
import 'package:project/model/server_response.dart';

void main() {
  late _Http http;
  late _Session session;
  late RoomLuckyConfigRepository repository;
  setUp(() {
    http = _Http();
    session = _Session();
    repository = RoomLuckyConfigRepository(http, session: session);
  });
  test(
    'Nady POST contract, concurrent merge, successful config cached',
    () async {
      final first = repository.load();
      final second = repository.load();
      await Future<void>.delayed(Duration.zero);
      expect(http.calls, 1);
      expect(http.path, HttpApi.systemConfigById);
      expect(http.data, {'configId': 'gift_award_bubble_config'});
      http.result.complete({'code': 200, 'data': _config});
      expect((await first).isEmpty, isFalse);
      await second;
      await repository.load();
      expect(http.calls, 1);
    },
  );
  test('empty or malformed config can retry', () async {
    http.result.complete({'code': 200, 'data': 'not json'});
    expect((await repository.load()).isEmpty, isTrue);
    await repository.load();
    expect(http.calls, 2);
  });
  test('failure uses msg, evicts failed future', () async {
    http.result.complete({
      'code': 1003,
      'msg': 'Server msg',
      'message': 'Other',
    });
    for (var i = 0; i < 2; i++) {
      await expectLater(
        repository.load(),
        throwsA(
          isA<NadyApiException>().having(
            (e) => e.message,
            'message',
            'Server msg',
          ),
        ),
      );
    }
    expect(http.calls, 2);
  });
  test(
    'old account and logout/relogin generation results are rejected',
    () async {
      final old = repository.load();
      await Future<void>.delayed(Duration.zero);
      session.uidValue = 20;
      http.result.complete({'code': 200, 'data': _config});
      await expectLater(old, throwsA(isA<NadyApiException>()));
      await repository.load();
      expect(http.calls, 2);
      RoomGiftManager.instance.clear();
      await repository.load();
      expect(http.calls, 3);
    },
  );
}

const _config =
    '{"self":{"small":{"count":10,"andMultiple":2,"orMultiple":20}}}';

class _Session implements AuthSession {
  int uidValue = 10;
  @override
  Future<int?> uid() async => uidValue;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Http implements HttpDioManager {
  final result = Completer<Object?>();
  int calls = 0;
  String? path;
  Object? data;
  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls++;
    this.path = path;
    this.data = data;
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
