import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../configs/app_configs.dart';
import '../configs/app_device.dart';
import '../configs/app_enum.dart';
import 'app_navigation.dart';
import 'auth_session.dart';

class HttpDioManager {
  static final HttpDioManager _instance = HttpDioManager._internal();

  late Dio _dio;
  bool _isHandlingUnauthorized = false;

  HttpDioManager._internal() {
    _initDio();
  }

  factory HttpDioManager() {
    return _instance;
  }

  static const String devBaseUrl = 'http://simi2.w1.luyouxia.net/simi';
  static const String qaBaseUrl = 'https://www.simijoy.com/simi';
  static const String prodBaseUrl = 'https://www.simisoul.com/simi';
  static const String devSecret = 'T4&pQ@9n';
  static const String prodSecret = 'ji18^##710*(%Mhoaeqwe';

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final startedAt = DateTime.now();
          options.extra['requestStartedAt'] = startedAt;

          final requestParams = _requestParamsForSign(options);
          final timestamp = DateTime.now()
              .toUtc()
              .millisecondsSinceEpoch
              .toString();
          requestParams['v'] = timestamp;

          options.headers.addAll(await _commonHeaders());
          options.headers['v'] = timestamp;
          options.headers['b'] = generateSign(requestParams, _apiSecret);

          _logRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          handler.next(response);
        },
        onError: (DioException e, handler) async {
          _logError(e);
          await _handleUnauthorized(e);
          handler.next(e);
        },
      ),
    );
  }

  String get _baseUrl {
    return switch (AppConfig.shared.appEnv) {
      AppEnv.product => prodBaseUrl,
      AppEnv.qa => qaBaseUrl,
      AppEnv.dev => devBaseUrl,
    };
  }

  String get _apiSecret {
    return AppConfig.shared.appEnv == AppEnv.product ? prodSecret : devSecret;
  }

  Future<Map<String, dynamic>> _commonHeaders() async {
    final device = AppDevice();
    final uid = await AuthSession.instance.uid();
    final token = await AuthSession.instance.token();

    return {
      'Content-Type': Headers.jsonContentType,
      if (uid != null && token != null) 'pub-uid': uid,
      if (uid != null && token != null) 'oauth-token': token,
      'systemLanguage': device.systemLanguage,
      'timeZone': device.timeZone,
      'storeCode': device.countryCode.isEmpty ? 'CN' : device.countryCode,
      'appVersion': device.appVersion,
      'appLanguage': device.appLanguage,
      'x-auth-token': await device.generateAuthToken(),
      'startTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _requestParamsForSign(RequestOptions options) {
    final requestParams = <String, dynamic>{};
    if (options.method.toUpperCase() == 'GET') {
      requestParams.addAll(options.queryParameters);
      return requestParams;
    }

    final data = options.data;
    if (data is FormData) {
      for (final field in data.fields) {
        requestParams[field.key] = field.value;
      }
    } else if (data is Map<String, dynamic>) {
      requestParams.addAll(data);
    } else if (data is Map) {
      data.forEach((key, value) {
        requestParams[key.toString()] = value;
      });
    }
    return requestParams;
  }

  @visibleForTesting
  static String generateSign(Map<String, dynamic> requestParam, String secret) {
    final params = Map<String, dynamic>.from(requestParam);
    params['secret'] = secret;
    final sortedKeys = params.keys.toList()..sort();
    final buffer = StringBuffer();
    for (var index = 0; index < sortedKeys.length; index++) {
      final key = sortedKeys[index];
      buffer.write('$key=${params[key]}');
      if (index != sortedKeys.length - 1) {
        buffer.write('&');
      }
    }
    final normalized = buffer.toString().replaceAll(
      RegExp(r'[^\p{L}\p{N}]', unicode: true),
      '',
    );
    return md5.convert(utf8.encode(normalized)).toString();
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> upload(
    String path, {
    required String filePath,
    String fileKey = 'file',
    Map<String, dynamic>? extraFields,
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileKey: await MultipartFile.fromFile(filePath),
        if (extraFields != null) ...extraFields,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _logRequest(RequestOptions options) {
    debugPrint(
      '[NadyAPI] -> ${options.method} ${options.baseUrl}${options.path} '
      'headers=${_headersSummary(options.headers)} '
      'params=${_paramsSummary(options)}',
    );
  }

  void _logResponse(Response<dynamic> response) {
    final startedAt = response.requestOptions.extra['requestStartedAt'];
    final durationMs = startedAt is DateTime
        ? DateTime.now().difference(startedAt).inMilliseconds
        : null;
    final data = response.data;
    if (data is Map) {
      debugPrint(
        '[NadyAPI] <- ${response.requestOptions.path} '
        'http=${response.statusCode} code=${data['code']} '
        'message=${data['message']} traceId=${data['traceId']} '
        'durationMs=$durationMs data=${_formatResponseData(data)}',
      );
      return;
    }
    debugPrint(
      '[NadyAPI] <- ${response.requestOptions.path} '
      'http=${response.statusCode} durationMs=$durationMs '
      'data=${_formatResponseData(data)}',
    );
  }

  String _formatResponseData(dynamic data) {
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  void _logError(DioException error) {
    final response = error.response;
    debugPrint(
      '[NadyAPI] !! ${error.requestOptions.path} '
      'type=${error.type} http=${response?.statusCode} '
      'message=${error.message} response=${response?.data}',
    );
  }

  Future<void> _handleUnauthorized(DioException error) async {
    final statusCode = error.response?.statusCode;
    if (statusCode != 401 || _isHandlingUnauthorized) return;

    _isHandlingUnauthorized = true;
    try {
      await AuthSession.instance.clear();
      AppNavigation.goLogin();
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        _isHandlingUnauthorized = false;
      });
    }
  }

  Map<String, dynamic> _headersSummary(Map<String, dynamic> headers) {
    return {
      'hasPubUid': headers['pub-uid'] != null,
      'hasOauthToken': headers['oauth-token'] != null,
      'hasSign': headers['b'] != null,
      'v': headers['v'],
      'systemLanguage': headers['systemLanguage'],
      'storeCode': headers['storeCode'],
      'appVersion': headers['appVersion'],
      'appLanguage': headers['appLanguage'],
      'xAuthTokenLength': headers['x-auth-token']?.toString().length,
    };
  }

  Map<String, dynamic> _paramsSummary(RequestOptions options) {
    final params = _requestParamsForSign(options);
    return params.map((key, value) {
      if (key.toLowerCase().contains('passwd') ||
          key.toLowerCase().contains('password') ||
          key.toLowerCase().contains('sms')) {
        return MapEntry(key, '******');
      }
      return MapEntry(key, value);
    });
  }

  void _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        debugPrint('Connection timeout: ${error.message}');
      case DioExceptionType.sendTimeout:
        debugPrint('Send timeout: ${error.message}');
      case DioExceptionType.receiveTimeout:
        debugPrint('Receive timeout: ${error.message}');
      case DioExceptionType.badResponse:
        debugPrint(
          'Bad response: ${error.response?.statusCode} - ${error.message}',
        );
      case DioExceptionType.cancel:
        debugPrint('Request cancelled: ${error.message}');
      case DioExceptionType.connectionError:
        debugPrint('Connection error: ${error.message}');
      case DioExceptionType.unknown:
        debugPrint('Unknown error: ${error.message}');
      case DioExceptionType.badCertificate:
        debugPrint('Bad certificate: ${error.message}');
    }
  }

  Dio getDio() {
    return _dio;
  }

  void close() {
    _dio.close();
  }
}
