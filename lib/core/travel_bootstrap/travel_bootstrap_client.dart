import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'travel_bootstrap_config.dart';
import 'travel_bootstrap_exception.dart';
import 'travel_crypto.dart';
import 'travel_protocol.dart';

/// Travel Bootstrap 与业务 AES 信封客户端。
final class TravelBootstrapClient {
  TravelBootstrapClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
            ),
          ),
      _crypto = TravelAesGcm();

  final Dio _dio;
  final TravelAesGcm _crypto;

  Future<TravelBootstrapRoutes> loadRoutes(TravelIdentity identity) async {
    _validateConfig();
    final response = await _callBootstrapEnvelope(
      uri: Uri.parse(TravelBootstrapConfig.bootstrapUrl),
      identity: identity,
      body: const <String, Object?>{},
    );
    final data = objectMap(response['data'] ?? response, 'data');
    final apiBaseValue = data['apiBaseUrl'];
    final apiBaseUri = apiBaseValue is String
        ? Uri.tryParse(apiBaseValue)
        : null;
    if (apiBaseUri == null || !_allowsUri(apiBaseUri)) {
      throw const TravelBootstrapException(
        'Travel Bootstrap returned an invalid API URL.',
      );
    }
    final normalized = _normalizeUri(apiBaseUri);
    final loginUri = _routeUri(
      normalized,
      TravelBootstrapConfig.tokenFor('oauth2.login'),
    );
    final clientInitUri = _routeUri(
      normalized,
      TravelBootstrapConfig.tokenFor('client.init'),
    );
    return TravelBootstrapRoutes(
      apiBaseUri: normalized,
      loginUri: loginUri,
      clientInitUri: clientInitUri,
      publicConfig: TravelPublicConfig.fromJson(data),
    );
  }

  Future<Map<String, Object?>> callBootstrapRoute({
    required TravelBootstrapRoutes routes,
    required TravelIdentity identity,
    required String routeToken,
    required Map<String, Object?> body,
    Map<String, String> headers = const <String, String>{},
  }) async {
    return _callBootstrapEnvelope(
      uri: _routeUri(routes.apiBaseUri, routeToken),
      identity: identity,
      body: body,
      headers: headers,
    );
  }

  Future<TravelRuntimeSession> initializeBusinessSession({
    required TravelBootstrapRoutes routes,
    required TravelIdentity identity,
    required Map<String, Object?> clientInitBody,
    required Map<String, String> authHeaders,
  }) async {
    final data = _dataOf(
      await _callBootstrapEnvelope(
        uri: routes.clientInitUri,
        identity: identity,
        body: clientInitBody,
        headers: authHeaders,
      ),
    );
    final initData = objectMap(data['initData'], 'initData');
    final cryptoData = objectMap(data['crypto'], 'crypto');
    final keyText = cryptoData['key'];
    final saltText = cryptoData['salt'];
    final kid = cryptoData['activeKid'];
    final key = base64UrlBytes(keyText, 'crypto.key');
    if (key.length != 32 ||
        saltText is! String ||
        saltText.isEmpty ||
        kid is! String ||
        kid.isEmpty) {
      throw const TravelBootstrapException(
        'Travel business encryption material is invalid.',
      );
    }
    if (initData['isVersionAuditing'] is! bool) {
      throw const TravelBootstrapException(
        'Travel client.init response is incomplete.',
      );
    }
    return TravelRuntimeSession(
      apiBaseUri: routes.apiBaseUri,
      identity: identity,
      crypto: TravelCryptoMaterial(kid: kid, key: key, saltText: saltText),
      allowInsecureHttp: TravelBootstrapConfig.allowInsecureHttp,
      aadContextPath: _aadContextPath(),
    );
  }

  Future<TravelBusinessResult> postBusiness({
    required TravelRuntimeSession session,
    required String routeToken,
    required Map<String, Object?> body,
    Map<String, String> headers = const <String, String>{},
  }) async {
    final uri = _routeUri(session.apiBaseUri, routeToken);
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final nonce = _crypto.encode(_crypto.randomBytes(16));
    final iv = _crypto.randomBytes(12);
    final path = session.aadPathFor(uri);
    final aad = '1\n${session.crypto.kid}\nPOST\n$path\n$timestamp\n$nonce';
    final plaintext = jsonEncode(
      session.identity.toJson(requestId: _requestId(), body: body),
    );
    final ciphertext = _crypto.encrypt(
      key: session.crypto.key,
      iv: iv,
      aad: aad,
      plaintext: plaintext,
    );
    final response = await _dio.postUri<Object>(
      uri,
      data: <String, Object>{
        'v': 1,
        'kid': session.crypto.kid,
        'ts': timestamp,
        'nonce': nonce,
        'iv': _crypto.encode(iv),
        'ct': _crypto.encode(ciphertext),
      },
      options: Options(
        headers: <String, String>{
          ...headers,
          ..._signature(session, body, timestamp),
        },
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
    return _decryptBusinessResponse(
      response.data,
      session: session,
      path: path,
    );
  }

  Future<Map<String, Object?>> _callBootstrapEnvelope({
    required Uri uri,
    required TravelIdentity identity,
    required Map<String, Object?> body,
    Map<String, String> headers = const <String, String>{},
  }) async {
    final sessionKey = _crypto.randomBytes(32);
    final nonce = _crypto.encode(_crypto.randomBytes(16));
    final iv = _crypto.randomBytes(12);
    final path = _bootstrapAadPathFor(uri);
    final aad = '1\n${TravelBootstrapConfig.bootstrapKid}\nPOST\n$path';
    final plaintext = jsonEncode(
      identity.toJson(
        requestId: _requestId(),
        timestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
        nonce: nonce,
        body: body,
      ),
    );
    final encryptedKey = _crypto.rsaOaepSha256(
      publicKeyPem: TravelBootstrapConfig.bootstrapPublicKeyPem,
      plaintext: sessionKey,
    );
    final ciphertext = _crypto.encrypt(
      key: sessionKey,
      iv: iv,
      aad: aad,
      plaintext: plaintext,
    );
    try {
      final response = await _dio.postUri<Object>(
        uri,
        data: <String, Object>{
          'v': 1,
          'bootstrapKid': TravelBootstrapConfig.bootstrapKid,
          'ek': _crypto.encode(encryptedKey),
          'iv': _crypto.encode(iv),
          'ct': _crypto.encode(ciphertext),
        },
        options: Options(
          headers: headers,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
      return _decryptBootstrapResponse(
        response.data,
        sessionKey: sessionKey,
        aad: '$aad\nRESPONSE',
      );
    } on DioException catch (error, stackTrace) {
      throw TravelBootstrapException(
        'Unable to connect to the Travel service.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, Object?> _decryptBootstrapResponse(
    Object? value, {
    required List<int> sessionKey,
    required String aad,
  }) {
    final envelope = objectMap(value, 'bootstrap response');
    if (envelope['v'] != 1 ||
        envelope['bootstrapKid'] != TravelBootstrapConfig.bootstrapKid) {
      throw const TravelBootstrapException(
        'Travel Bootstrap authentication failed.',
      );
    }
    final iv = envelope['iv'];
    final ciphertext = envelope['ct'];
    if (iv is! String || ciphertext is! String) {
      throw const TravelBootstrapException(
        'Travel Bootstrap response is incomplete.',
      );
    }
    final plaintext = _crypto.decrypt(
      key: Uint8List.fromList(sessionKey),
      iv: _crypto.decode(iv),
      aad: aad,
      ciphertext: _crypto.decode(ciphertext),
    );
    return objectMap(jsonDecode(plaintext), 'decrypted bootstrap response');
  }

  TravelBusinessResult _decryptBusinessResponse(
    Object? value, {
    required TravelRuntimeSession session,
    required String path,
  }) {
    final envelope = objectMap(value, 'business response');
    final ts = envelope['ts'];
    final iv = envelope['iv'];
    final ciphertext = envelope['ct'];
    if (envelope['v'] != 1 ||
        envelope['kid'] != session.crypto.kid ||
        ts is! num ||
        iv is! String ||
        ciphertext is! String) {
      throw const TravelBootstrapException(
        'Travel business response encryption is invalid.',
      );
    }
    final aad =
        '1\n${session.crypto.kid}\nPOST\n$path\n${ts.toInt()}\nRESPONSE';
    final plaintext = _crypto.decrypt(
      key: session.crypto.key,
      iv: _crypto.decode(iv),
      aad: aad,
      ciphertext: _crypto.decode(ciphertext),
    );
    return TravelBusinessResult.fromJson(
      objectMap(jsonDecode(plaintext), 'business response data'),
    );
  }

  Map<String, String> _signature(
    TravelRuntimeSession session,
    Map<String, Object?> body,
    int timestamp,
  ) {
    final values = <String, Object?>{
      ...body,
      'v': '$timestamp',
      'secret': session.crypto.saltText,
    };
    final keys = values.keys.toList()..sort();
    final normalized = keys
        .map((key) => '$key=${values[key]}')
        .join('&')
        .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    return <String, String>{'v': '$timestamp', 'b': _md5(normalized)};
  }

  String _md5(String value) {
    return md5.convert(utf8.encode(value)).toString();
  }

  Map<String, Object?> _dataOf(Map<String, Object?> response) {
    final root = objectMap(response['data'] ?? response, 'data');
    if (response['code'] is num && response['code'] != 200) {
      throw TravelBootstrapException(
        response['message']?.toString() ?? 'Travel request was rejected.',
        code: (response['code'] as num).toInt(),
      );
    }
    return root;
  }

  Uri _routeUri(Uri base, String token) {
    final path = base.path.replaceFirst(RegExp(r'/$'), '');
    final uri = base.replace(path: '$path/api/r/$token');
    if (!_allowsUri(uri)) {
      throw const TravelBootstrapException('Travel API URL is invalid.');
    }
    return uri;
  }

  void _validateConfig() {
    final uri = Uri.tryParse(TravelBootstrapConfig.bootstrapUrl);
    if (uri == null ||
        !_allowsUri(uri) ||
        !TravelBootstrapConfig.bootstrapAadPath.startsWith('/')) {
      throw const TravelBootstrapException(
        'Travel Bootstrap configuration is invalid.',
      );
    }
  }

  bool _allowsUri(Uri uri) =>
      uri.scheme == 'https' ||
      (TravelBootstrapConfig.allowInsecureHttp && uri.scheme == 'http');

  Uri _normalizeUri(Uri uri) =>
      TravelBootstrapConfig.allowInsecureHttp && uri.scheme == 'https'
      ? uri.replace(scheme: 'http')
      : uri;

  String _aadContextPath() {
    final path = Uri.parse(TravelBootstrapConfig.bootstrapUrl).path;
    if (!path.endsWith(TravelBootstrapConfig.bootstrapAadPath)) return '';
    return path.substring(
      0,
      path.length - TravelBootstrapConfig.bootstrapAadPath.length,
    );
  }

  String _bootstrapAadPathFor(Uri uri) {
    final context = _aadContextPath();
    if (context.isEmpty || !uri.path.startsWith(context)) return uri.path;
    final path = uri.path.substring(context.length);
    return path.startsWith('/') ? path : uri.path;
  }

  String _requestId() {
    final bytes = _crypto.randomBytes(16);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
