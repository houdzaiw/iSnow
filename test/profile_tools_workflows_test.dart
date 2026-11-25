import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/profile/binding/account_binding_repository.dart';
import 'package:project/classes/profile/binding/account_binding_view_model.dart';
import 'package:project/classes/profile/rewards/daily_reward_models.dart';
import 'package:project/classes/profile/rewards/daily_reward_repository.dart';
import 'package:project/classes/profile/rewards/daily_reward_view_model.dart';
import 'package:project/classes/profile/store/backpack_view_model.dart';
import 'package:project/classes/profile/store/store_models.dart';
import 'package:project/classes/profile/store/store_recipient_sheet.dart';
import 'package:project/classes/profile/store/store_repository.dart';
import 'package:project/classes/profile/store/store_view_model.dart';
import 'package:project/manager/http_api.dart';

import 'support/profile_tools_fakes.dart';

Future<void> flush() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late ProfileToolsFake f;
  setUp(() => f = ProfileToolsFake());

  test(
    'catalog pages deduplicate, refresh errors retain items and retry page 1',
    () async {
      final model = StoreViewModel(StoreRepository(f.features));
      addTearDown(model.dispose);
      await flush();
      f.data[HttpApi.storeProducts] = {
        'shopPropList': [
          ProfileToolsFake.product(),
          ProfileToolsFake.product(id: 2),
        ],
        'totalPage': 2,
      };
      await model.load(StoreCategory.avatar, more: true);
      expect(model.state.board.items.map((p) => p.id), [1, 2]);
      expect(model.state.board.more, isFalse);
      f.errors[HttpApi.storeProducts] = StateError('offline');
      await model.load(StoreCategory.avatar);
      expect(model.state.board.items, hasLength(2));
      expect(model.state.board.failedMore, isFalse);
      expect(model.state.board.loading, isFalse);
      f.errors.clear();
      await model.load(
        StoreCategory.avatar,
        more: model.state.board.failedMore,
      );
      expect(f.calls.last.params['pageNum'], 1);
    },
  );

  test(
    'late hidden category response never changes selected category',
    () async {
      final model = StoreViewModel(StoreRepository(f.features));
      addTearDown(model.dispose);
      await flush();
      f.held = HttpApi.storeProducts;
      f.gate = Completer<void>();
      model.selectCategory(StoreCategory.ripple);
      await flush();
      model.selectCategory(StoreCategory.bubble);
      f.gate!.complete();
      await flush();
      expect(model.state.category, StoreCategory.bubble);
    },
  );

  test(
    'balance error survives tab/selection and clears only after balance refresh',
    () async {
      f.errors[HttpApi.walletPurse] = StateError('offline');
      final model = StoreViewModel(StoreRepository(f.features));
      addTearDown(model.dispose);
      await flush();
      model.selectProduct(1);
      model.selectCategory(StoreCategory.bubble);
      expect(model.state.balanceError, isNotNull);
      f.errors.clear();
      await model.refreshBalance();
      expect(model.state.balanceError, isNull);
    },
  );

  test(
    'double submit buys once; close during preflight never purchases',
    () async {
      final model = StoreViewModel(StoreRepository(f.features));
      await flush();
      final order = (await model.order())!;
      f.held = HttpApi.walletPurse;
      f.gate = Completer<void>();
      final first = model.submit(order);
      await flush();
      expect(await model.submit(order), isNull);
      model.dispose();
      f.gate!.complete();
      await expectLater(first, throwsA(anything));
      expect(f.count(HttpApi.storePurchase), 0);
    },
  );

  test(
    'double purchase while request pending is coalesced; refresh failure is success',
    () async {
      final model = StoreViewModel(StoreRepository(f.features));
      addTearDown(model.dispose);
      await flush();
      final order = (await model.order())!;
      f.held = HttpApi.storePurchase;
      f.gate = Completer<void>();
      f.failRefresh = true;
      final first = model.submit(order);
      await flush();
      expect(await model.submit(order), isNull);
      f.gate!.complete();
      expect(await first, isFalse);
      expect(f.count(HttpApi.storePurchase), 1);
    },
  );

  test('recipient edit clears result and ignores late search', () async {
    final model = StoreRecipientModel(StoreRepository(f.features));
    addTearDown(model.dispose);
    model.change('10088');
    f.held = HttpApi.userHomepage;
    f.gate = Completer<void>();
    final query = model.search();
    await flush();
    model.change('999');
    f.gate!.complete();
    await query;
    expect(model.state.user, isNull);
    expect(model.state.input, '999');
    f.held = null;
    await model.search();
    expect(model.state.user?.uid, 88);
    model.change('123');
    expect(model.state.user, isNull);
  });

  test(
    'backpack use/remove refreshes and submission cannot duplicate',
    () async {
      final model = BackpackViewModel(
        StoreRepository(f.features),
        StoreCategory.avatar,
      );
      addTearDown(model.dispose);
      await flush();
      f.held = HttpApi.profileUseProp;
      f.gate = Completer<void>();
      final use = model.use();
      await flush();
      expect(await model.use(), isNull);
      f.data[HttpApi.profileProps] = [ProfileToolsFake.prop(state: 2)];
      f.gate!.complete();
      expect(await use, isTrue);
      expect(model.state.selected!.state, 2);
      f.held = null;
      await model.use();
      expect(
        f.calls
            .where((c) => c.path == HttpApi.profileUseProp)
            .map((c) => c.params['useState']),
        [1, 0],
      );
    },
  );

  test(
    'daily independent loaders retain other error and task claims deduplicate',
    () async {
      f.errors[HttpApi.dailySignInfo] = StateError('sign offline');
      final model = DailyRewardViewModel(DailyRewardRepository(f.features));
      addTearDown(model.dispose);
      await flush();
      expect(model.state.signError, isNotNull);
      await model.loadTasks();
      expect(model.state.signError, isNotNull);
      f.held = HttpApi.dailyClaim;
      f.gate = Completer<void>();
      final first = model.submit(missionId: 1);
      await flush();
      expect(await model.submit(missionId: 1), isNull);
      f.gate!.complete();
      expect((await first)!.refreshed, isFalse);
      expect(f.count(HttpApi.dailyClaim), 1);
    },
  );

  test(
    'daily Go chooses own room for game, preserves lobby intent, never starts mode',
    () async {
      final model = DailyRewardViewModel(
        DailyRewardRepository(f.features),
        currentRoom: () => 'other',
      );
      addTearDown(model.dispose);
      await flush();
      final task = DailyTask.fromJson(ProfileToolsFake.task(id: 6, status: 1));
      expect(
        (await model.destination(task))!.kind,
        DailyDestinationKind.createRoom,
      );
      f.data[HttpApi.myUserInfo] = {
        'userBaseInfo': {'uid': 10, 'roomId': '31'},
      };
      final target = (await model.destination(task))!;
      expect(target.room!.roomId, '31');
      expect(target.lobbyType, 1);
      expect(
        (await model.destination(
          DailyTask.fromJson(ProfileToolsFake.task(id: 8, status: 1)),
        ))!.kind,
        DailyDestinationKind.binding,
      );
      expect(f.count(HttpApi.lobbyOpen), 0);
    },
  );

  test(
    'daily false result fails, and account switch never submits following request',
    () async {
      f.data[HttpApi.dailySign] = false;
      final repo = DailyRewardRepository(f.features);
      await expectLater(repo.sign(), throwsA(anything));
      expect(f.refreshes, 0);
      final model = StoreViewModel(StoreRepository(f.features));
      addTearDown(model.dispose);
      await flush();
      final order = (await model.order())!;
      f.account = (uid: 11, token: 'other', generation: 2);
      await expectLater(model.submit(order), throwsA(anything));
      expect(f.count(HttpApi.storePurchase), 0);
    },
  );

  test(
    'binding verifies old phone before new phone, requires a code for new input',
    () async {
      f.data[HttpApi.profileAccountBindings] = [
        {
          'bandingType': 5,
          'isBanding': true,
          'accountId': '55555555',
          'attachCode': '966',
        },
      ];
      final model = AccountBindingViewModel(
        AccountBindingRepository(f.features, encrypt: (s) async => 'encrypted'),
      );
      addTearDown(model.dispose);
      await flush();
      expect(model.state.verifyOld, isTrue);
      model.edit(phone: '66666666');
      expect(model.state.phone, '55555555');
      await model.send();
      model.edit(code: '1234');
      expect(await model.submit(), isNull);
      expect(model.state.verifyOld, isFalse);
      expect(model.state.verifiedOld, isTrue);
      model.edit(phone: '66666666');
      await model.send(type: 2);
      model.edit(code: '1234');
      expect(await model.submit(), isTrue);
      expect(
        f.calls
            .where((c) => c.path == HttpApi.sendSms)
            .map((c) => c.params['purpose']),
        [5, 4],
      );
      expect(
        f.calls
            .where((c) => c.path == HttpApi.profileBindPhone)
            .single
            .params['passwd'],
        '',
      );
    },
  );

  test(
    'editing phone invalidates code and cooldown; disposing pending lookup sends no SMS',
    () async {
      final model = AccountBindingViewModel(
        AccountBindingRepository(f.features),
      );
      await flush();
      model.edit(phone: '55555555', password: 'secret1');
      await model.send();
      model.edit(phone: '66666666', code: '1234');
      expect(model.state.code, isEmpty);
      await expectLater(model.submit(), throwsA(anything));
      model.dispose();
      final next = AccountBindingViewModel(
        AccountBindingRepository(f.features),
      );
      await flush();
      next.edit(phone: '77777777');
      f.held = HttpApi.hasUser;
      f.gate = Completer<void>();
      final send = next.send();
      await flush();
      next.dispose();
      f.gate!.complete();
      await expectLater(send, throwsA(anything));
      expect(f.count(HttpApi.sendSms), 1);
    },
  );

  test(
    'false verification does not bind; metadata failure does not suggest resubmit',
    () async {
      final repo = AccountBindingRepository(
        f.features,
        encrypt: (s) async => 'enc',
        savePhone: (_, _, _) async => throw StateError('disk'),
      );
      f.data[HttpApi.verifyCode] = false;
      await expectLater(
        repo.bind('55555555', '966', '1234', 'secret1', needsPassword: true),
        throwsA(anything),
      );
      expect(f.count(HttpApi.profileBindPhone), 0);
      f.data[HttpApi.verifyCode] = true;
      expect(
        await repo.bind(
          '55555555',
          '966',
          '1234',
          'secret1',
          needsPassword: true,
        ),
        isFalse,
      );
      expect(f.count(HttpApi.profileBindPhone), 1);
    },
  );
}
