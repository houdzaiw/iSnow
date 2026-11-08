import 'package:flutter_test/flutter_test.dart';
import 'package:project/configs/app_routers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production router registers the friends activity page on startup', () {
    const path = '/party/friends-activity';
    expect(goRouter.namedLocation('friends-activity'), path);
    final match = goRouter.configuration.findMatch(Uri.parse(path));
    expect(match.isError, isFalse);
    expect(match.last.route.name, 'friends-activity');
  });

  tearDownAll(() => goRouter.dispose());
}
