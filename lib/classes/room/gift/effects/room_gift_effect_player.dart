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
import 'room_gift_playback_barrier.dart';

class RoomGiftEffectPlayer extends StatefulWidget {
  const RoomGiftEffectPlayer({
    super.key,
    required this.resource,
    this.gift,
    this.repeat = false,
    this.fit = BoxFit.contain,
    required this.onEnd,
    this.onReleaseFailed,
    this.playbackBarrier,
    this.onPlaybackFailed,
    this.startBefore,
    this.onStarted,
  });
  final RoomGiftAnimationResource resource;
  final RoomGift? gift;
  final bool repeat;
  final BoxFit fit;
  final VoidCallback onEnd;
  final ValueChanged<Object>? onReleaseFailed;
  final RoomGiftPlaybackBarrier? playbackBarrier;
  final ValueChanged<Object>? onPlaybackFailed;
  final DateTime? startBefore;
  final VoidCallback? onStarted;
  @override
  RoomGiftEffectPlayerState createState() => RoomGiftEffectPlayerState();
}

class RoomGiftEffectPlayerState extends State<RoomGiftEffectPlayer>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _svga;
  VideoPlayerController? _video;
  VapController? _vap;
  AnimationController? _native;
  Timer? _watchdog;
  bool _ended = false;
  bool _acquired = false;
  bool _playbackFailed = false;
  bool _didStart = false;
  final _pagKey = GlobalKey<PAGViewState>();
  PAGViewState? _pag;
  Future<void>? _releaseTask;
  RoomGiftPlaybackLease? _lease;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      _lease = await widget.playbackBarrier?.acquire();
      if (!mounted || _ended) {
        await _lease?.release(() async {});
        return;
      }
      if (widget.startBefore != null &&
          !DateTime.now().isBefore(widget.startBefore!)) {
        _end();
        return;
      }
      _acquired = true;
      if (!widget.repeat) _watchdog = Timer(const Duration(seconds: 25), _end);
      setState(() {});
      if (widget.resource.format == RoomGiftAnimationFormat.vap &&
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
          if (!mounted || _ended) {
            movie.dispose();
            return;
          }
          controller.videoItem = movie;
          setState(() {});
          _notifyStarted();
          if (widget.repeat) {
            controller.repeat();
          } else {
            await controller.forward().orCancel;
            _end();
          }
        case RoomGiftAnimationFormat.mp4:
          final controller = VideoPlayerController.file(
            widget.resource.file!,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
          _video = controller;
          await controller.initialize();
          if (!mounted || _ended) return;
          await controller.setVolume(0);
          if (!mounted || _ended) return;
          if (widget.repeat) await controller.setLooping(true);
          if (!mounted || _ended) return;
          controller.addListener(() {
            if (controller.value.hasError) {
              _fail(
                StateError(controller.value.errorDescription ?? 'Video failed'),
              );
            } else if (!widget.repeat && controller.value.isCompleted) {
              _end();
            }
          });
          setState(() {});
          await controller.play();
          _notifyStarted();
        case RoomGiftAnimationFormat.native:
          _native = AnimationController(
            vsync: this,
            duration: const Duration(seconds: 2),
          );
          setState(() {});
          _notifyStarted();
          await _native!.forward().orCancel;
          _end();
        case RoomGiftAnimationFormat.pag || RoomGiftAnimationFormat.vap:
          break;
      }
    } on TickerCanceled {
      /* Widget removed or backgrounded. */
    } catch (error) {
      debugPrint('[RoomGift] Player failed: $error');
      if (!_acquired) {
        if (mounted) widget.onReleaseFailed?.call(error);
        return;
      }
      _fail(error);
    }
  }

  void _fail(Object error) {
    if (_playbackFailed || _ended || !mounted) return;
    _playbackFailed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPlaybackFailed?.call(error);
    });
    _end();
  }

  void _notifyStarted() {
    if (_didStart || _ended || !mounted) return;
    if (widget.startBefore != null &&
        !DateTime.now().isBefore(widget.startBefore!)) {
      _end();
      return;
    }
    _didStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_ended) widget.onStarted?.call();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _end() {
    if (_ended || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_ended) unawaited(_finish());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _finish() async {
    try {
      await stop();
      if (mounted && (!_playbackFailed || widget.onPlaybackFailed == null)) {
        widget.onEnd();
      }
    } catch (error) {
      debugPrint('[RoomGift] Release failed: $error');
      if (mounted) widget.onReleaseFailed?.call(error);
    }
  }

  /// Stops before handover. Failure is propagated so the caller cannot start
  /// another native player while the previous resource may still be alive.
  Future<void> stop() =>
      _releaseTask ??= _lease?.release(_release) ?? _release();

  Future<void> _release() async {
    _ended = true;
    _watchdog?.cancel();
    _svga?.stop();
    _native?.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
    await Future.wait<void>([
      if (_video != null) _video!.dispose(),
      if (_vap != null) _vap!.stop(),
      if (_pag != null) _pag!.release(),
    ]).timeout(const Duration(seconds: 30));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (_ended || !_acquired) return const SizedBox.shrink();
      switch (widget.resource.format) {
        case RoomGiftAnimationFormat.svga:
          return _svga?.videoItem == null
              ? const SizedBox.shrink()
              : SVGAImage(_svga!, fit: widget.fit);
        case RoomGiftAnimationFormat.mp4:
          final video = _video;
          if (video == null || !video.value.isInitialized) {
            return const SizedBox.shrink();
          }
          return FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: video.value.size.width,
              height: video.value.size.height,
              child: VideoPlayer(video),
            ),
          );
        case RoomGiftAnimationFormat.vap:
          return VapView(
            fit: widget.fit == BoxFit.cover
                ? VapScaleFit.CENTER_CROP
                : widget.fit == BoxFit.fill
                ? VapScaleFit.FIT_XY
                : VapScaleFit.FIT_CENTER,
            onEvent: (event, _) {
              if (event == 'onStart') {
                _notifyStarted();
              } else if (event == 'onFailed') {
                _fail(StateError('VAP failed'));
              } else if (!widget.repeat && event == 'onComplete') {
                _end();
              }
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
                await controller.playPath(
                  widget.resource.file!.path,
                  loop: widget.repeat,
                  fetchResources: [
                    for (final entry in widget.resource.replacements.entries)
                      FetchResourceModel(tag: entry.key, resource: entry.value),
                  ],
                );
              } catch (error) {
                debugPrint('[RoomGift] VAP failed: $error');
                _fail(error);
                return;
              }
              if (!widget.repeat) _end();
            },
          );
        case RoomGiftAnimationFormat.pag:
          return PAGView.bytes(
            key: _pagKey,
            widget.resource.bytes,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            // Native autoplay can emit start before Dart receives the texture.
            autoPlay: false,
            onCreated: (controller) => _pag = controller,
            onInit: () {
              final controller = _pag;
              if (_ended || !mounted) {
                unawaited(controller?.release());
              } else {
                controller?.start();
              }
            },
            repeatCount: widget.repeat ? PAGView.REPEAT_COUNT_LOOP : 1,
            onAnimationEnd: _end,
            onAnimationStart: _notifyStarted,
            onAnimationCancel: _end,
            onError: () => _fail(StateError('PAG failed')),
            defaultBuilder: (_) => const SizedBox.shrink(),
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
                      source: widget.gift?.icon ?? '',
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
    unawaited(
      stop().catchError((Object error) {
        debugPrint('[RoomGift] Dispose release failed: $error');
      }),
    );
    _svga?.dispose();
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
