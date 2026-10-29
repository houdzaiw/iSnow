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

  for (final currency in [1, 2]) {
    test('Nady currency $currency uses a signed POST JSON body', () async {
      adapter.response = {'code': 200, 'message': 'success'};
      await repository.switchCharmCurrency('123', currency);
      final request = adapter.requests.single;
      expect(request.path, HttpApi.roomCharmSwitch);
      expect(request.method, 'POST');
      expect(request.queryParameters, isEmpty);
      expect(request.data, {'roomId': '123', 'digitalCurrency': currency});
      expect(request.headers['pub-uid'], 10);
      expect(request.headers['b'], isNotEmpty);
      expect(request.headers['v'], isNotEmpty);
    });
  }

  for (final data in [null, false, <String, dynamic>{}]) {
    test(
      'code 200 is an acknowledgement, not a boolean result: $data',
      () async {
        adapter.response = {'code': 200, 'data': data};
        await repository.switchCharmCurrency('123', 2);
      },
    );
  }

  test('failed acknowledgement prioritizes msg over malformed data', () async {
    adapter.response = {
      'code': 1003,
      'msg': 'Currency save rejected',
      'message': 'Generic failure',
      'data': <Object>[],
    };
    await expectLater(
      repository.switchCharmCurrency('123', 2),
      throwsA(
        isA<NadyApiException>().having(
          (e) => e.message,
          'message',
          'Currency save rejected',
        ),
      ),
    );
  });
}

class _Adapter implements HttpClientAdapter {
  Map<String, dynamic> response = {};
  final requests = <RequestOptions>[];
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
