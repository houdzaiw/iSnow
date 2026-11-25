import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/profile/binding/account_binding_repository.dart';
import 'package:project/classes/profile/mine/profile_menu_item.dart';
import 'package:project/classes/profile/rewards/daily_reward_repository.dart';
import 'package:project/classes/profile/store/store_models.dart';
import 'package:project/classes/profile/store/store_repository.dart';
import 'package:project/classes/profile/tools/profile_menu_repository.dart';
import 'package:project/classes/profile/tools/profile_tools_config.dart';
import 'package:project/configs/app_configs.dart';
import 'package:project/configs/app_enum.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/server_response.dart';
import 'package:project/model/user_profile.dart';

import 'support/profile_tools_fakes.dart';

void main() {
  late ProfileToolsFake f;
  setUp(() => f = ProfileToolsFake());
  test('role flags survive old cache, JSON and copy', () {
    expect(UserData.fromJson({'uid': 10}).isBd, isNull);
    final user = UserData.fromJson({
      'uid': 10,
      'roleType': 3,
      'isBd': true,
      'isCoiner': true,
    });
    final restored = UserData.fromJson(user.copyWith(nick: 'changed').toJson());
    expect(restored.isBd, isTrue);
    expect(restored.isCoiner, isTrue);
    expect(restored.roleType, 3);
  });
  for (final role in [0, 1, 2, 3]) {
    test('role $role sees only Nady authorized fixed tools', () async {
      final result = await ProfileMenuRepository(
        f.features,
      ).load(UserData(roleType: role));
      final keys = result.items.map((i) => i.titleKey).toList();
      expect(keys.contains('profile.agent'), role != 0);
      expect(keys.contains('profile.saleCoin'), role == 1 || role == 3);
      expect(keys.contains('profile.host'), isFalse);
      expect(keys.contains('profile.myTeam'), isFalse);
      expect(keys, contains('profile.dailyReward'));
    });
  }
  test(
    'BD and coiner permissions independent of role; audit disables them',
    () async {
      final repo = ProfileMenuRepository(f.features);
      final user = const UserData(roleType: 0, isBd: true, isCoiner: true);
      expect(
        (await repo.load(user)).items.map((i) => i.titleKey),
        containsAll(['profile.bd', 'profile.saleCoin']),
      );
      f.data[HttpApi.profileClientInit] = {'isVersionAuditing': true};
      final audited = await ProfileMenuRepository(f.features).load(user);
      expect(audited.items.map((i) => i.titleKey), ['profile.dailyReward']);
    },
  );
  test(
    'configuration failure is retryable and never grants role tools',
    () async {
      f.errors[HttpApi.profileClientInit] = StateError('offline');
      final repo = ProfileMenuRepository(f.features);
      final first = await repo.load(const UserData(roleType: 3));
      expect(first.error, isNotNull);
      expect(first.items, hasLength(1));
      f.errors.clear();
      expect((await repo.load(const UserData(roleType: 3))).items.length, 3);
    },
  );
  test(
    'dynamic tools preserve order, deduplicate, and hide invalid targets',
    () async {
      f.data[HttpApi.homeResourceBanner] = {
        'list': [
          {
            'id': 3,
            'name': 'Team',
            'pic': '',
            'routeUrl': 'https://example.test/team',
          },
          {
            'id': 3,
            'name': 'Duplicate',
            'routeUrl': 'https://example.test/team',
          },
          {'id': 4, 'name': 'Invalid', 'routeUrl': 'javascript:alert(1)'},
          {'id': 5, 'name': 'Backpack', 'routeUrl': 'nady:///main/me-store'},
        ],
      };
      final result = await ProfileMenuRepository(
        f.features,
      ).load(const UserData(roleType: 0));
      expect(result.items.map((i) => i.title), ['', 'Team', 'Backpack']);
      expect(
        f.calls
            .where((c) => c.path == HttpApi.homeResourceBanner)
            .single
            .params,
        {'position': 8},
      );
      expect(
        result.items.last.destination!.kind,
        ProfileDestinationKind.native,
      );
    },
  );
  test(
    'menu merges concurrent loads and rejects another account cached roles',
    () async {
      final repo = ProfileMenuRepository(f.features);
      f.held = HttpApi.homeResourceBanner;
      f.gate = Completer<void>();
      final one = repo.load(const UserData(uid: 10, roleType: 1));
      final two = repo.load(const UserData(uid: 10, roleType: 1));
      await Future<void>.delayed(Duration.zero);
      f.gate!.complete();
      await Future.wait([one, two]);
      expect(f.count(HttpApi.homeResourceBanner), 1);
      await expectLater(
        repo.load(const UserData(uid: 11, roleType: 3)),
        throwsA(anything),
      );
      expect(f.count(HttpApi.homeResourceBanner), 1);
    },
  );
  test('business H5 environment and language use actual Nady paths', () {
    final old = AppConfig.shared.appEnv;
    addTearDown(() => AppConfig.shared.appEnv = old);
    AppConfig.shared.appEnv = AppEnv.dev;
    expect(
      const ProfileToolsConfig().page('/h5/agent/invite.html', 'zh').toString(),
      'https://www.simijoy.com/h5/agent/invite.html?language=zh',
    );
    expect(
      const ProfileToolsConfig().trusted(
        Uri.parse('https://www.simijoy.com.evil.test/'),
      ),
      isFalse,
    );
    AppConfig.shared.appEnv = AppEnv.product;
    expect(const ProfileToolsConfig().origin, 'https://www.simisoul.com');
  });
  test(
    'malformed prices and unknown expiration never become free or permanent',
    () {
      for (final price in [null, 'bad', double.nan, double.infinity, 2.5]) {
        expect(
          StorePrice.fromJson({
            'currencyType': 1,
            'day': 7,
            'price': price,
          }).valid,
          isFalse,
        );
      }
      final unknown = OwnedProp.fromJson({
        ...ProfileToolsFake.prop(),
        'expireTime': 0,
      });
      expect(unknown.permanent, isFalse);
      expect(unknown.expired(DateTime.now()), isTrue);
      final forever = OwnedProp.fromJson({
        ...ProfileToolsFake.prop(),
        'expireTime': 0,
        'duration': -1,
      });
      expect(forever.expired(DateTime.now()), isFalse);
    },
  );
  test('store list uses POST pagination and actual property type', () async {
    final repo = StoreRepository(f.features);
    final result = await repo.products(StoreCategory.avatar, 2);
    expect(result.items.single.id, 1);
    expect(result.hasMore, isFalse);
    expect(f.calls.single.method, 'POST');
    expect(f.calls.single.path, HttpApi.storeProducts);
    expect(f.calls.single.params, {'type': 3, 'pageNum': 2, 'pageSize': 20});
  });
  test(
    'purchase freezes real receiver UID and selected currency/day',
    () async {
      final repo = StoreRepository(f.features);
      final product = StoreProduct.fromJson(
        ProfileToolsFake.product(currency: 2),
      );
      final order = StoreOrder(
        f.account,
        product,
        product.prices.single,
        targetUid: 88,
      );
      expect(await repo.purchase(order), isTrue);
      final call = f.calls.where((c) => c.path == HttpApi.storePurchase).single;
      expect(call.params, {
        'type': 3,
        'id': 1,
        'currencyType': 2,
        'day': 7,
        'targetUserId': 88,
      });
      expect(f.refreshes, 1);
    },
  );
  test('insufficient balance and recipient mismatch cannot submit', () async {
    final repo = StoreRepository(f.features);
    final product = StoreProduct.fromJson(
      ProfileToolsFake.product(price: 2000),
    );
    await expectLater(
      repo.purchase(StoreOrder(f.account, product, product.prices.single)),
      throwsA(isA<StoreInsufficientBalance>()),
    );
    expect(f.count(HttpApi.storePurchase), 0);
    f.data[HttpApi.userHomepage] = {
      'info': {
        'userBaseInfo': {'uid': 99, 'userStatus': 'USER_STATUS_NORMAL'},
      },
    };
    await expectLater(
      repo.purchase(
        StoreOrder(f.account, product, product.prices.single, targetUid: 88),
      ),
      throwsA(isA<NadyApiException>()),
    );
    expect(f.count(HttpApi.storePurchase), 0);
  });
  test(
    'timeout is never retried; refresh failure does not become purchase failure',
    () async {
      final repo = StoreRepository(f.features);
      final product = StoreProduct.fromJson(ProfileToolsFake.product());
      final order = StoreOrder(f.account, product, product.prices.single);
      f.errors[HttpApi.storePurchase] = TimeoutException('unknown');
      await expectLater(repo.purchase(order), throwsA(isA<TimeoutException>()));
      expect(f.count(HttpApi.storePurchase), 1);
      f.errors.clear();
      f.failRefresh = true;
      expect(await repo.purchase(order), isFalse);
    },
  );
  test(
    'closed page or changed account blocks purchase after balance wait',
    () async {
      final repo = StoreRepository(f.features);
      final product = StoreProduct.fromJson(ProfileToolsFake.product());
      f.held = HttpApi.walletPurse;
      f.gate = Completer<void>();
      var alive = true;
      final operation = repo.purchase(
        StoreOrder(f.account, product, product.prices.single),
        isCurrent: () => alive,
      );
      await Future<void>.delayed(Duration.zero);
      alive = false;
      f.gate!.complete();
      await expectLater(operation, throwsA(isA<NadyApiException>()));
      expect(f.count(HttpApi.storePurchase), 0);
    },
  );
  test(
    'owned prop expiration uses milliseconds and toggles exact Nady wire state',
    () async {
      final repo = StoreRepository(f.features);
      final prop = OwnedProp.fromJson(ProfileToolsFake.prop());
      expect(prop.expired(DateTime.utc(2031)), isTrue);
      expect(prop.expired(DateTime.utc(2026)), isFalse);
      await repo.use(prop, enable: true);
      await repo.use(prop, enable: false);
      expect(
        f.calls
            .where((c) => c.path == HttpApi.profileUseProp)
            .map((c) => c.params['useState']),
        [1, 0],
      );
      final expired = OwnedProp.fromJson(ProfileToolsFake.prop(expiry: 1000));
      await expectLater(
        repo.use(expired, enable: true),
        throwsA(isA<NadyApiException>()),
      );
      expect(f.count(HttpApi.profileUseProp), 2);
    },
  );
  test(
    'sign/claim requests and server msg retain their actual semantics',
    () async {
      final repo = DailyRewardRepository(f.features);
      expect((await repo.signInfo()).canSign, isTrue);
      expect((await repo.tasks()).single.items.single.id, 1);
      await repo.sign();
      await repo.claim(1);
      expect(f.calls.where((c) => c.path == HttpApi.dailyClaim).single.params, {
        'missionId': 1,
      });
      f.envelopes[HttpApi.dailySign] = {
        'code': 3021,
        'message': 'fallback',
        'msg': 'Already signed',
      };
      await expectLater(
        repo.sign(),
        throwsA(
          isA<NadyApiException>().having(
            (e) => e.message,
            'msg',
            'Already signed',
          ),
        ),
      );
    },
  );
  test(
    'binding verifies SMS and encrypts password without logging in',
    () async {
      final repo = AccountBindingRepository(
        f.features,
        encrypt: (value) async => 'encrypted:$value',
      );
      await repo.send('123456789', '966', verifyOld: false);
      expect(
        f.calls
            .where((c) => c.path == HttpApi.sendSms)
            .single
            .params['purpose'],
        4,
      );
      await repo.bind(
        '123456789',
        '966',
        '123456',
        'secretpass',
        needsPassword: true,
      );
      expect(f.calls.where((c) => c.path == HttpApi.verifyCode).single.params, {
        'code': '123456789',
        'areaCode': '966',
        'smsCode': '123456',
      });
      expect(
        f.calls.where((c) => c.path == HttpApi.profileBindPhone).single.params,
        {
          'phone': '123456789',
          'areaCode': '966',
          'passwd': 'encrypted:secretpass',
        },
      );
      expect(f.calls.any((c) => c.path.contains('/login')), isFalse);
    },
  );
}
