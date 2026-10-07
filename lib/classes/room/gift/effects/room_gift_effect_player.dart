import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_vap_plus/flutter_vap_plus.dart';
import 'package:pag/pag.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:video_player/video_player.dart';

import '../models/room_gift_models.dart';
import '../views/room_gift_image.dart';
import 'room_gift_asset_resolver.dart';

class RoomGiftEffectPlayer extends StatefulWidget {
  const RoomGiftEffectPlayer({
    super.key,
    required this.resource,
    required this.gift,
    required this.onEnd,
  });
  final RoomGiftAnimationResource resource;
  final RoomGift gift;
  final VoidCallback onEnd;
  @override
  State<RoomGiftEffectPlayer> createState() => _RoomGiftEffectPlayerState();
}

class _RoomGiftEffectPlayerState extends State<RoomGiftEffectPlayer>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _svga;
  VideoPlayerController? _video;
  VapController? _vap;
  AnimationController? _native;
  Timer? _watchdog;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _watchdog = Timer(const Duration(seconds: 25), _end);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      if ((widget.resource.format == RoomGiftAnimationFormat.vap ||
              widget.resource.format == RoomGiftAnimationFormat.pag) &&
          !Platform.isAndroid &&
          !Platform.isIOS) {
        _end();
        return;
      }
      switch (widget.resource.format) {
        case RoomGiftAnimationFormat.svga:
          final controller = SVGAAnimationController(vsync: this);
          _svga = controller;
          final movie = await SVGAParser.shared.decodeFromBuffer(
            widget.resource.bytes!,
          );
          if (!mounted) {
            movie.dispose();
            return;
          }
          controller.videoItem = movie;
          setState(() {});
          await controller.forward().orCancel;
          _end();
        case RoomGiftAnimationFormat.mp4:
          final controller = VideoPlayerController.file(widget.resource.file!);
          _video = controller;
          await controller.initialize();
          if (!mounted) return;
          await controller.setVolume(0);
          if (!mounted) return;
          controller.addListener(() {
            if (controller.value.hasError || controller.value.isCompleted) {
              _end();
            }
          });
          setState(() {});
          await controller.play();
        case RoomGiftAnimationFormat.native:
          _native = AnimationController(
            vsync: this,
            duration: const Duration(seconds: 2),
          );
          setState(() {});
          await _native!.forward().orCancel;
          _end();
        case RoomGiftAnimationFormat.pag || RoomGiftAnimationFormat.vap:
          break;
      }
    } on TickerCanceled {
      /* Widget removed or backgrounded. */
    } catch (error) {
      debugPrint('[RoomGift] Player failed: $error');
      _end();
    }
  }

  void _end() {
    if (_ended || !mounted) return;
    _ended = true;
    _watchdog?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onEnd();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      switch (widget.resource.format) {
        case RoomGiftAnimationFormat.svga:
          return _svga?.videoItem == null
              ? const SizedBox.shrink()
              : SVGAImage(_svga!, fit: BoxFit.contain);
        case RoomGiftAnimationFormat.mp4:
          final video = _video;
          if (video == null || !video.value.isInitialized) {
            return const SizedBox.shrink();
          }
          return FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: video.value.size.width,
              height: video.value.size.height,
              child: VideoPlayer(video),
            ),
          );
        case RoomGiftAnimationFormat.vap:
          return VapView(
            fit: VapScaleFit.FIT_CENTER,
            onEvent: (event, _) {
              if (event == 'onComplete' || event == 'onFailed') _end();
            },
            onControllerCreated: (controller) async {
              _vap = controller;
              if (!mounted || _ended) {
                await _stopVap();
                return;
              }
              try {
                if (Platform.isAndroid) {
                  await controller.setVideoMode(widget.resource.videoMode);
                }
                if (!mounted || _ended) {
                  await _stopVap();
                  return;
                }
                await controller.playPath(widget.resource.file!.path);
              } catch (error) {
                debugPrint('[RoomGift] VAP failed: $error');
              }
              _end();
            },
          );
        case RoomGiftAnimationFormat.pag:
          return PAGView.bytes(
            widget.resource.bytes,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            autoPlay: true,
            repeatCount: 1,
            onAnimationEnd: _end,
            onAnimationCancel: _end,
            defaultBuilder: (_) {
              _end();
              return const SizedBox.shrink();
            },
          );
        case RoomGiftAnimationFormat.native:
          if (_native == null) return const SizedBox.shrink();
          return AnimatedBuilder(
            animation: _native!,
            builder: (context, _) {
              final t = _native!.value;
              return Opacity(
                opacity: (1 - t).clamp(0, 1),
                child: Center(
                  child: Transform.scale(
                    scale: 0.6 + Curves.easeOutBack.transform(t),
                    child: RoomGiftImage(
                      source: widget.gift.icon,
                      size: constraints.maxWidth * 0.55,
                    ),
                  ),
                ),
              );
            },
          );
      }
    },
  );

  @override
  void dispose() {
    _watchdog?.cancel();
    _svga?.dispose();
    unawaited(_video?.dispose());
    unawaited(_stopVap());
    _native?.dispose();
    super.dispose();
  }

  Future<void> _stopVap() async {
    try {
      await _vap?.stop();
    } catch (error) {
      debugPrint('[RoomGift] VAP cleanup: $error');
    }
  }
}
