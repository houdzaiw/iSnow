import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../../room/gift/effects/room_gift_asset_resolver.dart';
import '../../room/gift/effects/room_gift_effect_player.dart';
import '../../room/gift/models/room_gift_models.dart';
import '../tools/profile_tools_widgets.dart';
import 'store_models.dart';

final storePreviewProvider = FutureProvider.autoDispose
    .family<RoomGiftAnimationResource, RoomGift>(
      (ref, gift) => ref.read(roomGiftAssetResolverProvider).resolve(gift),
    );

class StorePreview extends ConsumerWidget {
  const StorePreview({super.key, required this.product});
  final StoreProduct product;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (product.animation.isEmpty) {
      return MembershipImage(
        product.icon,
        width: double.infinity,
        height: ProfileToolsTheme.preview,
      );
    }
    final gift = RoomGift(
      id: -product.id,
      name: product.name,
      icon: product.icon,
      price: 0,
      isCombo: 0,
      tabId: 0,
      animationUrl: product.animation,
      animationType: product.animationType,
      direction: product.direction,
    );
    return ref
        .watch(storePreviewProvider(gift))
        .when(
          data: (resource) => RoomGiftEffectPlayer(
            key: ValueKey(gift),
            resource: resource,
            gift: gift,
            onEnd: () {},
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              MembershipImage(product.icon, size: ProfileToolsTheme.preview),
        );
  }
}
