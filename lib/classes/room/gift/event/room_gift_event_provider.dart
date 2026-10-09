import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../manager/app_socket_manager.dart';
import '../../../../manager/room_manager.dart';
import '../../room_repository.dart';
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
      final keepAlive = ref.keepAlive();
      final binding = _RoomGiftLifecycle(
        manager,
        repository,
        roomId,
        keepAlive.close,
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
    this.release,
    this.sender,
  );
  final RoomGiftEventManager manager;
  final RoomRepository repository;
  final String roomId;
  final VoidCallback release;
  final RoomGiftSendController sender;
  bool _hasEntered = false;
  bool _hasAttempted = false;
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
    final inRoom = room.currentRoomId == roomId && room.isInRoom;
    if (room.status == RoomStatus.entering) _hasAttempted = true;
    if (_hasAttempted && !inRoom && room.status == RoomStatus.error) release();
    if (inRoom) _hasEntered = true;
    if (_hasEntered && (!inRoom || room.status == RoomStatus.leaving)) {
      manager.reset(visible: false, clearHistory: true);
      release();
      return;
    }
    final status = repository.socketState.status;
    if (_socketStatus == AppSocketStatus.ready &&
        status != AppSocketStatus.ready) {
      manager.reset();
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
  }
}
