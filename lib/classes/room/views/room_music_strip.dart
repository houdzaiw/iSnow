part of '../room_page.dart';

class _RoomMusicStrip extends StatelessWidget {
  const _RoomMusicStrip({
    required this.state,
    required this.onAudienceTap,
    required this.onMusicTap,
    required this.musicAnchorKey,
  });

  final RoomPageState state;
  final VoidCallback onAudienceTap;
  final VoidCallback onMusicTap;
  final GlobalKey musicAnchorKey;

  @override
  Widget build(BuildContext context) {
    final users = state.audience
        .take(AppSpacing.roomAudiencePreviewLimit)
        .toList();
    final avatarSize = AppSpacing.roomAudiencePreviewAvatarSize.r;
    final avatarOffset = AppSpacing.roomAudiencePreviewAvatarOffset.r;
    return SizedBox(
      height: AppSpacing.roomMusicStripHeight.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                key: const ValueKey('room-music-entry'),
                onTap: state.isReady ? onMusicTap : null,
                borderRadius: AppRadius.pillBorder,
                child: Container(
                  key: musicAnchorKey,
                  height: AppSpacing.roomMusicPillHeight.h,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                  decoration: const BoxDecoration(
                    color: AppColors.roomMusicStripSurface,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Row(
                    children: [
                      _RoomAssetIcon(
                        asset: AppAssets.lanhuRoomMusicIcon,
                        size: AppSpacing.iconSizeMd.r,
                      ),
                      SizedBox(width: AppSpacing.inlineActionGap.w),
                      Expanded(
                        child: Text(
                          state.agoraState.music.isActive &&
                                  state.agoraState.music.title.isNotEmpty
                              ? state.agoraState.music.title
                              : context.l10n.t('room.more.music'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.roomMusicTitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            Semantics(
              button: true,
              label:
                  '${context.l10n.t('room.audience.users')} (${state.onlineCount})',
              child: InkWell(
                key: const ValueKey('room-audience-entry'),
                onTap: state.isReady ? onAudienceTap : null,
                borderRadius: AppRadius.pillBorder,
                child: SizedBox(
                  height: AppSpacing.roomMusicPillHeight.h,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (users.isNotEmpty) ...[
                        SizedBox(
                          width: avatarSize + (users.length - 1) * avatarOffset,
                          height: avatarSize,
                          child: Stack(
                            children: [
                              for (final entry in users.indexed)
                                PositionedDirectional(
                                  start: entry.$1 * avatarOffset,
                                  child: RoomAudienceAvatar(
                                    key: ValueKey(
                                      'room-audience-preview-${entry.$2.uid}',
                                    ),
                                    url: entry.$2.userBase.avatar,
                                    size: avatarSize,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.inlineActionGap.w),
                      ],
                      Container(
                        width: AppSpacing.roomAudienceCountWidth.w,
                        height: AppSpacing.controlHeightSm.h,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs.w,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.roomMusicStripSurface,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: Row(
                          children: [
                            _RoomAssetIcon(
                              asset: AppAssets.lanhuRoomOnlineIcon,
                              size: AppSpacing.iconSizeSm.r,
                            ),
                            SizedBox(width: AppSpacing.xs.w),
                            Expanded(
                              child: Text(
                                _formatCompact(state.onlineCount),
                                key: const ValueKey('room-online-count'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.roomAudienceName,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openRoomMusic(BuildContext context, WidgetRef ref, RoomPageState state) {
  if (!state.isReady) return;
  if (!state.isOnMic) {
    _showRoomMoreSnack(context, context.l10n.t('room.music.takeMic'));
    return;
  }
  ref.read(roomMusicViewModelProvider(state.currentRoomId).notifier).expand();
}
