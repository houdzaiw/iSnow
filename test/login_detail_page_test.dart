import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/oauth/login_detail_page.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/theme/app_theme.dart';

void main() {
  testWidgets('opens country code picker from login detail page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          supportedLocales: const [Locale('en'), Locale('zh')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginDetailPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Please enter your phone number'), findsOneWidget);
    expect(find.text('+996'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('country_code_picker')));
    await tester.pumpAndSettle();

    expect(find.text('Country code'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
  });
}
