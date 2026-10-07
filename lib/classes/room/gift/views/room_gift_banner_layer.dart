import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../theme/app_theme.dart';
import '../models/room_gift_event_models.dart';
import '../effects/room_gift_asset_resolver.dart';
import '../effects/room_gift_effect_player.dart';
import 'room_gift_image.dart';

class RoomGiftBannerLayer extends ConsumerStatefulWidget {
  const RoomGiftBannerLayer({
    super.key,
    required this.banner,
    required this.onEnd,
  });
  final RoomGiftBanner banner;
  final VoidCallback onEnd;
  @override
  ConsumerState<RoomGiftBannerLayer> createState() =>
      _RoomGiftBannerLayerState();
}

class _RoomGiftBannerLayerState extends ConsumerState<RoomGiftBannerLayer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(const Duration(seconds: 4), widget.onEnd);
  }

  @override
  Widget build(BuildContext context) {
    final banner = widget.banner;
    final language = Localizations.localeOf(context).languageCode;
    final content = banner.contents[language] ?? banner.contents['en'];
    final text = content?.isNotEmpty == true && content != 'null'
        ? content!
        : banner.multiplier > 0
        ? '${banner.sender.name} · x${banner.multiplier.toStringAsFixed(0)} · +${banner.amount}'
        : '${banner.sender.name} → ${banner.recipient?.name ?? 'Room'} · ${banner.gift.name} x${banner.count}';
    return IgnorePointer(
      child: SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: Stack(
          children: [
            if (banner.effectUrl.isNotEmpty)
              Positioned.fill(
                child: ref
                    .watch(roomGiftAnimationProvider(banner.effectGift))
                    .when(
                      data: (resource) => RoomGiftEffectPlayer(
                        key: ValueKey(banner.effectUrl),
                        resource: resource,
                        gift: banner.gift,
                        onEnd: () {},
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
              ),
            Container(
              height: AppSpacing.giftBannerHeight.h,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
              decoration: const BoxDecoration(
                color: AppColors.giftBannerBackground,
                borderRadius: AppRadius.pillBorder,
              ),
              child: Row(
                children: [
                  RoomGiftImage(
                    source: banner.gift.icon,
                    size: AppSpacing.giftSlotIconSize.r,
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.giftEffectTitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
