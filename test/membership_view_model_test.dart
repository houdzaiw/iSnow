import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/profile/membership/membership_aux_view_model.dart';
import 'package:project/classes/profile/membership/membership_models.dart';
import 'package:project/classes/profile/membership/membership_repository.dart';
import 'package:project/classes/profile/membership/membership_state.dart';
import 'package:project/classes/profile/membership/membership_view_model.dart';
import 'package:project/manager/account_balance_revision.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/server_response.dart';
import 'package:project/model/user_profile.dart';

import 'support/membership_fakes.dart';

void main() {
  late MembershipFixture f;
  late ProviderContainer container;
  late MembershipViewModel model;
  Future<void> ready() => model.load();
  setUp(() {
    f = MembershipFixture();
    container = ProviderContainer(
      overrides: [
        membershipRepositoryProvider.overrideWithValue(f.repository),
        membershipClockProvider.overrideWithValue(() => membershipNow),
      ],
    );
    model = container.read(membershipViewModelProvider.notifier);
  });
  tearDown(() => container.dispose());

  test(
    'initial selection uses owned levels and default server grades',
    () async {
      await ready();
      final s = container.read(membershipViewModelProvider);
      expect(s.selectedVip, 6);
      expect(s.selectedNoble, 6);
      expect(s.vipGrade, 1);
      expect(s.nobleGrade, 60);
      expect(s.cards, 2);
    },
  );
  test(
    'browse VIP changes preview, never the purchase level payload',
    () async {
      await ready();
      model.selectVip(2);
      final operation = await model.prepare(MembershipAction.buyVip);
      expect(operation.gradeId, 1);
      expect(operation.coins, 100);
      expect(await model.execute(operation), MembershipSubmitResult.success);
      final request = f.api.calls.singleWhere(
        (c) => c.path == HttpApi.membershipVipBuy,
      );
      expect(request.arguments, {'gradeId': 1, 'targetUid': null});
    },
  );
  test(
    'confirmation freezes a selected grade even if selection later changes',
    () async {
      await ready();
      final operation = await model.prepare(MembershipAction.buyVip);
      model.selectGrade(MembershipKind.vip, 3);
      await model.execute(operation);
      expect(
        f.api.calls
            .singleWhere((c) => c.path == HttpApi.membershipVipBuy)
            .arguments['gradeId'],
        1,
      );
    },
  );
  test(
    'noble uses the discounted price and prevents downgrade for self',
    () async {
      await ready();
      expect((await model.prepare(MembershipAction.buyNoble)).coins, 150);
      model.selectNoble(2);
      await expectLater(
        model.prepare(MembershipAction.buyNoble),
        throwsA(
          isA<MembershipFailure>().having(
            (e) => e.key,
            'reason',
            'membership.higherRank',
          ),
        ),
      );
    },
  );
  test('recipient rank, not sender rank, controls gift downgrade', () async {
    await ready();
    model.selectNoble(2);
    final recipient = await f.repository.recipient(10020);
    final operation = await model.prepare(
      MembershipAction.buyNoble,
      recipient: recipient,
    );
    expect(operation.targetUid, 20);
    expect(operation.nobleId, 2);
  });
  test(
    'experience card has VIP level, quota and recipient restrictions',
    () async {
      await ready();
      final recipient = await f.repository.recipient(20);
      expect(
        (await model.prepare(
          MembershipAction.experienceCard,
          recipient: recipient,
        )).targetUid,
        20,
      );
      final existingVip = MembershipRecipient(
        user: UserData.fromJson(membershipUser(uid: 20)),
        blocked: false,
        normal: true,
      );
      await expectLater(
        model.prepare(MembershipAction.experienceCard, recipient: existingVip),
        throwsA(isA<MembershipFailure>()),
      );
      f.api.responses[HttpApi.membershipVipExperienceCard] = 0;
      await model.loadVip(force: true);
      await expectLater(
        model.prepare(MembershipAction.experienceCard, recipient: recipient),
        throwsA(isA<MembershipFailure>()),
      );
    },
  );
  test(
    'reward quota is enforced and emitted as a reward not a paid purchase',
    () async {
      await ready();
      final recipient = await f.repository.recipient(20);
      final reward = (await f.repository.rewards()).single;
      await model.execute(
        await model.prepare(
          MembershipAction.reward,
          recipient: recipient,
          reward: reward,
        ),
      );
      expect(f.api.count(HttpApi.membershipNobleGive, method: 'POST'), 1);
      final exhausted = NobleReward(
        id: 1,
        name: '',
        icon: '',
        days: 1,
        limit: 1,
        sent: 1,
      );
      await expectLater(
        model.prepare(
          MembershipAction.reward,
          recipient: recipient,
          reward: exhausted,
        ),
        throwsA(isA<MembershipFailure>()),
      );
    },
  );
  test('VIP6 unblock requires a banned target and uses server cost', () async {
    await ready();
    final banned = await f.repository.recipient(10020, unblock: true);
    expect(
      (await model.prepare(MembershipAction.unblock, recipient: banned)).coins,
      50,
    );
    final normal = MembershipRecipient(
      user: banned.user,
      blocked: false,
      normal: true,
    );
    await expectLater(
      model.prepare(MembershipAction.unblock, recipient: normal),
      throwsA(isA<MembershipFailure>()),
    );
  });
  test('repeat execution while submitting produces only one debit', () async {
    await ready();
    final operation = await model.prepare(MembershipAction.buyVip);
    f.api.heldPath = HttpApi.membershipVipBuy;
    f.api.gate = Completer<void>();
    final first = model.execute(operation);
    await Future<void>.delayed(Duration.zero);
    expect(await model.execute(operation), MembershipSubmitResult.stale);
    f.api.gate!.complete();
    await first;
    expect(f.api.count(HttpApi.membershipVipBuy), 1);
  });
  test(
    'successful debit syncs user and balance, and invalidates consumers',
    () async {
      await ready();
      await model.execute(await model.prepare(MembershipAction.buyVip));
      expect(f.userRefreshes, 1);
      expect(f.balanceRefreshes, 1);
      expect(container.read(membershipRevisionProvider), 1);
      expect(container.read(accountBalanceRevisionProvider), 1);
    },
  );
  test('refresh failure after success never reports a failed debit', () async {
    await ready();
    f.failRefresh = true;
    expect(
      await model.execute(await model.prepare(MembershipAction.buyVip)),
      MembershipSubmitResult.refreshFailed,
    );
    expect(f.api.count(HttpApi.membershipVipBuy), 1);
  });
  test('ambiguous error never automatically resubmits', () async {
    await ready();
    f.api.failures[HttpApi.membershipVipBuy] = TimeoutException(
      'unknown outcome',
    );
    expect(
      await model.execute(await model.prepare(MembershipAction.buyVip)),
      MembershipSubmitResult.failed,
    );
    await Future<void>.delayed(Duration.zero);
    expect(f.api.count(HttpApi.membershipVipBuy), 1);
  });
  test(
    'insufficient coins has a distinct outcome without purchase retries',
    () async {
      await ready();
      f.api.failures[HttpApi.membershipVipBuy] = const NadyApiException(
        code: 10003,
        message: 'Not enough coins',
      );
      expect(
        await model.execute(await model.prepare(MembershipAction.buyVip)),
        MembershipSubmitResult.insufficientCoins,
      );
      expect(f.api.count(HttpApi.membershipVipBuy), 1);
    },
  );
  test(
    'switching account rejects a frozen confirmation before network write',
    () async {
      await ready();
      final operation = await model.prepare(MembershipAction.buyVip);
      f.account = (uid: 11, token: 'new', generation: 2);
      expect(await model.execute(operation), MembershipSubmitResult.failed);
      expect(f.api.count(HttpApi.membershipVipBuy), 0);
    },
  );
  test(
    'settings save failure keeps previous switch state; locked save is blocked',
    () async {
      final aux = container.read(membershipAuxProvider.notifier);
      await aux.load('settings');
      final setting = container.read(membershipAuxProvider).settings!.first;
      expect(await aux.saveSetting(setting, true, 1), isFalse);
      expect(f.api.count(HttpApi.userVipSetting, method: 'POST'), 0);
      f.api.failures[HttpApi.userVipSetting] = const NadyApiException(
        message: 'Save rejected',
      );
      expect(await aux.saveSetting(setting, true, 6), isFalse);
      expect(
        container.read(membershipAuxProvider).settings!.first.open,
        isFalse,
      );
    },
  );
  test(
    'history merges pages without duplicates and a refresh resets pagination',
    () async {
      final aux = container.read(membershipAuxProvider.notifier);
      f.api.responses[HttpApi.membershipNobleHistory] = {
        'list': [
          {'id': 1, 'source': 0},
          {'id': 2, 'source': 1},
        ],
        'total': 3,
      };
      await aux.history(MembershipKind.noble);
      f.api.responses[HttpApi.membershipNobleHistory] = {
        'list': [
          {'id': 2, 'source': 1},
          {'id': 3, 'source': 2},
        ],
        'total': 3,
      };
      await aux.history(MembershipKind.noble);
      expect(
        container
            .read(membershipAuxProvider)
            .records[MembershipKind.noble]!
            .map((r) => r.key),
        ['1', '2', '3'],
      );
      expect(aux.hasMore(MembershipKind.noble), isFalse);
      await aux.history(MembershipKind.noble, refresh: true);
      expect(f.api.calls.last.arguments['pageNum'], 1);
    },
  );
  test(
    'typing after a search clears the old recipient, late result is ignored',
    () async {
      final recipient = MembershipRecipientViewModel(
        f.repository,
        MembershipAction.experienceCard,
      );
      addTearDown(recipient.dispose);
      recipient.changed('20');
      await recipient.search();
      expect(recipient.state.user!.user.uid, 20);
      f.api.heldPath = HttpApi.userHomepage;
      f.api.gate = Completer<void>();
      final request = recipient.search();
      await Future<void>.delayed(Duration.zero);
      recipient.changed('21');
      expect(recipient.state.user, isNull);
      f.api.gate!.complete();
      await request;
      expect(recipient.state.user, isNull);
    },
  );
  test(
    'titles enforce emperor, block occupied titles and isolate old account',
    () async {
      final aux = container.read(membershipAuxProvider.notifier);
      await aux.load('titles');
      final title = container.read(membershipAuxProvider).titles!.single;
      expect(
        await aux.claim(title, nobleLevel: 5, account: f.account),
        MembershipSubmitResult.failed,
      );
      expect(f.api.count(HttpApi.membershipNobleTitleClaim), 0);
      expect(
        await aux.claim(title, nobleLevel: 6, account: f.account),
        MembershipSubmitResult.success,
      );
      expect(f.api.count(HttpApi.membershipNobleTitleClaim), 1);
    },
  );
  test(
    'unknown price or missing grade cannot become a free purchase',
    () async {
      final raw = membershipVip();
      raw['grades'] = [
        {'id': 1, 'day': 7},
      ];
      f.api.responses[HttpApi.membershipVip] = raw;
      await ready();
      await expectLater(
        model.prepare(MembershipAction.buyVip),
        throwsA(isA<MembershipFailure>()),
      );
      expect(f.api.count(HttpApi.membershipVipBuy), 0);
    },
  );
  test(
    'expired VIP cannot use experience cards or unblocking privileges',
    () async {
      final raw = membershipVip();
      (raw['userVipInfo'] as Map)['endTime'] = membershipNow
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch;
      f.api.responses[HttpApi.membershipVip] = raw;
      await ready();
      final target = await f.repository.recipient(20);
      final blocked = await f.repository.recipient(10020, unblock: true);
      await expectLater(
        model.prepare(MembershipAction.experienceCard, recipient: target),
        throwsA(isA<MembershipFailure>()),
      );
      await expectLater(
        model.prepare(MembershipAction.unblock, recipient: blocked),
        throwsA(isA<MembershipFailure>()),
      );
    },
  );
  test('rank restrictions and inactive noble packages are enforced', () async {
    await ready();
    final nobles = membershipNobles();
    nobles.last['status'] = 1;
    f.api.responses[HttpApi.membershipNoble] = nobles;
    await model.loadNoble(force: true);
    await expectLater(
      model.prepare(MembershipAction.buyNoble),
      throwsA(isA<MembershipFailure>()),
    );
    model.selectNoble(2);
    final target = MembershipRecipient(
      user: UserData.fromJson(membershipUser(uid: 20)),
      blocked: false,
      normal: true,
    );
    await expectLater(
      model.prepare(MembershipAction.buyNoble, recipient: target),
      throwsA(isA<MembershipFailure>()),
    );
  });
  test(
    'provider session replacement discards a late request from the old account',
    () async {
      await ready();
      final keepAlive = container.listen(
        membershipViewModelProvider,
        (_, _) {},
      );
      addTearDown(keepAlive.close);
      f.api.heldPath = HttpApi.membershipVip;
      f.api.gate = Completer<void>();
      final oldLoad = model.loadVip(force: true);
      await Future<void>.delayed(Duration.zero);
      final replacement = MembershipFixture();
      replacement.account = (uid: 11, token: 'replacement', generation: 2);
      replacement.api.responses[HttpApi.membershipVip] = membershipVip(
        level: 2,
        noble: 0,
      );
      container.updateOverrides([
        membershipRepositoryProvider.overrideWithValue(replacement.repository),
        membershipClockProvider.overrideWithValue(() => membershipNow),
      ]);
      await container.read(membershipViewModelProvider.notifier).load();
      f.api.gate!.complete();
      await oldLoad;
      expect(container.read(membershipViewModelProvider).vip!.level, 2);
      expect(container.read(membershipViewModelProvider).account!.uid, 11);
    },
  );
  test(
    'occupied title never submits a claim and refresh failure remains a successful claim',
    () async {
      final aux = container.read(membershipAuxProvider.notifier);
      final occupied = NobleTitle(
        id: 1,
        name: '',
        image: '',
        owner: UserData.fromJson(membershipUser(uid: 20)),
      );
      expect(
        await aux.claim(occupied, nobleLevel: 6, account: f.account),
        MembershipSubmitResult.failed,
      );
      expect(f.api.count(HttpApi.membershipNobleTitleClaim), 0);
      f.failRefresh = true;
      final title = NobleTitle(id: 2, name: '', image: '');
      expect(
        await aux.claim(title, nobleLevel: 6, account: f.account),
        MembershipSubmitResult.refreshFailed,
      );
      expect(f.balanceRefreshes, 1);
    },
  );
  test('closed recipient controller ignores a pending response', () async {
    final recipient = MembershipRecipientViewModel(
      f.repository,
      MembershipAction.buyVip,
    );
    recipient.changed('20');
    f.api.heldPath = HttpApi.userHomepage;
    f.api.gate = Completer<void>();
    final search = recipient.search();
    await Future<void>.delayed(Duration.zero);
    recipient.dispose();
    f.api.gate!.complete();
    await search;
  });
}
