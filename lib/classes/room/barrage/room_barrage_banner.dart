import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../gift/effects/room_gift_asset_resolver.dart';
import '../gift/effects/room_gift_effect_player.dart';
import '../gift/effects/room_gift_playback_barrier.dart';
import '../gift/views/room_gift_image.dart';
import 'room_barrage_models.dart';

final _backgroundBarrier = Provider((ref) => RoomGiftPlaybackBarrier());
final _foregroundBarrier = Provider((ref) => RoomGiftPlaybackBarrier());

class RoomBarrageBanner extends ConsumerStatefulWidget {
  const RoomBarrageBanner({
    super.key,
    required this.prepared,
    required this.onPresented,
    required this.onEnd,
    required this.onTap,
    this.busy = false,
    this.onFailure,
  });
  final RoomBarragePrepared prepared;
  final VoidCallback onPresented, onEnd, onTap;
  final bool busy;
  final ValueChanged<Object>? onFailure;
  @override
  ConsumerState<RoomBarrageBanner> createState() => _RoomBarrageBannerState();
}

class _RoomBarrageBannerState extends ConsumerState<RoomBarrageBanner>
    with SingleTickerProviderStateMixin {
  final _back = GlobalKey<RoomGiftEffectPlayerState>();
  final _front = GlobalKey<RoomGiftEffectPlayerState>();
  late final _controller = AnimationController(
    vsync: this,
    duration: RoomBarrageTheme.enterDuration,
  )..forward();
  Timer? _timer;
  bool _started = false, _finishing = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer(RoomBarrageTheme.initializationTimeout, _finish);
    final resource = widget.prepared.background;
    if (resource == null || resource.format == RoomGiftAnimationFormat.native) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _presented();
      });
    }
  }

  void _presented() {
    if (_started || _finishing || !mounted) return;
    _started = true;
    _timer?.cancel();
    _timer = Timer(RoomBarrageTheme.visibleDuration, _finish);
    widget.onPresented();
  }

  Future<void> _finish() async {
    if (_finishing || !mounted) return;
    _finishing = true;
    _timer?.cancel();
    try {
      await Future.wait([
        if (_back.currentState != null) _back.currentState!.stop(),
        if (_front.currentState != null) _front.currentState!.stop(),
      ]);
      if (mounted) widget.onEnd();
    } catch (error) {
      debugPrint('[RoomBarrage] Release blocked: $error');
      if (mounted) widget.onFailure?.call(error);
    }
  }

  Widget _art(
    RoomGiftAnimationResource? resource,
    String source,
    bool background,
  ) {
    if (resource == null) return const SizedBox.shrink();
    if (resource.format == RoomGiftAnimationFormat.native) {
      return RoomGiftImage(
        source: source,
        size: RoomBarrageTheme.height.h,
        fit: BoxFit.cover,
      );
    }
    return RoomGiftEffectPlayer(
      key: background ? _back : _front,
      resource: resource,
      fit: BoxFit.cover,
      repeat: true,
      playbackBarrier: ref.watch(
        background ? _backgroundBarrier : _foregroundBarrier,
      ),
      onStarted: background ? _presented : null,
      onPlaybackFailed: (_) => _finish(),
      onEnd: () {},
      onReleaseFailed: (error) {
        debugPrint('[RoomBarrage] Player unavailable: $error');
        if (mounted) widget.onFailure?.call(error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.prepared.task;
    final language = Localizations.localeOf(context).languageCode;
    return SlideTransition(
      textDirection: Directionality.of(context),
      position: Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          key: const ValueKey('room-account-barrage'),
          borderRadius: RoomBarrageTheme.radius,
          onTap: widget.busy || _finishing ? null : widget.onTap,
          child: ClipRRect(
            borderRadius: RoomBarrageTheme.radius,
            child: SizedBox(
              height: RoomBarrageTheme.height.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.prepared.background == null)
                    const ColoredBox(color: RoomBarrageTheme.background),
                  IgnorePointer(
                    child: _art(
                      widget.prepared.background,
                      task.background,
                      true,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
                    child: Row(
                      children: [
                        if (task.sender.avatar.isNotEmpty) ...[
                          ClipOval(
                            child: RoomGiftImage(
                              source: task.sender.avatar,
                              size: RoomBarrageTheme.avatar.r,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm.w),
                        ],
                        Expanded(
                          child: Text(
                            task.text(language),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: RoomBarrageTheme.title,
                          ),
                        ),
                        if (task.icon.isNotEmpty) ...[
                          SizedBox(width: AppSpacing.sm.w),
                          RoomGiftImage(
                            source: task.icon,
                            size: RoomBarrageTheme.icon.r,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IgnorePointer(
                    child: _art(
                      widget.prepared.foreground,
                      task.foreground,
                      false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
