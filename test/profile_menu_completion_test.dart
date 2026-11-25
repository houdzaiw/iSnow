import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/profile/honor/honor_models.dart';
import 'package:project/classes/profile/honor/honor_repository.dart';
import 'package:project/classes/profile/honor/honor_view_model.dart';
import 'package:project/classes/profile/settings/about_view_model.dart';
import 'package:project/classes/profile/settings/blacklist_view_model.dart';
import 'package:project/classes/profile/store/backpack_gift.dart';
import 'package:project/classes/profile/store/backpack_view_model.dart';
import 'package:project/classes/profile/store/store_models.dart';
import 'package:project/classes/profile/store/store_repository.dart';
import 'package:project/classes/profile/tools/profile_tools_config.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/profile_app_info_manager.dart';
import 'package:project/model/server_response.dart';
import 'package:project/model/user_profile.dart';
import 'support/profile_tools_fakes.dart';

Map<String, dynamic> badge(String id, {int current = 1, String? expiry}) => {
  'id': id,
  'medalType': 1,
  'medalName': '中文',
  'medalNameEn': 'English',
  'currentStage': current,
  'medalStages': [
    {
      'stage': 1,
      'desc': '说明\n第二行',
      'descEn': 'Description',
      'icon': '',
      if (expiry != null) 'expireTime': expiry,
    },
  ],
};
Map<String, dynamic> me({
  int vip = 5,
  int noble = 0,
  List<String> medals = const ['a'],
}) => {
  'userBaseInfo': {
    'uid': 10,
    'userLevel': {'vipLevel': vip, 'aristocracyLevel': noble},
    'userWearMedalVOS': [
      for (var i = 0; i < medals.length; i++)
        {'id': medals[i], 'icon': '', 'sortingOrder': i},
    ],
  },
};
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class TestAppManager extends ProfileAppInfoManager {
  int opens = 0;
  bool launchResult = true;
  Object? failure;
  @override
  Future<ProfileAppInfo> read(String language) async {
    if (failure != null) throw failure!;
    return ProfileAppInfo('3.2.1+123', {
      'app': 'actual-package-name',
      'appVersion': '3.2.1',
      'appVersionCode': '123',
      'appLanguage': language,
    });
  }

  @override
  Future<bool> open(Uri uri) async {
    opens++;
    return launchResult;
  }
}

void main() {
  late ProfileToolsFake f;
  setUp(() {
    f = ProfileToolsFake();
    f.data[HttpApi.myUserInfo] = me();
    f.data[HttpApi.medalWearingNum] = {'wearingNum': 8};
    f.data[HttpApi.medalShowList] = [badge('a'), badge('b'), badge('c')];
    f.data[HttpApi.medalAchieved] = [
      {'id': 'a', 'icon': ''},
    ];
    f.data[HttpApi.userBlacklist] = {'list': []};
  });
  test('old cache and worn medal ordering survive refresh/copy/JSON', () {
    expect(UserData.fromJson({'uid': 10}).wornMedals, isEmpty);
    final json = {
      'uid': 10,
      'userWearMedalVOS': [
        {'id': 'b', 'sortingOrder': 2},
        {'id': 'a', 'sortingOrder': 1},
        {'id': ''},
      ],
    };
    expect(
      UserData.fromJson(
        UserData.fromJson(json).copyWith(nick: 'new').toJson(),
      ).wornMedals.map((m) => m.id),
      ['a', 'b'],
    );
  });
  test(
    'medal dates handle seconds, milliseconds, invalid and permanent values',
    () {
      expect(HonorStage.date(1700000000), HonorStage.date(1700000000000));
      for (final value in [
        null,
        -1,
        0,
        double.nan,
        double.infinity,
        'invalid',
      ]) {
        expect(HonorStage.date(value), isNull);
      }
      expect(HonorBadge.fromJson(badge('a')).wearable(DateTime.now()), isTrue);
      expect(
        HonorBadge.fromJson(
          badge('b', expiry: '2000-01-01T00:00:00Z'),
        ).wearable(DateTime.now()),
        isFalse,
      );
      final unowned = HonorBadge.fromJson(badge('a', current: 0));
      expect(unowned.ownedStage, isNull);
      expect(unowned.title('ar'), 'English');
      expect(unowned.displayStage!.text('zh'), '说明\n第二行');
    },
  );
  for (final entry in {0: 3, 4: 6, 5: 8, 6: 10}.entries) {
    test('server/noble cap for noble ${entry.key}', () async {
      f.data[HttpApi.myUserInfo] = me(noble: entry.key);
      f.data[HttpApi.medalWearingNum] = {'wearingNum': 20};
      final repo = HonorRepository(f.features);
      expect((await repo.equipment()).limit, entry.value);
      f.data[HttpApi.medalWearingNum] = {'wearingNum': 2};
      expect((await repo.equipment()).limit, 2);
    });
  }
  test(
    'missing medal limit blocks editing and cannot silently assume zero',
    () async {
      f.data[HttpApi.medalWearingNum] = {};
      final model = HonorViewModel(HonorRepository(f.features));
      addTearDown(model.dispose);
      await settle();
      model.edit();
      expect(model.state.editing, isFalse);
      expect(model.state.error, isNotNull);
      expect(f.count(HttpApi.medalWear), 0);
    },
  );
  test(
    'medal draft add/remove/reorder/cancel has no writes; save preserves order',
    () async {
      final model = HonorViewModel(HonorRepository(f.features));
      addTearDown(model.dispose);
      await settle();
      model.edit();
      model.toggle(HonorBadge.fromJson(badge('b')));
      model.move(0, 2);
      expect(model.state.draft, ['b', 'a']);
      model.cancel();
      expect(model.state.draft, ['a']);
      expect(f.count(HttpApi.medalWear), 0);
      model.edit();
      model.remove('a');
      model.toggle(HonorBadge.fromJson(badge('b')));
      final result = await model.save();
      expect(result, true);
      expect(f.calls.where((c) => c.path == HttpApi.medalWear).single.params, {
        'medalIds': ['b'],
      });
      expect(model.state.editing, false);
      expect(f.refreshes, 1);
    },
  );
  test('medal save failure retains editing and draft, msg preferred', () async {
    final model = HonorViewModel(HonorRepository(f.features));
    addTearDown(model.dispose);
    await settle();
    model.edit();
    model.remove('a');
    f.envelopes[HttpApi.medalWear] = {
      'code': 1002,
      'message': 'fallback',
      'msg': 'precise reason',
    };
    expect(await model.save(), isNull);
    expect(model.state.editing, true);
    expect(model.state.draft, isEmpty);
    expect((model.state.error as NadyApiException).message, 'precise reason');
  });
  test(
    'expired/unowned/duplicate/over-limit medal selections cannot submit',
    () async {
      final repo = HonorRepository(f.features);
      for (final ids in [
        ['a', 'a'],
        ['a', 'b', 'c', 'd'],
        ['unknown'],
      ]) {
        await expectLater(
          repo.save(ids, f.account, () => true),
          throwsA(isA<NadyApiException>()),
        );
      }
      f.data[HttpApi.medalShowList] = [badge('a', current: 0)];
      await expectLater(
        repo.save(['a'], f.account, () => true),
        throwsA(isA<NadyApiException>()),
      );
      expect(f.count(HttpApi.medalWear), 0);
    },
  );
  test(
    'medal duplicate save coalesces; disposal while preflight prevents submission',
    () async {
      final model = HonorViewModel(HonorRepository(f.features));
      await settle();
      model.edit();
      f.held = HttpApi.medalWearingNum;
      f.gate = Completer<void>();
      final pending = model.save();
      await settle();
      expect(await model.save(), isNull);
      model.dispose();
      f.gate!.complete();
      await pending;
      expect(f.count(HttpApi.medalWear), 0);
    },
  );
  test(
    'achieved count coalesces requests and failed fetch can retry',
    () async {
      final repo = HonorRepository(f.features);
      await Future.wait([
        repo.achieved(force: true),
        repo.achieved(force: true),
      ]);
      expect(f.count(HttpApi.medalAchieved), 1);
      f.errors[HttpApi.medalAchieved] = StateError('offline');
      await expectLater(repo.achieved(force: true), throwsStateError);
      f.errors.clear();
      expect(await repo.achieved(), hasLength(1));
      expect(f.count(HttpApi.medalAchieved), 3);
      expect(f.calls.last.params, {'targetUid': 10});
    },
  );
  test(
    'gift and type9 inventory with same ID remain distinct and preserve expiration',
    () async {
      f.data[HttpApi.backpackGifts] = [
        {
          'giftId': 1,
          'giftName': 'gift',
          'amount': 3,
          'nearestExpireTimestamp': 1700000000000,
        },
      ];
      f.data[HttpApi.backpackUserProps] = [
        {'goodsId': 1, 'name': 'prop', 'amount': 2},
      ];
      final items = await BackpackGiftRepository(f.features).load();
      expect(items.map((i) => i.amount), [3, 2]);
      expect(items.map((i) => i.key).toSet(), hasLength(2));
      expect(items.first.expiresAt, HonorStage.date(1700000000000));
      expect(
        f.calls
            .where(
              (c) => [
                HttpApi.backpackGifts,
                HttpApi.backpackUserProps,
              ].contains(c.path),
            )
            .every((c) => c.method == 'GET' && c.params.isEmpty),
        true,
      );
    },
  );
  test(
    'Nady null inventories are empty; malformed objects remain errors',
    () async {
      f.data[HttpApi.backpackGifts] = null;
      f.data[HttpApi.backpackUserProps] = null;
      expect(await BackpackGiftRepository(f.features).load(), isEmpty);
      f.data[HttpApi.medalShowList] = null;
      expect(await HonorRepository(f.features).badges(1), isEmpty);
      f.data[HttpApi.backpackGifts] = {'bad': true};
      await expectLater(
        BackpackGiftRepository(f.features).load(),
        throwsA(isA<NadyApiException>()),
      );
    },
  );
  test(
    'transfer is owned id, never goodsId or purchase; refresh failure remains success',
    () async {
      final repo = StoreRepository(f.features),
          prop = OwnedProp.fromJson(ProfileToolsFake.prop(id: 7));
      f.data[HttpApi.profileProps] = [ProfileToolsFake.prop(id: 7)];
      final order = await repo.prepareTransfer(prop, 88, f.account);
      f.failRefresh = true;
      expect(await repo.transfer(order, () => true), false);
      expect(
        f.calls.where((c) => c.path == HttpApi.backpackTransfer).single.params,
        {'targetUid': 88, 'id': 7},
      );
      expect(f.count(HttpApi.storePurchase), 0);
    },
  );
  test(
    'VIP downgrade, invalid recipient, own UID, expired or removed prop cannot transfer',
    () async {
      final repo = StoreRepository(f.features),
          prop = OwnedProp.fromJson(ProfileToolsFake.prop());
      await expectLater(
        repo.prepareTransfer(prop, 10, f.account),
        throwsA(isA<NadyApiException>()),
      );
      f.data[HttpApi.myUserInfo] = me(vip: 4);
      await expectLater(
        repo.prepareTransfer(prop, 88, f.account),
        throwsA(isA<NadyApiException>()),
      );
      f.data[HttpApi.myUserInfo] = me();
      final order = await repo.prepareTransfer(prop, 88, f.account);
      f.data[HttpApi.profileProps] = [];
      await expectLater(
        repo.transfer(order, () => true),
        throwsA(isA<NadyApiException>()),
      );
      f.data[HttpApi.profileProps] = [ProfileToolsFake.prop()];
      f.data[HttpApi.userHomepage] = {
        'info': {
          'blocked': true,
          'userBaseInfo': {'uid': 88, 'userStatus': 'USER_STATUS_NORMAL'},
        },
      };
      await expectLater(
        repo.transfer(order, () => true),
        throwsA(isA<NadyApiException>()),
      );
      expect(f.count(HttpApi.backpackTransfer), 0);
    },
  );
  test('transfer closed/changed account cannot submit', () async {
    final repo = StoreRepository(f.features),
        prop = OwnedProp.fromJson(ProfileToolsFake.prop());
    final order = await repo.prepareTransfer(prop, 88, f.account);
    await expectLater(
      repo.transfer(order, () => false),
      throwsA(isA<NadyApiException>()),
    );
    f.account = (uid: 11, token: 'new', generation: 2);
    await expectLater(
      repo.transfer(order, () => true),
      throwsA(isA<NadyApiException>()),
    );
    expect(f.count(HttpApi.backpackTransfer), 0);
  });
  test(
    'backpack transfer locks duplicate entry and unlocks on cancel',
    () async {
      final model = BackpackViewModel(
        StoreRepository(f.features),
        StoreCategory.avatar,
      );
      addTearDown(model.dispose);
      await settle();
      expect(await model.beginTransfer(), true);
      expect(await model.beginTransfer(), false);
      model.endTransfer();
      expect(model.state.busy, false);
      expect(f.count(HttpApi.backpackTransfer), 0);
    },
  );
  test(
    'server blacklist pagination deduplicates and preserves internal UID',
    () async {
      f.data[HttpApi.userBlacklist] = {
        'list': [
          for (var i = 1; i <= 20; i++)
            {
              'targetUserInfo': {
                'uid': i,
                'userNo': 10000 + i,
                'nick': 'User$i',
              },
            },
        ],
      };
      final model = BlacklistViewModel(BlacklistRepository(f.features));
      addTearDown(model.dispose);
      await settle();
      expect(model.state.more, true);
      f.data[HttpApi.userBlacklist] = {
        'list': [
          {
            'targetUserInfo': {'uid': 20, 'userNo': 10020},
          },
          {
            'targetUserInfo': {'uid': 21, 'userNo': 10021},
          },
        ],
      };
      await model.load(more: true);
      expect(model.state.items, hasLength(21));
      expect(model.state.more, false);
      expect(
        f.calls.where((c) => c.path == HttpApi.userBlacklist).last.params,
        {'pageNum': 2, 'pageSize': 20},
      );
      f.envelopes[HttpApi.userBlacklistUpdate] = {
        'code': 1003,
        'msg': 'Cannot remove',
      };
      expect(await model.remove(21), false);
      expect(model.state.items, hasLength(21));
      expect(f.calls.last.params, {'targetUid': 21, 'blackOrNot': false});
      f.envelopes.clear();
      f.data[HttpApi.userBlacklist] = {'list': []};
      expect(await model.remove(21), true);
      expect(model.state.items, isEmpty);
    },
  );
  test(
    'blacklist late fetch after disposal or account change cannot update list',
    () async {
      f.held = HttpApi.userBlacklist;
      f.gate = Completer<void>();
      final model = BlacklistViewModel(BlacklistRepository(f.features));
      await settle();
      model.dispose();
      f.account = (uid: 11, token: 'new', generation: 2);
      f.gate!.complete();
      await settle();
      expect(f.count(HttpApi.userBlacklistUpdate), 0);
    },
  );
  test(
    'About only loads actual package metadata until explicit check',
    () async {
      final manager = TestAppManager(),
          model = AboutViewModel(AboutRepository(f.features, TestAppManager()));
      addTearDown(model.dispose);
      await settle();
      expect(model.state.info!.version, '3.2.1+123');
      expect(f.count(HttpApi.appVersion), 0);
      f.data[HttpApi.appVersion] = {'needUpdate': false};
      await model.check();
      expect(model.state.checked, true);
      expect(model.state.update!.needUpdate, false);
      expect(f.calls.last.method, 'POST');
      expect(f.calls.last.params['appVersionCode'], '123');
      expect(manager.opens, 0);
    },
  );
  test('update failure is not latest and invalid URL cannot launch', () async {
    final manager = TestAppManager(),
        model = AboutViewModel(AboutRepository(f.features, manager));
    addTearDown(model.dispose);
    await settle();
    f.envelopes[HttpApi.appVersion] = {
      'code': 1003,
      'msg': 'Version unavailable',
    };
    await model.check();
    expect(model.state.checked, false);
    expect(model.state.error, isA<NadyApiException>());
    f.envelopes.clear();
    f.data[HttpApi.appVersion] = {
      'needUpdate': true,
      'skipUrl': 'javascript:alert(1)',
    };
    await model.check();
    await model.open();
    expect(manager.opens, 0);
    expect(model.state.update!.url, isNull);
    f.data[HttpApi.appVersion] = {
      'needUpdate': true,
      'title': 'New',
      'explain': 'Details',
      'skipUrl': 'https://example.org/app',
    };
    await model.check();
    expect(manager.opens, 0);
    await model.open();
    expect(manager.opens, 1);
    manager.launchResult = false;
    await model.open();
    expect(model.state.error, isNotNull);
  });
  test(
    'update repeat clicks coalesce and late result cannot launch after close',
    () async {
      final manager = TestAppManager(),
          model = AboutViewModel(AboutRepository(f.features, manager));
      await settle();
      f.held = HttpApi.appVersion;
      f.gate = Completer<void>();
      f.data[HttpApi.appVersion] = {
        'needUpdate': true,
        'skipUrl': 'https://example.org/app',
      };
      final pending = model.check();
      await settle();
      await model.check();
      expect(f.count(HttpApi.appVersion), 1);
      model.dispose();
      f.gate!.complete();
      await pending;
      expect(manager.opens, 0);
    },
  );
  test('protocols and Level have real URLs and encoded current language', () {
    expect(ProfileToolsConfig.privacy, endsWith('/policy.html'));
    expect(ProfileToolsConfig.terms, endsWith('/protocol.html'));
    final uri = const ProfileToolsConfig().level('zh');
    expect(uri.path, '/h5/userlevel/index.html');
    expect(uri.queryParameters['language'], 'zh');
  });
}
