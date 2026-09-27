import 'travel_bootstrap_config.dart';
import 'travel_bootstrap_exception.dart';

/// 将 iSnow 的接口路径或已混淆的 Travel Token 解析成路由。
///
/// 服务端实际接收的地址不是原始路径，例如
/// `/api/user/hasUser` 会被发送到 `/api/r/<mapped-token>`。
final class TravelRouteResolver {
  const TravelRouteResolver._();

  static const pathToRouteName = <String, String>{
    '/country-list/default-country': 'country.default',
    '/country-list/hot': 'country.hot',
    '/country-list/supported': 'country.supported',
    '/api/user/hasUser': 'user.hasUser',
    '/oauth2/sendSms': 'oauth2.sendSms',
    '/oauth2/login': 'oauth2.login',
    '/oauth2/setPassword': 'oauth2.setPassword',
    '/oauth2/verify/code': 'oauth2.verifyCode',
    '/api/user/complete': 'user.complete',
    '/api/user/mine': 'user.mine',
    '/api/user/modifyUser': 'user.modify',
    '/api/resource/header-upload-param': 'resource.headerUploadParam',
    '/oauth2/logout': 'oauth2.logout',
    '/api/user/logoff': 'user.logoff',
  };

  static final routeTokenToName = <String, String>{
    for (final entry in TravelBootstrapConfig.routeTokens.entries)
      entry.value: entry.key,
  };

  /// 返回接口对应的 Travel 路由名称。
  ///
  /// 同时接受旧的接口路径和已替换到 [HttpApi] 中的混淆 Token。
  static String routeNameForPath(String pathOrToken) {
    final routeName =
        pathToRouteName[pathOrToken] ?? routeTokenToName[pathOrToken];
    if (routeName == null) {
      throw TravelBootstrapException(
        'Travel route is not configured for $pathOrToken.',
      );
    }
    return routeName;
  }

  /// 返回接口真正请求时使用的混淆 Token。
  static String tokenForPath(String pathOrToken) {
    if (routeTokenToName.containsKey(pathOrToken)) return pathOrToken;
    return TravelBootstrapConfig.tokenFor(routeNameForPath(pathOrToken));
  }

  /// 按 travel 项目约定拼接真实请求地址。
  static Uri resolve(Uri base, String token) {
    final basePath = base.path.replaceFirst(RegExp(r'/$'), '');
    return base.replace(path: '$basePath/api/r/$token');
  }
}
