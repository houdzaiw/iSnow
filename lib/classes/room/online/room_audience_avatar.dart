import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class RoomAudienceAvatar extends StatelessWidget {
  const RoomAudienceAvatar({super.key, required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget missing() => Image.asset(
      AppAssets.lanhuRoomIconMissing,
      width: size,
      height: size,
      color: AppColors.missingAsset,
    );
    final avatar = url?.trim() ?? '';
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: avatar.isEmpty
            ? missing()
            : CachedNetworkImage(
                imageUrl: avatar,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => missing(),
                errorWidget: (_, __, ___) => missing(),
              ),
      ),
    );
  }
}
