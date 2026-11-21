import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../../../../theme/app_theme.dart';

class RoomGiftImage extends StatelessWidget {
  const RoomGiftImage({
    super.key,
    required this.source,
    required this.size,
    this.placeholderBuilder,
    this.fit = BoxFit.contain,
  });
  final String source;
  final double size;
  final WidgetBuilder? placeholderBuilder;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final asset = AppAssets.roomGiftLocalImages[source] ?? source;
    Widget missing() => Image.asset(
      AppAssets.lanhuRoomIconMissing,
      width: size,
      height: size,
      fit: fit,
    );
    if (asset.startsWith('assets/')) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) => missing(),
      );
    }
    final uri = Uri.tryParse(asset);
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      return missing();
    }
    return CachedNetworkImage(
      imageUrl: asset,
      width: size,
      height: size,
      fit: fit,
      placeholder: (context, _) =>
          placeholderBuilder?.call(context) ??
          SizedBox(width: size, height: size),
      errorWidget: (_, __, ___) => missing(),
    );
  }
}
