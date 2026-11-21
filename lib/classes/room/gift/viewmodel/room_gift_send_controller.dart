import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../manager/api_error_message.dart';
import '../../../../manager/room_gift_feedback_manager.dart';
import '../models/room_gift_event_models.dart';
import '../models/room_gift_models.dart';
import '../room_gift_repository.dart';
import 'room_gift_state.dart';
import 'room_gift_send_state.dart';

export 'room_gift_send_state.dart';

final roomGiftSendControllerProvider = StateNotifierProvider.autoDispose
    .family<RoomGiftSendController, RoomGiftSendState, String>((ref, roomId) {
      return RoomGiftSendController(
        ref.watch(roomGiftRepositoryProvider),
        roomId,
      );
    });

class RoomGiftSendException implements Exception {
  const RoomGiftSendException(this.issue);
  final RoomGiftIssue issue;
}

/// HTTP confirms the combo button; only broadcasts supply visual gift events.
class RoomGiftSendController extends StateNotifier<RoomGiftSendState> {
  RoomGiftSendController(
    this._repository,
    this.roomId, {
    DateTime Function()? now,
    Future<void> Function()? feedback,
  }) : _now = now ?? DateTime.now,
       _feedback = feedback ?? RoomGiftFeedbackManager.lightImpact,
       super(const RoomGiftSendState());
  final DateTime Function() _now;
  final Future<void> Function() _feedback;
  DateTime? _lastTap, _expiresAt;
  int _tapCount = 0;
  final RoomGiftRepository _repository;
  final String roomId;
  RoomGiftSendState get snapshot => state;
  RoomGift? _gift;
  int _targetCount = 0;
  Set<int>? _roomMembers;
  bool? _canSendSelf;
  int _generation = 0;
  DateTime? _startedAt;
  RoomGiftAudience? audience;
  int? currentUid;
  bool _inFlight = false;
  Timer? _echoTimeout;
  int _remainingMilliseconds = 0;
  int _balanceEpoch = 0;
  Future<int?>? _balanceRefresh;
  int? _refreshEpoch;

  Future<int?> refreshBalance() {
    if (!mounted) return Future.value(null);
    final epoch = _balanceEpoch;
    if (_refreshEpoch == epoch && _balanceRefresh != null) {
      return _balanceRefresh!;
    }
    _refreshEpoch = epoch;
    return _balanceRefresh = _readBalance(epoch).whenComplete(() {
      if (_refreshEpoch == epoch) _balanceRefresh = null;
    });
  }

  Future<int?> _readBalance(int epoch) async {
    try {
      final balance = await _repository.fetchBalance();
      if (!mounted || epoch != _balanceEpoch) return null;
      final catalog = _repository.cachedCatalog ?? state.catalog;
      if (catalog != null) {
        state = state.withCatalog(catalog.copyWith(balance: balance));
      }
      return balance;
    } catch (error) {
      _log('balance refresh failed: ${userFacingErrorMessage(error)}');
      return null;
    }
  }

  Future<RoomGiftCatalog?> send({
    required SendRoomGiftRequest request,
    required RoomGift gift,
    required int targetCount,
    required RoomGiftCatalog catalog,
  }) async {
    if (_inFlight) return null;
    request = request.frozen();
    if (audience?.isInRoom == false) {
      throw const RoomGiftSendException(RoomGiftIssue.roomUnavailable);
    }
    if (request.giftCount < 1 || request.giftCount > 9999) {
      throw const RoomGiftSendException(RoomGiftIssue.invalidCount);
    }
    if (targetCount <= 0) {
      throw const RoomGiftSendException(RoomGiftIssue.noRecipient);
    }
    final total = targetCount * request.giftCount;
    if (gift.isBackpack &&
        (gift.userBackpackId == null ||
            gift.userBackpackId! <= 0 ||
            (gift.amount ?? 0) < total)) {
      throw const RoomGiftSendException(RoomGiftIssue.notEnoughGift);
    }
    if (!gift.isBackpack && catalog.balance < gift.price * total) {
      throw const RoomGiftSendException(RoomGiftIssue.notEnoughCoin);
    }
    final generation = _generation;
    _balanceEpoch++;
    _inFlight = true;
    _gift = gift;
    _targetCount = targetCount;
    _startedAt = _now();
    final previousMessage = request.comboId.isEmpty ? null : state.message;
    final previousComboId = request.comboId;
    if (request.comboId.isEmpty) {
      _roomMembers = audience?.onlineUids == null
          ? null
          : Set.unmodifiable(audience!.onlineUids!);
      _canSendSelf = catalog.canSendSelf;
      _echoTimeout?.cancel();
      _expiresAt = null;
      _tapCount = 1;
      _lastTap = null;
    }
    state = RoomGiftSendState(
      isSending: true,
      request: request,
      catalog: catalog,
      message: previousMessage,
      gift: gift,
      confirmedComboId: previousComboId,
      remainingMilliseconds: _remainingMilliseconds,
      tapCount: _tapCount,
    );
    try {
      final result = await _repository.sendGift(request);
      final nextBalance = gift.isBackpack
          ? catalog.balance
          : (catalog.balance - gift.price * total).clamp(0, catalog.balance);
      _repository.recordGiftSent(
        gift: gift,
        totalCount: total,
        balance: nextBalance,
      );
      final updated =
          _repository.cachedCatalog ??
          deductGift(catalog, gift, total, nextBalance);
      if (!mounted || generation != _generation) return updated;
      final confirmedId = result.comboId?.isNotEmpty == true
          ? result.comboId!
          : previousComboId;
      state = RoomGiftSendState(
        request: request,
        catalog: updated,
        message: state.message,
        gift: gift,
        confirmedComboId: confirmedId,
        awaitingEcho:
            confirmedId.isEmpty && state.message == null && gift.supportsCombo,
        tapCount: _tapCount,
      );
      _log(
        'confirmed giftId=${gift.id} comboId=${state.comboId} '
        'comboEnabled=${state.canContinue}',
      );
      if (previousComboId.isEmpty) {
        _restartCountdown();
      } else {
        _publishCountdown();
      }
      unawaited(refreshBalance());
      return updated;
    } catch (error) {
      if (mounted && generation == _generation) {
        state = RoomGiftSendState(
          request: request,
          catalog: catalog,
          message: previousMessage,
          gift: gift,
          confirmedComboId: previousComboId,
          issue: userFacingErrorMessage(error),
          remainingMilliseconds: _remainingMilliseconds,
          tapCount: _tapCount,
        );
        unawaited(refreshBalance());
      }
      rethrow;
    } finally {
      _inFlight = false;
      if (mounted && generation != _generation) {
        state = RoomGiftSendState(catalog: state.catalog);
      }
    }
  }

  void acknowledge(RoomScreenGiftMsg message, DateTime createdAt) {
    if (_expireIfNeeded()) return;
    final request = state.request;
    if (request == null ||
        message.roomId.isNotEmpty && message.roomId != roomId ||
        message.gift.id != request.giftId ||
        message.giftSource != request.giftSource ||
        message.sendType != request.sendType.value ||
        message.comboId.isEmpty ||
        (_startedAt != null &&
            createdAt.isBefore(
              _startedAt!.subtract(const Duration(seconds: 1)),
            )) ||
        (state.comboId.isNotEmpty && message.comboId != state.comboId)) {
      return;
    }
    final expected = request.targetUids?.toSet();
    if (expected != null &&
        (expected.length != message.targetUids.length ||
            !expected.containsAll(message.targetUids))) {
      return;
    }
    if (message.comboCount < (state.message?.comboCount ?? 0)) {
      return;
    }
    state = RoomGiftSendState(
      isSending: state.isSending,
      request: request,
      catalog: state.catalog,
      message: message,
      gift: state.gift,
      confirmedComboId: state.confirmedComboId,
      tapCount: _tapCount,
    );
    if (_expiresAt == null) {
      _restartCountdown();
    } else {
      _publishCountdown();
    }
  }

  Future<bool> continueCombo() async {
    if (_expireIfNeeded()) return false;
    if (!state.canContinue) return false;
    final now = _now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 200)) {
      return false;
    }
    final previous = state.request!;
    final comboId = state.comboId;
    final catalog = _repository.cachedCatalog ?? state.catalog;
    if (catalog == null || _gift == null) return false;
    if (_canSendSelf != catalog.canSendSelf) return _endChangedCombo();
    final eligible = audience?.recipients
        .where((user) => catalog.canSendSelf || user.uid != currentUid)
        .map((user) => user.uid)
        .toSet();
    if (eligible != null &&
        previous.sendType == RoomGiftSendType.onMic &&
        previous.targetUids != null &&
        (!eligible.containsAll(previous.targetUids!) ||
            eligible.length != previous.targetUids!.length)) {
      return _endChangedCombo();
    }
    if (previous.sendType == RoomGiftSendType.onRoom && audience != null) {
      final count = (audience!.onlineCount - (catalog.canSendSelf ? 0 : 1))
          .clamp(0, audience!.onlineCount);
      if (count != _targetCount ||
          _roomMembers != null &&
              !setEquals(_roomMembers, audience!.onlineUids)) {
        return _endChangedCombo();
      }
    }
    if ((previous.sendType == RoomGiftSendType.single ||
            previous.sendType == RoomGiftSendType.multi) &&
        audience?.onlineUids != null &&
        !audience!.onlineUids!.containsAll(previous.targetUids ?? const [])) {
      return _endChangedCombo();
    }
    final currentGift = catalog.tabs
        .expand((tab) => tab.gifts)
        .where((gift) => gift.selectionKey == _gift!.selectionKey)
        .firstOrNull;
    if (currentGift == null || currentGift.price != previous.price) {
      return _endChangedCombo();
    }
    final gift = _gift!.copyWith(amount: currentGift.amount);
    _lastTap = now;
    _tapCount++;
    _restartCountdown();
    unawaited(_giveFeedback());
    try {
      final result = await send(
        request: previous.frozen(confirmedComboId: comboId),
        gift: gift,
        targetCount: _targetCount,
        catalog: catalog,
      );
      return result != null;
    } catch (error) {
      if (mounted) {
        final attempted = _tapCount;
        resetCombo();
        state = RoomGiftSendState(
          request: state.request,
          catalog: state.catalog,
          message: state.message,
          gift: state.gift,
          confirmedComboId: state.confirmedComboId,
          issue: error is RoomGiftSendException
              ? error.issue.name
              : userFacingErrorMessage(error),
          remainingMilliseconds: _remainingMilliseconds,
          tapCount: attempted,
        );
      }
      return false;
    }
  }

  void resetCombo() {
    _echoTimeout?.cancel();
    _generation++;
    _gift = null;
    _roomMembers = null;
    _canSendSelf = null;
    _startedAt = null;
    _remainingMilliseconds = 0;
    _expiresAt = null;
    _lastTap = null;
    _tapCount = 0;
    if (mounted) {
      state = RoomGiftSendState(catalog: state.catalog, isSending: _inFlight);
    }
  }

  bool _endChangedCombo() {
    resetCombo();
    state = RoomGiftSendState(catalog: state.catalog, issue: 'comboChanged');
    return false;
  }

  void _restartCountdown() {
    _echoTimeout?.cancel();
    _remainingMilliseconds = 5000;
    _expiresAt = _now().add(const Duration(seconds: 5));
    _publishCountdown();
    _echoTimeout = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _remainingMilliseconds -= 250;
      final wallRemaining = _expiresAt?.difference(_now()).inMilliseconds ?? 0;
      if (wallRemaining < _remainingMilliseconds) {
        _remainingMilliseconds = wallRemaining;
      }
      if (_remainingMilliseconds <= 0) {
        resetCombo();
      } else {
        _publishCountdown();
      }
    });
  }

  bool _expireIfNeeded() {
    if (_expiresAt == null || _now().isBefore(_expiresAt!)) return false;
    resetCombo();
    return true;
  }

  Future<void> _giveFeedback() async {
    try {
      await _feedback();
    } catch (error) {
      _log('feedback failed: $error');
    }
  }

  void _publishCountdown() {
    if (!mounted) return;
    state = RoomGiftSendState(
      isSending: state.isSending,
      awaitingEcho: state.awaitingEcho,
      message: state.message,
      gift: state.gift,
      confirmedComboId: state.confirmedComboId,
      request: state.request,
      catalog: state.catalog,
      issue: state.issue,
      remainingMilliseconds: _remainingMilliseconds,
      tapCount: _tapCount,
    );
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[RoomGiftSend][$roomId] $message');
  }

  @override
  void dispose() {
    _echoTimeout?.cancel();
    super.dispose();
  }
}

RoomGiftCatalog deductGift(
  RoomGiftCatalog catalog,
  RoomGift gift,
  int total,
  int balance,
) {
  return catalog.copyWith(
    balance: balance,
    tabs: [
      for (final tab in catalog.tabs)
        tab.copyWith(
          gifts: [
            for (final item in tab.gifts)
              if (gift.isBackpack && item.selectionKey == gift.selectionKey)
                item.copyWith(
                  amount: ((item.amount ?? 0) - total).clamp(
                    0,
                    item.amount ?? 0,
                  ),
                )
              else
                item,
          ],
        ),
    ],
  );
}
