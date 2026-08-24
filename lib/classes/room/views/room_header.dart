part of '../room_page.dart';

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.state,
    required this.onMinimize,
    required this.onExit,
  });

  final RoomPageState state;
  final VoidCallback onMinimize;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final occupiedCount = state.seats.where((seat) => seat.isOccupied).length;
    return SizedBox(
      height: 110.h,
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoomAvatarImage(url: state.roomAvatar, size: 66.r, radius: 14.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 7.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            state.roomTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              height: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        _RoomAssetIcon(
                          asset: AppAssets.lanhuRoomAddFriend,
                          size: 22.r,
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'ID: ${state.roomNo}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              height: 1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _MetricChip(
                          asset: AppAssets.lanhuRoomIconMissing,
                          text: _formatCompact(state.onlineCount),
                        ),
                        SizedBox(width: 6.w),
                        _MetricChip(
                          asset: AppAssets.lanhuRoomMicSeat,
                          text: '$occupiedCount/20',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              children: [
                _HeaderIconButton(
                  asset: AppAssets.lanhuRoomIconMissing,
                  onTap: onMinimize,
                ),
                SizedBox(height: 8.h),
                _HeaderIconButton(
                  asset: AppAssets.lanhuRoomPower,
                  onTap: onExit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.asset, required this.text});

  final String asset;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 74.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoomAssetIcon(asset: asset, size: 14.r),
          SizedBox(width: 3.w),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _roomGold,
                fontSize: 13.sp,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36.r,
          height: 36.r,
          child: Center(
            child: _RoomAssetIcon(asset: asset, size: 24.r),
          ),
        ),
      ),
    );
  }
}

class _RoomAvatarImage extends StatelessWidget {
  const _RoomAvatarImage({
    required this.url,
    required this.size,
    required this.radius,
  });

  final String? url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl == null || imageUrl.isEmpty
            ? const _AvatarFallback()
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const _AvatarFallback(),
                errorWidget: (_, __, ___) => const _AvatarFallback(),
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A445A), Color(0xFF2A2738)],
        ),
      ),
      child: Image.asset(
        AppAssets.lanhuRoomAvatarSample,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

String _formatCompact(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}
