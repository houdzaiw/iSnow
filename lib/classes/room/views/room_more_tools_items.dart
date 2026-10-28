part of '../room_page.dart';

class _RoomMoreSection extends StatelessWidget {
  const _RoomMoreSection({this.title, required this.items});

  final String? title;
  final List<_RoomMoreToolItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final labelHeight =
        MediaQuery.textScalerOf(
          context,
        ).scale(AppTextStyles.roomMoreTool.fontSize!) *
        AppTextStyles.roomMoreTool.height! *
        2;
    final minimumTileHeight =
        AppSpacing.roomMoreToolIconBoxSize.r +
        AppSpacing.roomMoreToolLabelTop.h +
        labelHeight;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.roomMoreSectionTopGap.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.only(
                bottom: AppSpacing.roomMoreSectionTitleBottom.h,
              ),
              child: Text(title!, style: AppTextStyles.roomToolsHeading),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: AppSpacing.roomMoreGridMainGap.h,
              crossAxisSpacing: AppSpacing.roomMoreGridCrossGap.w,
              mainAxisExtent: AppSpacing.roomMoreToolTileHeight.h.clamp(
                minimumTileHeight,
                double.infinity,
              ),
            ),
            itemBuilder: (context, index) {
              return _RoomMoreToolTile(item: items[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _RoomMoreLoadingSection extends StatelessWidget {
  const _RoomMoreLoadingSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.roomMoreSectionTopGap.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.roomToolsHeading),
          SizedBox(
            height: AppSpacing.roomMoreLoadingHeight.h,
            child: Row(
              children: [
                SizedBox(
                  width: AppSpacing.iconSizeSm.r,
                  height: AppSpacing.iconSizeSm.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: AppSpacing.xxs,
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),
                Text(
                  context.l10n.t('room.more.loading'),
                  style: AppTextStyles.roomSettingsDescription,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomMoreErrorRow extends StatelessWidget {
  const _RoomMoreErrorRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.roomSettingsDescription,
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          InkWell(
            onTap: onRetry,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm.w,
                vertical: AppSpacing.xs.h,
              ),
              child: Text(
                context.l10n.t('app.retry'),
                style: AppTextStyles.roomToolsRetry,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomMoreToolTile extends StatelessWidget {
  const _RoomMoreToolTile({required this.item});

  final _RoomMoreToolItem item;

  @override
  Widget build(BuildContext context) {
    final enabled = item.onTap != null && !item.loading;

    return Opacity(
      opacity: enabled ? 1 : AppSpacing.roomToolDisabledOpacity,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: AppRadius.fieldBorder,
          onTap: enabled ? item.onTap : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoomMoreIconFrame(item: item),
              SizedBox(height: AppSpacing.roomMoreToolLabelTop.h),
              Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.roomMoreTool.copyWith(
                  color: AppColors.roomToolsTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomMoreIconFrame extends StatelessWidget {
  const _RoomMoreIconFrame({required this.item});

  final _RoomMoreToolItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.roomMoreToolIconBoxSize.r,
      height: AppSpacing.roomMoreToolIconBoxSize.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: item.selected
                  ? AppColors.roomMoreTileActive
                  : AppColors.roomToolsTile,
              borderRadius: AppRadius.roomToolsTileBorder,
              border: item.selected
                  ? Border.all(color: AppColors.roomMoreSelectedBorder)
                  : null,
            ),
            child: Center(child: _RoomMoreIcon(item: item)),
          ),
          if (item.tags.isNotEmpty) _RoomMoreToolTag(label: item.tags.first),
          if (item.loading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.roomToolsLoadingScrim,
                  borderRadius: AppRadius.roomToolsTileBorder,
                ),
                child: Center(
                  child: SizedBox(
                    width: AppSpacing.xl.r,
                    height: AppSpacing.xl.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: AppSpacing.xxs,
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

class _RoomMoreIcon extends StatelessWidget {
  const _RoomMoreIcon({required this.item});

  final _RoomMoreToolItem item;

  @override
  Widget build(BuildContext context) {
    final iconSize =
        (item.assetIncludesTile
                ? AppSpacing.roomMoreToolIconBoxSize
                : AppSpacing.roomMoreToolIconSize)
            .r;
    final imageUrl = item.imageUrl?.trim();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        placeholder: (_, __) => _RoomAssetIcon(
          asset: AppAssets.lanhuRoomIconMissing,
          size: iconSize,
        ),
        errorWidget: (_, __, ___) => _RoomAssetIcon(
          asset: AppAssets.lanhuRoomIconMissing,
          size: iconSize,
        ),
      );
    }

    return _RoomAssetIcon(
      asset: item.asset ?? AppAssets.lanhuRoomIconMissing,
      size: iconSize,
    );
  }
}

class _RoomMoreToolTag extends StatelessWidget {
  const _RoomMoreToolTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().toUpperCase();
    if (normalized.isEmpty) return const SizedBox.shrink();

    final color = normalized.contains('HOT')
        ? AppColors.roomMoreTagHot
        : AppColors.roomMoreTagNew;
    return Positioned(
      top: AppSpacing.roomToolTagOffsetTop.h,
      right: AppSpacing.roomToolTagOffsetRight.w,
      child: Container(
        height: AppSpacing.roomToolTagHeight.h,
        constraints: BoxConstraints(minWidth: AppSpacing.roomToolTagMinWidth.w),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.roomToolTagInset.w,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadius.roomToolsTagBorder,
        ),
        alignment: Alignment.center,
        child: Text(
          normalized,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.roomMoreTag,
        ),
      ),
    );
  }
}

class _RoomMoreToolItem {
  const _RoomMoreToolItem({
    required this.label,
    this.asset,
    this.assetIncludesTile = false,
    this.imageUrl,
    this.tags = const [],
    this.selected = false,
    this.loading = false,
    this.onTap,
  });

  final String label;
  final String? asset;
  final bool assetIncludesTile;
  final String? imageUrl;
  final List<String> tags;
  final bool selected;
  final bool loading;
  final VoidCallback? onTap;
}
