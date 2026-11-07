import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/account_balance_revision.dart';
import '../../../model/server_response.dart';
import 'membership_models.dart';
import 'membership_repository.dart';
import 'membership_state.dart';

final membershipViewModelProvider =
    NotifierProvider<MembershipViewModel, MembershipState>(
      MembershipViewModel.new,
    );
final membershipRevisionProvider = StateProvider<int>((ref) => 0);
final membershipClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class MembershipViewModel extends Notifier<MembershipState> {
  MembershipRepository get repository => ref.read(membershipRepositoryProvider);
  int _epoch = 0;
  bool _alive = false;
  Future<void>? _vipLoad, _nobleLoad;
  final Set<String> _expired = {};
  bool current(int epoch) => _alive && epoch == _epoch;

  @override
  MembershipState build() {
    ref.watch(membershipRepositoryProvider);
    _epoch++;
    _alive = true;
    _vipLoad = null;
    _nobleLoad = null;
    _expired.clear();
    final epoch = _epoch;
    Timer? timer;
    void tick() {
      if (!current(epoch)) return;
      state = state.copyWith(now: ref.read(membershipClockProvider)());
      final vip = state.vip;
      if (vip != null &&
          vip.active &&
          !vip.timeProtection &&
          vip.endTime > 0 &&
          vip.remaining(state.now!) == Duration.zero &&
          _expired.add('vip:${vip.endTime}')) {
        unawaited(loadVip(force: true));
      }
      for (final n in state.nobles ?? <NobleMembership>[]) {
        if (n.expiresAt != null &&
            n.remaining(state.now!) == Duration.zero &&
            _expired.add('noble:${n.id}:${n.expiresAt}')) {
          unawaited(loadNoble(force: true));
          break;
        }
      }
    }

    void startClock() {
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }

    startClock();
    ref.onCancel(() => timer?.cancel());
    ref.onResume(startClock);
    ref.onDispose(() {
      timer?.cancel();
      _alive = false;
      _epoch++;
    });
    Future.microtask(() {
      if (current(epoch)) unawaited(load());
    });
    return MembershipState(now: ref.read(membershipClockProvider)());
  }

  Future<void> load({bool force = false}) async {
    await Future.wait([loadVip(force: force), loadNoble(force: force)]);
  }

  Future<void> loadVip({bool force = false}) async {
    final epoch = _epoch;
    final pending = _vipLoad;
    if (pending != null) {
      await pending;
      if (!force || !current(epoch)) return;
    }
    if (!current(epoch)) return;
    final task = _loadVip(force);
    _vipLoad = task;
    try {
      await task;
    } finally {
      if (identical(_vipLoad, task)) _vipLoad = null;
    }
  }

  Future<void> _loadVip(bool force) async {
    final epoch = _epoch;
    final repo = repository;
    state = state.copyWith(loadingVip: true, vipError: null);
    try {
      final account = await repo.identity();
      final result = await repo.vip(force: force);
      if (!current(epoch)) return;
      final selection = result.levels.any((v) => v.level == state.selectedVip)
          ? state.selectedVip
          : result.levels
                    .where((v) => v.level == result.level)
                    .firstOrNull
                    ?.level ??
                result.levels.firstOrNull?.level ??
                0;
      state = state.copyWith(
        vip: result,
        account: account,
        selectedVip: selection,
        vipGrade: result.grades.any((g) => g.id == state.vipGrade)
            ? state.vipGrade
            : result.grades.firstOrNull?.id ?? 0,
        loadingVip: false,
      );
      try {
        final cards = await repo.experienceCards(force: force);
        if (current(epoch)) state = state.copyWith(cards: cards);
      } catch (_) {
        /* This auxiliary request must not hide the VIP page. */
      }
    } catch (e) {
      if (current(epoch)) {
        state = state.copyWith(loadingVip: false, vipError: e);
      }
    }
  }

  Future<void> loadNoble({bool force = false}) async {
    final epoch = _epoch;
    final pending = _nobleLoad;
    if (pending != null) {
      await pending;
      if (!force || !current(epoch)) return;
    }
    if (!current(epoch)) return;
    final task = _loadNoble(force);
    _nobleLoad = task;
    try {
      await task;
    } finally {
      if (identical(_nobleLoad, task)) _nobleLoad = null;
    }
  }

  Future<void> _loadNoble(bool force) async {
    final epoch = _epoch;
    final repo = repository;
    state = state.copyWith(loadingNoble: true, nobleError: null);
    try {
      final account = await repo.identity();
      final result = await repo.nobles(force: force);
      if (!current(epoch)) return;
      final selection =
          result.where((n) => n.id == state.selectedNoble).firstOrNull ??
          result
              .where((n) => n.remaining(state.now!) > Duration.zero)
              .lastOrNull ??
          result.firstOrNull;
      state = state.copyWith(
        nobles: result,
        account: account,
        selectedNoble: selection?.id ?? 0,
        nobleGrade:
            selection?.grades
                .where((g) => g.id == state.nobleGrade)
                .firstOrNull
                ?.id ??
            selection?.grades.firstOrNull?.id ??
            0,
        loadingNoble: false,
      );
    } catch (e) {
      if (current(epoch)) {
        state = state.copyWith(loadingNoble: false, nobleError: e);
      }
    }
  }

  void selectVip(int level) {
    if (!state.submitting &&
        state.vip?.levels.any((v) => v.level == level) == true) {
      state = state.copyWith(selectedVip: level);
    }
  }

  void selectNoble(int id) {
    final noble = state.nobles?.where((v) => v.id == id).firstOrNull;
    if (!state.submitting && noble != null) {
      state = state.copyWith(
        selectedNoble: id,
        nobleGrade: noble.grades.firstOrNull?.id ?? 0,
      );
    }
  }

  void selectGrade(MembershipKind kind, int id) {
    if (state.submitting) return;
    if (kind == MembershipKind.vip &&
        state.vip?.grades.any((g) => g.id == id) == true) {
      state = state.copyWith(vipGrade: id);
    }
    if (kind == MembershipKind.noble &&
        state.noble?.grades.any((g) => g.id == id) == true) {
      state = state.copyWith(nobleGrade: id);
    }
  }

  Future<MembershipOperation> prepare(
    MembershipAction action, {
    MembershipRecipient? recipient,
    NobleReward? reward,
  }) async {
    final epoch = _epoch;
    final account = await repository.identity();
    if (!current(epoch) || state.submitting) {
      throw const MembershipFailure('membership.busy');
    }
    if (recipient != null &&
        (recipient.user.uid == null || recipient.user.uid! <= 0)) {
      throw const MembershipFailure('membership.userNotFound');
    }
    if (recipient != null &&
        action != MembershipAction.unblock &&
        (recipient.blocked || !recipient.normal)) {
      throw const MembershipFailure('membership.invalidRecipient');
    }
    final target = recipient?.user.uid;
    final vip = state.vip;
    MembershipGrade? grade;
    int? nobleId;
    String label = 'VIP';
    switch (action) {
      case MembershipAction.buyVip:
        grade = state.selectedVipGrade;
        if (grade == null) {
          throw const MembershipFailure('membership.noPackage');
        }
      case MembershipAction.buyNoble:
        final noble = state.noble;
        grade = state.selectedNobleGrade;
        if (noble == null || !noble.enabled || grade == null) {
          throw const MembershipFailure('membership.noPackage');
        }
        if ((recipient == null
                ? state.nobleLevel
                : recipient.user.userLevel?.aristocracyLevel ?? 0) >
            noble.id) {
          throw const MembershipFailure('membership.higherRank');
        }
        nobleId = noble.id;
        label = noble.name;
      case MembershipAction.experienceCard:
        if (!state.vipActive ||
            (vip?.level ?? 0) < 4 ||
            state.cards <= 0 ||
            recipient == null ||
            (recipient.user.userLevel?.vipLevel ?? 0) > 0) {
          throw const MembershipFailure('membership.experienceUnavailable');
        }
      case MembershipAction.reward:
        if (state.nobleLevel < 5 ||
            state.selectedNoble < 5 ||
            reward == null ||
            reward.remaining <= 0 ||
            recipient == null) {
          throw const MembershipFailure('membership.rewardUnavailable');
        }
        nobleId = reward.id;
        label = reward.name;
      case MembershipAction.unblock:
        if (!state.vipActive ||
            (vip?.level ?? 0) < 6 ||
            recipient == null ||
            recipient.blockStatus != 1) {
          throw const MembershipFailure('membership.unblockUnavailable');
        }
    }
    return MembershipOperation(
      account: account,
      action: action,
      gradeId: grade?.id,
      nobleId: nobleId,
      targetUid: target,
      targetName: recipient?.user.nick,
      label: label,
      coins: action == MembershipAction.unblock
          ? recipient!.unblockCoins
          : grade?.payable ?? 0,
      days: grade?.days ?? reward?.days ?? 0,
    );
  }

  Future<MembershipSubmitResult> execute(MembershipOperation operation) async {
    if (state.submitting) return MembershipSubmitResult.stale;
    final epoch = _epoch;
    final repo = repository;
    state = state.copyWith(
      submitting: true,
      actionError: null,
      successAnimation: null,
    );
    try {
      await repo.check(operation.account);
      if (!current(epoch)) return MembershipSubmitResult.stale;
      await repo.submit(
        operation.action,
        account: operation.account,
        gradeId: operation.gradeId,
        nobleId: operation.nobleId,
        targetUid: operation.targetUid,
      );
    } catch (error) {
      if (!current(epoch)) return MembershipSubmitResult.stale;
      state = state.copyWith(submitting: false, actionError: error);
      // Query state after an uncertain result, never repeat a financial request.
      unawaited(load(force: true));
      return error is NadyApiException && error.code == 10003
          ? MembershipSubmitResult.insufficientCoins
          : MembershipSubmitResult.failed;
    }
    if (!current(epoch)) return MembershipSubmitResult.stale;
    ref.read(membershipRevisionProvider.notifier).state++;
    ref.read(accountBalanceRevisionProvider.notifier).state++;
    await load(force: true);
    if (!current(epoch)) return MembershipSubmitResult.stale;
    bool refreshFailed = state.vipError != null || state.nobleError != null;
    try {
      await repo.syncAccount(operation.account);
    } catch (_) {
      refreshFailed = true;
    }
    if (!current(epoch)) return MembershipSubmitResult.stale;
    state = state.copyWith(
      submitting: false,
      successAnimation: operation.targetUid != null
          ? null
          : operation.action == MembershipAction.buyVip
          ? state.vip?.levels
                .where((l) => l.level == state.vip?.level)
                .firstOrNull
                ?.animation
          : operation.action == MembershipAction.buyNoble
          ? state.nobles
                ?.where((n) => n.id == operation.nobleId)
                .firstOrNull
                ?.animation
          : null,
    );
    return refreshFailed
        ? MembershipSubmitResult.refreshFailed
        : MembershipSubmitResult.success;
  }

  void clearAnimation() => state = state.copyWith(successAnimation: null);
}
