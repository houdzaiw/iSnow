part of '../room_page.dart';

class _RoomChatPanel extends HookWidget {
  const _RoomChatPanel({
    required this.state,
    required this.onFilterChanged,
    required this.onClearMessages,
    required this.onUserTap,
    required this.onImageTap,
    required this.onPartyTap,
  });

  final RoomPageState state;
  final ValueChanged<RoomChatFilter> onFilterChanged;
  final VoidCallback onClearMessages;
  final ValueChanged<int> onUserTap;
  final ValueChanged<String> onImageTap;
  final ValueChanged<int> onPartyTap;

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
            onClearMessages:
                state.isReady &&
                    state.isOwnerOrManager &&
                    !state.clearingMessages
                ? onClearMessages
                : null,
            showClearButton: state.isOwnerOrManager,
          ),
          Expanded(
            child: ExtendedTabBarView(
              controller: tabController,
              cacheExtent: filters.length - 1,
              children: [
                for (final filter in filters)
                  _RoomChatMessageList(
                    key: PageStorageKey<String>('room-chat-${filter.name}'),
                    onUserTap: onUserTap,
                    onImageTap: onImageTap,
                    onPartyTap: onPartyTap,
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
    required this.onClearMessages,
    required this.showClearButton,
  });

  final RoomChatFilter selected;
  final TabController tabController;
  final ValueChanged<RoomChatFilter> onSelected;
  final VoidCallback? onClearMessages;
  final bool showClearButton;

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
          if (showClearButton)
            Padding(
              padding: EdgeInsets.only(
                right: AppSpacing.roomChatGiftRightInset.w,
              ),
              child: Semantics(
                button: true,
                enabled: onClearMessages != null,
                label: context.l10n.t('room.chat.clear'),
                child: Tooltip(
                  message: context.l10n.t('room.chat.clear'),
                  child: GestureDetector(
                    key: const ValueKey('room-chat-clear'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onClearMessages,
                    child: _RoomAssetIcon(
                      asset: AppAssets.lanhuRoomChatPanelGift,
                      size: AppSpacing.roomChatGiftIconSize.r,
                    ),
                  ),
                ),
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
  const _RoomChatMessageList({
    super.key,
    required this.messages,
    required this.onUserTap,
    required this.onImageTap,
    required this.onPartyTap,
  });

  final List<RoomChatEntry> messages;
  final ValueChanged<int> onUserTap;
  final ValueChanged<String> onImageTap;
  final ValueChanged<int> onPartyTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: RoomPublicChatTheme.listBottom.h),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: EdgeInsets.only(
            top: index == 0
                ? RoomPublicChatTheme.firstGap.h
                : RoomPublicChatTheme.rowGap.h,
          ),
          child: RoomPublicMessageItem(
            key: ValueKey(
              'room-public-entry-${message.kind.name}-${message.id}',
            ),
            message: message,
            onUserTap: onUserTap,
            onImageTap: onImageTap,
            onPartyTap: onPartyTap,
          ),
        );
      },
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
