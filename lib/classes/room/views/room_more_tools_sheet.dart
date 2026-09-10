part of '../room_page.dart';

void _showRoomMoreToolsSheet(
  BuildContext context,
  WidgetRef ref,
  AutoDisposeStateNotifierProvider<RoomViewModel, RoomPageState> provider,
) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.modalScrimStrong,
    builder: (sheetContext) {
      return _RoomMoreToolsSheet(
        roomProvider: provider,
        onOpenBanner: (banner) {
          final roomState = ref.read(provider);
          final targetUrl = banner.resolvedRouteUrl(
            roomId: _roomMoreRoomId(roomState),
            languageCode: Localizations.localeOf(context).languageCode,
          );
          if (targetUrl.isEmpty) {
            _showRoomMoreSnack(
              sheetContext,
              context.l10n.t('room.more.actionPending'),
            );
            return;
          }

          Navigator.of(sheetContext).pop();
          if (!context.mounted) return;
          context.push(
            Uri(
              path: '/web-view',
              queryParameters: {
                'title': banner.displayName,
                'uri': targetUrl,
                'hiddenAppBar': 'true',
              },
            ).toString(),
          );
        },
      );
    },
  );
}

class _RoomMoreToolsSheet extends ConsumerWidget {
  const _RoomMoreToolsSheet({
    required this.roomProvider,
    required this.onOpenBanner,
  });

  final AutoDisposeStateNotifierProvider<RoomViewModel, RoomPageState>
  roomProvider;
  final ValueChanged<RoomToolBanner> onOpenBanner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final roomId = _roomMoreRoomId(roomState);
    final toolsProvider = roomMoreToolsViewModelProvider(roomId);
    final toolsState = ref.watch(toolsProvider);
    final toolsNotifier = ref.read(toolsProvider.notifier);

    final sections = <Widget>[
      _RoomMoreSection(
        title: context.l10n.t('room.more.basicTools'),
        items: _basicTools(context, ref, roomState, toolsState),
      ),
      if (roomState.isOwnerOrManager)
        _RoomMoreSection(
          title: context.l10n.t('room.more.roomMode'),
          items: _roomModeTools(context, toolsState, roomState, toolsNotifier),
        ),
      if (roomState.isOwnerOrManager)
        _RoomMoreSection(
          title: context.l10n.t('room.more.party'),
          items: _partyTools(context),
        ),
      if (toolsState.loadingBanners && toolsState.gameBanners.isEmpty)
        _RoomMoreLoadingSection(title: context.l10n.t('room.more.game')),
      if (toolsState.gameBanners.isNotEmpty)
        _RoomMoreSection(
          title: context.l10n.t('room.more.game'),
          items: _bannerTools(toolsState.gameBanners),
        ),
      if (toolsState.errorMessage != null)
        _RoomMoreErrorRow(
          message: context.l10n.t('room.more.bannerLoadFailed'),
          onRetry: toolsNotifier.loadBanners,
        ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          AppSpacing.roomMoreSheetHorizontalMargin.w,
          0,
          AppSpacing.roomMoreSheetHorizontalMargin.w,
          AppSpacing.roomMoreSheetBottomMargin.h,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        decoration: BoxDecoration(
          color: AppColors.roomMoreSheet,
          borderRadius: BorderRadius.circular(AppRadius.roomMoreSheet.r),
          border: Border.all(color: AppColors.roomActionSheetBorder),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.roomMoreSheetHorizontalInset.w,
            AppSpacing.roomMoreSheetTopInset.h,
            AppSpacing.roomMoreSheetHorizontalInset.w,
            18.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections,
          ),
        ),
      ),
    );
  }

  List<_RoomMoreToolItem> _basicTools(
    BuildContext context,
    WidgetRef ref,
    RoomPageState roomState,
    RoomMoreToolsState toolsState,
  ) {
    return [
      _RoomMoreToolItem(
        label: context.l10n.t('room.more.share'),
        asset: AppAssets.lanhuRoomMoreShare,
        assetIncludesTile: true,
        onTap: () => _showRoomMoreSnack(
          context,
          context.l10n.t('room.more.actionPending'),
        ),
      ),
      _RoomMoreToolItem(
        label: context.l10n.t('room.more.report'),
        asset: AppAssets.lanhuRoomMoreReport,
        assetIncludesTile: true,
        onTap: () => _showRoomMoreSnack(
          context,
          context.l10n.t('room.more.actionPending'),
        ),
      ),
      if (roomState.isOwnerOrManager)
        _RoomMoreToolItem(
          label: context.l10n.t('room.more.music'),
          asset: AppAssets.lanhuRoomMoreMusic,
          assetIncludesTile: true,
          onTap: () => _showRoomMoreSnack(
            context,
            context.l10n.t('room.more.actionPending'),
          ),
        ),
      if (roomState.isOwnerOrManager)
        _RoomMoreToolItem(
          label: context.l10n.t('room.more.charmCounter'),
          asset: AppAssets.lanhuRoomMoreCharmCounter,
          assetIncludesTile: true,
          onTap: () => _showRoomMoreSnack(
            context,
            context.l10n.t('room.more.actionPending'),
          ),
        ),
      _RoomMoreToolItem(
        label: context.l10n.t('room.more.voice'),
        asset: roomState.agoraState.mutedSpeaker
            ? AppAssets.lanhuRoomMoreVoiceMuted
            : AppAssets.lanhuRoomMoreVoice,
        assetIncludesTile: true,
        selected: !roomState.agoraState.mutedSpeaker,
        onTap: () async {
          await ref.read(roomProvider.notifier).toggleSpeaker();
          if (!context.mounted) return;
          final muted = ref.read(roomProvider).agoraState.mutedSpeaker;
          _showRoomMoreSnack(
            context,
            context.l10n.t(muted ? 'room.more.voiceOff' : 'room.more.voiceOn'),
          );
        },
      ),
      _RoomMoreToolItem(
        label: context.l10n.t('room.more.effectSettings'),
        asset: AppAssets.lanhuRoomMoreEffectsSetting,
        assetIncludesTile: true,
        onTap: () => _showRoomMoreSnack(
          context,
          context.l10n.t('room.more.actionPending'),
        ),
      ),
      if (roomState.isOwnerOrManager)
        _RoomMoreToolItem(
          label: context.l10n.t('room.more.charmSet'),
          asset: AppAssets.lanhuRoomMoreCharmSetting,
          assetIncludesTile: true,
          onTap: () => _showRoomMoreSnack(
            context,
            context.l10n.t('room.more.actionPending'),
          ),
        ),
      ..._bannerTools(toolsState.additionalTools),
    ];
  }

  List<_RoomMoreToolItem> _roomModeTools(
    BuildContext context,
    RoomMoreToolsState toolsState,
    RoomPageState roomState,
    RoomMoreToolsViewModel toolsNotifier,
  ) {
    final activeLobbyType =
        toolsState.activeLobbyType ??
        (roomState.enterResponse?.status == 1
            ? roomState.enterResponse?.lobbyType
            : null);

    return RoomLobbyToolType.values.map((type) {
      final selected = activeLobbyType == type.value;
      final loading = toolsState.togglingLobbyType == type.value;
      final asset = _roomModeAsset(type);
      return _RoomMoreToolItem(
        label: context.l10n.t(type.labelKey),
        asset: asset,
        assetIncludesTile: asset != AppAssets.lanhuRoomIconMissing,
        selected: selected,
        loading: loading,
        onTap: loading
            ? null
            : () async {
                final open = !selected;
                final success = await toolsNotifier.setLobbyMode(
                  type,
                  open: open,
                );
                if (!context.mounted) return;
                _showRoomMoreSnack(
                  context,
                  context.l10n.t(
                    success
                        ? open
                              ? 'room.more.lobbyOpenSuccess'
                              : 'room.more.lobbyCloseSuccess'
                        : 'room.more.lobbyFailed',
                  ),
                );
              },
      );
    }).toList();
  }

  List<_RoomMoreToolItem> _partyTools(BuildContext context) {
    return [
      _RoomMoreToolItem(
        label: context.l10n.t('room.more.pk'),
        asset: AppAssets.lanhuRoomMorePk,
        assetIncludesTile: true,
        onTap: () => _showRoomMoreSnack(
          context,
          context.l10n.t('room.more.actionPending'),
        ),
      ),
      _RoomMoreToolItem(
        label: context.l10n.t('room.more.luckyBox'),
        asset: AppAssets.lanhuRoomMoreLuckyBox,
        assetIncludesTile: true,
        onTap: () => _showRoomMoreSnack(
          context,
          context.l10n.t('room.more.actionPending'),
        ),
      ),
    ];
  }

  List<_RoomMoreToolItem> _bannerTools(List<RoomToolBanner> banners) {
    return banners.map((banner) {
      return _RoomMoreToolItem(
        label: banner.displayName,
        imageUrl: banner.iconUrl,
        tags: banner.tagList,
        onTap: () => onOpenBanner(banner),
      );
    }).toList();
  }
}

class _RoomMoreSection extends StatelessWidget {
  const _RoomMoreSection({required this.title, required this.items});

  final String title;
  final List<_RoomMoreToolItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.roomMoreSectionTopGap.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: AppSpacing.roomMoreSectionTitleBottom.h,
            ),
            child: Text(
              title,
              style: AppTextStyles.roomMoreSectionTitle.copyWith(
                fontSize: 16.sp,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: AppSpacing.roomMoreGridMainGap.h,
              crossAxisSpacing: AppSpacing.roomMoreGridCrossGap.w,
              mainAxisExtent: AppSpacing.roomMoreToolTileHeight.h,
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
          Text(
            title,
            style: AppTextStyles.roomMoreSectionTitle.copyWith(fontSize: 16.sp),
          ),
          SizedBox(
            height: AppSpacing.roomMoreLoadingHeight.h,
            child: Row(
              children: [
                SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10.w),
                Text(
                  context.l10n.t('room.more.loading'),
                  style: AppTextStyles.roomMoreHint.copyWith(fontSize: 12.sp),
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
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.roomMoreHint.copyWith(fontSize: 12.sp),
            ),
          ),
          SizedBox(width: 8.w),
          InkWell(
            onTap: onRetry,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              child: Text(
                context.l10n.t('app.retry'),
                style: AppTextStyles.roomMoreHint.copyWith(
                  color: _roomGold,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
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
      opacity: enabled ? 1 : 0.62,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md.r),
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
                style: AppTextStyles.roomMoreTool.copyWith(fontSize: 11.sp),
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
                  : AppColors.roomMoreTile,
              borderRadius: BorderRadius.circular(AppRadius.roomMoreToolTile.r),
              border: item.selected
                  ? Border.all(color: _roomPink.withValues(alpha: 0.65))
                  : null,
            ),
            child: Center(child: _RoomMoreIcon(item: item)),
          ),
          if (item.tags.isNotEmpty) _RoomMoreToolTag(label: item.tags.first),
          if (item.loading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(
                    AppRadius.roomMoreToolTile.r,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
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
      top: -3.h,
      right: -4.w,
      child: Container(
        height: 14.h,
        constraints: BoxConstraints(minWidth: 28.w),
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.roomMoreTag.r),
        ),
        alignment: Alignment.center,
        child: Text(
          normalized,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.roomMoreTag.copyWith(fontSize: 8.sp),
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

String _roomModeAsset(RoomLobbyToolType type) {
  // The API exposes six mode values while the Lanhu sheet has five visuals;
  // reuse the closest visual without changing the server-side mode values.
  switch (type) {
    case RoomLobbyToolType.gameDefault:
      return AppAssets.lanhuRoomMoreModeGame;
    case RoomLobbyToolType.gameMining:
      return AppAssets.lanhuRoomMoreModeParty;
    case RoomLobbyToolType.gameSquare:
      return AppAssets.lanhuRoomMoreModeGame;
    case RoomLobbyToolType.gameGrandPrize:
      return AppAssets.lanhuRoomMoreModeWin;
    case RoomLobbyToolType.gameMenu:
      return AppAssets.lanhuRoomMoreModeKtv;
    case RoomLobbyToolType.mapSocial:
      return AppAssets.lanhuRoomMoreModeChat;
  }
}

String _roomMoreRoomId(RoomPageState state) {
  final currentRoomId = state.currentRoomId.trim();
  if (currentRoomId.isNotEmpty) return currentRoomId;
  return state.roomId.trim();
}

void _showRoomMoreSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
