import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/app_socket_manager.dart';
import '../../../model/room_socket_message.dart';
import '../../../manager/room_manager.dart';
import '../../../manager/room_gift_manager.dart';
import '../room_repository.dart';
import '../gift/effects/room_gift_asset_resolver.dart';
import '../more/room_tools_repository.dart';
import '../more/room_tools_models.dart';
import 'room_barrage_models.dart';

final roomBarrageRepositoryProvider = Provider(
  (ref) => RoomBarrageRepository(
    room: ref.watch(roomRepositoryProvider),
    assets: ref.watch(roomGiftAssetResolverProvider),
    tools: ref.watch(roomToolsRepositoryProvider),
  ),
);

class RoomBarrageIdentity {
  const RoomBarrageIdentity(this.uid, this.country, this.effects);
  final int? uid;
  final String? country;
  final RoomEffectPreferences effects;
}

class RoomBarrageRepository {
  RoomBarrageRepository({
    required this.room,
    required this.assets,
    required this.tools,
    AppSocketManager? socket,
  }) : socket = socket ?? AppSocketManager.instance;
  final RoomRepository room;
  final RoomGiftAssetResolver assets;
  final RoomToolsRepository tools;
  final AppSocketManager socket;
  Stream<RoomSocketMessage> get messages => room.socketMessages;
  int get roomGeneration => room.roomGeneration;
  RoomState get roomState => room.roomState;
  void addRoomListener(VoidCallback callback) => room.addListener(callback);
  void removeRoomListener(VoidCallback callback) =>
      room.removeListener(callback);
  void addAuthListener(VoidCallback callback) => room.addAuthListener(callback);
  void removeAuthListener(VoidCallback callback) =>
      room.removeAuthListener(callback);
  Future<void> bindAccount(int? uid, {bool reauthenticate = false}) =>
      socket.bindBarrageAccount(uid, reauthenticate: reauthenticate);
  Future<void> endPreviousRoom() async {
    if (room.roomState.status != RoomStatus.idle) await room.leaveRoom();
  }

  Future<RoomBarrageIdentity> identity() async {
    if (!await room.isLoggedIn()) {
      return const RoomBarrageIdentity(null, null, RoomEffectPreferences());
    }
    final uid = await room.currentUid();
    final user = await room.currentUser();
    RoomEffectPreferences effects;
    try {
      effects = uid == null
          ? const RoomEffectPreferences()
          : await tools.effects(uid);
    } catch (_) {
      effects = const RoomEffectPreferences();
    }
    if (await room.currentUid() != uid) {
      throw StateError('Barrage account changed');
    }
    return RoomBarrageIdentity(uid, user?.countryCode, effects);
  }

  int giftValue(RoomBarrageTask task) {
    if (task.value > 0) return task.value;
    final catalog = RoomGiftManager.instance.catalog;
    final gifts = catalog?.tabs.expand((tab) => tab.gifts);
    final gift = gifts?.where((gift) => gift.id == task.giftId).firstOrNull;
    return (gift?.price ?? 0) * task.count;
  }

  Future<RoomBarragePrepared> prepare(RoomBarrageTask task) async {
    Future<RoomGiftAnimationResource?> read(String source) async {
      if (source.isEmpty) return null;
      if (!source.startsWith('assets/') && roomBarrageWebLink(source) == null) {
        throw const FormatException('Invalid barrage artwork');
      }
      return assets
          .resolveSource(
            source,
            format: RoomGiftAssetResolver.formatForSource(source),
          )
          .timeout(const Duration(seconds: 15));
    }

    final resources = await Future.wait([
      read(task.background),
      read(task.foreground),
      if (task.fullscreen != null) assets.resolveTask(task.fullscreen!),
    ]);
    return RoomBarragePrepared(
      task,
      background: resources[0],
      foreground: resources[1],
    );
  }

  Future<bool> waitForRoom(String target, bool Function() valid) async {
    if (!valid()) return false;
    bool ready() =>
        roomState.currentRoomId == target &&
        roomState.isInRoom &&
        roomState.status == RoomStatus.ready;
    if (ready()) return true;
    final done = Completer<bool>();
    void sync() {
      if (!valid()) {
        if (!done.isCompleted) done.complete(false);
      } else if (ready() && !done.isCompleted) {
        done.complete(true);
      } else if (roomState.status == RoomStatus.error && !done.isCompleted) {
        done.complete(false);
      }
    }

    addRoomListener(sync);
    try {
      return await done.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );
    } finally {
      removeRoomListener(sync);
    }
  }
}
