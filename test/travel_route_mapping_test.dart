import 'package:flutter_test/flutter_test.dart';

import 'package:project/core/travel_bootstrap/travel_bootstrap_config.dart';
import 'package:project/core/travel_bootstrap/travel_route_resolver.dart';
import 'package:project/manager/http_api.dart';

void main() {
  test('maps hasUser to the Travel obfuscated token', () {
    const expectedToken = 'cJpmmSkf4QW6w9sbNhG3NLYTiVJQyKfv6hL_xEDdp6M';

    expect(TravelBootstrapConfig.tokenFor('user.hasUser'), expectedToken);
    expect(
      TravelRouteResolver.tokenForPath('/api/user/hasUser'),
      expectedToken,
    );
    expect(HttpApi.hasUser, expectedToken);
    expect(TravelRouteResolver.tokenForPath(HttpApi.hasUser), expectedToken);
    expect(
      TravelRouteResolver.routeNameForPath(HttpApi.hasUser),
      'user.hasUser',
    );
  });

  test('builds the real Travel route URL from the mapped token', () {
    const token = 'cJpmmSkf4QW6w9sbNhG3NLYTiVJQyKfv6hL_xEDdp6M';
    final uri = TravelRouteResolver.resolve(
      Uri.parse('https://api.example.test/lvy'),
      token,
    );

    expect(uri.toString(), 'https://api.example.test/lvy/api/r/$token');
  });
}
