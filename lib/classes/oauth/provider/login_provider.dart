import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/model/login_response.dart';
import 'package:project/manager/http/dio_provider.dart';
import 'package:project/manager/http/api_path.dart';
import 'package:project/manager/http/api_client.dart';
import 'package:project/configs/app_device.dart';
import 'package:project/lib/crypt_util.dart';

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
  final ApiClient _apiClient;
  final AppDevice _appDevice = AppDevice();

  LoginProvider(this._apiClient);

  // 登录接口
  Future<LoginResponse> login({
    required String account,
    required String password,
    required String smsCode,
    int loginType = 5,
    String areaCode = '966',
    String countryCode = 'us',
  }) async {
    try {
      // 加密密码
      final encryptedPassword = await CryptUtil.encrypt(password);

      // 构建登录参数
      final params = {
        "code": account,
        "loginType": loginType,
        "passwd": encryptedPassword,
        "smsCode": smsCode,
        "areaCode": areaCode,
        "countryCode": countryCode,
        "fbLimited": false,
        "deviceId": _appDevice.deviceId,
        "app": _appDevice.appName,
        "appVersion": _appDevice.appVersion,
        "appVersionCode": int.tryParse(_appDevice.appVersionCode) ?? 1,
        "channel": "DEV",
        "systemLanguage": _appDevice.systemLanguage,
        "appLanguage": _appDevice.appLanguage,
        "isp": "",
        "model": _appDevice.model,
        "os": _appDevice.os,
        "osVersion": _appDevice.osVersion,
        "deviceBrand": _appDevice.deviceBrand,
        "appsflyerUID": _appDevice.fingerprint,
      };

      final response = await _apiClient.dio.post(
        ApiPath.login,
        data: params,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 0) {
          return LoginResponse(
            success: true,
            message: 'Login successful',
            data: data['data'] != null ? UserData.fromJson(data['data']) : null,
            token: data['data']?['token'] as String?,
          );
        } else {
          return LoginResponse(
            success: false,
            message: data['message'] ?? 'Login failed',
          );
        }
      } else {
        return LoginResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
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

  // 发送验证码
  Future<LoginResponse> sendSms({
    required String phone,
    String areaCode = '966',
    GetSMSPurpose purpose = GetSMSPurpose.register,
    GetSMSType type = GetSMSType.sms,
  }) async {
    try {
      final params = {
        "phone": phone,
        "areaCode": areaCode,
        "purpose": purpose.value,
        "type": type == GetSMSType.sms ? 1 : 2,
        "language": _appDevice.appLanguage,
      };

      final response = await _apiClient.dio.post(
        ApiPath.sendSms,
        data: params,
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
    required String smsCode,
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

      final response = await login(
        account: account,
        password: "",
        smsCode: smsCode,
        areaCode: '966',
        countryCode: 'us',
      );
      // 调用getMineUserInfo
      final userInfoResponse = await _apiClient.dio.post(
        ApiPath.getMineUserInfo,
        data: {},
      );
      if (userInfoResponse.statusCode == 200) {
         //调用修改密码接口setPassword
        final setPasswordResponse = await _apiClient.dio.post(
          ApiPath.setPassword,
          data: {
            'password': await CryptUtil.encrypt(password),
          },
        );
        if (setPasswordResponse.statusCode == 200) {
          final setPasswordData = setPasswordResponse.data;
          if (setPasswordData['code'] == 0) {
            return LoginResponse(
              success: true,
              message: 'Registration and password setup successful',
            );
          } else {
            return LoginResponse(
              success: false,
              message: setPasswordData['message'] ?? 'Failed to set password',
            );
          }
        } else {
          print("mmmmmmmmmmmmmm333333333");
          return LoginResponse(
            success: false,
            message: 'Server error: ${setPasswordResponse.statusCode}',
          );
        }
      } else {
        return LoginResponse(
          success: false,
          message: 'Server error: ${userInfoResponse.statusCode}',
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
}

// Riverpod provider
final loginProviderProvider = Provider<LoginProvider>((ref) {
  final dio = ref.read(dioProvider);
  final apiClient = ApiClient(dio: dio);
  return LoginProvider(apiClient);
});

