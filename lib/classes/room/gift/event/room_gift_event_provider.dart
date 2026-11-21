import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../manager/app_socket_manager.dart';
import '../../../../manager/room_manager.dart';
import '../../../../manager/room_animation_performance_manager.dart';
import '../../room_repository.dart';
import '../models/room_gift_models.dart';
import '../effects/room_gift_asset_resolver.dart';
import '../models/room_gift_event_models.dart';
import '../viewmodel/room_gift_send_controller.dart';
import 'room_gift_event_manager.dart';

final roomGiftPerformanceProvider = StateNotifierProvider.autoDispose
    .family<RoomAnimationPerformanceManager, RoomAnimationQuality, String>(
      (ref, roomId) => RoomAnimationPerformanceManager(),
    );

final roomGiftEventManagerProvider = StateNotifierProvider.autoDispose
    .family<RoomGiftEventManager, RoomGiftEventState, String>((ref, roomId) {
      final repository = ref.watch(roomRepositoryProvider);
      final sender = ref.watch(roomGiftSendControllerProvider(roomId).notifier);
      final resolver = ref.watch(roomGiftAssetResolverProvider);
      final manager = RoomGiftEventManager(
        roomId: roomId,
        barrageManaged: true,
        messages: repository.socketMessages,
        onSelfGift: sender.acknowledge,
        preparePrize: (task) async {
          await resolver.resolveTask(task);
        },
        prepareEntrance: (entry) async {
          await Future.wait([
            if (entry.trackUrl.isNotEmpty)
              resolver.resolveSource(
                entry.trackUrl,
                format: RoomGiftAssetResolver.formatForSource(entry.trackUrl),
              ),
            if (entry.vehicle != null) resolver.resolve(entry.vehicle!),
          ]);
        },
        activeJackpotGift: (giftId) {
          final value = sender.snapshot;
          if (!value.canContinue ||
              value.gift?.id != giftId ||
              value.gift?.giftType != 3) {
            return null;
          }
          return value.message ??
              RoomScreenGiftMsg(
                gift: value.gift!,
                uid: sender.currentUid ?? 0,
                userInfo: RoomGiftUser(uid: sender.currentUid ?? 0),
                roomId: roomId,
                giftCount: 1,
              );
        },
        onComboEnd: (id) {
          if (id.isEmpty || sender.snapshot.comboId == id) {
            sender.resetCombo();
          }
        },
      );
      final binding = _RoomGiftLifecycle(
        manager,
        repository,
        roomId,
        ref.keepAlive,
        sender,
      );
      ref.listen(roomGiftSendControllerProvider(roomId), (previous, next) {
        final id = previous?.comboId ?? '';
        final wasVisible =
            previous?.canContinue == true ||
            previous?.isSending == true && id.isNotEmpty;
        final isVisible =
            next.canContinue || next.isSending && next.comboId.isNotEmpty;
        if (wasVisible && (!isVisible || next.comboId != id)) {
          manager.cancelComboFlights(id, uid: manager.currentUid);
        }
      });
      Future.microtask(() {
        if (manager.isAlive) binding.start();
      });
      final generation = repository.roomGeneration;
      unawaited(() async {
        try {
          final uid = await repository.currentUid();
          if (!manager.isAlive || repository.roomGeneration != generation) {
            return;
          }
          manager.currentUid = uid;
          sender.currentUid = uid;
          final user = await repository.currentUser();
          final currentUid = await repository.currentUid();
          if (manager.isAlive &&
              repository.roomGeneration == generation &&
              currentUid == uid) {
            manager.countryCode = user?.countryCode;
          }
        } catch (_) {
          // Optional local identity decoration must not break room event delivery.
        }
      }());
      ref.onDispose(binding.dispose);
      return manager;
    });

/// Keeps only the room's socket subscription alive while it is minimized.
class _RoomGiftLifecycle with WidgetsBindingObserver {
  _RoomGiftLifecycle(
    this.manager,
    this.repository,
    this.roomId,
    this.retain,
    this.sender,
  );
  final RoomGiftEventManager manager;
  final RoomRepository repository;
  final String roomId;
  final KeepAliveLink Function() retain;
  final RoomGiftSendController sender;
  KeepAliveLink? _keepAlive;
  bool _foreground = true;
  AppSocketStatus? _socketStatus;

  void start() {
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    repository.addListener(_sync);
    _sync();
  }

  void _sync() {
    final room = repository.roomState;
    sender.audience = repository.giftAudience(roomId);
    final inRoom =
        room.currentRoomId == roomId &&
        room.isInRoom &&
        room.status == RoomStatus.ready;
    if (!inRoom) {
      sender.audience = const RoomGiftAudience(
        isInRoom: false,
        onlineCount: 0,
        recipients: [],
      );
      manager.setSessionActive(false);
      _keepAlive?.close();
      _keepAlive = null;
      return;
    }
    manager.setSessionActive(true);
    manager.syncMicOccupants({
      for (final mic in room.micList)
        if (mic.uid != null && mic.uid! > 0) mic.position: mic.uid!,
    });
    _keepAlive ??= retain();
    final status = repository.socketState.status;
    if (_socketStatus == AppSocketStatus.ready &&
        status != AppSocketStatus.ready) {
      // A transient socket reconnect does not undo a paid HTTP confirmation.
      manager.reset(resetCombo: false);
    }
    _socketStatus = status;
    manager.setVisible(inRoom && !room.isMinimized && _foreground);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void dispose() {
    repository.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    _keepAlive?.close();
  }
}
