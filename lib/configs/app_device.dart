// filepath: /Users/admin/Documents/project/isnow/lib/configs/app_device.dart

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AppDevice {
  static final AppDevice _instance = AppDevice._internal();
  factory AppDevice() => _instance;
  AppDevice._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PackageInfo? _packageInfo;

  // 设备信息缓存
  String? _deviceId;
  String? _model;
  String? _os;
  String? _osVersion;
  String? _deviceBrand;

  /// 初始化设备信息
  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      await _initAndroidInfo();
    } else if (Platform.isIOS) {
      await _initIOSInfo();
    }
  }

  /// 初始化 Android 设备信息
  Future<void> _initAndroidInfo() async {
    final androidInfo = await _deviceInfo.androidInfo;

    _model = androidInfo.model;
    _os = 'android';
    _osVersion = '|${androidInfo.version.codename}|${androidInfo.version.sdkInt}|${androidInfo.version.incremental}|${androidInfo.version.baseOS}|';
    _deviceBrand = androidInfo.brand;

    // 生成设备ID (使用 androidId 生成 MD5)
    final androidId = androidInfo.id;
    _deviceId = _generateDeviceId(androidId);
  }

  /// 初始化 iOS 设备信息
  Future<void> _initIOSInfo() async {
    final iosInfo = await _deviceInfo.iosInfo;

    _model = iosInfo.model;
    _os = 'ios';
    _osVersion = iosInfo.systemVersion;
    _deviceBrand = 'Apple';

    // 生成设备ID (使用 identifierForVendor 生成 MD5)
    final vendorId = iosInfo.identifierForVendor ?? '';
    _deviceId = _generateDeviceId(vendorId);
  }

  /// 生成设备ID
  String _generateDeviceId(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 获取设备ID
  String get deviceId => _deviceId ?? '';

  /// 获取设备型号
  String get model => _model ?? '';

  /// 获取操作系统
  String get os => _os ?? '';

  /// 获取操作系统版本
  String get osVersion => _osVersion ?? '';

  /// 获取设备品牌
  String get deviceBrand => _deviceBrand ?? '';

  /// 获取应用版本号
  String get appVersion => _packageInfo?.version ?? '1.0.0';

  /// 获取应用构建号
  String get appVersionCode => _packageInfo?.buildNumber ?? '1';

  /// 获取应用名称
  String get appName => _packageInfo?.appName ?? 'Nady';

  /// 获取包名
  String get packageName => _packageInfo?.packageName ?? '';

  /// 获取系统语言
  String get systemLanguage {
    return Platform.localeName; // 例如: en-US, zh-CN
  }

  /// 获取应用语言 (简化版本)
  String get appLanguage {
    final locale = Platform.localeName.split('_').first;
    return locale; // 例如: en, zh
  }

  /// 获取时区偏移 (小时)
  int get timeZone {
    final offset = DateTime.now().timeZoneOffset;
    return offset.inHours;
  }

  /// 获取当前时间戳 (毫秒)
  int get currentTimestamp => DateTime.now().millisecondsSinceEpoch;

  /// 生成请求签名 b 参数
  String generateSignature() {
    // 根据实际业务规则生成签名
    // 这里使用简单的 MD5 示例，实际应该根据服务端要求
    final timestamp = currentTimestamp.toString();
    final input = '$timestamp-$deviceId-$appVersion';
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 生成 x-auth-token
  String generateAuthToken() {
    // 这里生成一个示例 token，实际应该根据服务端要求
    final timestamp = currentTimestamp.toString();
    final input = '$deviceId-$timestamp-$appVersion-secret';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

