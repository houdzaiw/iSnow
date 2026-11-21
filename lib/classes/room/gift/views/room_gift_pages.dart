import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../models/room_gift_models.dart';
import 'room_gift_image.dart';

class RoomGiftPages extends HookWidget {
  const RoomGiftPages({
    super.key,
    required this.gifts,
    required this.selectedGiftKey,
    required this.onGiftSelected,
    this.selectedCount = 1,
  });

  final List<RoomGift> gifts;
  final String? selectedGiftKey;
  final ValueChanged<RoomGift> onGiftSelected;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final pageCount = gifts.isEmpty
        ? 1
        : (gifts.length / AppSpacing.roomGiftPageSize).ceil();
    final selectedIndex = gifts.indexWhere(
      (gift) => gift.selectionKey == selectedGiftKey,
    );
    final controller = useTabController(
      initialLength: pageCount,
      initialIndex: selectedIndex < 0
          ? 0
          : selectedIndex ~/ AppSpacing.roomGiftPageSize,
      keys: [pageCount],
    );
    useListenable(controller);
    useEffect(() {
      if (selectedIndex >= 0) {
        final page = selectedIndex ~/ AppSpacing.roomGiftPageSize;
        if (controller.index != page) controller.animateTo(page);
      }
      return null;
    }, [controller, selectedGiftKey]);

    return Column(
      children: [
        Expanded(
          child: gifts.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.t('room.gift.empty'),
                    style: AppTextStyles.roomGiftStatus,
                  ),
                )
              : ExtendedTabBarView(
                  controller: controller,
                  link: true,
                  cacheExtent: pageCount > 1 ? 1 : 0,
                  children: [
                    for (var page = 0; page < pageCount; page++)
                      _GiftPage(
                        gifts: gifts
                            .skip(page * AppSpacing.roomGiftPageSize)
                            .take(AppSpacing.roomGiftPageSize)
                            .toList(growable: false),
                        selectedGiftKey: selectedGiftKey,
                        selectedCount: selectedCount,
                        onGiftSelected: onGiftSelected,
                      ),
                  ],
                ),
        ),
        SizedBox(
          height: AppSpacing.roomGiftPageIndicatorHeight.h,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var page = 0; page < pageCount; page++)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs.w,
                      ),
                      child: SizedBox(
                        width: AppSpacing.roomGiftPageDotWidth.w,
                        height: AppSpacing.roomGiftPageDotSize.h,
                        child: ColoredBox(
                          key: ValueKey('room-gift-page-$page'),
                          color: page == controller.index
                              ? AppColors.roomGiftPageSelected
                              : AppColors.roomGiftCountMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GiftPage extends StatelessWidget {
  const _GiftPage({
    required this.gifts,
    required this.selectedGiftKey,
    required this.onGiftSelected,
    required this.selectedCount,
  });

  final List<RoomGift> gifts;
  final String? selectedGiftKey;
  final ValueChanged<RoomGift> onGiftSelected;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.roomGiftGridHorizontalInset.w,
        ),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: AppSpacing.roomGiftGridColumns,
          mainAxisExtent: constraints.maxHeight / 2,
        ),
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return _GiftTile(
            gift: gift,
            selected: gift.selectionKey == selectedGiftKey,
            selectedCount: selectedCount,
            onTap: () => onGiftSelected(gift),
          );
        },
      ),
    );
  }
}

class _GiftTile extends HookWidget {
  const _GiftTile({
    required this.gift,
    required this.selected,
    required this.onTap,
    required this.selectedCount,
  });

  final RoomGift gift;
  final bool selected;
  final VoidCallback onTap;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final pulse = useAnimationController(
      duration: AppMotion.roomGiftSelectionPulse,
      initialValue: 1,
    );
    final disabled = MediaQuery.disableAnimationsOf(context);
    useEffect(() {
      if (selected && !disabled) {
        pulse.repeat(reverse: true);
      } else {
        pulse.stop();
        pulse.value = 1;
      }
      return null;
    }, [selected, disabled]);
    useListenable(pulse);
    final marks = [
      ...gift.displayMarks,
      if (gift.animationUrl?.isNotEmpty == true)
        context.l10n.t('room.gift.hasEffect'),
      if (gift.giftType == 3) context.l10n.t('room.gift.lucky'),
    ];
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey('room-gift-${gift.selectionKey}'),
        onTap: onTap,
        borderRadius: AppRadius.roomGiftItemBorder,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.roomGiftSelectedSurface
                : AppColors.transparent,
            border: Border.all(
              color: selected
                  ? ColorTween(
                      begin: AppColors.roomGiftSelectedBorderMuted,
                      end: AppColors.roomGiftSelectedBorder,
                    ).evaluate(pulse)!
                  : AppColors.transparent,
            ),
            borderRadius: AppRadius.roomGiftItemBorder,
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.xs.r),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(child: _GiftImage(url: gift.icon)),
                    ),
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
                        if (!gift.isBackpack) ...[
                          Image.asset(
                            AppAssets.lanhuRoomGiftCoin,
                            width: AppSpacing.roomGiftPriceCoinSize.r,
                            height: AppSpacing.roomGiftPriceCoinSize.r,
                          ),
                          SizedBox(width: AppSpacing.xxs.w),
                        ],
                        Flexible(
                          child: Text(
                            gift.isBackpack
                                ? 'x${gift.amount ?? 0}'
                                : gift.formattedPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.roomGiftPrice,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (marks.isNotEmpty)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final mark in marks.take(4))
                        _GiftCornerMark(mark: mark),
                    ],
                  ),
                ),
              if (selected)
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: _GiftCornerMark(mark: 'x$selectedCount'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftCornerMark extends StatelessWidget {
  const _GiftCornerMark({required this.mark});

  final String mark;

  @override
  Widget build(BuildContext context) {
    if (Uri.tryParse(mark)?.hasAuthority == true) {
      return CachedNetworkImage(
        imageUrl: mark,
        height: AppSpacing.roomGiftCornerMarkHeight.h,
        width: AppSpacing.roomGiftCornerMarkWidth.w,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) =>
            Image.asset(AppAssets.lanhuRoomIconMissing),
      );
    }
    if (mark.toUpperCase() == 'NEW') {
      return Image.asset(
        AppAssets.roomGiftNewBadge,
        height: AppSpacing.roomGiftCornerMarkHeight.h,
        width: AppSpacing.roomGiftCornerMarkWidth.w,
      );
    }
    return Container(
      constraints: BoxConstraints(maxWidth: AppSpacing.roomGiftImageSize.w),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs.w),
      decoration: const BoxDecoration(
        color: AppColors.roomGiftBadge,
        borderRadius: AppRadius.roomGiftItemBorder,
      ),
      child: Text(
        mark,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.roomGiftCornerMark,
      ),
    );
  }
}

class _GiftImage extends StatelessWidget {
  const _GiftImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return RoomGiftImage(
      source: url,
      size: AppSpacing.roomGiftImageSize.r,
      placeholderBuilder: (_) => SizedBox(
        width: AppSpacing.roomGiftImageSize.r,
        height: AppSpacing.roomGiftImageSize.r,
        child: Center(
          child: SizedBox(
            width: AppSpacing.iconSizeSm.r,
            height: AppSpacing.iconSizeSm.r,
            child: const CircularProgressIndicator(
              strokeWidth: AppSpacing.xxs,
              color: AppColors.roomGiftAccent,
            ),
          ),
        ),
      ),
    );
  }
}
