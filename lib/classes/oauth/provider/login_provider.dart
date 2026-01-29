import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../model/login_request.dart';
import '../../../model/login_response.dart';
import '../../../manager/http/dio_provider.dart';

class LoginProvider {
  final Dio _dio;

  LoginProvider(this._dio);

  // 登录接口
  Future<LoginResponse> login({
    required String account,
    required String password,
    int loginType = 5,
    String areaCode = '1',
    String countryCode = 'us',
  }) async {
    try {
      final request = LoginRequest(
        account: account,
        password: password,
        loginType: loginType,
        areaCode: areaCode,
        countryCode: countryCode,
      );

      final response = await _dio.post(
        '/api/login',
        data: request.toJson(),
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      // 处理网络错误
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return LoginResponse(
          success: false,
          message: 'Connection timeout, please try again',
        );
      } else if (e.type == DioExceptionType.badResponse) {
        // 服务器返回错误
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return LoginResponse.fromJson(data);
        }
        return LoginResponse(
          success: false,
          message: 'Server error: ${e.response?.statusCode}',
        );
      } else {
        return LoginResponse(
          success: false,
          message: 'Network error: ${e.message}',
        );
      }
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // 注册接口
  Future<LoginResponse> register({
    required String account,
    required String password,
    String areaCode = '1',
    String countryCode = 'us',
  }) async {
    try {
      final data = {
        'account': account,
        'password': password,
        'areaCode': areaCode,
        'countryCode': countryCode,
      };

      final response = await _dio.post(
        '/api/register',
        data: data,
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return LoginResponse(
          success: false,
          message: 'Connection timeout, please try again',
        );
      } else if (e.type == DioExceptionType.badResponse) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return LoginResponse.fromJson(data);
        }
        return LoginResponse(
          success: false,
          message: 'Server error: ${e.response?.statusCode}',
        );
      } else {
        return LoginResponse(
          success: false,
          message: 'Network error: ${e.message}',
        );
      }
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}

// Riverpod provider
final loginProviderProvider = Provider<LoginProvider>((ref) {
  final dio = ref.read(dioProvider);
  return LoginProvider(dio);
});

