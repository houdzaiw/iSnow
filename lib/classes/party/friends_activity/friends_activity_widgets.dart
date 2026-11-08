import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../model/home_friend_room.dart';
import 'friends_activity_view_model.dart';
import 'home_activity_navigation.dart';

class HomeActivityIcon extends StatelessWidget {
  const HomeActivityIcon(
    this.asset, {
    super.key,
    this.size,
    this.width,
    this.height,
  });
  final String asset;
  final double? size, width, height;
  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: width ?? size ?? HomeActivityTheme.icon.r,
    height: height ?? size ?? HomeActivityTheme.icon.r,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    errorBuilder: (_, __, ___) => Image.asset(
      AppAssets.iconMissing,
      color: AppColors.missingAsset,
      width: size ?? HomeActivityTheme.icon.r,
      height: size ?? HomeActivityTheme.icon.r,
    ),
  );
}

class HomeActivityPicture extends StatelessWidget {
  const HomeActivityPicture(this.url, {super.key, this.size});
  final String? url;
  final double? size;
  @override
  Widget build(BuildContext context) {
    Widget missing() => Center(
      child: Image.asset(
        AppAssets.iconMissing,
        color: AppColors.missingAsset,
        width: HomeActivityTheme.icon.r,
        height: HomeActivityTheme.icon.r,
      ),
    );
    final source = url?.trim() ?? '';
    final uri = Uri.tryParse(source);
    return SizedBox.square(
      dimension: size ?? HomeActivityTheme.avatar.r,
      child: ClipOval(
        child: source.startsWith('assets/')
            ? Image.asset(
                source,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => missing(),
              )
            : uri != null &&
                  {'http', 'https'}.contains(uri.scheme) &&
                  uri.host.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: source,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: HomeActivityTheme.field),
                errorWidget: (_, __, ___) => missing(),
              )
            : missing(),
      ),
    );
  }
}

String? homeFriendBadgeAsset(HomeFriendRoom item) => switch (item.badge) {
  HomeFriendBadge.hall => AppAssets.friendsActivityHall,
  HomeFriendBadge.mining => AppAssets.lanhuHomeBadgeMining,
  HomeFriendBadge.voice => AppAssets.lanhuHomeBadgeVoice,
  HomeFriendBadge.rocket =>
    AppAssets.roomRocketStages[0][(item.rocketSchedule!.level.clamp(1, 6)) - 1],
  null => null,
};

class HomeActivityNotice extends StatelessWidget {
  const HomeActivityNotice({
    super.key,
    required this.text,
    this.retry,
    this.error = false,
  });
  final String text;
  final VoidCallback? retry;
  final bool error;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(HomeActivityTheme.gap.r),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: error ? HomeActivityTheme.error : HomeActivityTheme.secondary,
        ),
        if (retry != null)
          TextButton(
            onPressed: retry,
            child: Text(
              context.l10n.t('app.retry'),
              style: HomeActivityTheme.status,
            ),
          ),
      ],
    ),
  );
}

class HomeFriendsActivity extends HookConsumerWidget {
  const HomeFriendsActivity({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsActivityProvider);
    final allOpen = useState(false);
    final opening = ref.watch(homeRoomOpeningProvider);
    final friends = state.items.take(12).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: HomeActivityTheme.pagePadding.w,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.t('home.friendsActivity'),
                  style: HomeActivityTheme.title,
                ),
              ),
              Semantics(
                button: true,
                label: context.l10n.t('home.all'),
                child: InkWell(
                  key: const ValueKey('friends-activity-all'),
                  onTap: () async {
                    if (allOpen.value) return;
                    allOpen.value = true;
                    try {
                      await context.pushNamed('friends-activity');
                    } finally {
                      if (context.mounted) allOpen.value = false;
                    }
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: HomeActivityTheme.touch.r,
                    ),
                    child: Row(
                      children: [
                        Text(
                          context.l10n.t('home.all'),
                          style: HomeActivityTheme.body,
                        ),
                        HomeActivityIcon(
                          AppAssets.lanhuCreatePartyChevronRight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state.error != null)
          HomeActivityNotice(
            text: state.error!,
            error: true,
            retry: () => ref.read(friendsActivityProvider.notifier).refresh(),
          ),
        if (friends.isEmpty)
          state.loading
              ? Center(
                  child: SizedBox.square(
                    dimension: HomeActivityTheme.progress.r,
                    child: const CircularProgressIndicator(),
                  ),
                )
              : state.error == null
              ? HomeActivityNotice(
                  text: context.l10n.t('home.noFriendsPlaying'),
                )
              : const SizedBox.shrink()
        else
          SizedBox(
            height: HomeActivityTheme.stripHeight.r,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: HomeActivityTheme.pagePadding.w,
              ),
              itemCount: friends.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: HomeActivityTheme.largeGap.w),
              itemBuilder: (context, i) {
                final item = friends[i];
                final badge = homeFriendBadgeAsset(item);
                return Semantics(
                  button: true,
                  label: item.title,
                  child: InkWell(
                    onTap: opening
                        ? null
                        : () => openHomeActivityRoom(
                            context,
                            ref,
                            item.roomId,
                            item.uid,
                          ),
                    child: SizedBox(
                      width: HomeActivityTheme.homeAvatar.r,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          HomeActivityPicture(
                            item.avatar,
                            size: HomeActivityTheme.homeAvatar.r,
                          ),
                          if (badge != null)
                            PositionedDirectional(
                              end: 0,
                              bottom: 0,
                              child: HomeActivityIcon(
                                badge,
                                size: HomeActivityTheme.badge.r,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
