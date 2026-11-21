import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../effects/room_gift_asset_resolver.dart';
import '../effects/room_gift_effect_player.dart';
import '../models/room_gift_models.dart';
import '../viewmodel/room_gift_panel_view_model.dart';
import 'room_gift_image.dart';

class RoomGiftPanelExtras extends StatelessWidget {
  const RoomGiftPanelExtras({
    super.key,
    required this.state,
    required this.onRetry,
    this.animate = true,
  });
  final RoomGiftPanelState state;
  final VoidCallback onRetry;
  final bool animate;
  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot, jackpot = state.jackpot;
    return SizedBox(
      height: AppSpacing.giftPanelExtrasHeight.h,
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.roomGiftPanelSwitch,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, AppSpacing.giftPanelSlideFraction),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: snapshot != null
                  ? Container(
                      key: ValueKey(
                        '${state.snapshotIndex}:${snapshot.senderUid}:${snapshot.winAmount}',
                      ),
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                      padding: EdgeInsets.all(AppSpacing.sm.r),
                      decoration: const BoxDecoration(
                        color: AppColors.giftBannerBackground,
                        borderRadius: AppRadius.cardBorder,
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: RoomGiftImage(
                              source: snapshot.senderAvatar,
                              size: AppSpacing.giftSlotAvatarSize.r,
                            ),
                          ),
                          SizedBox(width: AppSpacing.xs.w),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.senderName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.roomGiftStatus,
                                ),
                                Text(
                                  '${snapshot.winAmount} ${context.l10n.t('room.gift.coins')} · ×${snapshot.multiple.toStringAsFixed(0)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.roomGiftStatus,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : state.error != null
                  ? TextButton(
                      onPressed: onRetry,
                      child: Text(
                        state.error!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.roomGiftStatus,
                      ),
                    )
                  : state.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.roomGiftAccent,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          if (jackpot?.enabled == true)
            SizedBox(
              width: AppSpacing.giftPanelJackpotWidth.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      AppAssets.roomGiftJackpotPanelBackground,
                      fit: BoxFit.fill,
                    ),
                  ),
                  if (jackpot!.isSuper && animate)
                    const Positioned.fill(child: _PanelLoop()),
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xxl.h),
                    child: AnimatedSwitcher(
                      duration: AppMotion.roomGiftPanelSwitch,
                      child: Text(
                        '${jackpot.displayAmount}',
                        key: ValueKey(jackpot.displayAmount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.giftLuckyAmount,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelLoop extends ConsumerWidget {
  const _PanelLoop();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A small, muted panel decoration, not a second full-screen host.
    return ref
        .watch(roomGiftAnimationProvider(_gift))
        .when(
          data: (resource) => RoomGiftEffectPlayer(
            resource: resource,
            gift: _gift,
            repeat: true,
            onEnd: () {},
          ),
          error: (_, __) => const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
        );
  }

  static const _gift = RoomGift(
    id: -3,
    name: 'SUPER',
    icon: '',
    price: 0,
    isCombo: 0,
    tabId: 0,
    animationUrl: AppAssets.roomGiftJackpotPanel,
  );
}
