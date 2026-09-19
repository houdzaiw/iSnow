import 'dart:convert';
import 'dart:typed_data';

import 'travel_bootstrap_exception.dart';

final class TravelIdentity {
  const TravelIdentity({
    required this.platform,
    required this.packageName,
    required this.channel,
    required this.clientVersion,
  });

  final String platform;
  final String packageName;
  final String channel;
  final String clientVersion;

  Map<String, Object?> toJson({
    required String requestId,
    int? timestamp,
    String? nonce,
    Map<String, Object?> body = const <String, Object?>{},
  }) {
    return <String, Object?>{
      'platform': platform,
      'packageName': packageName,
      'channel': channel,
      'clientVersion': clientVersion,
      'requestId': requestId,
      if (timestamp != null) 'timestamp': timestamp,
      if (nonce != null) 'nonce': nonce,
      'body': body,
    };
  }
}

final class TravelClientInitInput {
  const TravelClientInitInput({required this.identity, required this.body});

  final TravelIdentity identity;
  final Map<String, Object?> body;
}

final class TravelPublicConfig {
  const TravelPublicConfig({
    this.h5Url,
    this.userAgreementUrl,
    this.privacyPolicyUrl,
    this.contactEmail,
  });

  final Uri? h5Url;
  final Uri? userAgreementUrl;
  final Uri? privacyPolicyUrl;
  final String? contactEmail;

  factory TravelPublicConfig.fromJson(Map<String, Object?> json) {
    return TravelPublicConfig(
      h5Url: _httpsUri(json['h5Url']),
      userAgreementUrl: _httpsUri(json['userAgreementUrl']),
      privacyPolicyUrl: _httpsUri(json['privacyPolicyUrl']),
      contactEmail: json['contactEmail']?.toString(),
    );
  }
}

final class TravelBootstrapRoutes {
  const TravelBootstrapRoutes({
    required this.apiBaseUri,
    required this.loginUri,
    required this.clientInitUri,
    required this.publicConfig,
  });

  final Uri apiBaseUri;
  final Uri loginUri;
  final Uri clientInitUri;
  final TravelPublicConfig publicConfig;
}

final class TravelCryptoMaterial {
  const TravelCryptoMaterial({
    required this.kid,
    required this.key,
    required this.saltText,
  });

  final String kid;
  final Uint8List key;
  final String saltText;
}

final class TravelRuntimeSession {
  const TravelRuntimeSession({
    required this.apiBaseUri,
    required this.identity,
    required this.crypto,
    required this.allowInsecureHttp,
    required this.aadContextPath,
  });

  final Uri apiBaseUri;
  final TravelIdentity identity;
  final TravelCryptoMaterial crypto;
  final bool allowInsecureHttp;
  final String aadContextPath;

  String aadPathFor(Uri uri) {
    if (aadContextPath.isEmpty || !uri.path.startsWith(aadContextPath)) {
      return uri.path;
    }
    final path = uri.path.substring(aadContextPath.length);
    return path.startsWith('/') ? path : uri.path;
  }
}

final class TravelBusinessResult {
  const TravelBusinessResult({
    required this.code,
    required this.data,
    required this.message,
    required this.traceId,
  });

  final int code;
  final Object? data;
  final String message;
  final String traceId;

  bool get isSuccess => code == 200;

  factory TravelBusinessResult.fromJson(Map<String, Object?> json) {
    final code = json['code'];
    if (code is! num) {
      throw const TravelBootstrapException('Travel response code is invalid.');
    }
    return TravelBusinessResult(
      code: code.toInt(),
      data: json['data'],
      message: json['message']?.toString() ?? json['msg']?.toString() ?? '',
      traceId: json['traceId']?.toString() ?? '',
    );
  }
}

Uri? _httpsUri(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
      ? uri
      : null;
}

Map<String, Object?> objectMap(Object? value, String field) {
  if (value is! Map) {
    throw TravelBootstrapException('Travel response field $field is invalid.');
  }
  return value.map<String, Object?>((key, value) => MapEntry('$key', value));
}

Uint8List base64UrlBytes(Object? value, String field) {
  if (value is! String || value.isEmpty) {
    throw TravelBootstrapException('Travel response is missing $field.');
  }
  try {
    return Uint8List.fromList(base64Url.decode(base64Url.normalize(value)));
  } on Object catch (error, stackTrace) {
    throw TravelBootstrapException(
      'Travel response field $field is not valid Base64URL.',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
