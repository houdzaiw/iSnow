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
            _RoomAvatarImage(
              url: state.roomAvatar,
              size: 66.r,
              radius: 14.r,
              fallbackIcon: Icons.headphones_rounded,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 7.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.public_rounded,
                          color: Colors.white.withValues(alpha: 0.82),
                          size: 17.r,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            state.roomTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26.sp,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          width: 31.r,
                          height: 31.r,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _roomPink,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 25.r,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'ID: ${state.roomNo}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              height: 1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _MetricChip(
                          icon: Icons.groups_2_rounded,
                          text: _formatCompact(state.onlineCount),
                        ),
                        SizedBox(width: 6.w),
                        _MetricChip(
                          icon: Icons.mic_rounded,
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
                  icon: Icons.keyboard_arrow_down_rounded,
                  onTap: onMinimize,
                ),
                SizedBox(height: 8.h),
                _HeaderIconButton(
                  icon: Icons.power_settings_new,
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
  const _MetricChip({required this.icon, required this.text});

  final IconData icon;
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
          Icon(icon, color: _roomGold, size: 14.r),
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
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
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
          child: Icon(icon, color: Colors.white, size: 25.r),
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
    required this.fallbackIcon,
  });

  final String? url;
  final double size;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl == null || imageUrl.isEmpty
            ? _AvatarFallback(icon: fallbackIcon)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _AvatarFallback(icon: fallbackIcon),
                errorWidget: (_, __, ___) =>
                    _AvatarFallback(icon: fallbackIcon),
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.icon});

  final IconData icon;

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
      child: Icon(icon, color: Colors.white70, size: 28.r),
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
