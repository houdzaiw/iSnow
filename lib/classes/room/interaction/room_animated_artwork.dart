import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../gift/effects/room_gift_asset_resolver.dart';
import '../gift/effects/room_gift_effect_player.dart';
import 'room_expression_sheet.dart';
import 'room_public_media.dart';

typedef _ArtworkKey = ({String url, RoomGiftAnimationFormat format});
final _roomArtworkProvider = FutureProvider.autoDispose
    .family<RoomGiftAnimationResource, _ArtworkKey>(
      (ref, key) => ref
          .watch(roomGiftAssetResolverProvider)
          .resolveSource(key.url, format: key.format),
    );

class RoomAnimatedArtwork extends HookConsumerWidget {
  const RoomAnimatedArtwork({
    super.key,
    required this.url,
    this.preview,
    this.fit = BoxFit.contain,
    this.repeat = false,
    this.backdrop = false,
  });

  final String url;
  final String? preview;
  final BoxFit fit;
  final bool repeat, backdrop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ended = useState(false);
    final validUrl = roomMediaUrl(url);
    final format = RoomGiftAssetResolver.formatForSource(url);
    final isImage = format == RoomGiftAnimationFormat.native;
    if (validUrl == null || isImage) {
      return Stack(
        fit: StackFit.expand,
        children: [
          RoomPublicImage(url: validUrl, fit: fit),
          if (backdrop)
            const ColoredBox(color: AppColors.roomCustomBackdropScrim),
        ],
      );
    }
    final resource = ref.watch(
      _roomArtworkProvider((url: validUrl, format: format)),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (resource.valueOrNull case final asset? when !ended.value)
          RoomGiftEffectPlayer(
            key: ValueKey(validUrl),
            resource: asset,
            repeat: repeat,
            fit: fit,
            onEnd: () {
              if (context.mounted) ended.value = true;
            },
          )
        else if (preview != null || !backdrop)
          RoomPublicImage(url: preview, fit: fit),
        if (backdrop)
          const ColoredBox(color: AppColors.roomCustomBackdropScrim),
      ],
    );
  }
}
