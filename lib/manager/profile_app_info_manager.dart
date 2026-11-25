import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../configs/app_device.dart';

class ProfileAppInfo {
  const ProfileAppInfo(this.version, this.params);
  final String version;
  final Map<String, dynamic> params;
}

class ProfileAppInfoManager {
  Future<ProfileAppInfo> read(String language) async {
    final package = await PackageInfo.fromPlatform();
    final device = AppDevice();
    return ProfileAppInfo('${package.version}+${package.buildNumber}', {
      'deviceId': device.deviceId,
      'app': package.appName,
      'appVersion': package.version,
      'appVersionCode': package.buildNumber,
      'channel': const String.fromEnvironment('CHANNEL', defaultValue: 'DEV'),
      'systemLanguage': device.systemLocale,
      'appLanguage': language,
      'isp': '',
      'countryCode': device.countryCode,
      'model': device.model,
      'os': device.os,
      'osVersion': device.osVersion,
      'deviceBrand': device.deviceBrand,
    });
  }

  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
