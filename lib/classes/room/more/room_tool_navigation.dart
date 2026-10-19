import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../gift/views/room_gift_sheet.dart';
import '../room_repository.dart';

Future<void> openRoomToolGift(
  BuildContext context,
  WidgetRef ref,
  String roomId, {
  int? targetUid,
  int? giftId,
  bool backpack = false,
}) async {
  final repository = ref.read(roomRepositoryProvider);
  final audience = repository.giftAudience(roomId);
  if (!audience.isInRoom) return;
  final generation = repository.roomGeneration;
  final uid = await repository.currentUid();
  if (!context.mounted ||
      generation != repository.roomGeneration ||
      !repository.giftAudience(roomId).isInRoom) {
    return;
  }
  final result = await showRoomGiftSheet(
    context: context,
    roomId: roomId,
    onlineCount: audience.onlineCount,
    currentUid: uid,
    recipients: audience.recipients,
    targetUid: targetUid,
    presetGiftId: giftId,
    backpack: backpack,
  );
  if (context.mounted && result == RoomGiftSheetResult.openWallet) {
    await context.push('/wallet');
  }
}
