import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../manager/api_error_message.dart';
import '../../../../manager/account_balance_revision.dart';
import '../../../wallet/wallet_models.dart';
import '../../../wallet/wallet_state.dart';
import '../../../wallet/wallet_view_model.dart';
import '../../room_repository.dart';
import 'room_first_recharge_models.dart';
import 'room_first_recharge_repository.dart';

final roomFirstRechargeProvider = StateNotifierProvider.autoDispose
    .family<RoomFirstRechargeViewModel, RoomFirstRechargeState, String>((
      ref,
      roomId,
    ) {
      late final RoomFirstRechargeViewModel vm;
      ProviderSubscription<WalletState>? billing;
      vm = RoomFirstRechargeViewModel(
        roomId,
        ref.read(roomFirstRechargeRepositoryProvider),
        ref.read(roomRepositoryProvider),
        onVerified: () =>
            ref.read(accountBalanceRevisionProvider.notifier).state++,
        purchase: (product, valid) async {
          // Merely viewing packs never starts billing or unfinished-order recovery.
          billing ??= ref.listen(walletViewModelProvider, vm.paymentChanged);
          if (ref.read(walletViewModelProvider.notifier).hasPendingCheckout) {
            throw StateError('Another purchase is pending');
          }
          await ref
              .read(walletViewModelProvider.notifier)
              .purchase(product, isCurrent: valid);
        },
      );
      ref.onDispose(() => billing?.close());
      return vm;
    });

class RoomFirstRechargeState {
  const RoomFirstRechargeState({
    this.loading = true,
    this.active = true,
    this.eligible = false,
    this.paying = false,
    this.confirming = false,
    this.completed = false,
    this.packs = const [],
    this.selectedId,
    this.error,
  });
  final bool loading, active, eligible, paying, confirming, completed;
  final List<RoomFirstRechargePack> packs;
  final String? selectedId, error;
  RoomFirstRechargePack? get selected =>
      packs.where((p) => p.id == selectedId).firstOrNull;
  bool get canBuy =>
      active &&
      eligible &&
      !loading &&
      !paying &&
      !confirming &&
      selected?.purchasable == true;
}

class RoomFirstRechargeViewModel extends StateNotifier<RoomFirstRechargeState> {
  RoomFirstRechargeViewModel(
    this.roomId,
    this.repository,
    this.room, {
    required this.purchase,
    this.onVerified,
  }) : generation = room.roomGeneration,
       super(const RoomFirstRechargeState()) {
    room.addListener(_sessionChanged);
    room.addAuthListener(_accountChanged);
    _sessionChanged();
    if (state.active) unawaited(load());
  }
  final String roomId;
  final RoomFirstRechargeRepository repository;
  final RoomRepository room;
  final int generation;
  final Future<void> Function(WalletRechargeProduct, bool Function()) purchase;
  final void Function()? onVerified;
  bool _confirmationNotified = false;
  int _revision = 0;
  int? _uid;
  String? _ownedProduct;
  bool get valid =>
      mounted &&
      state.active &&
      room.roomGeneration == generation &&
      room.roomState.isInRoom &&
      room.roomState.currentRoomId == roomId;
  void _accountChanged() => _invalidate();
  void _sessionChanged() {
    if (!valid) _invalidate();
  }

  void _invalidate() {
    if (!mounted || !state.active) return;
    _revision++;
    state = const RoomFirstRechargeState(active: false, loading: false);
  }

  Future<void> load({bool afterPayment = false}) async {
    if (!valid || state.paying) return;
    final revision = ++_revision;
    final selected = state.selectedId;
    final confirming = state.confirming || afterPayment;
    state = RoomFirstRechargeState(
      packs: state.packs,
      selectedId: selected,
      eligible: state.eligible,
      confirming: confirming,
    );
    try {
      final uid = await room.currentUid();
      if (!valid || revision != _revision) return;
      if (uid == null || _uid != null && _uid != uid) {
        _invalidate();
        return;
      }
      _uid = uid;
      final purse = await repository.fetchPurse();
      if (!valid || revision != _revision) return;
      final packs = purse.isFirst
          ? await repository.fetchPacks()
          : <RoomFirstRechargePack>[];
      if (!valid || revision != _revision) return;
      final done =
          confirming &&
          (!purse.isFirst ||
              packs.any((p) => p.id == _ownedProduct && !p.isBuy));
      state = RoomFirstRechargeState(
        loading: false,
        eligible: purse.isFirst,
        packs: packs,
        selectedId: packs.any((p) => p.id == selected)
            ? selected
            : packs.firstOrNull?.id,
        confirming: confirming && !done,
        completed: done,
        error: confirming && !done ? 'room.gift.firstRechargeConfirming' : null,
      );
      if (done && !_confirmationNotified) {
        _confirmationNotified = true;
        onVerified?.call();
      }
    } catch (error) {
      if (valid && revision == _revision) {
        state = RoomFirstRechargeState(
          loading: false,
          packs: state.packs,
          selectedId: selected,
          confirming: confirming,
          error: userFacingErrorMessage(
            error,
            fallback: 'room.gift.firstRechargeLoadFailed',
          ),
        );
      }
    }
  }

  void select(String id) {
    if (!valid ||
        state.loading ||
        state.paying ||
        state.confirming ||
        !state.packs.any((p) => p.id == id)) {
      return;
    }
    state = RoomFirstRechargeState(
      loading: false,
      eligible: state.eligible,
      packs: state.packs,
      selectedId: id,
    );
  }

  Future<void> buy() async {
    if (!valid || !state.canBuy) return;
    final selected = state.selected!;
    _ownedProduct = selected.id;
    final revision = ++_revision;
    state = RoomFirstRechargeState(
      loading: false,
      eligible: state.eligible,
      packs: state.packs,
      selectedId: selected.id,
      paying: true,
    );
    bool current() => valid && revision == _revision;
    try {
      // Recheck first-time eligibility and the selected package before any order.
      final purse = await repository.fetchPurse();
      if (!current()) return;
      final packs = purse.isFirst
          ? await repository.fetchPacks()
          : <RoomFirstRechargePack>[];
      if (!current()) return;
      final latest = packs
          .where((p) => p.id == selected.id && p.purchasable)
          .firstOrNull;
      if (latest == null) {
        state = RoomFirstRechargeState(
          loading: false,
          packs: packs,
          selectedId: selected.id,
          eligible: purse.isFirst,
          error: 'room.gift.firstRechargeUnavailable',
        );
        return;
      }
      await purchase(latest.paymentProduct, current);
    } catch (error) {
      if (current()) {
        state = RoomFirstRechargeState(
          loading: false,
          packs: state.packs,
          selectedId: selected.id,
          eligible: state.eligible,
          error: userFacingErrorMessage(
            error,
            fallback: 'wallet.paymentFailed',
          ),
        );
      }
    }
  }

  void paymentChanged(WalletState? previous, WalletState next) {
    if (previous?.purchaseProductId != _ownedProduct &&
        next.purchaseProductId != _ownedProduct) {
      return;
    }
    if (!valid ||
        !state.paying ||
        previous?.noticeKey == next.noticeKey &&
            previous?.noticeMessage == next.noticeMessage) {
      return;
    }
    if (next.noticeKey == 'wallet.paymentSuccess') {
      state = RoomFirstRechargeState(
        loading: false,
        packs: state.packs,
        selectedId: state.selectedId,
        eligible: state.eligible,
        confirming: true,
      );
      unawaited(load(afterPayment: true));
    } else if (!next.isPurchasing &&
        (next.noticeKey != null || next.noticeMessage != null)) {
      state = RoomFirstRechargeState(
        loading: false,
        packs: state.packs,
        selectedId: state.selectedId,
        eligible: state.eligible,
        error: next.noticeMessage ?? next.noticeKey,
      );
    }
  }

  @override
  void dispose() {
    _revision++;
    room.removeListener(_sessionChanged);
    room.removeAuthListener(_accountChanged);
    super.dispose();
  }
}
