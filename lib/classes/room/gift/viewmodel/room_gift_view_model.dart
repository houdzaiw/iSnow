import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/server_response.dart';
import '../models/room_gift_models.dart';
import '../room_gift_repository.dart';
import 'room_gift_state.dart';

final roomGiftViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomGiftViewModel, RoomGiftState, String>((ref, roomId) {
      return RoomGiftViewModel(
        repository: ref.watch(roomGiftRepositoryProvider),
        roomId: roomId,
      );
    });

class RoomGiftViewModel extends StateNotifier<RoomGiftState> {
  RoomGiftViewModel({
    required RoomGiftRepository repository,
    required String roomId,
  }) : _repository = repository,
       super(RoomGiftState(roomId: roomId));

  final RoomGiftRepository _repository;
  bool _initialized = false;
  List<RoomGiftRecipient> _sourceRecipients = const [];

  Future<void> initialize({
    required List<RoomGiftRecipient> recipients,
    required int onlineCount,
    required int? currentUid,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _sourceRecipients = recipients;
    state = state.copyWith(
      recipients: recipients,
      onlineCount: onlineCount,
      currentUid: currentUid,
    );
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(
      status: RoomGiftLoadStatus.loading,
      loadErrorMessage: null,
      issue: null,
      issueMessage: null,
    );
    try {
      final catalog = await _repository.fetchCatalog();
      final availableRecipients = catalog.canSendSelf
          ? _sourceRecipients
          : _sourceRecipients
                .where((recipient) => recipient.uid != state.currentUid)
                .toList(growable: false);
      final firstTab = catalog.tabs.isEmpty ? null : catalog.tabs.first;
      final firstGift = firstTab?.gifts.isEmpty == false
          ? firstTab!.gifts.first
          : null;
      final recipientUids = availableRecipients
          .map((recipient) => recipient.uid)
          .toSet();
      state = state.copyWith(
        status: RoomGiftLoadStatus.ready,
        balance: catalog.balance,
        canSendSelf: catalog.canSendSelf,
        tabs: catalog.tabs,
        recipients: availableRecipients,
        targetMode: recipientUids.isEmpty
            ? RoomGiftTargetMode.allRoom
            : RoomGiftTargetMode.allMic,
        selectedRecipientUids: recipientUids,
        selectedTabId: firstTab?.id,
        selectedGiftKey: firstGift?.selectionKey,
        giftCount: firstGift?.defaultGiftNum ?? 1,
      );
    } catch (error) {
      state = state.copyWith(
        status: RoomGiftLoadStatus.error,
        loadErrorMessage: _errorMessage(error),
      );
    }
  }

  void selectTab(int tabId) {
    final tab = state.tabs.where((item) => item.id == tabId).firstOrNull;
    if (tab == null) return;
    final gift = tab.gifts.isEmpty ? null : tab.gifts.first;
    state = state.copyWith(
      selectedTabId: tab.id,
      selectedGiftKey: gift?.selectionKey,
      giftCount: gift?.defaultGiftNum ?? 1,
      issue: null,
      issueMessage: null,
    );
  }

  void selectGift(RoomGift gift) {
    state = state.copyWith(
      selectedTabId: gift.tabId,
      selectedGiftKey: gift.selectionKey,
      giftCount: gift.defaultGiftNum,
      issue: null,
      issueMessage: null,
    );
  }

  void selectTargetMode(RoomGiftTargetMode mode) {
    var selected = state.selectedRecipientUids;
    if (mode == RoomGiftTargetMode.allMic) {
      selected = state.recipients.map((recipient) => recipient.uid).toSet();
    } else if (mode == RoomGiftTargetMode.allRoom) {
      selected = const <int>{};
    } else if ((state.targetMode != RoomGiftTargetMode.selected ||
            selected.isEmpty) &&
        state.recipients.isNotEmpty) {
      selected = <int>{state.recipients.first.uid};
    }
    state = state.copyWith(
      targetMode: mode,
      selectedRecipientUids: selected,
      issue: null,
      issueMessage: null,
    );
  }

  void toggleRecipient(int uid) {
    final selected = {...state.selectedRecipientUids};
    if (!selected.add(uid)) selected.remove(uid);
    final allSelected =
        selected.isNotEmpty && selected.length == state.recipients.length;
    state = state.copyWith(
      targetMode: allSelected
          ? RoomGiftTargetMode.allMic
          : RoomGiftTargetMode.selected,
      selectedRecipientUids: selected,
      issue: null,
      issueMessage: null,
    );
  }

  void setGiftCount(int count) {
    if (count <= 0) return;
    state = state.copyWith(giftCount: count, issue: null, issueMessage: null);
  }

  Future<bool> sendSelectedGift() async {
    if (state.isSending) return false;
    final gift = state.selectedGift;
    if (gift == null) {
      _setIssue(RoomGiftIssue.chooseGift);
      return false;
    }

    final targetUids = _targetUids();
    if (state.targetMode != RoomGiftTargetMode.allRoom && targetUids.isEmpty) {
      _setIssue(RoomGiftIssue.noRecipient);
      return false;
    }

    final totalCount = state.giftCount * state.targetCount;
    if (gift.isBackpack && (gift.amount ?? 0) < totalCount) {
      _setIssue(RoomGiftIssue.notEnoughGift);
      return false;
    }
    if (!gift.isBackpack && state.balance < gift.price * totalCount) {
      _setIssue(RoomGiftIssue.notEnoughCoin);
      return false;
    }

    state = state.copyWith(isSending: true, issue: null, issueMessage: null);
    try {
      await _repository.sendGift(
        SendRoomGiftRequest(
          targetUids: targetUids.isEmpty ? null : targetUids,
          sendType: _sendType(targetUids),
          roomId: state.roomId,
          giftId: gift.id,
          giftCount: state.giftCount,
          giftSource: gift.isBackpack ? 2 : 1,
          comboId: '',
          comboCount: 1,
          price: gift.price,
          userBackpackId: gift.userBackpackId,
        ),
      );
      final nextBalance = gift.isBackpack
          ? state.balance
          : state.balance - gift.price * totalCount;
      state = state.copyWith(isSending: false, balance: nextBalance);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        issue: RoomGiftIssue.requestFailed,
        issueMessage: _errorMessage(error),
      );
      return false;
    }
  }

  List<int> _targetUids() {
    if (state.targetMode == RoomGiftTargetMode.allRoom) return const [];
    return state.selectedRecipientUids.toList(growable: false);
  }

  RoomGiftSendType _sendType(List<int> targetUids) {
    return switch (state.targetMode) {
      RoomGiftTargetMode.allMic => RoomGiftSendType.onMic,
      RoomGiftTargetMode.allRoom => RoomGiftSendType.onRoom,
      RoomGiftTargetMode.selected =>
        targetUids.length == 1
            ? RoomGiftSendType.single
            : RoomGiftSendType.multi,
    };
  }

  void _setIssue(RoomGiftIssue issue) {
    state = state.copyWith(issue: issue, issueMessage: null);
  }

  String _errorMessage(Object error) {
    if (error is NadyApiException) return error.message;
    return error.toString();
  }
}
