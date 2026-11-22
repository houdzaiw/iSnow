import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/gift/recharge/room_first_recharge_models.dart';
import 'package:project/classes/room/gift/recharge/room_first_recharge_repository.dart';
import 'package:project/classes/room/gift/recharge/room_first_recharge_sheet.dart';
import 'package:project/classes/room/gift/recharge/room_first_recharge_view_model.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/wallet/wallet_models.dart';
import 'package:project/classes/wallet/wallet_payment_service.dart';
import 'package:project/classes/wallet/wallet_repository.dart';
import 'package:project/classes/wallet/wallet_state.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/server_response.dart';
import 'package:project/theme/app_theme.dart';

import 'support/room_lifecycle_fakes.dart';

RoomFirstRechargePack pack({bool buy = true}) =>
    RoomFirstRechargePack.fromJson({
      'id': 'first_google_pack',
      'name': 'First gift package',
      'dollarAmount': 199,
      'originalPrice': 399,
      'coinAmount': 100,
      'sortNo': 1,
      'isBuy': buy,
    });
WalletPurse purse(bool first) =>
    WalletPurse(uid: 10, coin: 100, diamond: 0, usd: 0, isFirst: first);
RoomRepository roomFor(RoomLifecycleFixture f) => RoomRepository(
  roomManager: f.manager,
  socketManager: f.socket,
  agoraManager: f.agora,
  httpManager: f.http,
  authSession: f.auth,
);

void main() {
  test(
    'Nady package fields, isBuy meaning, cents and reward types are preserved',
    () {
      final p = RoomFirstRechargePack.fromJson({
        'id': 'first_google_pack',
        'dollarAmount': 199,
        'originalPrice': 399,
        'isBuy': true,
        'rewardPack': {
          'resourceVOList': [
            {
              'prizeName': 'Rose',
              'prizeIcon': '',
              'goodsConsumeType': 1,
              'amount': 3,
            },
            {
              'name': 'Frame',
              'goodsConsumeType': 2,
              'durationType': 2,
              'durationMillis': 259200000,
            },
            {'name': 'Car', 'goodsConsumeType': 2, 'durationType': 1},
          ],
        },
      });
      expect(p.price, 'USD 1.99');
      expect(p.purchasable, isTrue);
      expect(p.paymentProduct.id, 'first_google_pack');
      expect(p.paymentProduct.useType, 2);
      expect(p.rewards[0].amount, 3);
      expect(p.rewards[1].days, 3);
      expect(p.rewards[2].permanent, isTrue);
      expect(pack(buy: false).purchasable, isFalse);
    },
  );
  test('GET giftBag has no invented parameters; errors prefer msg', () async {
    final http = _Http();
    final repo = RoomFirstRechargeRepository(http, _Wallet());
    expect((await repo.fetchPacks()).single.id, 'first_google_pack');
    expect(http.calls, [HttpApi.walletFirstRechargePacks]);
    expect(http.query, isNull);
    http.error = true;
    await expectLater(
      repo.fetchPacks(),
      throwsA(
        isA<NadyApiException>().having(
          (e) => e.message,
          'msg',
          'Gift bag server msg',
        ),
      ),
    );
  });

  late RoomLifecycleFixture f;
  late _Repository repo;
  late RoomFirstRechargeViewModel vm;
  final calls = <WalletRechargeProduct>[];
  Future<void> open({
    Future<void> Function(WalletRechargeProduct, bool Function())? purchase,
    void Function()? onVerified,
  }) async {
    f = RoomLifecycleFixture();
    await f.enter();
    repo = _Repository();
    calls.clear();
    vm = RoomFirstRechargeViewModel(
      'first',
      repo,
      roomFor(f),
      onVerified: onVerified,
      purchase:
          purchase ??
          (p, valid) async {
            if (valid()) calls.add(p);
          },
    );
    await f.flush();
    addTearDown(() async {
      if (vm.mounted) vm.dispose();
      await f.dispose();
    });
  }

  test('viewing loads purse/packs only; no purchase is initiated', () async {
    await open();
    expect(vm.state.canBuy, isTrue);
    expect(calls, isEmpty);
    expect(repo.purseCalls, 1);
    expect(repo.packCalls, 1);
  });
  test('non-first users never query gift packs or purchase', () async {
    await open();
    repo.first = false;
    await vm.load();
    await vm.buy();
    expect(vm.state.eligible, isFalse);
    expect(calls, isEmpty);
    expect(repo.packCalls, 1);
  });
  test(
    'package unavailable or eligibility lost before click blocks order',
    () async {
      await open();
      repo.items = [pack(buy: false)];
      await vm.buy();
      expect(calls, isEmpty);
      expect(vm.state.error, 'room.gift.firstRechargeUnavailable');
      repo.items = [pack()];
      await vm.load();
      repo.first = false;
      await vm.buy();
      expect(calls, isEmpty);
    },
  );
  test(
    'repeated buy clicks merge and same selected product reaches shared billing',
    () async {
      final gate = Completer<void>();
      await open(
        purchase: (p, valid) async {
          calls.add(p);
          await gate.future;
        },
      );
      final task = vm.buy();
      await vm.buy();
      await f.flush();
      expect(calls.single.id, 'first_google_pack');
      expect(vm.state.paying, isTrue);
      gate.complete();
      await task;
      vm.paymentChanged(
        const WalletState(purchaseProductId: 'first_google_pack'),
        const WalletState(noticeKey: 'wallet.paymentCanceled'),
      );
      expect(vm.state.paying, isFalse);
      expect(vm.state.error, 'wallet.paymentCanceled');
    },
  );
  test(
    'account change during validation discards old response before payment',
    () async {
      await open();
      repo.gate = Completer<WalletPurse>();
      final task = vm.buy();
      await f.auth.clear();
      repo.gate!.complete(purse(true));
      await task;
      expect(vm.state.active, isFalse);
      expect(calls, isEmpty);
    },
  );
  test('room switch invalidates the billing launch predicate', () async {
    bool Function()? predicate;
    await open(
      purchase: (p, valid) async {
        calls.add(p);
        predicate = valid;
      },
    );
    await vm.buy();
    expect(predicate!(), isTrue);
    await f.manager.leaveRoom();
    expect(predicate!(), isFalse);
    expect(vm.state.active, isFalse);
  });
  test(
    'gateway server error preserves packages and allows explicit retry',
    () async {
      var attempted = 0;
      await open(
        purchase: (p, valid) async {
          attempted++;
          throw const NadyApiException(message: 'Use another payment method');
        },
      );
      await vm.buy();
      expect(attempted, 1);
      expect(vm.state.error, 'Use another payment method');
      expect(vm.state.canBuy, isTrue);
      await f.flush();
      expect(attempted, 1);
    },
  );
  test(
    'payment success waits for server eligibility; does not automatically buy again',
    () async {
      var verified = 0;
      await open(onVerified: () => verified++);
      await vm.buy();
      vm.paymentChanged(
        const WalletState(purchaseProductId: 'unrelated'),
        const WalletState(noticeKey: 'wallet.paymentSuccess'),
      );
      expect(vm.state.paying, isTrue);
      vm.paymentChanged(
        const WalletState(purchaseProductId: 'first_google_pack'),
        const WalletState(noticeKey: 'wallet.paymentSuccess'),
      );
      await f.flush();
      expect(vm.state.confirming, isTrue);
      expect(vm.state.canBuy, isFalse);
      expect(verified, 0);
      await vm.buy();
      expect(calls, hasLength(1));
      repo.first = false;
      await vm.load();
      expect(vm.state.completed, isTrue);
      expect(vm.state.confirming, isFalse);
      expect(verified, 1);
      await vm.load();
      expect(verified, 1);
    },
  );
  test(
    'disposal during pending package request prevents state write and purchase',
    () async {
      await open();
      repo.packGate = Completer<List<RoomFirstRechargePack>>();
      final task = vm.load();
      await f.flush();
      vm.dispose();
      repo.packGate!.complete([pack()]);
      await task;
      expect(calls, isEmpty);
    },
  );

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'first package sheet at $width never initializes billing merely to render',
      (tester) async {
        final fixture = RoomLifecycleFixture();
        await tester.runAsync(() => fixture.enter());
        tester.view.physicalSize = Size(width, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roomRepositoryProvider.overrideWithValue(roomFor(fixture)),
              roomFirstRechargeRepositoryProvider.overrideWithValue(
                _Repository(),
              ),
              walletPaymentServiceProvider.overrideWith(
                (ref) => throw StateError('Billing must remain uninitialized'),
              ),
            ],
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, __) => MaterialApp(
                theme: AppTheme.light,
                localizationsDelegates: const [AppLocalizations.delegate],
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () =>
                          showRoomFirstRechargeSheet(context, 'first'),
                      child: const Text('Open first pack'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open first pack'));
        await tester.pumpAndSettle();
        expect(find.text('First gift package'), findsOneWidget);
        expect(find.textContaining('100 Coins'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await fixture.auth.clear();
        await tester.pumpAndSettle();
        expect(find.byType(RoomFirstRechargeSheet), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(fixture.dispose);
      },
    );
  }
}

class _Repository extends RoomFirstRechargeRepository {
  _Repository() : super(HttpDioManager(), _Wallet());
  bool first = true;
  int purseCalls = 0, packCalls = 0;
  List<RoomFirstRechargePack> items = [pack()];
  Completer<WalletPurse>? gate;
  Completer<List<RoomFirstRechargePack>>? packGate;
  @override
  Future<WalletPurse> fetchPurse() async {
    purseCalls++;
    return gate?.future ?? purse(first);
  }

  @override
  Future<List<RoomFirstRechargePack>> fetchPacks() async {
    packCalls++;
    return packGate?.future ?? items;
  }
}

class _Wallet extends WalletRepository {
  _Wallet() : super(HttpDioManager());
  @override
  Future<WalletPurse> fetchPurse() async => purse(true);
}

class _Http implements HttpDioManager {
  bool error = false;
  final calls = <String>[];
  Map<String, dynamic>? query;
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add(path);
    query = queryParameters;
    return error
        ? {'code': 1003, 'message': 'fallback', 'msg': 'Gift bag server msg'}
        : {
            'code': 200,
            'data': [
              {'id': 'first_google_pack', 'isBuy': true, 'dollarAmount': 199},
            ],
          };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
