import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../event/room_gift_event_manager.dart';
import 'room_gift_asset_resolver.dart';
import 'room_gift_effect_player.dart';

class RoomGiftFullScreenEffectLayer extends ConsumerWidget {
  const RoomGiftFullScreenEffectLayer({
    super.key,
    required this.tasks,
    required this.onCompleted,
  });
  final List<RoomGiftEffectTask> tasks;
  final ValueChanged<String> onCompleted;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final task = tasks.first;
    final resource = ref.watch(roomGiftAnimationProvider(task.message.gift));
    return IgnorePointer(
      child: resource.when(
        data: (data) => RoomGiftEffectPlayer(
          key: ValueKey(task.key),
          resource: data,
          gift: task.message.gift,
          onEnd: () => onCompleted(task.key),
        ),
        loading: () => const SizedBox.shrink(),
        error: (error, _) {
          debugPrint('[RoomGift] Resource failed: $error');
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => onCompleted(task.key),
          );
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
