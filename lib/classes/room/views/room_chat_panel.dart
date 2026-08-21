part of '../room_page.dart';

class _RoomMusicStrip extends StatelessWidget {
  const _RoomMusicStrip({required this.state});

  final RoomPageState state;

  @override
  Widget build(BuildContext context) {
    final listeners = state.seats.where((seat) => seat.isOccupied).take(5);
    return SizedBox(
      height: 48.h,
      child: Padding(
        padding: EdgeInsets.fromLTRB(28.w, 5.h, 28.w, 6.h),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 37.h,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Row(
                  children: [
                    _RoomAssetIcon(
                      asset: AppAssets.lanhuRoomIconMissing,
                      size: 24.r,
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        state.roomDesc?.isNotEmpty == true
                            ? state.roomDesc!
                            : 'A song about music A...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.66),
                          fontSize: 15.sp,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            SizedBox(
              width: 136.w,
              height: 38.h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final entry in listeners.indexed)
                    Positioned(
                      left: entry.$1 * 26.w,
                      child: _RoomAvatarImage(
                        url: entry.$2.avatar,
                        size: 38.r,
                        radius: 19.r,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              height: 34.h,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Row(
                children: [
                  _RoomAssetIcon(
                    asset: AppAssets.lanhuRoomIconMissing,
                    size: 17.r,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _formatCompact(state.onlineCount),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomChatPanel extends StatelessWidget {
  const _RoomChatPanel({required this.state, required this.onFilterChanged});

  final RoomPageState state;
  final ValueChanged<RoomChatFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final messages = state.visibleMessages;
    return Container(
      width: double.infinity,
      color: _roomPanel,
      child: Column(
        children: [
          _RoomChatTabs(
            selected: state.chatFilter,
            onSelected: onFilterChanged,
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(28.w, 2.h, 28.w, 10.h),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 4.h : 8.h),
                  child: _RoomChatMessageBubble(message: message),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomChatTabs extends StatelessWidget {
  const _RoomChatTabs({required this.selected, required this.onSelected});

  final RoomChatFilter selected;
  final ValueChanged<RoomChatFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Row(
        children: [
          for (final filter in RoomChatFilter.values)
            _RoomChatTab(
              filter: filter,
              selected: selected == filter,
              onTap: () => onSelected(filter),
            ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.only(right: 22.w),
            child: _RoomAssetIcon(
              asset: AppAssets.lanhuRoomChatPanelGift,
              size: 28.r,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomChatTab extends StatelessWidget {
  const _RoomChatTab({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final RoomChatFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 92.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _filterLabel(filter),
              maxLines: 1,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.48),
                fontSize: 22.sp,
                height: 1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            SizedBox(height: 6.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 22.w : 0,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomChatMessageBubble extends StatelessWidget {
  const _RoomChatMessageBubble({required this.message});

  final RoomChatEntry message;

  @override
  Widget build(BuildContext context) {
    final isSystem = message.kind == RoomChatEntryKind.system;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSystem) ...[
          _RoomAvatarImage(url: message.senderAvatar, size: 34.r, radius: 17.r),
          SizedBox(width: 8.w),
        ],
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: isSystem
                  ? Colors.black.withValues(alpha: 0.58)
                  : Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: _ChatMessageText(message: message),
          ),
        ),
      ],
    );
  }
}

class _ChatMessageText extends StatelessWidget {
  const _ChatMessageText({required this.message});

  final RoomChatEntry message;

  @override
  Widget build(BuildContext context) {
    final name = message.senderName;
    final textColor = switch (message.kind) {
      RoomChatEntryKind.gift => _roomGold,
      RoomChatEntryKind.system => const Color(0xFFFF80D8),
      _ => Colors.white,
    };
    return RichText(
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          color: textColor,
          fontSize: 15.sp,
          height: 1.24,
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (name != null && name.isNotEmpty)
            TextSpan(
              text: '$name ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w800,
              ),
            ),
          TextSpan(text: message.text),
        ],
      ),
    );
  }
}

String _filterLabel(RoomChatFilter filter) {
  return switch (filter) {
    RoomChatFilter.all => 'All',
    RoomChatFilter.chat => 'Chat',
    RoomChatFilter.gift => 'Gift',
  };
}
