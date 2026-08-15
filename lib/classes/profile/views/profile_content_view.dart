import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../mine/profile_menu_item.dart';
import '../mine/profile_models.dart';
import '../mine/profile_state.dart';

class ProfileContentView extends StatelessWidget {
  const ProfileContentView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onEditProfile,
    required this.onBadgeAction,
    required this.onMenuAction,
  });

  final ProfileState state;
  final Future<void> Function() onRefresh;
  final VoidCallback onEditProfile;
  final ValueChanged<ProfileBadgeItem> onBadgeAction;
  final ValueChanged<ProfileMenuItem> onMenuAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFBFC), AppColors.pageBackground],
          stops: [0, 0.48],
        ),
      ),
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: onRefresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: SafeArea(
                      bottom: true,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 375),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: Column(
                              children: [
                                const SizedBox(height: 27),
                                _ProfileHeader(
                                  state: state,
                                  onEditProfile: onEditProfile,
                                ),
                                if (state.loadError != null)
                                  _ProfileLoadError(onRetry: onRefresh),
                                const SizedBox(height: 26),
                                _ProfileMetrics(items: state.metricItems),
                                const SizedBox(height: 18),
                                const _ProfileMembershipCards(),
                                const SizedBox(height: 16),
                                _ProfileShortcutCard(
                                  items: state.quickItems,
                                  onMenuAction: onMenuAction,
                                ),
                                const SizedBox(height: 8),
                                _ProfileBadgeCard(
                                  items: state.badgeItems,
                                  onBadgeAction: onBadgeAction,
                                ),
                                const SizedBox(height: 17),
                                _ProfileMenuCard(
                                  items: state.featureItems,
                                  onMenuAction: onMenuAction,
                                ),
                                // const SizedBox(height: 8),
                                _ProfileMenuCard(
                                  items: state.legalItems,
                                  onMenuAction: onMenuAction,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (state.isSubmitting)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0x33000000),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.state, required this.onEditProfile});

  final ProfileState state;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 341,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileAvatar(url: state.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          state.displayName(context.l10n.t('profile.nickname')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _GenderTag(gender: state.gender),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    state.displayUserId(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0x99000000),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _ProfileTinyTag(
                        text: state.displayRegion(
                          context.l10n.t('profile.notSet'),
                        ),
                      ),
                      _ProfileTinyTag(text: context.l10n.t('profile.vip')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: onEditProfile,
            icon: Image.asset(
              AppAssets.profileEditIcon,
              width: 16,
              height: 16,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.avatarPlaceholder,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? Image.asset(AppAssets.profileAvatar, fit: BoxFit.cover)
          : CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Image.asset(AppAssets.profileAvatar, fit: BoxFit.cover),
              errorWidget: (_, __, ___) =>
                  Image.asset(AppAssets.profileAvatar, fit: BoxFit.cover),
            ),
    );
  }
}

class _GenderTag extends StatelessWidget {
  const _GenderTag({required this.gender});

  final int gender;

  @override
  Widget build(BuildContext context) {
    final String asset = gender == 2
        ? AppAssets.profileFemaleIcon
        : AppAssets.profileMaleIcon;
    final List<Color> colors = gender == 2
        ? const [Color(0xFFFF9BC2), Color(0xFFFF5C9D)]
        : const [Color(0xFF8ECEFF), Color(0xFF4A9FFF)];

    return Container(
      width: 32,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(asset, width: 12, height: 12, fit: BoxFit.contain),
    );
  }
}

class _ProfileTinyTag extends StatelessWidget {
  const _ProfileTinyTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      constraints: const BoxConstraints(minWidth: 45),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF747474),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F5),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.t('profile.loadFailed'),
                style: const TextStyle(
                  color: AppColors.primaryPinkDeep,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(context.l10n.t('app.retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetrics extends StatelessWidget {
  const _ProfileMetrics({required this.items});

  final List<ProfileMetricItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 275,
      height: 45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.t(item.titleKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileMembershipCards extends StatelessWidget {
  const _ProfileMembershipCards();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 349,
      height: 68,
      child: Row(
        children: const [
          Expanded(
            child: _ProfileImageCard(asset: AppAssets.lanhuProfileVipCard),
          ),
          SizedBox(width: 5),
          Expanded(
            child: _ProfileImageCard(asset: AppAssets.lanhuProfileNobleCard),
          ),
        ],
      ),
    );
  }
}

class _ProfileImageCard extends StatelessWidget {
  const _ProfileImageCard({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.asset(asset, fit: BoxFit.cover),
    );
  }
}

class _ProfileShortcutCard extends StatelessWidget {
  const _ProfileShortcutCard({required this.items, required this.onMenuAction});

  final List<ProfileMenuItem> items;
  final ValueChanged<ProfileMenuItem> onMenuAction;

  @override
  Widget build(BuildContext context) {
    return _ProfileWhiteCard(
      width: 351,
      height: 95,
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _ProfileShortcutItem(
                item: item,
                onTap: () => onMenuAction(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileShortcutItem extends StatelessWidget {
  const _ProfileShortcutItem({required this.item, required this.onTap});

  final ProfileMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.iconAsset != null)
            Image.asset(
              item.iconAsset!,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            )
          else
            const SizedBox(width: 40, height: 40),
          const SizedBox(height: 7),
          Text(
            context.l10n.t(item.titleKey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadgeCard extends StatelessWidget {
  const _ProfileBadgeCard({required this.items, required this.onBadgeAction});

  final List<ProfileBadgeItem> items;
  final ValueChanged<ProfileBadgeItem> onBadgeAction;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(8).toList(growable: false);

    return _ProfileWhiteCard(
      width: 351,
      height: 196,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / 5;

            return Wrap(
              alignment: WrapAlignment.start,
              runSpacing: 18,
              children: [
                for (final item in visibleItems)
                  SizedBox(
                    width: itemWidth,
                    child: Center(
                      child: _ProfileBadgeItemView(
                        item: item,
                        onTap: () => onBadgeAction(item),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileBadgeItemView extends StatelessWidget {
  const _ProfileBadgeItemView({required this.item, required this.onTap});

  final ProfileBadgeItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: SizedBox(
        width: 54,
        child: Column(
          children: [
            Image.asset(
              item.iconAsset,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.t(item.titleKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF747474),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.items, required this.onMenuAction});

  final List<ProfileMenuItem> items;
  final ValueChanged<ProfileMenuItem> onMenuAction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 351,
        color: AppColors.cardBackground,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _ProfileMenuRow(
                item: items[index],
                onTap: () => onMenuAction(items[index]),
              ),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.item, required this.onTap});

  final ProfileMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = item.iconAsset;
    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Row(
            children: [
              const SizedBox(width: 18),
              if (icon == null)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.missingAsset,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                )
              else
                Image.asset(icon, width: 28, height: 28, fit: BoxFit.contain),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.l10n.t(item.titleKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFB2B2B2),
                size: 18,
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileWhiteCard extends StatelessWidget {
  const _ProfileWhiteCard({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
