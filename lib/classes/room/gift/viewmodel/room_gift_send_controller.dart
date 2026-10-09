import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/room_gift_event_models.dart';
import '../models/room_gift_models.dart';
import '../room_gift_repository.dart';
import 'room_gift_state.dart';

final roomGiftSendControllerProvider = StateNotifierProvider.autoDispose
    .family<RoomGiftSendController, RoomGiftSendState, String>((ref, roomId) {
      return RoomGiftSendController(
        ref.watch(roomGiftRepositoryProvider),
        roomId,
      );
    });

class RoomGiftSendState {
  const RoomGiftSendState({
    this.isSending = false,
    this.awaitingEcho = false,
    this.message,
    this.gift,
    this.confirmedComboId = '',
    this.request,
    this.catalog,
    this.issue,
  });
  final bool isSending, awaitingEcho;
  final RoomScreenGiftMsg? message;
  final RoomGift? gift;
  final String confirmedComboId;
  String get comboId =>
      confirmedComboId.isNotEmpty ? confirmedComboId : message?.comboId ?? '';
  final SendRoomGiftRequest? request;
  final RoomGiftCatalog? catalog;
  final String? issue;
  bool get canContinue =>
      !isSending && gift?.isCombo == 1 && comboId.isNotEmpty && request != null;

  bool matches(RoomScreenGiftMsg other) =>
      comboId.isNotEmpty &&
      comboId == other.comboId &&
      gift?.id == other.gift.id &&
      request?.giftSource == other.giftSource;
}

class RoomGiftSendException implements Exception {
  const RoomGiftSendException(this.issue);
  final RoomGiftIssue issue;
}

/// HTTP confirms the combo button; only broadcasts supply visual gift events.
class RoomGiftSendController extends StateNotifier<RoomGiftSendState> {
  RoomGiftSendController(this._repository, this.roomId)
    : super(const RoomGiftSendState());
  final RoomGiftRepository _repository;
  final String roomId;
  RoomGiftSendState get snapshot => state;
  RoomGift? _gift;
  int _targetCount = 0;
  int _generation = 0;
  DateTime? _startedAt;
  RoomGiftAudience? audience;
  int? currentUid;
  bool _inFlight = false;
  Timer? _echoTimeout;

  Future<RoomGiftCatalog?> send({
    required SendRoomGiftRequest request,
    required RoomGift gift,
    required int targetCount,
    required RoomGiftCatalog catalog,
  }) async {
    if (_inFlight) return null;
    if (audience?.isInRoom == false) {
      throw const RoomGiftSendException(RoomGiftIssue.roomUnavailable);
    }
    if (targetCount <= 0 || request.giftCount <= 0) {
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
    _inFlight = true;
    _gift = gift;
    _targetCount = targetCount;
    _startedAt = DateTime.now();
    final previousMessage = request.comboId.isEmpty ? null : state.message;
    final previousComboId = request.comboId;
    _echoTimeout?.cancel();
    state = RoomGiftSendState(
      isSending: true,
      request: request,
      catalog: catalog,
      message: previousMessage,
      gift: gift,
      confirmedComboId: previousComboId,
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
            confirmedId.isEmpty && state.message == null && gift.isCombo == 1,
      );
      _log(
        'confirmed giftId=${gift.id} comboId=${state.comboId} '
        'comboEnabled=${state.canContinue}',
      );
      _echoTimeout?.cancel();
      _echoTimeout = Timer(const Duration(seconds: 5), resetCombo);
      return updated;
    } catch (error) {
      if (mounted && generation == _generation) {
        state = RoomGiftSendState(
          request: request,
          catalog: catalog,
          message: previousMessage,
          gift: gift,
          confirmedComboId: previousComboId,
          issue: error.toString(),
        );
        if (previousComboId.isNotEmpty) {
          _echoTimeout = Timer(const Duration(seconds: 5), resetCombo);
        }
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
    );
    _echoTimeout?.cancel();
    _echoTimeout = Timer(const Duration(seconds: 5), resetCombo);
  }

  Future<bool> continueCombo() async {
    if (!state.canContinue) return false;
    final previous = state.request!;
    final comboId = state.comboId;
    final catalog = _repository.cachedCatalog ?? state.catalog;
    if (catalog == null || _gift == null) return false;
    final eligible = audience?.recipients
        .where((user) => catalog.canSendSelf || user.uid != currentUid)
        .map((user) => user.uid)
        .toSet();
    if (eligible != null &&
        previous.targetUids != null &&
        (!eligible.containsAll(previous.targetUids!) ||
            previous.sendType == RoomGiftSendType.onMic &&
                eligible.length != previous.targetUids!.length)) {
      resetCombo();
      return false;
    }
    if (previous.sendType == RoomGiftSendType.onRoom && audience != null) {
      _targetCount = (audience!.onlineCount - (catalog.canSendSelf ? 0 : 1))
          .clamp(0, audience!.onlineCount);
    }
    final gift =
        catalog.tabs
            .expand((tab) => tab.gifts)
            .where((gift) => gift.selectionKey == _gift!.selectionKey)
            .firstOrNull ??
        _gift!;
    try {
      final result = await send(
        request: SendRoomGiftRequest(
          targetUids: previous.targetUids,
          sendType: previous.sendType,
          roomId: roomId,
          giftId: gift.id,
          giftCount: previous.giftCount,
          giftSource: previous.giftSource,
          comboId: comboId,
          // Nady sends the number of taps in this request, not a running total.
          comboCount: 1,
          price: gift.price,
          userBackpackId: gift.userBackpackId,
        ),
        gift: gift,
        targetCount: _targetCount,
        catalog: catalog,
      );
      return result != null;
    } catch (error) {
      if (mounted) {
        state = RoomGiftSendState(
          request: state.request,
          catalog: state.catalog,
          message: state.message,
          gift: state.gift,
          confirmedComboId: state.confirmedComboId,
          issue: error is RoomGiftSendException
              ? error.issue.name
              : error.toString(),
        );
      }
      return false;
    }
  }

  void resetCombo() {
    _echoTimeout?.cancel();
    _generation++;
    _gift = null;
    _startedAt = null;
    if (mounted) {
      state = RoomGiftSendState(catalog: state.catalog, isSending: _inFlight);
    }
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
