import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../configs/app_device.dart';
import '../../../manager/auth_session.dart';
import '../../../manager/http_api.dart';
import '../../../manager/http_dio_manager.dart';
import '../../../model/country_info.dart';
import '../../../model/login_response.dart';
import '../../../model/server_response.dart';
import '../../../model/upload_param.dart';
import '../../../model/user_profile.dart';

class LoginProvider {
  final HttpDioManager _httpManager = HttpDioManager();
  final AppDevice _appDevice = AppDevice();
  final AuthSession _authSession = AuthSession.instance;

  Future<String> _encryptPassword(String password) async {
    final algorithm = Chacha20.poly1305Aead();
    final secretKey = await algorithm.newSecretKey();
    final secretBox = await algorithm.encrypt(
      utf8.encode(password),
      secretKey: secretKey,
    );
    final secretKeyBytes = await secretKey.extractBytes();
    return hex.encode(secretKeyBytes) +
        hex.encode(secretBox.nonce) +
        hex.encode(secretBox.mac.bytes) +
        hex.encode(secretBox.cipherText);
  }

  Map<String, dynamic> _publicParams() {
    final deviceId = _appDevice.deviceId;
    return {
      'deviceId': deviceId,
      'appsflyerUID':
          '${DateTime.now().millisecondsSinceEpoch}-${deviceId.hashCode}',
      'app': 'Nady',
      'appVersion': _appDevice.appVersion,
      'appVersionCode': _appDevice.appVersionCode,
      'channel': 'DEV',
      'systemLanguage': _appDevice.systemLocale,
      'appLanguage': _appDevice.appLanguage,
      'isp': '',
      'countryCode': '',
      'model': _appDevice.model,
      'os': _appDevice.os,
      'osVersion': _appDevice.osVersion,
      'deviceBrand': _appDevice.deviceBrand,
    };
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }

  NadyServerResponse<T> _server<T>(
    dynamic response,
    T Function(Object? json)? fromJsonT,
  ) {
    return NadyServerResponse<T>.fromJson(_asMap(response), fromJsonT);
  }

  T _requireData<T>(dynamic response, T Function(Object? json) fromJsonT) {
    final server = _server<T>(response, fromJsonT);
    if (!server.isSuccess) {
      throw server.toException();
    }
    final data = server.data;
    if (data == null) {
      throw NadyApiException(
        message: server.message.isEmpty ? 'Empty server data' : server.message,
        code: server.code,
        traceId: server.traceId,
      );
    }
    return data;
  }

  Future<CountryInfo> getDefaultCountry() async {
    final response = await _httpManager.get(HttpApi.defaultCountry);
    return _requireData(
      response,
      (json) => CountryInfo.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<String> queryCountryDialCode(String countryCode) async {
    final response = await _httpManager.get(
      HttpApi.queryCountryCode,
      queryParameters: {'code': countryCode.toUpperCase()},
    );
    final dialCode = _requireData(response, (json) => json?.toString() ?? '');
    final normalizedDialCode = dialCode.replaceFirst('+', '').trim();
    if (normalizedDialCode.isEmpty) {
      throw const NadyApiException(message: 'Empty country dial code');
    }
    return normalizedDialCode;
  }

  Future<List<CountryInfo>> getHotCountries() async {
    final response = await _httpManager.get(HttpApi.hotCountry);
    return _requireData(
      response,
      (json) => (json as List? ?? const [])
          .map(
            (item) =>
                CountryInfo.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }

  Future<List<CountryInfo>> getSupportedCountries() async {
    final response = await _httpManager.get(HttpApi.supportedCountry);
    return _requireData(
      response,
      (json) => (json as List? ?? const [])
          .map(
            (item) =>
                CountryInfo.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }

  Future<HasUserResponse> hasUser({
    required String phone,
    required String areaCode,
  }) async {
    final response = await _httpManager.get(
      HttpApi.hasUser,
      queryParameters: {'phone': phone, 'areaCode': areaCode},
    );
    return _requireData(
      response,
      (json) => HasUserResponse.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<LoginResponse> login({
    required String account,
    required String password,
    int loginType = 5,
    String areaCode = '1',
    String countryCode = '',
    String smsCode = '',
  }) async {
    try {
      final encryptedPassword = password.isEmpty
          ? ''
          : await _encryptPassword(password);
      final normalizedCountryCode = countryCode.toUpperCase();
      final params = <String, dynamic>{
        'code': account,
        'loginType': loginType,
        'passwd': encryptedPassword,
        'smsCode': smsCode,
        'areaCode': areaCode,
        'countryCode': '',
        'fbLimited': false,
        ..._publicParams(),
      };
      if (normalizedCountryCode.isNotEmpty) {
        params['countryCode'] = normalizedCountryCode;
      }

      debugPrint('Login request POST: ${HttpApi.login}');

      final response = await _httpManager.post(HttpApi.login, data: params);
      final server = _server<LoginResponse>(
        response,
        (json) => LoginResponse.fromJson((json as Map).cast<String, dynamic>()),
      );
      if (!server.isSuccess) {
        return LoginResponse.failure(server.message);
      }
      final loginResponse = server.data;
      if (loginResponse == null) {
        return LoginResponse.failure(server.message);
      }

      await _authSession.saveLogin(
        loginResponse,
        phone: account,
        areaCode: areaCode,
        countryCode: normalizedCountryCode,
      );
      return loginResponse;
    } on DioException catch (e) {
      debugPrint('Login DioException: ${e.message}');
      final data = e.response?.data;
      if (data is Map) {
        return LoginResponse.failure(data['message']?.toString() ?? e.message);
      }
      return LoginResponse.failure(e.message);
    } catch (e) {
      debugPrint('Login exception: $e');
      return LoginResponse.failure('$e');
    }
  }

  Future<LoginResponse> registerWithSmsPassword({
    required String phone,
    required String password,
    required String smsCode,
    required String areaCode,
    required String countryCode,
  }) {
    return login(
      account: phone,
      password: password,
      loginType: 5,
      areaCode: areaCode,
      countryCode: countryCode,
      smsCode: smsCode,
    );
  }

  Future<void> sendSms({
    required String phoneNumber,
    required String areaCode,
    int purpose = 1,
    int type = 1,
    String? language,
  }) async {
    final response = await _httpManager.post(
      HttpApi.sendSms,
      data: {
        'phoneNo': phoneNumber,
        'areaCode': areaCode,
        'purpose': purpose,
        'type': type,
        'language': language ?? _appDevice.appLanguage,
      },
    );
    final server = _server<dynamic>(response, null);
    if (!server.isSuccess) throw server.toException();
  }

  Future<void> verifyCode({
    required String phoneNumber,
    required String code,
    required String areaCode,
  }) async {
    final response = await _httpManager.post(
      HttpApi.verifyCode,
      data: {'code': phoneNumber, 'areaCode': areaCode, 'smsCode': code},
    );
    final server = _server<dynamic>(response, null);
    if (!server.isSuccess) throw server.toException();
  }

  Future<void> setPassword({
    required String phoneNumber,
    required String password,
    required String areaCode,
  }) async {
    final encryptedPassword = await _encryptPassword(password);
    final response = await _httpManager.post(
      HttpApi.setPassword,
      data: {
        'phone': phoneNumber,
        'password': encryptedPassword,
        'areaCode': areaCode,
      },
    );
    final server = _server<dynamic>(response, null);
    if (!server.isSuccess) throw server.toException();
  }

  Future<UserData?> completeUser({
    required int uid,
    required String nick,
    required String avatar,
    required int gender,
    required String birth,
    required String countryCode,
    String? inviteCode,
  }) async {
    final response = await _httpManager.post(
      HttpApi.completeUser,
      data: {
        'nick': nick,
        'avatar': avatar,
        'gender': gender,
        'birth': birth,
        'uid': uid,
        'code': countryCode,
        'inviteCode': inviteCode,
      },
    );
    final user = _requireData(
      response,
      (json) => UserData.fromJson((json as Map).cast<String, dynamic>()),
    );
    await _authSession.saveUser(user);
    return user;
  }

  Future<MeModel> getMyProfileInfo() async {
    final response = await _httpManager.get(HttpApi.myUserInfo);
    final me = _requireData(
      response,
      (json) => MeModel.fromJson((json as Map).cast<String, dynamic>()),
    );
    final cachedPhone = await _authSession.phone();
    final cachedAreaCode = await _authSession.areaCode();
    final cachedCountryCode = await _authSession.countryCode();
    final user = me.userBaseInfo.copyWith(
      phone: cachedPhone,
      areaCode: me.userBaseInfo.areaCode ?? cachedAreaCode,
      countryCode: me.userBaseInfo.countryCode ?? cachedCountryCode,
    );
    await _authSession.saveUser(user);
    return MeModel(
      followingNum: me.followingNum,
      followerNum: me.followerNum,
      visitorNum: me.visitorNum,
      receiveGiftValue: me.receiveGiftValue,
      userBaseInfo: user,
    );
  }

  Future<UserData> getMyUserInfo() async {
    final me = await getMyProfileInfo();
    return me.userBaseInfo;
  }

  Future<UserData> modifyUser({
    required String nick,
    required int gender,
    required String avatar,
    required String signature,
    required Object birth,
  }) async {
    final response = await _httpManager.post(
      HttpApi.modifyUser,
      data: {
        'nick': nick,
        'gender': gender,
        'avatar': avatar,
        'signature': signature,
        'birth': birth,
      },
    );
    final user = _requireData(
      response,
      (json) => UserData.fromJson((json as Map).cast<String, dynamic>()),
    );
    await _authSession.saveUser(user);
    return user;
  }

  Future<UploadParam> getUploadParam() async {
    final response = await _httpManager.get(HttpApi.uploadParam);
    return _requireData(
      response,
      (json) => UploadParam.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<String> uploadAvatarFile(String filePath) async {
    final uploadParam = await getUploadParam();
    final bytes = await File(filePath).readAsBytes();
    final extension = filePath.split('.').last.toLowerCase();
    final safeExtension = extension == filePath ? 'jpg' : extension;
    final uploadPath = '${uploadParam.path}.$safeExtension';
    final endpoint = uploadParam.endpoint.startsWith('http')
        ? uploadParam.endpoint
        : 'https://${uploadParam.endpoint}';
    final endpointUri = Uri.parse(endpoint);
    final objectUri = Uri(
      scheme: endpointUri.scheme,
      host: '${uploadParam.bucket}.${endpointUri.host}',
      port: endpointUri.hasPort ? endpointUri.port : null,
      path: '/$uploadPath',
    );
    const contentType = 'image/jpeg';
    final date = HttpDate.format(DateTime.now().toUtc());
    final canonicalizedHeaders =
        'x-oss-security-token:${uploadParam.securityToken}\n';
    final canonicalizedResource = '/${uploadParam.bucket}/$uploadPath';
    final stringToSign =
        'PUT\n\n$contentType\n$date\n$canonicalizedHeaders$canonicalizedResource';
    final signature = base64Encode(
      crypto.Hmac(
        crypto.sha1,
        utf8.encode(uploadParam.accessKeySecret),
      ).convert(utf8.encode(stringToSign)).bytes,
    );

    final dio = Dio();
    await dio.putUri(
      objectUri,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Date': date,
          'Content-Type': contentType,
          'Authorization': 'OSS ${uploadParam.accessKeyId}:$signature',
          'x-oss-security-token': uploadParam.securityToken,
          'Content-Length': bytes.length,
        },
        responseType: ResponseType.plain,
      ),
    );
    return uploadPath;
  }

  Future<void> logout() async {
    try {
      final response = await _httpManager.post(HttpApi.logout, data: {});
      final server = _server<dynamic>(response, null);
      if (!server.isSuccess) throw server.toException();
    } finally {
      await _authSession.clear();
    }
  }

  Future<void> logoff() async {
    try {
      final response = await _httpManager.post(HttpApi.logoff);
      final server = _server<dynamic>(response, null);
      if (!server.isSuccess) throw server.toException();
    } finally {
      await _authSession.clear();
    }
  }

  Future<UserData?> cachedUser() {
    return _authSession.user();
  }

  Future<bool> isLoggedIn() {
    return _authSession.isLoggedIn();
  }
}
