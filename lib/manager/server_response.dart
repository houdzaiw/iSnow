// Simple server response models implemented without code generation.
// This avoids dependency on freezed/build_runner during development.

class ServerResponse<T> {
  final int code;
  final String message;
  final String timestamp;
  final String? traceId;
  final T? data;

  ServerResponse({
    required this.code,
    required this.message,
    required this.timestamp,
    this.traceId,
    this.data,
  });

  factory ServerResponse.fromJson(
      Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    final dataJson = json['data'];
    return ServerResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      traceId: json['traceId'] as String?,
      data: dataJson == null ? null : fromJsonT(dataJson),
    );
  }
}

class BaseServerResponse {
  final int code;
  final String? message;
  final String timestamp;

  BaseServerResponse({
    required this.code,
    this.message,
    required this.timestamp,
  });

  factory BaseServerResponse.fromJson(Map<String, dynamic> json) =>
      BaseServerResponse(
        code: json['code'] as int,
        message: json['message'] as String?,
        timestamp: json['timestamp'] as String? ?? '',
      );
}

class ServerPageResponse<T> {
  final int total;
  final List<T>? list;

  ServerPageResponse({
    required this.total,
    this.list,
  });

  factory ServerPageResponse.fromJson(
          Map<String, dynamic> json, T Function(Object? json) fromJsonT) =>
      ServerPageResponse<T>(
        total: json['total'] as int,
        list: (json['list'] as List?)
            ?.map((e) => fromJsonT(e)).cast<T>()
            .toList(),
      );
}
