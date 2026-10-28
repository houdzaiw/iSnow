part of '../room_page.dart';

class _RoomMoreToolsSheet extends HookConsumerWidget {
  const _RoomMoreToolsSheet({
    required this.onOpenMusic,
    required this.roomProvider,
    required this.onOpenBanner,
    required this.onOpenTool,
  });

  final AutoDisposeStateNotifierProvider<RoomViewModel, RoomPageState>
  roomProvider;
  final void Function(RoomToolBanner, bool) onOpenBanner;
  final VoidCallback onOpenMusic;
  final ValueChanged<String> onOpenTool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final roomId = _roomMoreRoomId(roomState);
    final toolsProvider = roomMoreToolsViewModelProvider(roomId);
    final toolsState = ref.watch(toolsProvider);
    final toolsNotifier = ref.read(toolsProvider.notifier);
    final featureState = ref.watch(roomToolsControllerProvider(roomId));
    final features = ref.read(roomToolsControllerProvider(roomId).notifier);
    final tabs = useTabController(initialLength: 2);
    final basicScroll = useScrollController();
    final settingsScroll = useScrollController();
    final effectsKey = useMemoized(() => GlobalKey(), [roomId]);
    final currencyKey = useMemoized(() => GlobalKey(), [roomId]);

    void showSetting(String action) {
      tabs.animateTo(1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || tabs.index != 1) return;
        final target =
            (action == 'currency' ? currencyKey : effectsKey).currentContext;
        final render = target?.findRenderObject();
        if (target == null || render == null) return;
        Scrollable.of(
          target,
        ).position.ensureVisible(render, duration: kThemeAnimationDuration);
      });
    }

    final sections = <Widget>[
      _RoomMoreSection(
        items: _basicTools(context, ref, roomState, toolsState, showSetting),
      ),
      if (roomState.isOwnerOrManager)
        _RoomMoreSection(
          title: context.l10n.t('room.more.roomMode'),
          items: [
            for (final type in featureState.config.moreModes)
              _RoomMoreToolItem(
                label: type == 0
                    ? toolText(context, 'Chat', '聊天')
                    : type == 1
                    ? 'Win'
                    : toolText(context, 'Treasure', '宝藏大厅'),
                asset: type == 0
                    ? AppAssets.lanhuRoomMoreModeChat
                    : type == 1
                    ? AppAssets.lanhuRoomMoreModeWin
                    : AppAssets.lanhuRoomMoreModeParty,
                assetIncludesTile: true,
                selected: featureState.lobbyType == type,
                loading: featureState.busy.contains('mode'),
                onTap: featureState.busy.contains('mode')
                    ? null
                    : () async {
                        final success = await features.selectMode(type);
                        if (!context.mounted) return;
                        if (success &&
                            type != 0 &&
                            features.snapshot.lobbyType == type) {
                          onOpenTool('lobby');
                        } else if (!success) {
                          _showRoomMoreSnack(
                            context,
                            features.snapshot.error ??
                                context.l10n.t('room.more.lobbyFailed'),
                          );
                        }
                      },
              ),
          ],
        ),
      if (roomState.isOwnerOrManager || features.canSendLucky)
        _RoomMoreSection(
          title: context.l10n.t('room.more.party'),
          items: _partyTools(
            context,
            roomState.isOwnerOrManager,
            features.canSendLucky,
          ),
        ),
      if (toolsState.loadingBanners && toolsState.gameBanners.isEmpty)
        _RoomMoreLoadingSection(title: context.l10n.t('room.more.game')),
      if (toolsState.gameBanners.isNotEmpty)
        _RoomMoreSection(
          title: context.l10n.t('room.more.game'),
          items: _bannerTools(toolsState.gameBanners, game: true),
        ),
      if (toolsState.errorMessage != null)
        _RoomMoreErrorRow(
          message: context.l10n.t('room.more.bannerLoadFailed'),
          onRetry: toolsNotifier.loadBanners,
        ),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: double.infinity,
            height: AppSpacing.roomToolsSheetHeight.h.clamp(
              0,
              constraints.maxHeight,
            ),
            child: Material(
              key: const ValueKey('room-more-tools-sheet'),
              color: AppColors.roomToolsSheet,
              borderRadius: AppRadius.roomToolsSheetBorder,
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: AppSpacing.roomToolsTabsWidth.w,
                        height: AppSpacing.roomToolsTabHeight.h,
                        child: ExtendedTabBar(
                          key: const ValueKey('room-more-tabs'),
                          controller: tabs,
                          labelStyle: AppTextStyles.roomToolsTabSelected,
                          unselectedLabelStyle: AppTextStyles.roomToolsTab,
                          labelColor: AppColors.roomToolsText,
                          unselectedLabelColor: AppColors.roomToolsTextInactive,
                          labelPadding: EdgeInsets.zero,
                          dividerColor: AppColors.transparent,
                          overlayColor: const WidgetStatePropertyAll(
                            AppColors.transparent,
                          ),
                          splashFactory: NoSplash.splashFactory,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              color: AppColors.primaryPink,
                              width: AppSpacing.roomToolsTabIndicatorHeight.h,
                            ),
                            insets: EdgeInsets.symmetric(
                              horizontal:
                                  (AppSpacing.roomToolsTabsWidth -
                                          AppSpacing
                                                  .roomToolsTabIndicatorWidth *
                                              2)
                                      .w /
                                  4,
                            ),
                          ),
                          tabs: [
                            for (final label in [
                              'room.more.basicTools',
                              'room.more.setting',
                            ])
                              Tab(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    context.l10n.t(label),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ExtendedTabBarView(
                        key: const ValueKey('room-more-tab-view'),
                        controller: tabs,
                        cacheExtent: 1,
                        children: [
                          SingleChildScrollView(
                            key: const PageStorageKey('room-more-basic-scroll'),
                            controller: basicScroll,
                            padding: EdgeInsets.all(
                              AppSpacing.roomMoreSheetHorizontalInset.w,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sections,
                            ),
                          ),
                          SingleChildScrollView(
                            key: const PageStorageKey(
                              'room-more-settings-scroll',
                            ),
                            controller: settingsScroll,
                            padding: EdgeInsets.all(
                              AppSpacing.roomToolsContentInset.w,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (roomState.isOwnerOrManager) ...[
                                  Text(
                                    key: currencyKey,
                                    toolText(context, 'Charm Setting', '魅力值设置'),
                                    style: AppTextStyles.roomToolsHeading,
                                  ),
                                  SizedBox(height: AppSpacing.sm.h),
                                  RoomCharmCurrencyContent(roomId: roomId),
                                  SizedBox(
                                    height: AppSpacing.roomSettingsSectionGap.h,
                                  ),
                                ],
                                Text(
                                  key: effectsKey,
                                  toolText(context, 'Effects Setting', '特效设置'),
                                  style: AppTextStyles.roomToolsHeading,
                                ),
                                SizedBox(height: AppSpacing.sm.h),
                                RoomEffectSettingsContent(roomId: roomId),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<_RoomMoreToolItem> _basicTools(
    BuildContext context,
    WidgetRef ref,
    RoomPageState roomState,
    RoomMoreToolsState toolsState,
    ValueChanged<String> showSetting,
  ) {
    final features = ref.read(
      roomToolsControllerProvider(_roomMoreRoomId(roomState)).notifier,
    );
    final featureState = features.snapshot;
    return [
      _RoomMoreToolItem(
        label: context.l10n.t('room.more.share'),
        asset: AppAssets.lanhuRoomMoreShare,
        assetIncludesTile: true,
        onTap: () => onOpenTool('share'),
      ),
      _RoomMoreToolItem(
        label: context.l10n.t('room.more.report'),
        asset: AppAssets.lanhuRoomMoreReport,
        assetIncludesTile: true,
        onTap: () => onOpenTool('report'),
      ),
      if (roomState.isOwnerOrManager)
        _RoomMoreToolItem(
          label: context.l10n.t('room.more.music'),
          asset: AppAssets.lanhuRoomMoreMusic,
          assetIncludesTile: true,
          onTap: onOpenMusic,
        ),
      if (roomState.isOwnerOrManager)
        _RoomMoreToolItem(
          label: context.l10n.t('room.more.charmCounter'),
          asset: featureState.charmEnabled
              ? AppAssets.lanhuRoomMoreCharmCounter
              : AppAssets.lanhuRoomMoreCharmCounterMuted,
          assetIncludesTile: true,
          toggled: features.charmStatusReady ? featureState.charmEnabled : null,
          loading: features.charmStatusBusy,
          onTap: features.charmStatusBusy
              ? null
              : () async {
                  final route = ModalRoute.of(context);
                  final generation = features.room.roomGeneration;
                  final success = await features.toggleCharmCounter();
                  if (!context.mounted ||
                      !(route?.isCurrent ?? false) ||
                      route?.animation?.status == AnimationStatus.reverse ||
                      !features.canManage ||
                      features.room.roomGeneration != generation ||
                      success) {
                    return;
                  }
                  _showRoomMoreSnack(
                    context,
                    features.snapshot.error ??
                        toolText(
                          context,
                          'Unable to change charm counter',
                          '魅力值计数切换失败',
                        ),
                  );
                },
        ),
      _RoomMoreToolItem(
        label: context.l10n.t('room.more.voice'),
        asset: roomState.agoraState.mutedSpeaker
            ? AppAssets.lanhuRoomMoreVoiceMuted
            : AppAssets.lanhuRoomMoreVoice,
        assetIncludesTile: true,
        selected: !roomState.agoraState.mutedSpeaker,
        onTap: () async {
          final success = await ref
              .read(
                roomToolsControllerProvider(
                  _roomMoreRoomId(roomState),
                ).notifier,
              )
              .toggleVoice();
          if (!context.mounted) return;
          if (!success) {
            _showRoomMoreSnack(
              context,
              ref
                      .read(
                        roomToolsControllerProvider(_roomMoreRoomId(roomState)),
                      )
                      .error ??
                  context.l10n.t('room.more.lobbyFailed'),
            );
            return;
          }
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
        onTap: () => showSetting('effects'),
      ),
      if (roomState.isOwnerOrManager)
        _RoomMoreToolItem(
          label: context.l10n.t('room.more.charmSet'),
          asset: AppAssets.lanhuRoomMoreCharmSetting,
          assetIncludesTile: true,
          onTap: () => showSetting('currency'),
        ),
      ..._bannerTools(toolsState.additionalTools),
    ];
  }

  List<_RoomMoreToolItem> _partyTools(
    BuildContext context,
    bool manager,
    bool lucky,
  ) {
    return [
      if (manager)
        _RoomMoreToolItem(
          label: context.l10n.t('room.more.pk'),
          asset: AppAssets.lanhuRoomMorePk,
          assetIncludesTile: true,
          onTap: () => onOpenTool('pk'),
        ),
      if (lucky)
        _RoomMoreToolItem(
          label: context.l10n.t('room.more.luckyBox'),
          asset: AppAssets.lanhuRoomMoreLuckyBox,
          assetIncludesTile: true,
          onTap: () => onOpenTool('lucky'),
        ),
    ];
  }

  List<_RoomMoreToolItem> _bannerTools(
    List<RoomToolBanner> banners, {
    bool game = false,
  }) {
    return banners.map((banner) {
      return _RoomMoreToolItem(
        label: banner.displayName,
        imageUrl: banner.iconUrl,
        tags: banner.tagList,
        onTap: () => onOpenBanner(banner, game),
      );
    }).toList();
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
