import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../models/room_gift_models.dart';
import 'room_gift_pages.dart';

class RoomGiftCatalogView extends HookWidget {
  const RoomGiftCatalogView({
    super.key,
    required this.tabs,
    required this.selectedTabId,
    required this.selectedGiftKey,
    required this.onTabSelected,
    required this.onGiftSelected,
  });

  final List<RoomGiftTab> tabs;
  final int? selectedTabId;
  final String? selectedGiftKey;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<RoomGift> onGiftSelected;

  @override
  Widget build(BuildContext context) {
    final selectedTabIndex = _selectedTabIndex;
    final tabController = useTabController(
      initialLength: tabs.length,
      initialIndex: selectedTabIndex,
      keys: [Object.hashAll(tabs.map((tab) => tab.id))],
    );
    final lastNotifiedTabId = useRef<int?>(selectedTabId);

    useEffect(() {
      lastNotifiedTabId.value = selectedTabId;
      if (tabController.index != selectedTabIndex) {
        tabController.animateTo(selectedTabIndex);
      }
      return null;
    }, [selectedTabId, selectedTabIndex, tabController]);

    useEffect(() {
      void handleTabChanged() {
        final index = tabController.index;
        if (index < 0 || index >= tabs.length) return;
        final tabId = tabs[index].id;
        if (lastNotifiedTabId.value == tabId) return;
        lastNotifiedTabId.value = tabId;
        onTabSelected(tabId);
      }

      tabController.addListener(handleTabChanged);
      return () => tabController.removeListener(handleTabChanged);
    }, [tabController, tabs, onTabSelected]);

    return Column(
      children: [
        _GiftTabs(tabs: tabs, tabController: tabController),
        Expanded(
          child: ExtendedTabBarView(
            controller: tabController,
            cacheExtent: tabs.length > 1 ? 1 : 0,
            children: [
              for (final tab in tabs)
                RoomGiftPages(
                  key: ValueKey<int>(tab.id),
                  gifts: tab.gifts,
                  selectedGiftKey: selectedGiftKey,
                  onGiftSelected: onGiftSelected,
                ),
            ],
          ),
        ),
      ],
    );
  }

  int get _selectedTabIndex {
    final index = tabs.indexWhere((tab) => tab.id == selectedTabId);
    return index < 0 ? 0 : index;
  }
}

class _GiftTabs extends HookWidget {
  const _GiftTabs({required this.tabs, required this.tabController});

  final List<RoomGiftTab> tabs;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    useListenable(tabController);
    final regularTabs = tabs.where((tab) => !tab.isBackpack).toList();
    final selectedTab = tabs[tabController.index];
    final regularIndex = regularTabs.indexWhere(
      (tab) => tab.id == selectedTab.id,
    );
    final headerController = useTabController(
      initialLength: regularTabs.length,
      initialIndex: regularIndex < 0 ? 0 : regularIndex,
      keys: [Object.hashAll(regularTabs.map((tab) => tab.id))],
    );
    useEffect(() {
      if (regularIndex >= 0 && headerController.index != regularIndex) {
        headerController.animateTo(regularIndex);
      }
      return null;
    }, [headerController, regularIndex]);

    final backpackIndex = tabs.indexWhere((tab) => tab.isBackpack);
    return SizedBox(
      height: AppSpacing.roomGiftTabHeight.h,
      child: Row(
        children: [
          Expanded(
            child: regularTabs.isEmpty
                ? const SizedBox.shrink()
                : ExtendedTabBar(
                    controller: headerController,
                    isScrollable: true,
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                    indicator: const BoxDecoration(
                      color: AppColors.transparent,
                    ),
                    dividerColor: AppColors.transparent,
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md.w,
                    ),
                    overlayColor: WidgetStateProperty.all(
                      AppColors.transparent,
                    ),
                    splashFactory: NoSplash.splashFactory,
                    onTap: (index) => tabController.animateTo(
                      tabs.indexWhere((tab) => tab.id == regularTabs[index].id),
                    ),
                    tabs: [
                      for (final tab in regularTabs)
                        Tab(
                          height: AppSpacing.roomGiftTabHeight.h,
                          child: Text(
                            tab.name,
                            style: selectedTab.id == tab.id
                                ? AppTextStyles.roomGiftTabSelected
                                : AppTextStyles.roomGiftTab,
                          ),
                        ),
                    ],
                  ),
          ),
          if (backpackIndex >= 0) ...[
            SizedBox(
              height: AppSpacing.roomGiftTabDividerHeight.h,
              child: const VerticalDivider(
                width: AppSpacing.xxs,
                thickness: AppSpacing.hairline,
                color: AppColors.roomGiftTextMuted,
              ),
            ),
            Tooltip(
              message: context.l10n.t('room.gift.backpack'),
              child: InkWell(
                key: const ValueKey('room-gift-backpack'),
                onTap: () => tabController.animateTo(backpackIndex),
                child: SizedBox(
                  width: AppSpacing.controlHeightMd.w,
                  height: AppSpacing.roomGiftTabHeight.h,
                  child: Center(
                    child: Image.asset(
                      AppAssets.lanhuRoomGiftBackpack,
                      width: AppSpacing.xxl.r,
                      height: AppSpacing.xxl.r,
                      color: selectedTab.isBackpack
                          ? AppColors.roomGiftAccent
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
