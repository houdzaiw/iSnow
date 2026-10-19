import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/manager/auth_session.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manager = HttpDioManager();
  final dio = manager.getDio();
  late HttpClientAdapter previousAdapter;
  late BaseOptions previousOptions;
  late _Adapter adapter;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'nady.oauthToken': 'stored-token',
      'nady.pubUid': 42,
    });
    previousAdapter = dio.httpClientAdapter;
    previousOptions = dio.options;
    adapter = _Adapter();
    dio.httpClientAdapter = adapter;
    dio.options = dio.options.copyWith(
      headers: {
        'oauth-token': 'inherited-token',
        'x-auth-token': 'inherited-device-token',
        'Authorization': 'inherited-auth',
      },
      queryParameters: {
        'deviceId': 'inherited-did',
        'pub-uid': 42,
        'v': 'inherited-signing-value',
      },
    );
  });
  tearDown(() {
    dio.httpClientAdapter = previousAdapter;
    dio.options = previousOptions;
    adapter.close(force: true);
  });

  test(
    'anonymous lookup strips inherited credentials, DID and signing parameters',
    () async {
      final response = await manager.getExternalJson(
        HttpApi.publicIp,
        queryParameters: {'format': 'json'},
      );
      expect(response, {'ip': '203.0.113.10'});
      final request = adapter.requests.single;
      expect(request.uri.host, 'api64.ipify.org');
      expect(request.method, 'GET');
      expect(request.data, isNull);
      expect(request.queryParameters, {'format': 'json'});
      expect(request.headers.keys.map((key) => key.toLowerCase()).toSet(), {
        'accept',
      });
      expect(dio.options.headers['oauth-token'], 'inherited-token');
      expect(dio.options.queryParameters['deviceId'], 'inherited-did');
    },
  );

  test('external HTTP 401 cannot clear the Nady login session', () async {
    adapter.statusCode = 401;
    await expectLater(
      manager.getExternalJson(HttpApi.publicIp),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    expect(await AuthSession.instance.token(), 'stored-token');
    expect(await AuthSession.instance.uid(), 42);
  });

  test('an external deadline cancels only its own request', () async {
    adapter.hang = true;
    await expectLater(
      manager.getExternalJson(
        HttpApi.publicIp,
        timeout: const Duration(milliseconds: 10),
      ),
      throwsA(isA<TimeoutException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(adapter.cancelled, isTrue);
    expect(await AuthSession.instance.isLoggedIn(), isTrue);
  });

  test('normal Nady requests still use session headers and signing', () async {
    await manager.get('/api/test');
    final request = adapter.requests.single;
    expect(request.headers['oauth-token'], 'stored-token');
    expect(request.headers['pub-uid'], 42);
    expect(request.headers['b'], isNotEmpty);
    expect(request.headers['v'], isNotEmpty);
    expect(request.headers['x-auth-token'], isNotEmpty);
  });

  for (final url in [
    'http://api64.ipify.org',
    '/api/test',
    HttpDioManager.qaBaseUrl,
    HttpDioManager.prodBaseUrl,
    'https://user:password@api64.ipify.org',
  ]) {
    test(
      'anonymous requests cannot bypass Nady auth or send HTTPS credentials: $url',
      () async {
        await expectLater(manager.getExternalJson(url), throwsArgumentError);
        expect(adapter.requests, isEmpty);
      },
    );
  }

  test('nonpositive external timeouts are rejected before a request', () async {
    await expectLater(
      manager.getExternalJson(HttpApi.publicIp, timeout: Duration.zero),
      throwsArgumentError,
    );
    expect(adapter.requests, isEmpty);
  });
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int statusCode = 200;
  bool hang = false;
  bool cancelled = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (hang) {
      await cancelFuture;
      cancelled = true;
    }
    return ResponseBody.fromString(
      '{"ip":"203.0.113.10"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
