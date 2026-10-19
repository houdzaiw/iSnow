import '../../../configs/app_configs.dart';
import '../../../configs/app_enum.dart';
import '../../../manager/http_dio_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final roomToolsConfigProvider = Provider<RoomToolsConfig>(
  (ref) => const RoomToolsConfig(),
);

/// Supply branded integration values with --dart-define, never Nady defaults.
class RoomToolsConfig {
  const RoomToolsConfig();
  String get apiBase => switch (AppConfig.shared.appEnv) {
    AppEnv.product => HttpDioManager.prodBaseUrl,
    AppEnv.qa => HttpDioManager.qaBaseUrl,
    AppEnv.dev => HttpDioManager.devBaseUrl,
  };
  String get inviteBase =>
      const String.fromEnvironment('ISNOW_INVITE_BASE_URL');
  String get shareScheme => const String.fromEnvironment('ISNOW_SHARE_SCHEME');
  Set<String> get webBridgeHosts =>
      const String.fromEnvironment('ISNOW_WEB_BRIDGE_HOSTS')
          .split(',')
          .map((host) => host.trim().toLowerCase())
          .where((host) => host.isNotEmpty)
          .toSet();
  Set<String> get gameHosts => const String.fromEnvironment('ISNOW_GAME_HOSTS')
      .split(',')
      .map((host) => host.trim().toLowerCase())
      .where((host) => host.isNotEmpty)
      .toSet();
  Set<String> get yomiHosts => const String.fromEnvironment('ISNOW_YOMI_HOSTS')
      .split(',')
      .map((host) => host.trim().toLowerCase())
      .where((host) => host.isNotEmpty)
      .toSet();
  bool trustedGame(Uri uri) =>
      uri.hasAuthority &&
      {'http', 'https'}.contains(uri.scheme) &&
      uri.userInfo.isEmpty &&
      ((uri.origin == Uri.parse(apiBase).origin) ||
          uri.scheme == 'https' && gameHosts.contains(uri.host.toLowerCase()));
  bool trustedWebBridge(Uri uri) =>
      uri.hasAuthority &&
      {'http', 'https'}.contains(uri.scheme) &&
      uri.userInfo.isEmpty &&
      (uri.origin == Uri.parse(apiBase).origin ||
          uri.scheme == 'https' &&
              (webBridgeHosts.contains(uri.host.toLowerCase()) ||
                  gameHosts.contains(uri.host.toLowerCase())));
}
