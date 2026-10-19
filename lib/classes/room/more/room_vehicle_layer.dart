import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../gift/effects/room_gift_effect_layer.dart';
import '../gift/event/room_gift_event_manager.dart';
import '../gift/models/room_gift_event_models.dart';
import '../gift/models/room_gift_models.dart';
import 'room_tools_controller.dart';
import 'room_tools_models.dart';

class RoomVehicleLayer extends ConsumerWidget {
  const RoomVehicleLayer({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    final vehicle = state.vehicleEffects.firstOrNull;
    if (!state.sessionActive || vehicle == null) return const SizedBox.shrink();
    return _VehicleTask(
      key: ValueKey(vehicle['_key']),
      roomId: roomId,
      user: vehicle,
    );
  }
}

class _VehicleTask extends ConsumerStatefulWidget {
  const _VehicleTask({super.key, required this.roomId, required this.user});
  final String roomId;
  final ToolJson user;
  @override
  ConsumerState<_VehicleTask> createState() => _VehicleTaskState();
}

class _VehicleTaskState extends ConsumerState<_VehicleTask> {
  final _tasks = <String, RoomGiftEffectTask>{};
  final _pending = <String>{};
  Timer? _watchdog;
  bool _completed = false;
  @override
  void initState() {
    super.initState();
    for (final name in ['vehicle', 'specialEffects']) {
      final effect = toolMap(widget.user[name]);
      final url = '${effect['animationUrl'] ?? ''}';
      if (url.isEmpty) continue;
      _pending.add(name);
      final gift = RoomGift(
        id: -1,
        tabId: -1,
        name: '${widget.user['nick'] ?? ''}',
        icon: '${widget.user['avatar'] ?? ''}',
        price: 0,
        isCombo: 0,
        animationUrl: url,
        animationType: toolInt(effect['animationType']),
        direction: toolInt(effect['direction'], 1),
      );
      _tasks[name] = RoomGiftEffectTask(
        key: '${widget.user['_key']}:$name',
        createdAt: DateTime.now(),
        message: RoomScreenGiftMsg(
          gift: gift,
          uid: toolInt(widget.user['uid']),
          userInfo: RoomGiftUser.fromJson(widget.user),
          roomId: widget.roomId,
          giftCount: 1,
        ),
      );
    }
    _watchdog = Timer(const Duration(seconds: 30), _finish);
    if (_pending.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
  }

  void _finish() {
    if (!mounted || _completed) return;
    _completed = true;
    _watchdog?.cancel();
    ref
        .read(roomToolsControllerProvider(widget.roomId).notifier)
        .completeVehicle('${widget.user['_key']}');
  }

  void _end(String name) {
    if (!mounted || !_pending.remove(name)) return;
    if (_pending.isEmpty) {
      _finish();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: [
        for (final entry in _tasks.entries)
          if (_pending.contains(entry.key))
            Positioned.fill(
              child: RoomGiftFullScreenEffectLayer(
                tasks: [entry.value],
                onCompleted: (_) => _end(entry.key),
              ),
            ),
      ],
    ),
  );
  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }
}
