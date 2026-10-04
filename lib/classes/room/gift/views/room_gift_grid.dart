import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../models/room_gift_models.dart';

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
                _GiftTabGrid(
                  key: PageStorageKey<int>(tab.id),
                  gifts: tab.gifts,
                  selectedGiftKey: selectedGiftKey,
                  onGiftSelected: onGiftSelected,
                ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
      ],
    );
  }

  int get _selectedTabIndex {
    final index = tabs.indexWhere((tab) => tab.id == selectedTabId);
    return index < 0 ? 0 : index;
  }
}

class _GiftTabs extends StatelessWidget {
  const _GiftTabs({required this.tabs, required this.tabController});

  final List<RoomGiftTab> tabs;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.roomGiftTabHeight.h,
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) => ExtendedTabBar(
          controller: tabController,
          isScrollable: true,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
          indicator: const BoxDecoration(color: AppColors.transparent),
          indicatorColor: AppColors.transparent,
          dividerColor: AppColors.transparent,
          labelPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
          overlayColor: WidgetStateProperty.all(AppColors.transparent),
          splashFactory: NoSplash.splashFactory,
          tabs: [
            for (var index = 0; index < tabs.length; index++)
              Tab(
                height: AppSpacing.roomGiftTabHeight.h,
                child: _GiftTabLabel(
                  tab: tabs[index],
                  selected: tabController.index == index,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GiftTabLabel extends StatelessWidget {
  const _GiftTabLabel({required this.tab, required this.selected});

  final RoomGiftTab tab;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.isBackpack) ...[
              Image.asset(
                AppAssets.lanhuRoomGiftBackpack,
                width: AppSpacing.iconSizeSm.r,
                height: AppSpacing.iconSizeSm.r,
              ),
              SizedBox(width: AppSpacing.xs.w),
            ],
            Text(
              tab.isBackpack ? context.l10n.t('room.gift.backpack') : tab.name,
              style: selected
                  ? AppTextStyles.roomGiftTabSelected
                  : AppTextStyles.roomGiftTab,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: selected ? AppSpacing.sm.w : AppSpacing.roomGiftPageDotSize.w,
          height: AppSpacing.xxs.h,
          decoration: BoxDecoration(
            color: selected ? AppColors.textInverse : AppColors.transparent,
            borderRadius: AppRadius.pillBorder,
          ),
        ),
      ],
    );
  }
}

class _GiftTabGrid extends StatelessWidget {
  const _GiftTabGrid({
    super.key,
    required this.gifts,
    required this.selectedGiftKey,
    required this.onGiftSelected,
  });

  final List<RoomGift> gifts;
  final String? selectedGiftKey;
  final ValueChanged<RoomGift> onGiftSelected;

  @override
  Widget build(BuildContext context) {
    if (gifts.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.roomGiftGridHorizontalInset.w,
        vertical: AppSpacing.xs.h,
      ),
      physics: const ClampingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.roomGiftGridMainSpacing.h,
        crossAxisSpacing: AppSpacing.roomGiftGridCrossSpacing.w,
        childAspectRatio: AppSpacing.roomGiftGridChildAspectRatio,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        return _GiftTile(
          gift: gift,
          selected: gift.selectionKey == selectedGiftKey,
          onTap: () => onGiftSelected(gift),
        );
      },
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({
    required this.gift,
    required this.selected,
    required this.onTap,
  });

  final RoomGift gift;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roomGiftItemBorder,
      child: Container(
        decoration: BoxDecoration(
          border: selected
              ? Border.all(color: AppColors.roomGiftSelectedBorder)
              : null,
          borderRadius: AppRadius.roomGiftItemBorder,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GiftImage(url: gift.icon),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  gift.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.roomGiftName,
                ),
                SizedBox(height: AppSpacing.xxs.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!gift.isBackpack)
                      Image.asset(
                        AppAssets.lanhuRoomGiftCoin,
                        width: AppSpacing.iconSizeXs.r,
                        height: AppSpacing.iconSizeXs.r,
                      ),
                    if (!gift.isBackpack) SizedBox(width: AppSpacing.xxs.w),
                    Flexible(
                      child: Text(
                        gift.isBackpack
                            ? 'x${gift.amount ?? 0}'
                            : '${gift.price}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.roomGiftPrice,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (gift.cornerMark.isNotEmpty)
              PositionedDirectional(
                top: 0,
                start: 0,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: AppSpacing.roomGiftCornerMarkHeight.h,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
                  decoration: const BoxDecoration(
                    color: AppColors.roomGiftBadge,
                    borderRadius: AppRadius.roomGiftItemBorder,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    gift.cornerMark,
                    style: AppTextStyles.roomGiftCornerMark,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GiftImage extends StatelessWidget {
  const _GiftImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: url,
      width: AppSpacing.roomGiftImageSize.r,
      height: AppSpacing.roomGiftImageSize.r,
      fit: BoxFit.contain,
      placeholder: (_, __) => SizedBox(
        width: AppSpacing.roomGiftImageSize.r,
        height: AppSpacing.roomGiftImageSize.r,
        child: Center(
          child: SizedBox(
            width: AppSpacing.iconSizeSm.r,
            height: AppSpacing.iconSizeSm.r,
            child: const CircularProgressIndicator(
              strokeWidth: AppSpacing.xxs,
              color: AppColors.roomGiftGold,
            ),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Image.asset(
      AppAssets.lanhuRoomIconMissing,
      width: AppSpacing.roomGiftImageSize.r,
      height: AppSpacing.roomGiftImageSize.r,
      fit: BoxFit.contain,
    );
  }
}
