import '../models/room_gift_event_models.dart';
import '../models/room_gift_models.dart';

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
    this.remainingMilliseconds = 0,
    this.tapCount = 0,
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
  final int remainingMilliseconds;
  final int tapCount;
  bool get canContinue =>
      !isSending &&
      gift?.supportsCombo == true &&
      comboId.isNotEmpty &&
      request != null;

  bool matches(RoomScreenGiftMsg other) =>
      comboId.isNotEmpty &&
      comboId == other.comboId &&
      gift?.id == other.gift.id &&
      request?.giftSource == other.giftSource;

  RoomGiftSendState withCatalog(RoomGiftCatalog value) => RoomGiftSendState(
    isSending: isSending,
    awaitingEcho: awaitingEcho,
    message: message,
    gift: gift,
    confirmedComboId: confirmedComboId,
    request: request,
    catalog: value,
    issue: issue,
    remainingMilliseconds: remainingMilliseconds,
    tapCount: tapCount,
  );
}
