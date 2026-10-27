import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/room_share_models.dart';
import '../../../theme/app_theme.dart';
import 'room_share_contacts.dart';
import 'room_share_material_view.dart';
import 'room_share_view_model.dart';
import 'room_tools_widgets.dart';

Future<void> showRoomShareSheet(BuildContext context, String roomId) async {
  final router = GoRouter.maybeOf(context);
  ModalRoute<dynamic>? sheetRoute;
  final user = await showModalBottomSheet<RoomShareContact>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.modalScrimStrong,
    builder: (context) {
      sheetRoute = ModalRoute.of(context);
      return RoomSharePage(roomId: roomId);
    },
  );
  await sheetRoute?.completed;
  if (user == null || !context.mounted || router == null) return;
  router.push(
    Uri(
      path: '/chat-view',
      queryParameters: {'targetUID': '${user.uid}', 'title': user.nickname},
    ).toString(),
  );
}

/// Room sharing is a root sheet, not a route that replaces the room page.
class RoomSharePage extends HookConsumerWidget {
  const RoomSharePage({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (
      roomId: roomId,
      language: Localizations.localeOf(context).languageCode,
    );
    final provider = roomShareViewModelProvider(key);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final messenger = useMemoized(GlobalKey<ScaffoldMessengerState>.new);
    ref.listen(provider.select((state) => state.error), (_, error) {
      if (error != null && context.mounted) {
        messenger.currentState?.showSnackBar(SnackBar(content: Text(error)));
      }
    });
    useEffect(() => vm.close, [vm]);
    const tabs = [
      RoomShareTab.share,
      RoomShareTab.recent,
      RoomShareTab.friends,
    ];
    final controller = useTabController(
      initialLength: tabs.length,
      initialIndex: tabs.indexOf(state.tab).clamp(0, tabs.length - 1),
    );
    useEffect(() {
      void changed() {
        final tab = tabs[controller.index];
        vm.selectTab(tab);
      }

      controller.addListener(changed);
      return () => controller.removeListener(changed);
    }, [controller]);
    final showPoster =
        state.tab == RoomShareTab.share && state.materials.isNotEmpty;
    final media = MediaQuery.of(context);
    return PopScope<RoomShareContact>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) vm.close();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight =
                constraints.maxHeight * AppSpacing.roomShareMaxHeightRatio;
            final panelHeight = math.min(
              showPoster
                  ? AppSpacing.roomSharePanelHeight
                  : AppSpacing.roomShareContactsHeight,
              math.max(
                    0.0,
                    maxHeight -
                        AppSpacing.roomShareHeaderHeight -
                        media.padding.bottom,
                  ) *
                  (showPoster ? AppSpacing.roomSharePanelMaxRatio : 1),
            );
            return SizedBox(
              key: const ValueKey('room-share-sheet'),
              height: showPoster
                  ? maxHeight
                  : math.min(
                      maxHeight,
                      panelHeight +
                          AppSpacing.roomShareHeaderHeight +
                          media.padding.bottom,
                    ),
              child: Column(
                children: [
                  if (showPoster)
                    Expanded(
                      child: RoomSharePoster(
                        materials: state.materials,
                        index: state.materialIndex,
                        enabled: state.isActive && !state.busy,
                        onChanged: vm.selectMaterial,
                      ),
                    ),
                  Flexible(
                    flex: showPoster ? 0 : 1,
                    child: Material(
                      color: AppColors.cardBackground,
                      borderRadius: AppRadius.roomShareSheetBorder,
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height:
                            panelHeight +
                            AppSpacing.roomShareHeaderHeight +
                            media.padding.bottom,
                        child: ScaffoldMessenger(
                          key: messenger,
                          child: Scaffold(
                            backgroundColor: AppColors.cardBackground,
                            resizeToAvoidBottomInset: false,
                            body: SafeArea(
                              top: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: AppSpacing.roomShareHeaderHeight,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TabBar(
                                            controller: controller,
                                            tabAlignment: TabAlignment.fill,
                                            labelPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: AppSpacing.xs,
                                                ),
                                            dividerColor: AppColors.transparent,
                                            indicator: const BoxDecoration(),
                                            labelStyle: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.merge(
                                                  AppTextStyles.bodyStrongSmall,
                                                ),
                                            unselectedLabelStyle:
                                                Theme.of(
                                                  context,
                                                ).textTheme.labelMedium?.merge(
                                                  AppTextStyles.caption,
                                                ),
                                            labelColor: AppColors.textPrimary,
                                            unselectedLabelColor:
                                                AppColors.textSecondary,
                                            tabs: tabs
                                                .map(
                                                  (tab) => Tab(
                                                    child: Text(
                                                      switch (tab) {
                                                        RoomShareTab.share =>
                                                          toolText(
                                                            context,
                                                            'Share',
                                                            '分享',
                                                          ),
                                                        RoomShareTab.recent =>
                                                          toolText(
                                                            context,
                                                            'Recent Chats',
                                                            '最近会话',
                                                          ),
                                                        RoomShareTab.friends =>
                                                          toolText(
                                                            context,
                                                            'Friends',
                                                            '好友',
                                                          ),
                                                      },
                                                      maxLines: 2,
                                                      textAlign:
                                                          TextAlign.center,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                        Tooltip(
                                          message: toolText(
                                            context,
                                            'Close',
                                            '关闭',
                                          ),
                                          child: SizedBox.square(
                                            dimension:
                                                AppSpacing.controlHeightMd,
                                            child: TextButton(
                                              key: const ValueKey(
                                                'room-share-close',
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: Image.asset(
                                                AppAssets.roomShareCollapse,
                                                width: AppSpacing.iconSizeSm,
                                                height: AppSpacing.iconSizeSm,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: panelHeight,
                                    child: state.isActive
                                        ? TabBarView(
                                            controller: controller,
                                            children: tabs
                                                .map(
                                                  (tab) => _tab(
                                                    context,
                                                    vm,
                                                    state,
                                                    tab,
                                                  ),
                                                )
                                                .toList(),
                                          )
                                        : Center(
                                            child: Text(
                                              toolText(
                                                context,
                                                'This room is no longer available',
                                                '当前房间已失效',
                                              ),
                                              style: AppTextStyles.bodySmall,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    RoomShareViewModel vm,
    RoomShareState state,
    RoomShareTab tab,
  ) {
    if (tab == RoomShareTab.share) {
      return Column(
        children: [
          if (state.materialsLoading) const LinearProgressIndicator(),
          if (state.materialsError != null ||
              !state.materialsLoading && state.materials.isEmpty)
            Flexible(
              fit: FlexFit.tight,
              child: _materialsStatus(
                context,
                state.materialsError ??
                    toolText(context, 'No share materials available', '暂无分享素材'),
                state.materialsLoading ? null : vm.loadMaterials,
              ),
            ),
          if (state.materials.isNotEmpty)
            Expanded(
              child: RoomShareActions(
                material: state.materials[state.materialIndex],
                content: state.preview,
                enabled:
                    state.isActive &&
                    !state.busy &&
                    state.preview != null &&
                    !state.materialsLoading,
                busy: state.busy,
                onShare: (action, buttonContext) =>
                    _share(buttonContext, vm, action),
              ),
            ),
        ],
      );
    }
    final recent = tab == RoomShareTab.recent;
    return RoomShareContacts(
      contacts: recent ? state.recent : state.friends,
      query: state.query,
      onSearch: vm.search,
      enabled: state.isActive && !state.busy,
      loading: recent ? state.recentLoading : state.friendsLoading,
      error: recent ? state.recentError : state.friendsError,
      onRetry: recent ? vm.loadRecent : () => vm.loadFriends(reset: true),
      onLoadMore: !recent && state.hasMore ? vm.loadFriends : null,
      onInvite: (user) => _invite(context, vm, user),
    );
  }

  Widget _materialsStatus(
    BuildContext context,
    String message,
    VoidCallback? onRetry,
  ) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            key: const ValueKey('room-share-materials-message'),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            key: const ValueKey('room-share-materials-retry'),
            onPressed: onRetry,
            child: Text(
              toolText(context, 'Retry', '重试'),
              style: AppTextStyles.bodyStrongSmall,
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _share(
    BuildContext context,
    RoomShareViewModel vm,
    RoomShareAction action,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = (box.localToGlobal(Offset.zero) & box.size).intersect(
      Offset.zero & MediaQuery.sizeOf(context),
    );
    final result = await vm.share(action, origin: origin);
    if (context.mounted && result == RoomShareOutcome.copied) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(toolText(context, 'Link copied', '链接已复制'))),
      );
    }
  }

  Future<void> _invite(
    BuildContext context,
    RoomShareViewModel vm,
    RoomShareContact user,
  ) async {
    final confirmed = await confirmRoomTool(
      context,
      toolText(context, 'Invite to room', '邀请进入房间'),
      '${user.nickname}\n${vm.roomCard()['title'] ?? roomId}',
    );
    if (!confirmed || !context.mounted) return;
    if (await vm.invite(user.uid) && context.mounted) {
      Navigator.of(context).pop(user);
    }
  }
}
