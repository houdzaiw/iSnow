import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../manager/http_dio_manager.dart';
import '../room/more/room_tools_config.dart';

final webBridgeRepositoryProvider = Provider<WebBridgeRepository>((ref) {
  return WebBridgeRepository(HttpDioManager());
});

class WebBridgeRepository {
  const WebBridgeRepository(this._http);

  final HttpDioManager _http;

  Future<dynamic> callApi(WebBridgeApiRequest request) {
    final target = Uri.parse(request.normalizedUrl);
    final base = Uri.parse(const RoomToolsConfig().apiBase);
    if (target.userInfo.isNotEmpty ||
        target.hasAuthority &&
            (!target.hasScheme || target.origin != base.origin) ||
        target.hasScheme && !{'http', 'https'}.contains(target.scheme)) {
      throw const WebBridgeApiRequestException('Untrusted API origin');
    }
    final method = request.method.toUpperCase();
    return switch (method) {
      'GET' => _http.get(
        request.normalizedUrl,
        queryParameters: request.queryParameters,
      ),
      'PUT' => _http.put(
        request.normalizedUrl,
        data: request.usesQueryParameters
            ? const <String, dynamic>{}
            : request.body,
        queryParameters: request.usesQueryParameters
            ? request.queryParameters
            : null,
      ),
      'DELETE' => _http.delete(
        request.normalizedUrl,
        data: request.usesQueryParameters
            ? const <String, dynamic>{}
            : request.body,
        queryParameters: request.usesQueryParameters
            ? request.queryParameters
            : null,
      ),
      _ => _http.post(
        request.normalizedUrl,
        data: request.usesQueryParameters
            ? const <String, dynamic>{}
            : request.body,
        queryParameters: request.usesQueryParameters
            ? request.queryParameters
            : null,
      ),
    };
  }
}

class WebBridgeApiRequest {
  const WebBridgeApiRequest({
    required this.method,
    required this.url,
    required this.param,
    required this.keys,
  });

  factory WebBridgeApiRequest.fromJson(Map<String, dynamic> json) {
    return WebBridgeApiRequest(
      method: json['method']?.toString() ?? 'get',
      url: json['url']?.toString() ?? '',
      param: json['param'],
      keys: json['keys']?.toString() ?? 'data',
    );
  }

  final String method;
  final String url;
  final Object? param;
  final String keys;

  bool get usesQueryParameters => keys.toLowerCase() == 'params';

  String get normalizedUrl {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw const WebBridgeApiRequestException('Missing API url');
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        trimmed.contains('\\') ||
        uri.hasScheme && !{'http', 'https'}.contains(uri.scheme)) {
      throw const WebBridgeApiRequestException('Invalid API url');
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  Map<String, dynamic>? get queryParameters => _mapOrNull(param);

  Object get body => param ?? const <String, dynamic>{};

  WebBridgeApiRequest withLanguage(String? language) {
    final normalizedLanguage = language?.trim();
    if (normalizedLanguage == null || normalizedLanguage.isEmpty) {
      return this;
    }

    final nextParam = _mapOrNull(param) ?? <String, dynamic>{};
    nextParam.putIfAbsent('language', () => normalizedLanguage);
    return WebBridgeApiRequest(
      method: method,
      url: url,
      param: nextParam,
      keys: keys,
    );
  }

  static Map<String, dynamic>? _mapOrNull(Object? value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value)
        ..removeWhere((_, value) => value == null);
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value))
        ..removeWhere((_, value) => value == null);
    }
    return null;
  }
}

class WebBridgeApiRequestException implements Exception {
  const WebBridgeApiRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
