// filepath: /Users/admin/Documents/project/isnow/lib/classes/oauth/provider/login_provider.dart

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../../manager/http_dio_manager.dart';
import '../../../manager/http_api.dart';
import '../../../configs/app_device.dart';
import '../../../model/login_response.dart';

class LoginProvider {
  final HttpDioManager _httpManager = HttpDioManager();
  final AppDevice _appDevice = AppDevice();

  /// 生成请求 Header 公参
  Future<Map<String, String>> _getCommonHeaders() async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    return {
      'Content-Type': 'application/json',
      'b': _appDevice.generateSignature(),
      'v': startTime.toString(),
      'systemLanguage': _appDevice.systemLanguage,
      'timeZone': _appDevice.timeZone.toString(),
      'storeCode': 'US',
      'appVersion': _appDevice.appVersion,
      'appLanguage': _appDevice.appLanguage,
      'x-auth-token': _appDevice.generateAuthToken(),
      'startTime': startTime.toString(),
    };
  }

  /// 加密密码 (使用 SHA256)
  String _encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 登录
  /// [account] - 账号 (手机号或邮箱)
  /// [password] - 密码
  /// [loginType] - 登录类型 (5: 密码登录)
  /// [areaCode] - 区号 (如: 966, 86)
  /// [countryCode] - 国家代码 (如: us, cn)
  Future<LoginResponse> login({
    required String account,
    required String password,
    int loginType = 5,
    String areaCode = '1',
    String countryCode = 'us',
    String smsCode = '',
  }) async {
    try {
      // 获取公共 headers
      final headers = await _getCommonHeaders();

      // 加密密码
      final encryptedPassword = _encryptPassword(password);

      // 构建请求参数
      final params = {
        'code': account,
        'loginType': loginType,
        'passwd': encryptedPassword,
        'smsCode': smsCode,
        'areaCode': areaCode,
        'countryCode': countryCode,
        'fbLimited': false,
        'deviceId': _appDevice.deviceId,
        'app': _appDevice.appName,
        'appVersion': _appDevice.appVersion,
        'appVersionCode': _appDevice.appVersionCode,
        'channel': 'DEV',
        'systemLanguage': _appDevice.systemLanguage,
        'appLanguage': _appDevice.appLanguage,
        'isp': '',
        'model': _appDevice.model,
        'os': _appDevice.os,
        'osVersion': _appDevice.osVersion,
        'deviceBrand': _appDevice.deviceBrand,
        'appsflyerUID': '${DateTime.now().millisecondsSinceEpoch}-${_appDevice.deviceId.hashCode}',
      };

      print('🦊登录请求🦊 POST: ${HttpApi.login}');
      print('│ header: $headers');
      print('│ params: $params');

      // 发送 POST 请求
      final response = await _httpManager.post(
        HttpApi.login,
        data: params,
        options: Options(headers: headers),
      );

      print('🦊登录响应🦊 $response');

      // 解析响应
      return LoginResponse.fromJson(response);
    } on DioException catch (e) {
      print('🦊登录错误🦊 DioException: ${e.message}');
      // 处理 Dio 异常
      if (e.response != null) {
        print('🦊错误响应🦊 ${e.response?.data}');
        return LoginResponse(
          success: false,
          message: e.response?.data['message'] ?? 'Login failed',
        );
      } else {
        return LoginResponse(
          success: false,
          message: e.message ?? 'Network error',
        );
      }
    } catch (e) {
      print('🦊登录错误🦊 Exception: $e');
      // 处理其他异常
      return LoginResponse(
        success: false,
        message: 'Unknown error: $e',
      );
    }
  }

  /// 发送验证码
  Future<Map<String, dynamic>> sendSms({
    required String phoneNumber,
    required String countryCode,
    String areaCode = '1',
  }) async {
    try {
      final headers = await _getCommonHeaders();
      
      final response = await _httpManager.post(
        HttpApi.sendSms,
        data: {
          'phoneNumber': phoneNumber,
          'countryCode': countryCode,
          'areaCode': areaCode,
        },
        options: Options(headers: headers),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 校验验证码
  Future<Map<String, dynamic>> verifyCode({
    required String phoneNumber,
    required String code,
    String areaCode = '1',
  }) async {
    try {
      final headers = await _getCommonHeaders();
      
      final response = await _httpManager.post(
        HttpApi.verifyCode,
        data: {
          'phoneNumber': phoneNumber,
          'code': code,
          'areaCode': areaCode,
        },
        options: Options(headers: headers),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 设置密码
  Future<Map<String, dynamic>> setPassword({
    required String userId,
    required String password,
  }) async {
    try {
      final headers = await _getCommonHeaders();
      final encryptedPassword = _encryptPassword(password);
      
      final response = await _httpManager.post(
        HttpApi.setPassword,
        data: {
          'userId': userId,
          'password': encryptedPassword,
        },
        options: Options(headers: headers),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 登出
  Future<Map<String, dynamic>> logout() async {
    try {
      final headers = await _getCommonHeaders();
      
      final response = await _httpManager.post(
        HttpApi.logout,
        options: Options(headers: headers),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 检查用户是否存在
  Future<Map<String, dynamic>> hasUser(String email) async {
    try {
      final headers = await _getCommonHeaders();
      
      final response = await _httpManager.get(
        HttpApi.hasUser,
        queryParameters: {'email': email},
        options: Options(headers: headers),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

