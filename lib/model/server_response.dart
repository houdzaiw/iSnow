// 服务端响应基础模型
class ServerResponse<T> {
  final int code;
  final T? data;
  final String timestamp;
  final String message;
  final String traceId;
  final String msg;

  ServerResponse({
    required this.code,
    this.data,
    required this.timestamp,
    required this.message,
    required this.traceId,
    required this.msg,
  });

  factory ServerResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ServerResponse<T>(
      code: json['code'] as int,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      timestamp: json['timestamp'] as String? ?? '',
      message: json['message'] as String? ?? '',
      traceId: json['traceId'] as String? ?? '',
      msg: json['msg'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'data': data,
      'timestamp': timestamp,
      'message': message,
      'traceId': traceId,
      'msg': msg,
    };
  }

  /// 判断业务是否成功
  bool get isSuccess => code == 200;
}

