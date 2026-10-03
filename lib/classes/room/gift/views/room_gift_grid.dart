import 'package:cached_network_image/cached_network_image.dart';
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
    final tab = _selectedTab;
    final pages = _giftPages(tab?.gifts ?? const []);
    final pageIndex = useState(0);
    final pageController = usePageController();

    useEffect(() {
      pageIndex.value = 0;
      if (pageController.hasClients) pageController.jumpToPage(0);
      return null;
    }, [tab?.id]);

    return Column(
      children: [
        _GiftTabs(
          tabs: tabs,
          selectedTabId: selectedTabId,
          onSelected: onTabSelected,
        ),
        Expanded(
          child: pages.isEmpty
              ? const SizedBox.shrink()
              : PageView.builder(
                  controller: pageController,
                  itemCount: pages.length,
                  onPageChanged: (value) => pageIndex.value = value,
                  itemBuilder: (context, index) {
                    return GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.roomGiftGridHorizontalInset.w,
                        vertical: AppSpacing.xs.h,
                      ),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: AppSpacing.roomGiftGridMainSpacing.h,
                        crossAxisSpacing: AppSpacing.roomGiftGridCrossSpacing.w,
                        childAspectRatio:
                            AppSpacing.roomGiftGridChildAspectRatio,
                      ),
                      itemCount: pages[index].length,
                      itemBuilder: (context, giftIndex) {
                        final gift = pages[index][giftIndex];
                        return _GiftTile(
                          gift: gift,
                          selected: gift.selectionKey == selectedGiftKey,
                          onTap: () => onGiftSelected(gift),
                        );
                      },
                    );
                  },
                ),
        ),
        _GiftPageDots(count: pages.length, selectedIndex: pageIndex.value),
        SizedBox(height: AppSpacing.sm.h),
      ],
    );
  }

  RoomGiftTab? get _selectedTab {
    for (final tab in tabs) {
      if (tab.id == selectedTabId) return tab;
    }
    return tabs.isEmpty ? null : tabs.first;
  }

  List<List<RoomGift>> _giftPages(List<RoomGift> gifts) {
    final pages = <List<RoomGift>>[];
    for (var start = 0; start < gifts.length; start += 8) {
      final end = (start + 8).clamp(0, gifts.length);
      pages.add(gifts.sublist(start, end));
    }
    return pages;
  }
}

class _GiftTabs extends StatelessWidget {
  const _GiftTabs({
    required this.tabs,
    required this.selectedTabId,
    required this.onSelected,
  });

  final List<RoomGiftTab> tabs;
  final int? selectedTabId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.roomGiftTabHeight.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: AppSpacing.lg.w),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = tab.id == selectedTabId;
          return InkWell(
            onTap: () => onSelected(tab.id),
            child: Column(
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
                      tab.isBackpack
                          ? context.l10n.t('room.gift.backpack')
                          : tab.name,
                      style: selected
                          ? AppTextStyles.roomGiftTabSelected
                          : AppTextStyles.roomGiftTab,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xs.h),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: selected
                      ? AppSpacing.sm.w
                      : AppSpacing.roomGiftPageDotSize.w,
                  height: AppSpacing.xxs.h,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.textInverse
                        : AppColors.transparent,
                    borderRadius: AppRadius.pillBorder,
                  ),
                ),
              ],
            ),
          );
        },
      ),
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

class _GiftPageDots extends StatelessWidget {
  const _GiftPageDots({required this.count, required this.selectedIndex});

  final int count;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) {
      return SizedBox(height: AppSpacing.roomGiftPageDotSize.h);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == selectedIndex;
        return Container(
          width:
              (selected
                      ? AppSpacing.roomGiftPageDotSelectedWidth
                      : AppSpacing.roomGiftPageDotSize)
                  .w,
          height: AppSpacing.roomGiftPageDotSize.h,
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.xxs.w),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.roomGiftGold
                : AppColors.roomGiftTextMuted,
            borderRadius: AppRadius.pillBorder,
          ),
        );
      }),
    );
  }
}
