import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../model/home_history_room.dart';
import '../viewmodel/home_list_view_model.dart';
import 'friends_activity_view_model.dart';
import 'friends_activity_widgets.dart';
import 'home_activity_navigation.dart';

class FriendsActivityPage extends HookConsumerWidget {
  const FriendsActivityPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = useTabController(initialLength: 2);
    final visitedHistory = useState(false);
    final friends = ref.watch(friendsActivityProvider);
    final history = visitedHistory.value
        ? ref.watch(homeRoomHistoryProvider)
        : const HomeListState<HomeHistoryRoom>();
    final ownRoomId = ref.watch(homeOwnRoomIdProvider).valueOrNull;
    final opening = ref.watch(homeRoomOpeningProvider);
    listenHomeSessionRoute(context, ref);
    useEffect(() {
      void changed() {
        if (tabs.index == 1) visitedHistory.value = true;
      }

      tabs.addListener(changed);
      Future.microtask(() {
        if (context.mounted) {
          ref.read(friendsActivityProvider.notifier).refresh();
        }
      });
      return () => tabs.removeListener(changed);
    }, [tabs]);
    return Scaffold(
      backgroundColor: HomeActivityTheme.background,
      appBar: AppBar(
        backgroundColor: HomeActivityTheme.surface,
        foregroundColor: HomeActivityTheme.ink,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.l10n.t('home.friendRooms'),
          style: HomeActivityTheme.title,
        ),
        leading: Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: HomeActivityIcon(
                AppAssets.roomPartyHistoryBack,
                size: HomeActivityTheme.back.r,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ExtendedTabBar(
              controller: tabs,
              labelColor: HomeActivityTheme.ink,
              unselectedLabelColor: HomeActivityTheme.muted,
              labelStyle: HomeActivityTheme.tab,
              dividerColor: AppColors.transparent,
              indicatorColor: HomeActivityTheme.pink,
              indicatorWeight: HomeActivityTheme.indicator,
              tabs: [
                for (final key in [
                  'home.friendsPlaying',
                  'home.recentFootprints',
                ])
                  Tab(
                    height: HomeActivityTheme.tabHeight.h,
                    text: context.l10n.t(key),
                  ),
              ],
            ),
            Expanded(
              child: ExtendedTabBarView(
                controller: tabs,
                children: [
                  _ActivityList(
                    key: const PageStorageKey('friends-playing'),
                    state: friends,
                    onRefresh: () =>
                        ref.read(friendsActivityProvider.notifier).refresh(),
                    emptyText: context.l10n.t('home.noFriendsPlaying'),
                    itemBuilder: (context, index) {
                      final item = friends.items[index];
                      return _RoomActivityCard(
                        title: item.title,
                        avatar: item.avatar,
                        subtitle:
                            item.roomId == ownRoomId &&
                                item.roomDesc?.isNotEmpty == true
                            ? item.roomDesc
                            : context.l10n.t(item.relationKey),
                        partying: item.inMicNum > 0,
                        onTap: opening
                            ? null
                            : () => openHomeActivityRoom(
                                context,
                                ref,
                                item.roomId,
                                item.uid,
                              ),
                      );
                    },
                  ),
                  visitedHistory.value
                      ? _ActivityList(
                          key: const PageStorageKey('recent-footprints'),
                          state: history,
                          onRefresh: () => ref
                              .read(homeRoomHistoryProvider.notifier)
                              .refresh(),
                          onMore: () => ref
                              .read(homeRoomHistoryProvider.notifier)
                              .loadMore(),
                          emptyText: context.l10n.t('home.noFootprints'),
                          itemBuilder: (context, index) {
                            final item = history.items[index];
                            return _RoomActivityCard(
                              title: item.title,
                              avatar: item.cover,
                              partying: item.inMicNum > 0,
                              onTap: opening
                                  ? null
                                  : () => openHomeActivityRoom(
                                      context,
                                      ref,
                                      item.roomId,
                                      item.uid,
                                    ),
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityList<T> extends StatelessWidget {
  const _ActivityList({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.emptyText,
    required this.itemBuilder,
    this.onMore,
  });
  final HomeListState<T> state;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onMore;
  final String emptyText;
  final IndexedWidgetBuilder itemBuilder;
  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.depth == 0 &&
              n.metrics.extentAfter < HomeActivityTheme.pagingThreshold &&
              state.hasMore &&
              state.error == null) {
            onMore?.call();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: HomeActivityTheme.pink,
          child: ListView.builder(
            key: key,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(HomeActivityTheme.pagePadding.r),
            itemCount: state.items.length + 1,
            itemBuilder: (context, index) {
              if (index < state.items.length) {
                return itemBuilder(context, index);
              }
              if (state.loading || state.loadingMore) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.error != null) {
                return HomeActivityNotice(
                  text: state.error!,
                  error: true,
                  retry:
                      state.errorPage != 1 &&
                          state.items.isNotEmpty &&
                          onMore != null
                      ? onMore
                      : onRefresh,
                );
              }
              return state.items.isEmpty
                  ? HomeActivityNotice(text: emptyText)
                  : const SizedBox.shrink();
            },
          ),
        ),
      );
}

class _RoomActivityCard extends StatelessWidget {
  const _RoomActivityCard({
    required this.title,
    required this.avatar,
    required this.partying,
    this.subtitle,
    this.onTap,
  });
  final String title;
  final String? avatar, subtitle;
  final bool partying;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: HomeActivityTheme.gap.h),
    child: Material(
      color: HomeActivityTheme.surface,
      borderRadius: HomeActivityTheme.radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: HomeActivityTheme.radius,
        child: Padding(
          padding: EdgeInsets.all(HomeActivityTheme.mediumGap.r),
          child: Row(
            children: [
              HomeActivityPicture(avatar),
              SizedBox(width: HomeActivityTheme.mediumGap.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeActivityTheme.roomTitle,
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: HomeActivityTheme.smallGap.h),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: HomeActivityTheme.secondary,
                      ),
                    ],
                  ],
                ),
              ),
              if (partying) ...[
                SizedBox(width: HomeActivityTheme.gap.w),
                HomeActivityIcon(
                  AppAssets.lanhuHomeBadgeVoice,
                  size: HomeActivityTheme.badge.r,
                ),
                SizedBox(width: HomeActivityTheme.smallGap.w),
                Text(
                  context.l10n.t('home.partying'),
                  style: HomeActivityTheme.status,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
