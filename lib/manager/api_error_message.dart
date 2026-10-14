import 'package:dio/dio.dart';

import '../model/server_response.dart';

/// Extract server text without exposing exception types, codes or trace IDs.
String? serverErrorMessage(Object? error) {
  if (error is NadyApiException) {
    if (!error.hasDisplayMessage) return null;
    final message = error.message.trim();
    return message.isEmpty ? null : message;
  }
  if (error is DioException) {
    final response = error.response?.data;
    if (response is Map) {
      final message = nadyResponseMessage(response);
      if (message != null) return message;
    }
    if (error.error is NadyApiException) {
      return serverErrorMessage(error.error);
    }
  }
  return null;
}

/// Keep the caller's existing fallback for errors without server text.
String userFacingErrorMessage(Object? error, {String? fallback}) =>
    serverErrorMessage(error) ??
    fallback ??
    (error is NadyApiException ? error.message : error?.toString()) ??
    'Request failed';
