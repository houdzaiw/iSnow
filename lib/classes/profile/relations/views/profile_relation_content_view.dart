import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../profile_relation_models.dart';
import '../profile_relation_state.dart';

class ProfileRelationContentView extends StatelessWidget {
  const ProfileRelationContentView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onToggleFollow,
    required this.onOpenHomepage,
  });

  final ProfileRelationState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final ValueChanged<ProfileRelationUser> onToggleFollow;
  final ValueChanged<ProfileRelationUser> onOpenHomepage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 245, 247, 1),
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.l10n.t(state.type.titleKey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.066,
          ),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 120) {
            onLoadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: _RelationBody(
            state: state,
            onRefresh: onRefresh,
            onToggleFollow: onToggleFollow,
            onOpenHomepage: onOpenHomepage,
          ),
        ),
      ),
    );
  }
}

class _RelationBody extends StatelessWidget {
  const _RelationBody({
    required this.state,
    required this.onRefresh,
    required this.onToggleFollow,
    required this.onOpenHomepage,
  });

  final ProfileRelationState state;
  final Future<void> Function() onRefresh;
  final ValueChanged<ProfileRelationUser> onToggleFollow;
  final ValueChanged<ProfileRelationUser> onOpenHomepage;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return _StateList(
        text: context.l10n.t('profile.relationsLoadFailed'),
        actionLabel: context.l10n.t('app.retry'),
        onAction: onRefresh,
      );
    }
    if (state.items.isEmpty) {
      return _StateList(text: context.l10n.t('profile.relationsEmpty'));
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(9, 23, 9, 28),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _RelationUserRow(
          user: state.items[index],
          typeShowsFollowButton: state.type.showsFollowButton,
          typeShowsVisitTime: state.type.showsVisitTime,
          onToggleFollow: () => onToggleFollow(state.items[index]),
          onOpenHomepage: () => onOpenHomepage(state.items[index]),
        );
      },
    );
  }
}

class _RelationUserRow extends StatelessWidget {
  const _RelationUserRow({
    required this.user,
    required this.typeShowsFollowButton,
    required this.typeShowsVisitTime,
    required this.onToggleFollow,
    required this.onOpenHomepage,
  });

  final ProfileRelationUser user;
  final bool typeShowsFollowButton;
  final bool typeShowsVisitTime;
  final VoidCallback onToggleFollow;
  final VoidCallback onOpenHomepage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpenHomepage,
                child: Row(
                  children: [
                    _RelationAvatar(url: user.avatar),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.nick.isEmpty
                                  ? context.l10n.t('profile.nickname')
                                  : user.nick,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.066,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _RelationTags(user: user),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (typeShowsFollowButton)
              _FollowButton(user: user, onPressed: onToggleFollow)
            else if (typeShowsVisitTime)
              Padding(
                padding: const EdgeInsets.only(right: 11, top: 23),
                child: Text(
                  _formatDate(user.visitTime),
                  style: const TextStyle(
                    color: Color.fromRGBO(104, 104, 104, 1),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RelationAvatar extends StatelessWidget {
  const _RelationAvatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = url;
    return ClipOval(
      child: Container(
        width: 61,
        height: 61,
        color: AppColors.avatarPlaceholder,
        child: avatarUrl == null
            ? Image.asset(AppAssets.profileAvatar, fit: BoxFit.cover)
            : CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Image.asset(AppAssets.profileAvatar, fit: BoxFit.cover),
                errorWidget: (_, __, ___) =>
                    Image.asset(AppAssets.profileAvatar, fit: BoxFit.cover),
              ),
      ),
    );
  }
}

class _RelationTags extends StatelessWidget {
  const _RelationTags({required this.user});

  final ProfileRelationUser user;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      runSpacing: 4,
      children: [
        _LevelTag(
          text: user.wealthLevel == 0 ? '80' : user.wealthLevel.toString(),
          gradient: const LinearGradient(
            colors: [
              Color.fromRGBO(239, 0, 112, 1),
              Color.fromRGBO(84, 0, 255, 1),
            ],
          ),
        ),
        _LevelTag(
          text: user.charmLevel == 0 ? '10' : user.charmLevel.toString(),
          color: const Color.fromRGBO(115, 135, 255, 1),
        ),
        _LevelTag(
          text: user.vipLevel == 0 ? '20' : user.vipLevel.toString(),
          color: const Color.fromRGBO(255, 124, 216, 1),
        ),
      ],
    );
  }
}

class _LevelTag extends StatelessWidget {
  const _LevelTag({required this.text, this.gradient, this.color});

  final String text;
  final Gradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.user, required this.onPressed});

  final ProfileRelationUser user;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final following = user.isFollowing;
    return Padding(
      padding: const EdgeInsets.only(right: 11, top: 21),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 68,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: following ? const Color.fromRGBO(191, 191, 191, 1) : null,
            gradient: following
                ? null
                : const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Color.fromRGBO(255, 87, 116, 1),
                      Color.fromRGBO(255, 78, 174, 1),
                    ],
                  ),
            borderRadius: BorderRadius.circular(98),
          ),
          child: Text(
            context.l10n.t(
              following ? 'profile.followingStatus' : 'profile.follow',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textInverse,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: 0.066,
            ),
          ),
        ),
      ),
    );
  }
}

class _StateList extends StatelessWidget {
  const _StateList({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        Center(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
        ],
      ],
    );
  }
}

String _formatDate(int? rawTime) {
  if (rawTime == null || rawTime <= 0) return '';
  final milliseconds = rawTime < 10000000000 ? rawTime * 1000 : rawTime;
  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
