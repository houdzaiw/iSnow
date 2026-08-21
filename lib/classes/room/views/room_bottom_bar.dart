part of '../room_page.dart';

class _RoomBottomBar extends StatelessWidget {
  const _RoomBottomBar({
    required this.state,
    required this.onChatTap,
    required this.onToggleMic,
    required this.onToggleSpeaker,
  });

  final RoomPageState state;
  final VoidCallback onChatTap;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleSpeaker;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108.h + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.fromLTRB(
        28.w,
        12.h,
        28.w,
        MediaQuery.paddingOf(context).bottom + 8.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF565665).withValues(alpha: 0.98),
        border: const Border(
          top: BorderSide(color: Color(0xFFFF5C78), width: 6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BottomIconButton(
            asset: AppAssets.lanhuRoomBottomChat,
            onTap: onChatTap,
            badge: state.messages.length > 99 ? '99+' : null,
          ),
          SizedBox(width: 18.w),
          _BottomIconButton(
            asset: state.agoraState.mutedMicrophone
                ? AppAssets.lanhuRoomIconMissing
                : AppAssets.lanhuRoomBottomMic,
            selected: !state.agoraState.mutedMicrophone && state.isOnMic,
            onTap: onToggleMic,
          ),
          const Spacer(),
          _GiftButton(onTap: () {}),
          const Spacer(),
          _BottomIconButton(
            asset: state.agoraState.mutedSpeaker
                ? AppAssets.lanhuRoomIconMissing
                : AppAssets.lanhuRoomBottomMessage,
            onTap: onToggleSpeaker,
          ),
          SizedBox(width: 18.w),
          _BottomIconButton(asset: AppAssets.lanhuRoomBottomMore, onTap: () {}),
        ],
      ),
    );
  }
}

class _BottomIconButton extends StatelessWidget {
  const _BottomIconButton({
    required this.asset,
    required this.onTap,
    this.selected = false,
    this.badge,
  });

  final String asset;
  final VoidCallback onTap;
  final bool selected;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: selected ? _roomGold : const Color(0xFF252631),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 54.r,
              height: 54.r,
              child: Center(
                child: _RoomAssetIcon(
                  asset: asset,
                  size: asset == AppAssets.lanhuRoomBottomMore ? 40.r : 30.r,
                ),
              ),
            ),
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
        child: Container(
          width: 72.r,
          height: 72.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF79B8), Color(0xFFFF3E85), Color(0xFFE72D72)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: _roomPink.withValues(alpha: 0.36),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _RoomAssetIcon(
              asset: AppAssets.lanhuRoomBottomGift,
              size: 44.r,
            ),
          ),
        ),
      ),
    );
  }
}
