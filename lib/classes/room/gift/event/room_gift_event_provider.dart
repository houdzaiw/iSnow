import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../manager/app_socket_manager.dart';
import '../../../../manager/room_manager.dart';
import '../../room_repository.dart';
import '../models/room_gift_models.dart';
import '../viewmodel/room_gift_send_controller.dart';
import 'room_gift_event_manager.dart';

final roomGiftEventManagerProvider = StateNotifierProvider.autoDispose
    .family<RoomGiftEventManager, RoomGiftEventState, String>((ref, roomId) {
      final repository = ref.watch(roomRepositoryProvider);
      final sender = ref.watch(roomGiftSendControllerProvider(roomId).notifier);
      final manager = RoomGiftEventManager(
        roomId: roomId,
        messages: repository.socketMessages,
        onSelfGift: sender.acknowledge,
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
      Future.microtask(() {
        if (manager.isAlive) binding.start();
      });
      unawaited(
        repository.currentUid().then((uid) {
          if (manager.isAlive) {
            manager.currentUid = uid;
            sender.currentUid = uid;
          }
        }),
      );
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
