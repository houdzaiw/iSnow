import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../model/login_request.dart';
import '../../../model/login_response.dart';
import '../../../model/get_sms_code_request.dart';
import '../../../manager/http/dio_provider.dart';
import '../../../manager/http/api_path.dart';
import '../../../configs/app_device.dart';

enum GetSMSType {
  none,
  sms,
  whatsapp,
}

enum GetSMSPurpose {
  register,
  forgetPassword,
  accountBinding,
  accountChangeBinding,
  verifyBinding,
}

extension GetSMSPurposeExt on GetSMSPurpose {
  int get value {
    switch (this) {
      case GetSMSPurpose.register:
        return 1;
      case GetSMSPurpose.forgetPassword:
        return 2;
      case GetSMSPurpose.accountBinding:
        return 3;
      case GetSMSPurpose.accountChangeBinding:
        return 4;
      case GetSMSPurpose.verifyBinding:
        return 5;
    }
  }

  static GetSMSPurpose fromValue(int value) {
    switch (value) {
      case 1:
        return GetSMSPurpose.register;
      case 2:
        return GetSMSPurpose.forgetPassword;
      case 3:
        return GetSMSPurpose.accountBinding;
      case 4:
        return GetSMSPurpose.accountChangeBinding;
      case 5:
        return GetSMSPurpose.verifyBinding;
      default:
        throw ArgumentError('Invalid GetSMSPurpose value: $value');
    }
  }
}

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

  // 发送验证码
  Future<LoginResponse> sendSms({
    required String phone,
    String areaCode = '966',
    String countryCode = 'us',
    int smsType = 1, // 1: 注册, 2: 登录, 3: 找回密码
  }) async {
    try {
      final appDevice = AppDevice();
      final request = GetSMSCodeRequest(
        phone: phone,
        areaCode: areaCode,
        purpose: GetSMSPurpose.register,
        type: GetSMSType.sms,
        language: appDevice.appLanguage,
      );

      print('Sending SMS with params: $request');

      final response = await _dio.post(
        ApiPath.sendSms,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['code'] == 0) {
          return LoginResponse(
            success: true,
            message: 'Verification code sent successfully',
          );
        } else {
          return LoginResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to send verification code',
          );
        }
      } else {
        return LoginResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
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
          return LoginResponse(
            success: false,
            message: data['message'] ?? 'Server error',
          );
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
    String areaCode = '966',
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

