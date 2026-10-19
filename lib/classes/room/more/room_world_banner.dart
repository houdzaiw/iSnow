import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../gift/effects/room_gift_asset_resolver.dart';
import '../gift/effects/room_gift_effect_player.dart';
import '../gift/models/room_gift_models.dart';
import 'room_tools_models.dart';
import 'room_tools_widgets.dart';

class RoomWorldBanner extends StatelessWidget {
  const RoomWorldBanner({super.key, required this.banner, required this.onTap});
  final ToolJson banner;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.roomMoreSheet,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: AppSpacing.giftBannerHeight,
        child: Stack(
          children: [
            for (final source in ['effectUrl', 'upperEffect'])
              if ('${banner[source] ?? ''}'.isNotEmpty)
                Positioned.fill(
                  child: _BannerArt(
                    url: '${banner[source]}',
                    effectKey: '${banner['_key']}:$source',
                  ),
                ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    ToolImage(
                      '${toolMap(banner['userBaseInfo'])['avatar'] ?? banner['icon'] ?? ''}',
                      size: AppSpacing.iconSizeLg,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${toolMap(banner['userBaseInfo'])['nick'] ?? ''} ${Localizations.localeOf(context).languageCode == 'ar' ? banner['descAr'] ?? banner['desc'] ?? '' : banner['desc'] ?? ''} ${banner['goldCount'] ?? ''}',
                        style: AppTextStyles.roomGiftStatus,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BannerArt extends ConsumerWidget {
  const _BannerArt({required this.url, required this.effectKey});
  final String url, effectKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gift = RoomGift(
      id: -900003,
      tabId: -1,
      name: '',
      icon: '',
      price: 0,
      isCombo: 0,
      animationUrl: url,
    );
    final resource = ref.watch(roomGiftAnimationProvider(gift));
    return IgnorePointer(
      child: resource.when(
        data: (value) => value.format == RoomGiftAnimationFormat.native
            ? const SizedBox.shrink()
            : RoomGiftEffectPlayer(
                key: ValueKey(effectKey),
                resource: value,
                gift: gift,
                onEnd: () {},
              ),
        error: (_, _) => const SizedBox.shrink(),
        loading: () => const SizedBox.shrink(),
      ),
    );
  }
}
