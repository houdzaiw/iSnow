import 'package:flutter_test/flutter_test.dart';
import 'package:project/lib_main.dart';

void main() {
  testWidgets('shows login actions after launch', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('登录'), findsOneWidget);
    expect(find.text('注册'), findsOneWidget);
  });
}
