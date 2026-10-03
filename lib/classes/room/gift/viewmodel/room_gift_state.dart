import '../models/room_gift_models.dart';

enum RoomGiftLoadStatus { initial, loading, ready, error }

enum RoomGiftIssue {
  chooseGift,
  noRecipient,
  notEnoughCoin,
  notEnoughGift,
  requestFailed,
}

class RoomGiftState {
  const RoomGiftState({
    required this.roomId,
    this.status = RoomGiftLoadStatus.initial,
    this.balance = 0,
    this.canSendSelf = true,
    this.onlineCount = 0,
    this.currentUid,
    this.tabs = const [],
    this.recipients = const [],
    this.targetMode = RoomGiftTargetMode.allRoom,
    this.selectedRecipientUids = const {},
    this.selectedTabId,
    this.selectedGiftKey,
    this.giftCount = 1,
    this.isSending = false,
    this.loadErrorMessage,
    this.issue,
    this.issueMessage,
  });

  final String roomId;
  final RoomGiftLoadStatus status;
  final int balance;
  final bool canSendSelf;
  final int onlineCount;
  final int? currentUid;
  final List<RoomGiftTab> tabs;
  final List<RoomGiftRecipient> recipients;
  final RoomGiftTargetMode targetMode;
  final Set<int> selectedRecipientUids;
  final int? selectedTabId;
  final String? selectedGiftKey;
  final int giftCount;
  final bool isSending;
  final String? loadErrorMessage;
  final RoomGiftIssue? issue;
  final String? issueMessage;

  bool get isLoading => status == RoomGiftLoadStatus.loading;
  bool get hasContent => tabs.any((tab) => tab.gifts.isNotEmpty);

  RoomGiftTab? get selectedTab {
    for (final tab in tabs) {
      if (tab.id == selectedTabId) return tab;
    }
    return tabs.isEmpty ? null : tabs.first;
  }

  RoomGift? get selectedGift {
    for (final tab in tabs) {
      for (final gift in tab.gifts) {
        if (gift.selectionKey == selectedGiftKey) return gift;
      }
    }
    return null;
  }

  int get targetCount {
    return switch (targetMode) {
      RoomGiftTargetMode.allMic ||
      RoomGiftTargetMode.selected => selectedRecipientUids.length,
      RoomGiftTargetMode.allRoom => onlineCount > 0 ? onlineCount : 1,
    };
  }

  RoomGiftState copyWith({
    RoomGiftLoadStatus? status,
    int? balance,
    bool? canSendSelf,
    int? onlineCount,
    Object? currentUid = _sentinel,
    List<RoomGiftTab>? tabs,
    List<RoomGiftRecipient>? recipients,
    RoomGiftTargetMode? targetMode,
    Set<int>? selectedRecipientUids,
    Object? selectedTabId = _sentinel,
    Object? selectedGiftKey = _sentinel,
    int? giftCount,
    bool? isSending,
    Object? loadErrorMessage = _sentinel,
    Object? issue = _sentinel,
    Object? issueMessage = _sentinel,
  }) {
    return RoomGiftState(
      roomId: roomId,
      status: status ?? this.status,
      balance: balance ?? this.balance,
      canSendSelf: canSendSelf ?? this.canSendSelf,
      onlineCount: onlineCount ?? this.onlineCount,
      currentUid: identical(currentUid, _sentinel)
          ? this.currentUid
          : currentUid as int?,
      tabs: tabs ?? this.tabs,
      recipients: recipients ?? this.recipients,
      targetMode: targetMode ?? this.targetMode,
      selectedRecipientUids:
          selectedRecipientUids ?? this.selectedRecipientUids,
      selectedTabId: identical(selectedTabId, _sentinel)
          ? this.selectedTabId
          : selectedTabId as int?,
      selectedGiftKey: identical(selectedGiftKey, _sentinel)
          ? this.selectedGiftKey
          : selectedGiftKey as String?,
      giftCount: giftCount ?? this.giftCount,
      isSending: isSending ?? this.isSending,
      loadErrorMessage: identical(loadErrorMessage, _sentinel)
          ? this.loadErrorMessage
          : loadErrorMessage as String?,
      issue: identical(issue, _sentinel) ? this.issue : issue as RoomGiftIssue?,
      issueMessage: identical(issueMessage, _sentinel)
          ? this.issueMessage
          : issueMessage as String?,
    );
  }
}

const Object _sentinel = Object();
