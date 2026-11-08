part of '../room_page.dart';

class _RoomHeader extends HookWidget {
  const _RoomHeader({
    super.key,
    required this.state,
    required this.metrics,
    required this.onMinimize,
    required this.onExit,
    required this.onFollowRoom,
    this.onDetails,
    this.onShare,
    this.onRank,
  });

  final RoomPageState state;
  final RoomHeaderMetrics metrics;
  final VoidCallback onMinimize;
  final VoidCallback onExit;
  final VoidCallback onFollowRoom;
  final VoidCallback? onDetails, onShare;
  final ValueChanged<bool>? onRank;

  @override
  Widget build(BuildContext context) {
    final rankIndex = useState(0);
    String metricValue(int? value) =>
        value == null ? '—' : _formatCompact(value);
    return SizedBox(
      height: AppSpacing.roomHeaderHeight.h.clamp(
        AppSpacing.roomHeaderMinHeight.w,
        double.infinity,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: RoomHeaderTheme.horizontalInset.w,
          vertical: RoomHeaderTheme.verticalInset.h,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              key: const ValueKey('room-cover-details'),
              onTap: onDetails,
              child: _RoomAvatarImage(
                url: state.roomAvatar,
                size: RoomHeaderTheme.avatar.r,
                radius: RoomHeaderTheme.avatarRadius.r,
              ),
            ),
            SizedBox(width: RoomHeaderTheme.gap.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: InkWell(
                          onTap: onDetails,
                          child: Text(
                            state.roomTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RoomHeaderTheme.title.copyWith(
                              fontSize: RoomHeaderTheme.title.fontSize!.sp,
                            ),
                          ),
                        ),
                      ),
                      if (state.showFollowRoomButton) ...[
                        SizedBox(width: AppSpacing.inlineActionGap.w),
                        Semantics(
                          button: true,
                          enabled: !state.followingRoom,
                          label: context.l10n.t('profile.follow'),
                          child: InkWell(
                            key: const ValueKey('room-follow-owner'),
                            onTap: state.followingRoom ? null : onFollowRoom,
                            customBorder: const CircleBorder(),
                            child: _RoomAssetIcon(
                              asset: AppAssets.lanhuRoomAddFriend,
                              size: AppSpacing.iconSizeCompact.r,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: RoomHeaderTheme.lineGap.h),
                  Row(
                    children: [
                      Flexible(
                        child: InkWell(
                          onTap: onDetails,
                          child: Text(
                            'ID: ${state.roomNo}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RoomHeaderTheme.number.copyWith(
                              fontSize: RoomHeaderTheme.number.fontSize!.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: RoomHeaderTheme.lineGap.h),
                  Row(
                    children: [
                      Semantics(
                        label: toolText(context, 'Room heat', '房间热度'),
                        value: metricValue(metrics.heat),
                        child: Tooltip(
                          message:
                              metrics.heatError ??
                              toolText(context, 'Room heat', '房间热度'),
                          child: _MetricChip(
                            key: const ValueKey('room-header-heat'),
                            asset: AppAssets.roomHeaderHeat,
                            text: metricValue(metrics.heat),
                          ),
                        ),
                      ),
                      SizedBox(width: RoomHeaderTheme.gap.w),
                      Semantics(
                        button: true,
                        label: rankIndex.value == 0
                            ? toolText(context, 'Contribution Rank', '贡献榜')
                            : toolText(context, 'Profit Rank', '收益榜'),
                        child: InkWell(
                          key: const ValueKey('room-rank-entry'),
                          onTap: onRank == null
                              ? null
                              : () => onRank!(rankIndex.value == 1),
                          child: SizedBox(
                            key: const ValueKey('room-header-rank-carousel'),
                            width: RoomHeaderTheme.metricWidth.w,
                            height: RoomHeaderTheme.metricHeight.h,
                            child: Swiper(
                              itemCount: 2,
                              autoplay:
                                  metrics.active &&
                                  (ModalRoute.of(context)?.isCurrent ?? true),
                              duration: RoomHeaderTheme.carouselDuration,
                              autoplayDelay: RoomHeaderTheme.carouselDelay,
                              scrollDirection: Axis.vertical,
                              onIndexChanged: (index) =>
                                  rankIndex.value = index,
                              itemBuilder: (_, index) => _MetricChip(
                                asset: index == 0
                                    ? AppAssets.roomHeaderContribution
                                    : AppAssets.roomHeaderProfit,
                                text: metricValue(
                                  index == 0
                                      ? metrics.contribution
                                      : metrics.profit,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _HeaderIconButton(
              key: const ValueKey('room-header-share'),
              asset: AppAssets.roomInteractionShare,
              onTap: onShare,
              label: toolText(context, 'Share', '分享'),
            ),
            _HeaderIconButton(asset: AppAssets.lanhuRoomPower, onTap: onExit),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({super.key, required this.asset, required this.text});

  final String asset;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: RoomHeaderTheme.metricWidth.w),
      padding: EdgeInsets.symmetric(
        horizontal: RoomHeaderTheme.metricHorizontal.w,
        vertical: RoomHeaderTheme.metricVertical.h,
      ),
      decoration: const BoxDecoration(
        color: RoomHeaderTheme.metricSurface,
        borderRadius: RoomHeaderTheme.metricBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoomAssetIcon(asset: asset, size: RoomHeaderTheme.metricIcon.r),
          SizedBox(width: RoomHeaderTheme.metricGap.w),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RoomHeaderTheme.metric.copyWith(
                fontSize: RoomHeaderTheme.metric.fontSize!.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    super.key,
    required this.asset,
    required this.onTap,
    this.label,
  });

  final String asset;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
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
