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

class _RoomChatPanel extends HookWidget {
  const _RoomChatPanel({required this.state, required this.onFilterChanged});

  final RoomPageState state;
  final ValueChanged<RoomChatFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final filters = RoomChatFilter.values;
    final selectedIndex = filters.indexOf(state.chatFilter);
    final tabController = useTabController(
      initialLength: filters.length,
      initialIndex: selectedIndex,
    );
    final selectedFilter = useRef(state.chatFilter);

    void updateFilter(RoomChatFilter filter) {
      if (filter == selectedFilter.value) return;
      selectedFilter.value = filter;
      onFilterChanged(filter);
    }

    useEffect(() {
      selectedFilter.value = state.chatFilter;
      if (tabController.index != selectedIndex) {
        tabController.animateTo(selectedIndex);
      }
      return null;
    }, [selectedIndex]);

    useEffect(() {
      void handleTabChanged() {
        final index = tabController.index;
        if (index < 0 || index >= filters.length) return;
        updateFilter(filters[index]);
      }

      tabController.addListener(handleTabChanged);
      return () => tabController.removeListener(handleTabChanged);
    }, [tabController, state.chatFilter, onFilterChanged]);

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          _RoomChatTabs(
            selected: state.chatFilter,
            tabController: tabController,
            onSelected: updateFilter,
          ),
          Expanded(
            child: ExtendedTabBarView(
              controller: tabController,
              cacheExtent: filters.length - 1,
              children: [
                for (final filter in filters)
                  _RoomChatMessageList(
                    key: PageStorageKey<String>('room-chat-${filter.name}'),
                    messages: _messagesForFilter(state.messages, filter),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomChatTabs extends StatelessWidget {
  const _RoomChatTabs({
    required this.selected,
    required this.tabController,
    required this.onSelected,
  });

  final RoomChatFilter selected;
  final TabController tabController;
  final ValueChanged<RoomChatFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.roomChatTabBarHeight.h,
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.roomChatTabsWidth.w,
            child: AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                return ExtendedTabBar(
                  controller: tabController,
                  mainAxisAlignment: MainAxisAlignment.start,
                  indicator: const BoxDecoration(color: AppColors.transparent),
                  indicatorColor: AppColors.transparent,
                  dividerColor: AppColors.transparent,
                  labelPadding: EdgeInsets.zero,
                  overlayColor: WidgetStateProperty.all(AppColors.transparent),
                  splashFactory: NoSplash.splashFactory,
                  onTap: (index) => onSelected(RoomChatFilter.values[index]),
                  tabs: [
                    for (final filter in RoomChatFilter.values)
                      Tab(
                        height: AppSpacing.roomChatTabBarHeight.h,
                        child: _RoomChatTab(
                          filter: filter,
                          selected: selected == filter,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.only(
              right: AppSpacing.roomChatGiftRightInset.w,
            ),
            child: _RoomAssetIcon(
              asset: AppAssets.lanhuRoomChatPanelGift,
              size: AppSpacing.roomChatGiftIconSize.r,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomChatTab extends StatelessWidget {
  const _RoomChatTab({required this.filter, required this.selected});

  final RoomChatFilter filter;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.roomChatTabWidth.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _filterLabel(filter),
            maxLines: 1,
            style: selected
                ? AppTextStyles.roomChatTabSelected
                : AppTextStyles.roomChatTab,
          ),
          SizedBox(height: AppSpacing.roomChatTabIndicatorTop.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: selected ? AppSpacing.roomChatTabIndicatorWidth.w : 0,
            height: AppSpacing.roomChatTabIndicatorHeight.h,
            decoration: BoxDecoration(
              color: AppColors.roomChatTabSelected,
              borderRadius: BorderRadius.circular(
                AppSpacing.roomChatTabIndicatorRadius.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomChatMessageList extends StatelessWidget {
  const _RoomChatMessageList({super.key, required this.messages});

  final List<RoomChatEntry> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.roomChatMessageHorizontalInset.w,
        AppSpacing.xxs.h,
        AppSpacing.roomChatMessageHorizontalInset.w,
        AppSpacing.roomChatMessageBottomInset.h,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: EdgeInsets.only(
            top: index == 0
                ? AppSpacing.roomChatMessageTopFirst.h
                : AppSpacing.roomChatMessageTop.h,
          ),
          child: _RoomChatMessageBubble(message: message),
        );
      },
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

List<RoomChatEntry> _messagesForFilter(
  List<RoomChatEntry> messages,
  RoomChatFilter filter,
) {
  return switch (filter) {
    RoomChatFilter.all => messages,
    RoomChatFilter.chat => messages.where((item) => item.isChat).toList(),
    RoomChatFilter.gift => messages.where((item) => item.isGift).toList(),
  };
}
