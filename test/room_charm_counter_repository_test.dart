import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/server_response.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final http = HttpDioManager();
  final repository = RoomToolsRepository(http: http);
  late HttpClientAdapter previous;
  late _Adapter adapter;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'nady.pubUid': 10,
      'nady.oauthToken': 'test-token',
    });
    previous = http.getDio().httpClientAdapter;
    adapter = _Adapter();
    http.getDio().httpClientAdapter = adapter;
  });
  tearDown(() {
    http.getDio().httpClientAdapter = previous;
    adapter.close();
  });

  for (final enabled in [true, false]) {
    test('Nady GET contract preserves status $enabled', () async {
      adapter.response = {'code': 200, 'data': enabled};
      expect(await repository.charmEnabled('123'), enabled);
      expect(await repository.updateCharmStatus('123', enabled), enabled);
      expect(adapter.requests.map((r) => r.path), [
        HttpApi.roomCharmEnabled,
        HttpApi.roomCharmUpdate,
      ]);
      expect(adapter.requests.first.queryParameters, {'roomId': '123'});
      expect(adapter.requests.last.queryParameters, {
        'roomId': '123',
        'enable': enabled,
      });
      for (final request in adapter.requests) {
        expect(request.method, 'GET');
        expect(request.data, isNull);
        expect(request.headers['pub-uid'], 10);
        expect(request.headers['b'], isNotEmpty);
        expect(request.headers['v'], isNotEmpty);
      }
    });
  }

  for (final invalid in [null, 1, 'false', <String, dynamic>{}]) {
    test('invalid status $invalid is not silently treated as false', () async {
      adapter.response = {'code': 200, 'data': invalid};
      await expectLater(
        repository.charmEnabled('123'),
        throwsA(isA<NadyApiException>()),
      );
      await expectLater(
        repository.updateCharmStatus('123', true),
        throwsA(isA<NadyApiException>()),
      );
    });
  }

  test(
    'service failure keeps msg even when data has an unexpected shape',
    () async {
      adapter.response = {
        'code': 1003,
        'message': 'Generic error',
        'msg': 'Counter cannot be changed',
        'data': {'invalid': true},
      };
      await expectLater(
        repository.updateCharmStatus('123', false),
        throwsA(
          isA<NadyApiException>().having(
            (e) => e.message,
            'message',
            'Counter cannot be changed',
          ),
        ),
      );
    },
  );
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Map<String, dynamic> response = {};
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
