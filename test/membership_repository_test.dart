import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/profile/membership/membership_models.dart';
import 'package:project/classes/profile/membership/membership_repository.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/server_response.dart';
import 'package:project/model/user_profile.dart';

import 'support/membership_fakes.dart';

void main() {
  late MembershipFixture f;
  setUp(() => f = MembershipFixture());
  test(
    'old UserData cache remains compatible; membership survives copy and JSON',
    () {
      expect(UserData.fromJson({'uid': 1}).userLevel, isNull);
      final user = UserData.fromJson(membershipUser());
      final restored = UserData.fromJson(user.copyWith(nick: 'new').toJson());
      expect(restored.userLevel!.vipLevel, 6);
      expect(restored.userLevel!.aristocracyLevel, 6);
    },
  );
  test('VIP milliseconds and noble seconds represent actual expiry', () async {
    final vip = await f.repository.vip();
    final nobles = await f.repository.nobles();
    expect(vip.remaining(membershipNow).inDays, 10);
    expect(nobles.last.remaining(membershipNow).inDays, 8);
    expect(
      vip.remaining(membershipNow.add(const Duration(days: 20))),
      Duration.zero,
    );
  });
  test('concurrent reads coalesce and force refresh bypasses cache', () async {
    f.api.heldPath = HttpApi.membershipVip;
    f.api.gate = Completer<void>();
    final first = f.repository.vip();
    final second = f.repository.vip();
    await Future<void>.delayed(Duration.zero);
    expect(f.api.count(HttpApi.membershipVip), 1);
    f.api.gate!.complete();
    expect(identical(await first, await second), isTrue);
    await f.repository.vip();
    expect(f.api.count(HttpApi.membershipVip), 1);
    await f.repository.vip(force: true);
    expect(f.api.count(HttpApi.membershipVip), 2);
  });
  test(
    'account generation prevents late reads and reuses no former cache',
    () async {
      f.api.heldPath = HttpApi.membershipVip;
      f.api.gate = Completer<void>();
      final read = f.repository.vip();
      final assertion = expectLater(read, throwsA(isA<NadyApiException>()));
      await Future<void>.delayed(Duration.zero);
      f.account = (uid: 11, token: 'another', generation: 2);
      f.api.gate!.complete();
      await assertion;
      f.api.heldPath = null;
      await f.repository.vip();
      expect(f.api.count(HttpApi.membershipVip), 2);
    },
  );
  test('VIP history uses pagePage; noble uses pageSize', () async {
    await f.repository.history(MembershipKind.vip, 2);
    await f.repository.history(MembershipKind.noble, 3);
    expect(f.api.calls[0].arguments, {'pageNum': 2, 'pagePage': 20});
    expect(f.api.calls[1].arguments, {'pageNum': 3, 'pageSize': 20});
  });
  test(
    'settings only exposes Nady active items and uses the authenticated UID',
    () async {
      final items = await f.repository.settings();
      expect(items.map((s) => s.type), ['invisibleEnter', 'invisibleVisitor']);
      expect(f.api.calls.single.arguments, {'uid': 10});
      await f.repository.setSetting(1, true);
      expect(f.api.calls.last.arguments, {'id': 1, 'open': true});
    },
  );
  test(
    'recipient resolution distinguishes lookup value and returned internal UID',
    () async {
      final recipient = await f.repository.recipient(10020);
      expect(f.api.calls.single.arguments, {'targetUid': 10020});
      expect(recipient.user.uid, 20);
      await f.repository.recipient(10020, unblock: true);
      expect(f.api.calls.last.arguments, {'userNo': 10020});
    },
  );
  test(
    'VIP purchase has no browsed-level parameter and preserves null self target',
    () async {
      await f.repository.submit(
        MembershipAction.buyVip,
        account: f.account,
        gradeId: 2,
      );
      expect(f.api.calls.single.arguments, {'gradeId': 2, 'targetUid': null});
    },
  );
  test(
    'noble purchase, reward, card and unblock use exact Nady wire shapes',
    () async {
      await f.repository.submit(
        MembershipAction.buyNoble,
        account: f.account,
        gradeId: 60,
        nobleId: 6,
        targetUid: 20,
      );
      expect(f.api.calls.last.arguments, {
        'gradeId': 60,
        'aristocracyId': 6,
        'targetUid': 20,
      });
      await f.repository.submit(
        MembershipAction.reward,
        account: f.account,
        nobleId: 2,
        targetUid: 20,
      );
      expect(f.api.calls.last.arguments, {'aristocracyId': 2, 'targetUid': 20});
      await f.repository.submit(
        MembershipAction.experienceCard,
        account: f.account,
        targetUid: 20,
      );
      expect(f.api.calls.last.arguments, {'targetUid': 20});
      await f.repository.submit(
        MembershipAction.unblock,
        account: f.account,
        targetUid: 20,
      );
      expect(f.api.calls.last.method, 'GET');
      expect(f.api.calls.last.arguments, {'targetUid': 20});
    },
  );
  test(
    'null successful submission data is accepted; title claim body remains id',
    () async {
      await f.repository.claimTitle(7, f.account);
      expect(f.api.calls.single.arguments, {'id': 7});
    },
  );
  test('expired operation never sends a financial request', () async {
    final old = f.account;
    f.account = (uid: 10, token: 'new-login', generation: 2);
    await expectLater(
      f.repository.submit(MembershipAction.buyVip, account: old, gradeId: 1),
      throwsA(isA<NadyApiException>()),
    );
    expect(f.api.calls, isEmpty);
  });
  test(
    'business error prefers msg and never attempts to parse failed data',
    () async {
      final api = _ErrorApi();
      final errorRepository = _errorRepository(api, f);
      await expectLater(
        errorRepository.vip(),
        throwsA(
          isA<NadyApiException>().having(
            (e) => e.message,
            'msg',
            'Actual backend message',
          ),
        ),
      );
    },
  );
}

class _ErrorApi extends MembershipApi {
  @override
  Future<Object?> get(String path, [Map<String, dynamic>? query]) async => {
    'code': 1003,
    'msg': 'Actual backend message',
    'message': 'Generic',
    'data': null,
  };
  @override
  Future<Object?> post(String path, Map<String, dynamic> body) => get(path);
}

MembershipRepository _errorRepository(MembershipApi api, MembershipFixture f) =>
    MembershipRepository(api, identity: () async => f.account);
