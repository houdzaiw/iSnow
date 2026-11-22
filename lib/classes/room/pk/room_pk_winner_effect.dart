import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

import '../../../theme/app_theme.dart';
import '../gift/effects/room_gift_asset_resolver.dart';
import '../gift/effects/room_gift_playback_barrier.dart';
import 'room_pk_models.dart';

class RoomPkWinnerEffect extends ConsumerStatefulWidget {
  const RoomPkWinnerEffect({
    super.key,
    required this.user,
    required this.onEnd,
  });
  final RoomPkUser user;
  final VoidCallback onEnd;
  @override
  ConsumerState<RoomPkWinnerEffect> createState() => _RoomPkWinnerEffectState();
}

class _RoomPkWinnerEffectState extends ConsumerState<RoomPkWinnerEffect>
    with SingleTickerProviderStateMixin {
  late final controller = SVGAAnimationController(vsync: this);
  RoomGiftPlaybackLease? lease;
  Timer? watchdog;
  bool ended = false, released = false;
  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      lease = await ref.read(roomGiftPlaybackBarrierProvider).acquire();
      if (!mounted || ended) {
        await lease?.release(() async {});
        return;
      }
      watchdog = Timer(const Duration(seconds: 15), _end);
      final movie = await SVGAParser.shared.decodeFromAssets(
        AppAssets.roomActivityPkWin,
      );
      if (!mounted || ended) {
        movie.dispose();
        return;
      }
      final file = await ref
          .read(roomGiftAssetResolverProvider)
          .resolveImage(widget.user.avatar);
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted || ended) {
        frame.image.dispose();
        movie.dispose();
        return;
      }
      movie.bitmapCache['avatar02'] = frame.image;
      movie.dynamicItem.setText(
        TextPainter(
          text: TextSpan(
            text: widget.user.name,
            style: RoomActivityTheme.winnerText,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        ),
        'userName',
      );
      controller.videoItem = movie;
      setState(() {});
      await controller.forward().orCancel;
      _end();
    } catch (_) {
      _end();
    }
  }

  void _end() {
    if (ended) return;
    ended = true;
    watchdog?.cancel();
    controller.stop();
    unawaited(lease?.release(() async {}) ?? Future.value());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onEnd();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: controller.videoItem == null
        ? const SizedBox.shrink()
        : SVGAImage(controller, fit: BoxFit.contain),
  );
  @override
  void dispose() {
    ended = true;
    watchdog?.cancel();
    controller.dispose();
    released = true;
    unawaited(lease?.release(() async {}) ?? Future.value());
    super.dispose();
  }
}
