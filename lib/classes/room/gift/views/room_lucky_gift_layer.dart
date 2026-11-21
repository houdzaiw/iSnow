import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/room_gift_event_models.dart';
import '../viewmodel/room_lucky_animation_provider.dart';
import '../effects/room_gift_effect_player.dart';
import '../effects/room_gift_playback_barrier.dart';

/// A full canvas is needed: Nady's transparent VAP already positions the numbers.
class RoomLuckyGiftLayer extends ConsumerStatefulWidget {
  const RoomLuckyGiftLayer({
    super.key,
    required this.result,
    required this.onEnd,
    this.currentUid,
    this.stopRequested = false,
  });
  final RoomLuckyGiftResult result;
  final VoidCallback onEnd;
  final int? currentUid;
  final bool stopRequested;
  @override
  ConsumerState<RoomLuckyGiftLayer> createState() => _RoomLuckyGiftLayerState();
}

class _RoomLuckyGiftLayerState extends ConsumerState<RoomLuckyGiftLayer> {
  final _player = GlobalKey<RoomGiftEffectPlayerState>();
  bool _finishing = false, _failed = false, _scheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.stopRequested) _scheduleStop();
  }

  @override
  void didUpdateWidget(RoomLuckyGiftLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stopRequested) _scheduleStop();
  }

  void _scheduleStop() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_finish());
    });
  }

  Future<void> _finish() async {
    if (_finishing || _failed || !mounted) return;
    setState(() => _finishing = true);
    try {
      await _player.currentState?.stop();
      if (mounted) widget.onEnd();
    } catch (error) {
      _releaseFailed(error);
    }
  }

  void _releaseFailed(Object error) {
    debugPrint('[RoomGift] Numeric handover blocked: $error');
    if (mounted) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_finishing && _player.currentState == null) {
      return const SizedBox.shrink();
    }
    final animation = ref.watch(
      roomLuckyAnimationProvider((
        result: widget.result,
        currentUid: widget.currentUid,
      )),
    );
    return IgnorePointer(
      child: animation.when(
        data: (resource) {
          if (resource == null) {
            _scheduleStop();
            return const SizedBox.shrink();
          }
          if ((_finishing || widget.stopRequested) &&
              _player.currentState == null) {
            return const SizedBox.shrink();
          }
          return RoomGiftEffectPlayer(
            key: _player,
            resource: resource,
            fit: BoxFit.cover,
            onEnd: _scheduleStop,
            onPlaybackFailed: (_) => _scheduleStop(),
            playbackBarrier: ref.read(roomGiftPlaybackBarrierProvider),
            onReleaseFailed: _releaseFailed,
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) {
          _scheduleStop();
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
