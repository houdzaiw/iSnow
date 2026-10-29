part of '../room_page.dart';

class _RoomBottomBar extends StatelessWidget {
  const _RoomBottomBar({
    super.key,
    required this.state,
    required this.onChatTap,
    required this.onToggleMic,
    required this.onMessageTap,
    required this.unreadCount,
    required this.onGiftTap,
    required this.onMoreTap,
  });

  final RoomPageState state;
  final VoidCallback onChatTap;
  final VoidCallback onToggleMic;
  final VoidCallback onMessageTap;
  final int unreadCount;
  final VoidCallback onGiftTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          AppSpacing.roomBottomBarHeight.h +
          MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.fromLTRB(
        28.w,
        8.h,
        28.w,
        MediaQuery.paddingOf(context).bottom + 8.h,
      ),
      decoration: BoxDecoration(gradient: AppGradients.roomBottomBar),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BottomIconButton(
            asset: AppAssets.lanhuRoomBottomChat,
            onTap: onChatTap,
            badge: state.messages.length > 99 ? '99+' : null,
          ),
          if (state.isOnMic) ...[
            SizedBox(width: AppSpacing.toolbarItemSpacing.w),
            _BottomIconButton(
              key: const ValueKey('room-microphone-toggle'),
              asset: state.agoraState.mutedMicrophone
                  ? AppAssets.lanhuRoomBottomMicMuted
                  : AppAssets.lanhuRoomBottomMic,
              selected: !state.agoraState.mutedMicrophone,
              onTap: state.togglingMicrophone ? null : onToggleMic,
            ),
          ],
          const Spacer(),
          _GiftButton(onTap: onGiftTap),
          const Spacer(),
          _BottomIconButton(
            key: const ValueKey('room-message-button'),
            asset: AppAssets.lanhuRoomBottomMessage,
            onTap: onMessageTap,
            unread: unreadCount > 0,
          ),
          SizedBox(width: AppSpacing.toolbarItemSpacing.w),
          _BottomIconButton(
            asset: AppAssets.lanhuRoomBottomMore,
            onTap: onMoreTap,
          ),
        ],
      ),
    );
  }
}

class _BottomIconButton extends StatelessWidget {
  const _BottomIconButton({
    super.key,
    required this.asset,
    required this.onTap,
    this.selected = false,
    this.badge,
    this.unread = false,
  });

  final String asset;
  final VoidCallback? onTap;
  final bool selected;
  final String? badge;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          child: SizedBox(
            child: Image.asset(asset, width: 34.r, height: 34.r),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -4.h,
            right: -10.w,
            child: Container(
              height: 20.h,
              constraints: BoxConstraints(minWidth: 33.w),
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3D54),
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              child: Text(
                badge!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        if (unread)
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Semantics(
              label: 'Unread messages',
              child: Container(
                key: const ValueKey('room-message-unread'),
                width: AppSpacing.messageUnreadDot.r,
                height: AppSpacing.messageUnreadDot.r,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GiftButton extends StatelessWidget {
  const _GiftButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: _RoomAssetIcon(
            asset: AppAssets.lanhuRoomBottomGift,
            size: 44.r,
          ),
        ),
      ),
    );
  }
}
