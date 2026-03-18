import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/model/login_response.dart';
import 'package:project/model/user_model.dart';
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

      // 使用 ApiClient 统一处理 HTTP 请求
      final response = await _apiClient.post(
        ApiPath.login,
        data: params,
      );

      // HTTP 或业务层面失败（ApiClient 已统一处理）
      if (!response.success) {
        return LoginResponse(
          success: false,
          message: response.message ?? 'Request failed',
        );
      }

      // 成功，response.data 已经是纯净的业务数据
      final data = response.data;
      return LoginResponse(
        success: true,
        message: response.message ?? 'Login successful',
        data: data != null ? UserData.fromJson(data) : null,
        token: data?['token'] as String?,
      );
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
      final hasUserParams = {
        "phone": phone,
        "areaCode": areaCode,
      };
      final params = {
        "phone": phone,
        "areaCode": areaCode,
        "purpose": purpose.value,
        "type": type == GetSMSType.sms ? 1 : 2,
        "language": _appDevice.appLanguage,
      };

      // 检查用户是否存在
      final result = await _apiClient.get(
        ApiPath.hasUser,
        queryParameters: hasUserParams,
      );

      // HTTP 或业务层面失败
      if (!result.success) {
        return LoginResponse(
          success: false,
          message: result.message ?? 'Request failed',
        );
      }

      // 检查用户是否存在
      final resultData = result.data;
      final hasUser = resultData?['hasUser'] as bool? ?? false;

      if (purpose == GetSMSPurpose.register && hasUser) {
        return LoginResponse(
          success: false,
          message: 'Account already exists',
        );
      }

      // 发送验证码
      final response = await _apiClient.post(
        ApiPath.sendSms,
        data: params,
      );

      // HTTP 或业务层面失败
      if (!response.success) {
        return LoginResponse(
          success: false,
          message: response.message ?? 'Request failed',
        );
      }

      // 成功
      return LoginResponse(
        success: true,
        message: response.message ?? 'Verification code sent successfully',
      );
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
      // 先调用登录接口验证短信验证码
      final loginResponse = await login(
        account: account,
        password: "",
        smsCode: smsCode,
        areaCode: areaCode,
        countryCode: countryCode,
      );

      // 如果登录失败，直接返回错误
      if (!loginResponse.success) {
        return loginResponse;
      }

      // 调用getMineUserInfo
      final userInfoResponse = await _apiClient.get(
        ApiPath.getMineUserInfo,
      );

      // HTTP 或业务层面失败
      if (!userInfoResponse.success) {
        return LoginResponse(
          success: false,
          message: userInfoResponse.message ?? 'Failed to get user info',
        );
      }

      // 调用修改密码接口setPassword
      final setPasswordResponse = await _apiClient.post(
        ApiPath.setPassword,
        data: {
          'password': await CryptUtil.encrypt(password),
        },
      );

      // HTTP 或业务层面失败
      if (!setPasswordResponse.success) {
        return LoginResponse(
          success: false,
          message: setPasswordResponse.message ?? 'Failed to set password',
        );
      }

      // 继续完善用户信息completeUserInfo
      final completeParams = {
        'nick': 'User${DateTime.now().millisecondsSinceEpoch}',
        'gender': 0,
        'birth': '2000-01-01',
        'uid': 18416564,
        'code': 'SA',
        'inviteCode': '',
      };

      final completeInfoResponse = await _apiClient.post(
        ApiPath.completeUserInfo,
        data: completeParams,
      );

      // HTTP 或业务层面失败
      if (!completeInfoResponse.success) {
        return LoginResponse(
          success: false,
          message: completeInfoResponse.message ?? 'Failed to complete user info',
        );
      }

      // 成功
      return LoginResponse(
        success: true,
        message: completeInfoResponse.message ?? 'Registration successful',
      );
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // 获取当前登录用户信息
  Future<UserModel?> getUserInfo() async {
    try {
      final response = await _apiClient.get(ApiPath.getMineUserInfo);
      if (!response.success || response.data == null) {
        return null;
      }
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}

// Riverpod provider
final loginProviderProvider = Provider<LoginProvider>((ref) {
  final dio = ref.read(dioProvider);
  final apiClient = ApiClient(dio: dio);
  return LoginProvider(apiClient);
});

