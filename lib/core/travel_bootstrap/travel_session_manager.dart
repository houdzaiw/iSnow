import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../../configs/app_device.dart';
import '../../manager/auth_session.dart';
import 'travel_bootstrap_client.dart';
import 'travel_bootstrap_config.dart';
import 'travel_bootstrap_exception.dart';
import 'travel_protocol.dart';

/// 负责启动 Bootstrap、登录后 client.init 和公共 API 动态路由的单例会话。
final class TravelSessionManager {
  TravelSessionManager._();

  static final TravelSessionManager shared = TravelSessionManager._();

  final TravelBootstrapClient _client = TravelBootstrapClient();
  final AppDevice _device = AppDevice();

  TravelBootstrapRoutes? _routes;
  TravelRuntimeSession? _session;
  TravelClientInitInput? _input;
  Future<void>? _starting;

  bool get isReady => _session != null;
  Uri? get apiBaseUri => _session?.apiBaseUri ?? _routes?.apiBaseUri;

  /// 启动时必须先完成 Bootstrap；存在本地登录态时继续完成 client.init。
  Future<void> start() async {
    final running = _starting;
    if (running != null) return running;
    final future = _startInternal();
    _starting = future;
    try {
      await future;
    } finally {
      if (identical(_starting, future)) _starting = null;
    }
  }

  Future<void> _startInternal() async {
    final input = await _loadInput();
    final routes = await _client.loadRoutes(input.identity);
    _input = input;
    _routes = routes;
    _session = null;

    if (!await AuthSession.instance.isLoggedIn()) return;
    final token = await AuthSession.instance.token();
    final uid = await AuthSession.instance.uid();
    if (token == null || uid == null) return;
    try {
      _session = await _client.initializeBusinessSession(
        routes: routes,
        identity: input.identity,
        clientInitBody: input.body,
        authHeaders: <String, String>{
          'oauth-token': token,
          'pub-uid': '$uid',
          'x-auth-token': await _createXAuthToken(input),
        },
      );
    } on TravelBootstrapException catch (error) {
      if (error.requiresSessionRefresh || error.code == 1006) {
        await AuthSession.instance.clear();
        _session = null;
        return;
      }
      rethrow;
    }
  }

  /// 由登录接口调用，登录成功后立即完成 client.init。
  Future<void> completeLogin({required Map<String, Object?> loginData}) async {
    final input = _input;
    final routes = _routes;
    if (input == null || routes == null) {
      throw const TravelBootstrapException('Travel startup has not completed.');
    }
    final token = loginData['token'];
    final uid = loginData['uid'];
    if (token is! String || token.isEmpty || uid == null) {
      throw const TravelBootstrapException(
        'Travel login response is missing authentication.',
      );
    }
    _session = await _client.initializeBusinessSession(
      routes: routes,
      identity: input.identity,
      clientInitBody: input.body,
      authHeaders: <String, String>{
        'oauth-token': token,
        'pub-uid': '$uid',
        'x-auth-token': await _createXAuthToken(input),
      },
    );
  }

  /// 将现有 iSnow HttpDioManager 的接口路径转成 Travel 混淆路由。
  Future<dynamic> request({
    required String path,
    required String method,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await start();
    final routeName = _routeName(path);
    final routeToken = TravelBootstrapConfig.tokenFor(routeName);
    final body = <String, Object?>{
      if (queryParameters != null) ...queryParameters,
      if (data != null) ...data,
    };
    final input = _input;
    final routes = _routes;
    if (input == null || routes == null) {
      throw const TravelBootstrapException('Travel startup is unavailable.');
    }

    if (_session == null) {
      final response = await _client.callBootstrapRoute(
        routes: routes,
        identity: input.identity,
        routeToken: routeToken,
        body: body,
        headers: <String, String>{
          'x-auth-token': await _createXAuthToken(input),
        },
      );
      if (routeName == 'oauth2.login') {
        final loginData = _objectData(response);
        await completeLogin(loginData: loginData);
      }
      return response;
    }

    final result = await _client.postBusiness(
      session: _session!,
      routeToken: routeToken,
      body: body,
      headers: await _authHeaders(),
    );
    return <String, Object?>{
      'code': result.code,
      'message': result.message,
      'timestamp': DateTime.now().toIso8601String(),
      'traceId': result.traceId,
      'data': result.data,
    };
  }

  Future<TravelClientInitInput> _loadInput() async {
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'IOS'
        : 'ANDROID';
    final language = _device.appLanguage.isEmpty ? 'en' : _device.appLanguage;
    final identity = TravelIdentity(
      platform: platform,
      packageName: _device.packageName,
      channel: TravelBootstrapConfig.channel,
      clientVersion: _device.appVersion,
    );
    return TravelClientInitInput(
      identity: identity,
      body: <String, Object?>{
        'deviceId': _device.deviceId,
        'model': _device.model,
        'os': _device.os,
        'osVersion': _device.osVersion,
        'app': 'Travel',
        'appVersion': _device.appVersion,
        'appVersionCode': _device.appVersionCode,
        'channel': TravelBootstrapConfig.channel,
        'deviceBrand': _device.deviceBrand,
        'systemLanguage': language,
        'appLanguage': language,
        'countryCode': _device.countryCode,
        'isPhysicalDevice': _device.isPhysicalDevice,
        'bundleId': _device.packageName,
      },
    );
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthSession.instance.token();
    final uid = await AuthSession.instance.uid();
    final input = _input;
    if (token == null || uid == null || input == null) {
      throw const TravelBootstrapException(
        'Travel login session is unavailable.',
      );
    }
    return <String, String>{
      'oauth-token': token,
      'pub-uid': '$uid',
      'x-auth-token': await _createXAuthToken(input),
    };
  }

  Future<String> _createXAuthToken(TravelClientInitInput input) async {
    final plaintext = jsonEncode(<String, String>{
      'simCountryCode': _stringOf(input.body['countryCode']),
      'systemLanguage': _stringOf(input.body['systemLanguage']),
      'fingerprint': _stringOf(input.body['deviceId']),
      'deviceID': _stringOf(input.body['deviceId']),
      'timezone': DateTime.now().timeZoneName,
      'os': _stringOf(
        input.body['osVersion'],
        fallback: _stringOf(input.body['os']),
      ),
      'appVersionCode':
          '${input.identity.clientVersion}+${_stringOf(input.body['appVersionCode'])}',
      'channel': input.identity.channel,
    });
    final algorithm = Chacha20.poly1305Aead();
    final key = await algorithm.newSecretKey();
    final box = await algorithm.encrypt(utf8.encode(plaintext), secretKey: key);
    final keyBytes = await key.extractBytes();
    return hex.encode(keyBytes) +
        hex.encode(box.nonce) +
        hex.encode(box.mac.bytes) +
        hex.encode(box.cipherText);
  }

  Map<String, Object?> _objectData(dynamic response) {
    if (response is! Map) {
      throw const TravelBootstrapException('Travel response is invalid.');
    }
    final data = response['data'];
    if (data is! Map) {
      throw const TravelBootstrapException('Travel response data is invalid.');
    }
    return data.map<String, Object?>((key, value) => MapEntry('$key', value));
  }

  String _routeName(String path) {
    const routes = <String, String>{
      '/country-list/default-country': 'country.default',
      '/country-list/hot': 'country.hot',
      '/country-list/supported': 'country.supported',
      '/api/user/hasUser': 'user.hasUser',
      '/oauth2/sendSms': 'oauth2.sendSms',
      '/oauth2/login': 'oauth2.login',
      '/oauth2/setPassword': 'oauth2.setPassword',
      '/oauth2/verify/code': 'oauth2.verifyCode',
      '/api/user/complete': 'user.complete',
      '/api/user/mine': 'user.mine',
      '/api/user/modifyUser': 'user.modify',
      '/api/resource/header-upload-param': 'resource.headerUploadParam',
      '/oauth2/logout': 'oauth2.logout',
      '/api/user/logoff': 'user.logoff',
    };
    final route = routes[path];
    if (route == null) {
      throw TravelBootstrapException(
        'Travel route is not configured for $path.',
      );
    }
    return route;
  }

  String _stringOf(Object? value, {String fallback = ''}) =>
      value is String && value.isNotEmpty ? value : fallback;
}
