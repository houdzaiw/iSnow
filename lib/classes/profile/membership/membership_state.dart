import 'membership_models.dart';
import 'membership_session.dart';

const membershipUnset = Object();

class MembershipState {
  const MembershipState({
    this.vip,
    this.nobles,
    this.account,
    this.loadingVip = true,
    this.loadingNoble = true,
    this.vipError,
    this.nobleError,
    this.actionError,
    this.selectedVip = 0,
    this.selectedNoble = 0,
    this.vipGrade = 0,
    this.nobleGrade = 0,
    this.cards = 0,
    this.submitting = false,
    this.now,
    this.successAnimation,
  });
  final VipMembership? vip;
  final List<NobleMembership>? nobles;
  final MembershipIdentity? account;
  final bool loadingVip, loadingNoble, submitting;
  final Object? vipError, nobleError, actionError;
  final int selectedVip, selectedNoble, vipGrade, nobleGrade, cards;
  final DateTime? now;
  final String? successAnimation;
  bool get vipActive =>
      vip?.active == true &&
      (vip!.timeProtection ||
          vip!.remaining(now ?? DateTime.now()) > Duration.zero);
  int get nobleLevel => nobles == null
      ? vip?.user.userLevel?.aristocracyLevel ?? 0
      : nobles!
            .where((n) => n.remaining(now ?? DateTime.now()) > Duration.zero)
            .fold(0, (level, n) => n.id > level ? n.id : level);
  VipMembershipLevel? get vipLevel =>
      vip?.levels.where((l) => l.level == selectedVip).firstOrNull;
  NobleMembership? get noble =>
      nobles?.where((l) => l.id == selectedNoble).firstOrNull;
  MembershipGrade? get selectedVipGrade =>
      vip?.grades.where((g) => g.id == vipGrade).firstOrNull;
  MembershipGrade? get selectedNobleGrade =>
      noble?.grades.where((g) => g.id == nobleGrade).firstOrNull;
  MembershipState copyWith({
    VipMembership? vip,
    List<NobleMembership>? nobles,
    MembershipIdentity? account,
    bool? loadingVip,
    bool? loadingNoble,
    bool? submitting,
    Object? vipError = membershipUnset,
    Object? nobleError = membershipUnset,
    Object? actionError = membershipUnset,
    int? selectedVip,
    int? selectedNoble,
    int? vipGrade,
    int? nobleGrade,
    int? cards,
    DateTime? now,
    Object? successAnimation = membershipUnset,
  }) => MembershipState(
    vip: vip ?? this.vip,
    nobles: nobles ?? this.nobles,
    account: account ?? this.account,
    loadingVip: loadingVip ?? this.loadingVip,
    loadingNoble: loadingNoble ?? this.loadingNoble,
    submitting: submitting ?? this.submitting,
    selectedVip: selectedVip ?? this.selectedVip,
    selectedNoble: selectedNoble ?? this.selectedNoble,
    vipGrade: vipGrade ?? this.vipGrade,
    nobleGrade: nobleGrade ?? this.nobleGrade,
    cards: cards ?? this.cards,
    now: now ?? this.now,
    vipError: identical(vipError, membershipUnset) ? this.vipError : vipError,
    nobleError: identical(nobleError, membershipUnset)
        ? this.nobleError
        : nobleError,
    actionError: identical(actionError, membershipUnset)
        ? this.actionError
        : actionError,
    successAnimation: identical(successAnimation, membershipUnset)
        ? this.successAnimation
        : successAnimation as String?,
  );
}

class MembershipFailure implements Exception {
  const MembershipFailure(this.key);
  final String key;
}

class MembershipOperation {
  const MembershipOperation({
    required this.account,
    required this.action,
    required this.coins,
    required this.days,
    required this.label,
    this.gradeId,
    this.nobleId,
    this.targetUid,
    this.targetName,
  });
  final MembershipIdentity account;
  final MembershipAction action;
  final int coins, days;
  final String label;
  final String? targetName;
  final int? gradeId, nobleId, targetUid;
}

enum MembershipSubmitResult {
  success,
  refreshFailed,
  failed,
  insufficientCoins,
  stale,
}
