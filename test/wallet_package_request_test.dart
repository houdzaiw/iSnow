import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/classes/wallet/wallet_repository.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/server_response.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  String response =
      '{"code":200,"data":[{"id":"sku_2","sortNo":2},{"id":"sku_1","sortNo":1}]}';
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      response,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final http = HttpDioManager();
  late HttpClientAdapter previous;
  late _Adapter adapter;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'nady.pubUid': 42,
      'nady.oauthToken': 'fixture',
    });
    previous = http.getDio().httpClientAdapter;
    adapter = _Adapter();
    http.getDio().httpClientAdapter = adapter;
  });
  tearDown(() => http.getDio().httpClientAdapter = previous);
  for (final channel in ['google', 'apple']) {
    test(
      '$channel package query matches Nady POST query and absent body',
      () async {
        final repo = WalletRepository(http, platformChannel: channel);
        final products = await repo.fetchRechargePackages();
        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.path, HttpApi.walletRechargePackageList);
        expect(request.queryParameters, {
          'channel': channel,
          'merchant': channel,
        });
        expect(request.data, isNull);
        expect(request.headers['b'], isNotEmpty);
        expect(products.map((p) => p.id), ['sku_1', 'sku_2']);
        expect(
          adapter.requests.any(
            (r) => r.path == HttpApi.walletRechargeGoogleCreation,
          ),
          isFalse,
        );
      },
    );
  }
  test(
    'package errors preserve msg and do not become an empty successful list',
    () async {
      adapter.response =
          '{"code":1002,"message":"Illegal argument","msg":"不能为空"}';
      final repo = WalletRepository(http, platformChannel: 'google');
      await expectLater(
        repo.fetchRechargePackages(),
        throwsA(
          isA<NadyApiException>().having((e) => e.message, 'msg', '不能为空'),
        ),
      );
      expect(adapter.requests, hasLength(1));
    },
  );
}
