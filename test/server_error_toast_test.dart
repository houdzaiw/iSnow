import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/oauth/login_detail_page.dart';
import 'package:project/classes/oauth/provider/login_provider.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/model/country_info.dart';
import 'package:project/model/server_response.dart';
import 'package:project/model/user_profile.dart';
import 'package:project/theme/app_theme.dart';

void main() {
  const text = 'Network anomaly, pleaselogin again.';
  final options = RequestOptions(path: '/api/user/hasUser');
  for (final error in [
    NadyServerResponse<void>.fromJson(const {
      'code': 8011,
      'msg': text,
      'message': 'Internal fallback',
      'traceId': 'has-user-error',
    }, null).toException(),
    DioException.badResponse(
      statusCode: 500,
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 500,
        data: {'msg': text, 'message': 'Internal fallback'},
      ),
    ),
  ]) {
    testWidgets(
      'hasUser toast displays only server text for ${error.runtimeType}',
      (tester) async {
        final repository = _LoginRepository(error);
        await _openLogin(tester, repository);
        await tester.enterText(find.byType(TextField).first, '123456789');
        await tester.pump(const Duration(milliseconds: 601));
        await tester.pumpAndSettle();
        final toast = find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(text),
        );
        expect(toast, findsOneWidget);
        expect(find.text('Internal fallback'), findsNothing);
        expect(find.textContaining('NadyApiException('), findsNothing);
        expect(find.textContaining('traceId='), findsNothing);
        expect(repository.checks, 1);

        // Submit retries the check and must not replace msg with a generic error.
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(repository.checks, 2);
        expect(toast, findsOneWidget);
        expect(find.text('Failed to check account status'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final error in [
    StateError('offline'),
    NadyServerResponse<void>.fromJson(const {
      'code': 8011,
      'msg': '',
    }, null).toException(),
  ]) {
    testWidgets(
      'errors without server text keep the local fallback: ${error.runtimeType}',
      (tester) async {
        final repository = _LoginRepository(error);
        await _openLogin(tester, repository);
        await tester.enterText(find.byType(TextField).first, '123456789');
        await tester.pump(const Duration(milliseconds: 601));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        final toast = tester.widget<Text>(
          find
              .descendant(
                of: find.byType(SnackBar),
                matching: find.byType(Text),
              )
              .first,
        );
        expect(toast.data, 'Failed to check account status');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'late hasUser failure cannot show a toast after leaving the page',
    (tester) async {
      final repository = _LoginRepository(const NadyApiException(message: text))
        ..gate = Completer<void>();
      await _openLogin(tester, repository);
      await tester.enterText(find.byType(TextField).first, '123456789');
      await tester.pump(const Duration(milliseconds: 601));
      expect(repository.checks, 1);
      await tester.pumpWidget(const SizedBox());
      repository.gate!.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _openLogin(WidgetTester tester, LoginProvider repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [loginRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const LoginDetailPage(
          initialAreaCode: '1',
          initialCountryCode: 'US',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _LoginRepository extends LoginProvider {
  _LoginRepository(this.error);
  final Object error;
  int checks = 0;
  Completer<void>? gate;
  @override
  Future<List<CountryInfo>> getSupportedCountries() async => const [];
  @override
  Future<HasUserResponse> hasUser({
    required String phone,
    required String areaCode,
  }) async {
    checks++;
    await gate?.future;
    throw error;
  }
}
