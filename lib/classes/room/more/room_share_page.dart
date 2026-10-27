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
    ref.listen(provider.select((state) => state.error), (_, error) {
      if (error != null && context.mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(error)));
      }
    });
    useEffect(() => vm.close, [vm]);
    final tabs = [
      if (!state.materialsLoaded || state.materials.isNotEmpty)
        RoomShareTab.share,
      RoomShareTab.recent,
      RoomShareTab.friends,
    ];
    final controller = useTabController(
      initialLength: tabs.length,
      initialIndex: tabs.indexOf(state.tab).clamp(0, tabs.length - 1),
      keys: [tabs.length],
    );
    useEffect(() {
      void changed() {
        final tab = tabs[controller.index];
        if (tab != vm.state.tab) vm.selectTab(tab);
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
                      borderRadius: AppRadius.sheetBorder,
                      clipBehavior: Clip.antiAlias,
                      child: SafeArea(
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
                                      isScrollable: true,
                                      tabAlignment: TabAlignment.start,
                                      dividerColor: AppColors.transparent,
                                      labelStyle: AppTextStyles.bodyStrongSmall,
                                      unselectedLabelStyle:
                                          AppTextStyles.caption,
                                      labelColor: AppColors.textPrimary,
                                      unselectedLabelColor:
                                          AppColors.textSecondary,
                                      tabs: tabs
                                          .map(
                                            (tab) => Tab(
                                              text: switch (tab) {
                                                RoomShareTab.share => toolText(
                                                  context,
                                                  'Share',
                                                  '分享',
                                                ),
                                                RoomShareTab.recent => toolText(
                                                  context,
                                                  'Recent chats',
                                                  '最近会话',
                                                ),
                                                RoomShareTab.friends =>
                                                  toolText(
                                                    context,
                                                    'Friends',
                                                    '好友',
                                                  ),
                                              },
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                  Tooltip(
                                    message: toolText(context, 'Close', '关闭'),
                                    child: TextButton(
                                      key: const ValueKey('room-share-close'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Image.asset(
                                        AppAssets.lanhuCloseCircle,
                                        width: AppSpacing.iconSizeMd,
                                        height: AppSpacing.iconSizeMd,
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
                                            (tab) =>
                                                _tab(context, vm, state, tab),
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
          if (state.materialsError != null)
            Flexible(
              child: SingleChildScrollView(
                child: TextButton(
                  onPressed: state.materialsLoading ? null : vm.loadMaterials,
                  child: Text(
                    state.materialsError!,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
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
    return Column(
      children: [
        if (state.materialsLoaded && state.materials.isEmpty)
          TextButton(
            onPressed: state.materialsLoading ? null : vm.loadMaterials,
            child: Text(
              state.materialsError ??
                  toolText(context, 'Retry share materials', '重新获取分享素材'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ),
        Expanded(
          child: RoomShareContacts(
            contacts: recent ? state.recent : state.friends,
            query: state.query,
            onSearch: vm.search,
            enabled: state.isActive && !state.busy,
            loading: recent ? state.recentLoading : state.friendsLoading,
            error: recent ? state.recentError : state.friendsError,
            onRetry: recent ? vm.loadRecent : () => vm.loadFriends(reset: true),
            onLoadMore: !recent && state.hasMore ? vm.loadFriends : null,
            onInvite: (user) => _invite(context, vm, user),
          ),
        ),
      ],
    );
  }

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
