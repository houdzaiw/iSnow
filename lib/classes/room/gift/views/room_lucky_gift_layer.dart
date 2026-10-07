import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../theme/app_theme.dart';
import '../models/room_gift_event_models.dart';
import '../effects/room_gift_asset_resolver.dart';
import '../effects/room_gift_effect_player.dart';

class RoomLuckyGiftLayer extends ConsumerStatefulWidget {
  const RoomLuckyGiftLayer({
    super.key,
    required this.result,
    required this.onEnd,
  });
  final RoomLuckyGiftResult result;
  final VoidCallback onEnd;
  @override
  ConsumerState<RoomLuckyGiftLayer> createState() => _RoomLuckyGiftLayerState();
}

class _RoomLuckyGiftLayerState extends ConsumerState<RoomLuckyGiftLayer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onEnd();
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(RoomLuckyGiftLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final lucky = widget.result;
    final gift = RoomGiftAssetResolver.luckyAnimation(lucky);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.75, 1),
            ),
          ),
          child: Transform.translate(
            offset: Offset(0, -AppSpacing.xxl.h * _controller.value),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!lucky.isJackpot)
                  Positioned.fill(
                    child: ref
                        .watch(roomGiftAnimationProvider(gift))
                        .when(
                          data: (resource) => RoomGiftEffectPlayer(
                            resource: resource,
                            gift: gift,
                            onEnd: () {},
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                  ),
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg.r),
                  decoration: const BoxDecoration(
                    color: AppColors.giftLuckyBackground,
                    borderRadius: AppRadius.cardBorder,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lucky.isJackpot
                            ? 'JACKPOT'
                            : '${lucky.sender.name} · Lucky gift',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.giftEffectTitle,
                      ),
                      if (lucky.multiplier > 0)
                        Text(
                          'x${lucky.multiplier.toStringAsFixed(0)}',
                          style: AppTextStyles.giftComboCount,
                        ),
                      if (lucky.showCoins)
                        Text(
                          '+${lucky.amount}',
                          style: AppTextStyles.giftLuckyAmount,
                        ),
                      if (lucky.giftCount > 0)
                        Text(
                          'x${lucky.giftCount}',
                          style: AppTextStyles.giftEffectSubtitle,
                        ),
                    ],
                  ),
                ),
              ],
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
