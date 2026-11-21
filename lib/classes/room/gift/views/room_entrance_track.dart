import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../theme/app_theme.dart';
import '../../interaction/room_animated_artwork.dart';
import '../../online/room_audience_avatar.dart';
import '../event/room_gift_event_manager.dart';
import '../event/room_gift_event_provider.dart';
import '../models/room_entrance.dart';

class RoomEntranceTrack extends ConsumerWidget {
  const RoomEntranceTrack({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomGiftEventManagerProvider(roomId));
    final entrance = state.entrance;
    if (!state.isVisible || entrance == null || !TickerMode.of(context)) {
      return const SizedBox.shrink();
    }
    return _EntranceAnimation(
      key: ValueKey(entrance.key),
      entrance: entrance,
      onEnd: () => ref
          .read(roomGiftEventManagerProvider(roomId).notifier)
          .completeEntranceTrack(entrance.key),
    );
  }
}

class _EntranceAnimation extends StatefulWidget {
  const _EntranceAnimation({
    super.key,
    required this.entrance,
    required this.onEnd,
  });
  final RoomEntrance entrance;
  final VoidCallback onEnd;
  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onEnd();
        })
        ..forward();
  late final _slide = TweenSequence<Offset>([
    TweenSequenceItem(
      tween: Tween(begin: const Offset(-1.5, 0), end: Offset.zero),
      weight: 20,
    ),
    TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 70),
    TweenSequenceItem(
      tween: Tween(begin: Offset.zero, end: const Offset(1.5, 0)),
      weight: 10,
    ),
  ]).animate(_controller);
  @override
  Widget build(BuildContext context) {
    final entry = widget.entrance;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return IgnorePointer(
      child: SizedBox(
        height: AppSpacing.roomEntranceHeight.h,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: SlideTransition(
            position: _slide,
            child: SizedBox(
              width: AppSpacing.roomEntranceWidth.w,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (entry.trackUrl.isNotEmpty)
                    RoomAnimatedArtwork(
                      url: entry.trackUrl,
                      repeat: true,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: AppSpacing.roomEntranceAvatar.r,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              RoomAudienceAvatar(
                                url: entry.user.avatar,
                                size: AppSpacing.roomEntranceAvatar.r,
                              ),
                              if (entry.user.appearance.frameUrl
                                  case final frame?)
                                RoomAnimatedArtwork(
                                  url: frame,
                                  preview: entry.user.appearance.framePreview,
                                  repeat: true,
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm.w),
                        Expanded(
                          child: Text(
                            entry.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.giftEffectTitle,
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs.w),
                        Flexible(
                          child: Text(
                            zh ? '进入房间' : 'Enter the room',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.giftEffectSubtitle,
                          ),
                        ),
                      ],
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
    _controller.dispose();
    super.dispose();
  }
}
