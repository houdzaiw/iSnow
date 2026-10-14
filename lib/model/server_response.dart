/// Server text for user-facing notices, with `msg` taking precedence.
String? nadyResponseMessage(Map<dynamic, dynamic> json) {
  for (final key in const ['msg', 'message']) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

class NadyServerResponse<T> {
  const NadyServerResponse({
    required this.code,
    required this.message,
    required this.timestamp,
    this.traceId,
    this.data,
  });

  static const int successCode = 200;

  final int code;
  final String message;
  final String timestamp;
  final String? traceId;
  final T? data;

  bool get isSuccess => code == successCode;

  factory NadyServerResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    final rawCode = json['code'];
    final code = rawCode is num
        ? rawCode.toInt()
        : int.tryParse(rawCode?.toString() ?? '') ?? 0;
    final data = json['data'];
    return NadyServerResponse<T>(
      code: code,
      message: nadyResponseMessage(json) ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      traceId: json['traceId']?.toString(),
      data: code == successCode && json.containsKey('data') && fromJsonT != null
          ? fromJsonT(data)
          : null,
    );
  }

  NadyApiException toException() {
    return NadyApiException(
      message: message.isEmpty ? 'Request failed' : message,
      code: code,
      traceId: traceId,
      hasDisplayMessage: message.isNotEmpty,
    );
  }
}

class NadyApiException implements Exception {
  const NadyApiException({
    required this.message,
    this.code,
    this.traceId,
    this.hasDisplayMessage = true,
  });

  final String message;
  final int? code;
  final String? traceId;

  /// False when `message` is only the diagnostic default for an empty response.
  final bool hasDisplayMessage;

  @override
  String toString() {
    final codeText = code == null ? '' : 'code=$code ';
    final traceText = traceId == null ? '' : 'traceId=$traceId ';
    return 'NadyApiException($codeText$traceText$message)';
  }
}
