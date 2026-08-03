import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/login_response.dart';
import '../model/user_profile.dart';

class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const _tokenKey = 'nady.oauthToken';
  static const _uidKey = 'nady.pubUid';
  static const _userKey = 'nady.userBaseInfo';
  static const _phoneKey = 'nady.phone';
  static const _areaCodeKey = 'nady.areaCode';
  static const _countryCodeKey = 'nady.countryCode';

  Future<void> saveLogin(
    LoginResponse response, {
    required String phone,
    required String areaCode,
    required String countryCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.token ?? '');
    await prefs.setInt(_uidKey, response.uid ?? 0);
    await prefs.setString(_phoneKey, phone);
    await prefs.setString(_areaCodeKey, areaCode);
    await prefs.setString(_countryCodeKey, countryCode);
    final user = response.data?.copyWith(
      phone: phone,
      areaCode: areaCode,
      countryCode: response.data?.countryCode ?? countryCode,
    );
    if (user != null) {
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    }
  }

  Future<void> saveUser(UserData user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    if (user.uid != null) {
      await prefs.setInt(_uidKey, user.uid!);
    }
  }

  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token == null || token.isEmpty ? null : token;
  }

  Future<int?> uid() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt(_uidKey);
    return uid == null || uid == 0 ? null : uid;
  }

  Future<String?> phone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  Future<String?> areaCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_areaCodeKey);
  }

  Future<String?> countryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_countryCodeKey);
  }

  Future<UserData?> user() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserData.fromJson(json).copyWith(
        phone: prefs.getString(_phoneKey),
        areaCode: prefs.getString(_areaCodeKey),
        countryCode:
            json['countryCode']?.toString() ?? prefs.getString(_countryCodeKey),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final currentToken = await token();
    final currentUid = await uid();
    return currentToken != null && currentUid != null;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_uidKey);
    await prefs.remove(_userKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_areaCodeKey);
    await prefs.remove(_countryCodeKey);
  }
}
