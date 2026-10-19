import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../gift/models/room_gift_models.dart';
import '../gift/room_gift_repository.dart';
import '../gift/viewmodel/room_gift_send_controller.dart';
import '../room_repository.dart';
import 'room_tools_models.dart';

final roomTreasureGiftProvider = Provider.autoDispose
    .family<RoomTreasureGiftViewModel, String>(
      (ref, roomId) => RoomTreasureGiftViewModel(
        roomId,
        ref.watch(roomRepositoryProvider),
        ref.watch(roomGiftRepositoryProvider),
        ref.watch(roomGiftSendControllerProvider(roomId).notifier),
      ),
    );

class RoomTreasureGiftViewModel {
  const RoomTreasureGiftViewModel(
    this.roomId,
    this.room,
    this.gifts,
    this.sender,
  );
  final String roomId;
  final RoomRepository room;
  final RoomGiftRepository gifts;
  final RoomGiftSendController sender;
  Future<void> send(ToolJson config) async {
    final generation = room.roomGeneration;
    final catalog = await gifts.fetchCatalog();
    final uid = await room.currentUid();
    if (room.roomGeneration != generation ||
        !room.giftAudience(roomId).isInRoom) {
      return;
    }
    final gift = catalog.tabs
        .expand((tab) => tab.gifts)
        .where(
          (gift) => !gift.isBackpack && gift.id == toolInt(config['giftId']),
        )
        .firstOrNull;
    if (gift == null || gift.price != toolInt(config['price'])) {
      throw StateError('Gift configuration changed');
    }
    final audience = room.giftAudience(roomId);
    final targets = audience.recipients
        .where((user) => catalog.canSendSelf || user.uid != uid)
        .map((user) => user.uid)
        .toList();
    final onMic = audience.recipients.isNotEmpty;
    sender.audience = audience;
    sender.currentUid = uid;
    await sender.send(
      request: SendRoomGiftRequest(
        roomId: roomId,
        giftId: gift.id,
        price: gift.price,
        giftCount: toolInt(config['defaultGiftNum'], 1),
        giftSource: 1,
        sendType: onMic ? RoomGiftSendType.onMic : RoomGiftSendType.onRoom,
        targetUids: onMic ? targets : null,
        comboCount: 1,
        comboId: '',
      ),
      gift: gift,
      catalog: catalog,
      targetCount: onMic
          ? targets.length
          : (audience.onlineCount - (catalog.canSendSelf ? 0 : 1)).clamp(
              0,
              audience.onlineCount,
            ),
    );
  }
}
