import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../configs/app_device.dart';
import 'web_bridge_repository.dart';

final webBridgeViewModelProvider = Provider<WebBridgeViewModel>((ref) {
  return WebBridgeViewModel(ref.read(webBridgeRepositoryProvider), AppDevice());
});

class WebBridgeViewModel {
  const WebBridgeViewModel(this._repository, this._device);

  final WebBridgeRepository _repository;
  final AppDevice _device;

  Future<WebBridgeApiResult> callApi(
    Map<String, dynamic> data, {
    String? language,
  }) async {
    try {
      final request = WebBridgeApiRequest.fromJson(data).withLanguage(language);
      final response = await _repository.callApi(request);
      return WebBridgeApiResult.success(response);
    } on DioException catch (error) {
      return WebBridgeApiResult.failure(
        message: error.message ?? 'Network request failed',
        response: error.response?.data,
      );
    } catch (error) {
      return WebBridgeApiResult.failure(message: error.toString());
    }
  }

  Map<String, dynamic> appInfo({required double statusBarHeight}) {
    return {
      'statusBarHeight': statusBarHeight,
      'isNotCommon': false,
      'version': _device.appVersion,
      'auditUids': '',
    };
  }

  Map<String, dynamic> paymentList(Map<String, dynamic> data) {
    return {'list': const <Object>[], 'type': data['type']};
  }
}

class WebBridgeApiResult {
  const WebBridgeApiResult._({required this.isSuccess, this.data, this.error});

  factory WebBridgeApiResult.success(Object? data) {
    return WebBridgeApiResult._(isSuccess: true, data: data);
  }

  factory WebBridgeApiResult.failure({
    required String message,
    Object? response,
  }) {
    return WebBridgeApiResult._(
      isSuccess: false,
      error: {
        'message': message,
        'response': response ?? {'code': -1, 'message': message},
      },
    );
  }

  final bool isSuccess;
  final Object? data;
  final Map<String, dynamic>? error;
}
