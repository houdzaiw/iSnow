import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/oauth/register_page.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders sms code input below phone field on register page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        supportedLocales: const [Locale('en'), Locale('zh')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const RegisterPage(
          initialPhone: '13212345678',
          initialAreaCode: '996',
          initialCountryCode: 'KG',
          enableCountryCodeLookup: false,
        ),
      ),
    );

    await tester.pump();

    final phoneLabel = find.text('Phone number');
    final smsLabel = find.text('SMS code');

    expect(phoneLabel, findsOneWidget);
    expect(smsLabel, findsOneWidget);
    expect(find.byKey(const ValueKey('register_phone_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('register_sms_field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('register_send_code_button')),
      findsOneWidget,
    );
    expect(find.text('Send code'), findsOneWidget);
    expect(
      tester.getTopLeft(smsLabel).dy,
      greaterThan(tester.getTopLeft(phoneLabel).dy),
    );
  });
}
