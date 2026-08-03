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
    return NadyServerResponse<T>(
      code: (json['code'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      traceId: json['traceId']?.toString(),
      data: json.containsKey('data') && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
    );
  }

  NadyApiException toException() {
    return NadyApiException(
      message: message.isEmpty ? 'Request failed' : message,
      code: code,
      traceId: traceId,
    );
  }
}

class NadyApiException implements Exception {
  const NadyApiException({required this.message, this.code, this.traceId});

  final String message;
  final int? code;
  final String? traceId;

  @override
  String toString() {
    final codeText = code == null ? '' : 'code=$code ';
    final traceText = traceId == null ? '' : 'traceId=$traceId ';
    return 'NadyApiException($codeText$traceText$message)';
  }
}
