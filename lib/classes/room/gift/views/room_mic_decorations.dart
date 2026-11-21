import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../interaction/room_animated_artwork.dart';
import '../../interaction/room_expression_sheet.dart';
import '../../viewmodel/room_state.dart';
import '../effects/room_gift_asset_resolver.dart';
import '../effects/room_gift_effect_player.dart';
import '../effects/room_gift_playback_barrier.dart';
import '../event/room_gift_event_provider.dart';
import '../event/room_gift_event_manager.dart';
import '../event/room_gift_room_id_provider.dart';
import '../models/room_mic_effect.dart';

final _micPlaybackProvider = Provider.autoDispose
    .family<RoomGiftPlaybackBarrier, (String, int)>(
      (ref, key) => RoomGiftPlaybackBarrier(),
    );

/// Independent from the full-screen lane: wave, frame and one temporary layer.
class RoomMicDecorations extends ConsumerWidget {
  const RoomMicDecorations({super.key, required this.seat});
  final RoomSeatViewData seat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(roomGiftRoomIdProvider(''));
    if (roomId.isEmpty || !seat.isOccupied || !TickerMode.of(context)) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(roomGiftEventManagerProvider(roomId));
    final barrier = ref.watch(_micPlaybackProvider((roomId, seat.position)));
    if (!state.isVisible) return const SizedBox.shrink();
    final effect = state.micEffects[seat.position];
    final frame = seat.appearance.frameUrl;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (frame != null && frame.isNotEmpty)
            RoomAnimatedArtwork(
              key: ValueKey('${seat.uid}:$frame'),
              url: frame,
              preview: seat.appearance.framePreview,
              repeat: true,
            ),
          if (effect != null && effect.uid == seat.uid)
            _TemporaryEffect(
              key: ValueKey(effect.key),
              effect: effect,
              barrier: barrier,
              onEnd: () => ref
                  .read(roomGiftEventManagerProvider(roomId).notifier)
                  .completeMicEffect(seat.position, effect.key),
            ),
        ],
      ),
    );
  }
}

class _TemporaryEffect extends ConsumerStatefulWidget {
  const _TemporaryEffect({
    super.key,
    required this.effect,
    required this.barrier,
    required this.onEnd,
  });
  final RoomMicEffect effect;
  final RoomGiftPlaybackBarrier barrier;
  final VoidCallback onEnd;
  @override
  ConsumerState<_TemporaryEffect> createState() => _TemporaryEffectState();
}

class _TemporaryEffectState extends ConsumerState<_TemporaryEffect> {
  final _player = GlobalKey<RoomGiftEffectPlayerState>();
  Timer? _timer;
  bool _ending = false;
  @override
  void initState() {
    super.initState();
    final remaining = widget.effect.expiresAt.difference(DateTime.now());
    _timer = Timer(remaining.isNegative ? Duration.zero : remaining, _finish);
  }

  Future<void> _finish() async {
    if (_ending || !mounted) return;
    _ending = true;
    _timer?.cancel();
    try {
      await _player.currentState?.stop();
      if (mounted) widget.onEnd();
    } catch (error) {
      debugPrint('[RoomGift] Mic effect release blocked: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gift = widget.effect.gift;
    if (RoomGiftAssetResolver.formatFor(gift) ==
        RoomGiftAnimationFormat.native) {
      return RoomPublicImage(url: gift.animationUrl, fit: BoxFit.contain);
    }
    final resource = ref.watch(roomGiftAnimationProvider(gift));
    return resource.when(
      data: (value) => _ending && _player.currentState == null
          ? const SizedBox.shrink()
          : RoomGiftEffectPlayer(
              key: _player,
              resource: value,
              playbackBarrier: widget.barrier,
              startBefore: widget.effect.expiresAt,
              onEnd: _finish,
              onPlaybackFailed: (_) => _finish(),
            ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _finish();
        });
        return const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
