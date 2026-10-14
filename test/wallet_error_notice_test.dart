import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:project/classes/wallet/wallet_models.dart';
import 'package:project/classes/wallet/wallet_page.dart';
import 'package:project/classes/wallet/wallet_payment_service.dart';
import 'package:project/classes/wallet/wallet_repository.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/model/server_response.dart';

void main() {
  testWidgets(
    'wallet load failure uses the server text instead of a notice key',
    (tester) async {
      final billing = _Billing();
      addTearDown(billing.purchases.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletRepositoryProvider.overrideWithValue(_WalletRepository()),
            walletPaymentServiceProvider.overrideWithValue(billing),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('en')],
              home: WalletPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Please log in again'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('traceId='), findsNothing);
      expect(find.textContaining('NadyApiException('), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _WalletRepository extends WalletRepository {
  _WalletRepository() : super(HttpDioManager());
  @override
  Future<WalletPurse> fetchPurse() async =>
      throw NadyServerResponse<void>.fromJson(const {
        'code': 8011,
        'msg': 'Please log in again',
        'message': 'Internal fallback',
        'traceId': 'wallet-error',
      }, null).toException();
  @override
  Future<List<WalletRechargeProduct>> fetchRechargePackages() async => const [];
}

class _Billing implements WalletPaymentService {
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;
  @override
  Future<bool> isAvailable() async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
