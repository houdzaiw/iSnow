/// Travel Bootstrap、业务信封和启动配置相关的可展示异常。
class TravelBootstrapException implements Exception {
  const TravelBootstrapException(
    this.message, {
    this.code,
    this.requiresSessionRefresh = false,
    this.cause,
    this.stackTrace,
  });

  final String message;
  final int? code;
  final bool requiresSessionRefresh;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'TravelBootstrapException: $message';
}
