import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/room_manager.dart';
import '../gift/event/room_gift_event_provider.dart';
import '../gift/models/room_gift_event_models.dart';
import '../gift/viewmodel/room_gift_send_controller.dart';
import 'room_barrage_repository.dart';
import 'room_barrage_view_model.dart';

final roomBarrageProvider =
    StateNotifierProvider<RoomBarrageViewModel, RoomBarrageState>((ref) {
      final repository = ref.watch(roomBarrageRepositoryProvider);
      final vm = RoomBarrageViewModel(
        repository,
        activeJackpotGift: (giftId) {
          final room = repository.roomState;
          if (!room.isInRoom || room.currentRoomId == null) return null;
          final sender = ref.read(
            roomGiftSendControllerProvider(room.currentRoomId!).notifier,
          );
          final combo = sender.snapshot;
          if (!combo.canContinue ||
              combo.gift?.id != giftId ||
              combo.gift?.giftType != 3) {
            return null;
          }
          return combo.message ??
              RoomScreenGiftMsg(
                gift: combo.gift!,
                uid: sender.currentUid ?? 0,
                userInfo: RoomGiftUser(uid: sender.currentUid ?? 0),
                roomId: room.currentRoomId!,
                giftCount: 1,
              );
        },
        onPresentedEffect: (task) {
          final room = repository.roomState;
          if (room.currentRoomId == null ||
              !room.isInRoom ||
              room.isMinimized ||
              room.status != RoomStatus.ready) {
            return;
          }
          ref
              .read(roomGiftEventManagerProvider(room.currentRoomId!).notifier)
              .enqueueFullscreen(task);
        },
      );
      Future.microtask(() {
        if (vm.mounted) vm.start();
      });
      ref.onDispose(() => unawaited(repository.bindAccount(null)));
      return vm;
    });
