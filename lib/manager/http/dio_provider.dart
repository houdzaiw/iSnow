import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:project/lib/logger.dart';
import 'package:project/manager/http/request_interceptor.dart';
import 'package:project/manager/http/request_params_crypto_interceptor.dart';

// 手动创建 Dio Provider（不使用代码生成）
final dioProvider = Provider<Dio>((ref) {
  return _createDio(ref, isBrowser: null);
});

// 创建 Dio 实例的函数
Dio _createDio(Ref ref, {bool? isBrowser}) {
  final ret = Dio();

  (ret.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) {
      return true;
    };
    return client;
  };

  if (!const bool.fromEnvironment("proxy", defaultValue: false)) {
    try {
      ret.httpClientAdapter = NativeAdapter(
        createCronetEngine: () => CronetEngine.build(
            cacheMode: CacheMode.disabled,
            enableBrotli: true,
            enableHttp2: true,
            enablePublicKeyPinningBypassForLocalTrustAnchors: false,
            enableQuic: true),
        createCupertinoConfiguration: () =>
            URLSessionConfiguration.ephemeralSessionConfiguration()
              ..allowsCellularAccess = true
              ..allowsConstrainedNetworkAccess = true
              ..allowsExpensiveNetworkAccess = true,
      );
    } catch (e) {
      debugPrint("dio error:$e");
    }
  }

  ret.options = BaseOptions(
    receiveTimeout: const Duration(seconds: 30),
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  );

  // if (kDebugMode) {
  //   ret.interceptors.add(
  //     TalkerDioLogger(
  //       talker: Logger.talker,
  //       settings: const TalkerDioLoggerSettings(
  //         printRequestHeaders: kDebugMode,
  //         printRequestData: kDebugMode,
  //         printResponseMessage: kDebugMode,
  //         printResponseData: kDebugMode,
  //         printResponseHeaders: kDebugMode,
  //       ),
  //     ),
  //   );
  // }
  // request params crypto
  ret.interceptors.add(RequestParamsCryptoInterceptor(ref: ref));

  ret.interceptors.add(RequestInterceptors(
      ref: ref, isBrowser: isBrowser)); // 添加拦截器，如 token之类，需要全局使用的参数

  // retry
  ret.interceptors.add(RetryInterceptor(
    dio: ret,
    logPrint: Logger.info,
    retries: 2,
    retryDelays: const [
      Duration(milliseconds: 100),
      Duration(milliseconds: 500),
    ],
  ));

  return ret;
}
