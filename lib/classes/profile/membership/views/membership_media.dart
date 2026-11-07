import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../theme/app_theme.dart';
import '../../../room/gift/effects/room_gift_asset_resolver.dart';
import '../../../room/gift/effects/room_gift_effect_player.dart';
import '../../../room/gift/models/room_gift_models.dart';
import 'membership_widgets.dart';

typedef MembershipMediaKey = ({String url, bool success});
final membershipMediaProvider = FutureProvider.autoDispose
    .family<RoomGiftAnimationResource, MembershipMediaKey>((ref, key) {
      return ref
          .read(roomGiftAssetResolverProvider)
          .resolve(_resource(key.url));
    });
RoomGift _resource(String url) => RoomGift(
  id: -900001,
  name: 'Membership preview',
  icon: '',
  price: 0,
  isCombo: 0,
  tabId: 0,
  animationUrl: url,
);

/// Reuses the existing bounded CDN cache and native players, never the gift queue.
class MembershipMedia extends ConsumerWidget {
  const MembershipMedia({
    super.key,
    required this.url,
    this.onEnd,
    this.success = false,
  });
  final String url;
  final VoidCallback? onEnd;
  final bool success;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    if (!['.mp4', '.vap', '.pag', '.svga'].any(path.endsWith)) {
      return MembershipImage(
        url,
        width: double.infinity,
        height: MembershipTheme.preview,
      );
    }
    final resource = ref.watch(
      membershipMediaProvider((url: url, success: success)),
    );
    return resource.when(
      data: (value) => RoomGiftEffectPlayer(
        key: ValueKey(url),
        resource: value,
        gift: _resource(url),
        onEnd: onEnd ?? () {},
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: MembershipTheme.gold),
      ),
      error: (_, _) => const Center(child: MembershipImage('')),
    );
  }
}
