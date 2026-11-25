import '../../../configs/app_configs.dart';
import '../../../configs/app_enum.dart';

class ProfileToolsConfig {
  const ProfileToolsConfig();
  static const brand = 'iSnow';
  static const privacy = 'https://www.simisoul.com/policy.html';
  static const terms = 'https://www.simisoul.com/protocol.html';
  Uri level(String language) => page('/h5/userlevel/index.html', language);
  String get origin => AppConfig.shared.appEnv == AppEnv.product
      ? 'https://www.simisoul.com'
      : 'https://www.simijoy.com';
  Uri page(String path, String language) => Uri.parse(
    '$origin$path',
  ).replace(queryParameters: {'language': language});
  bool trusted(Uri uri) =>
      uri.scheme == 'https' && uri.userInfo.isEmpty && uri.origin == origin;
}
