import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_flags/country_flags.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../profile_homepage_models.dart';
import '../profile_homepage_state.dart';
import 'profile_homepage_gifts_view.dart';
import 'profile_homepage_honor_view.dart';
import 'profile_homepage_profile_view.dart';

class ProfileHomepageContentView extends StatelessWidget {
  const ProfileHomepageContentView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onFollow,
    required this.onChat,
  });

  final ProfileHomepageState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onFollow;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final info = state.info;
    final appBarScale = MediaQuery.sizeOf(context).width / 375;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: info != null,
        appBar: info == null ? null : _TopBar(scale: appBarScale),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (state.isLoading && info == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null && info == null) {
              return _StateList(
                text: context.l10n.t('profile.homepageLoadFailed'),
                actionLabel: context.l10n.t('app.retry'),
                onAction: onRefresh,
              );
            }
            if (info == null) {
              return _StateList(text: context.l10n.t('profile.homepageEmpty'));
            }

            final width = constraints.maxWidth;
            final scale = width / 375;
            final canvasHeight = math.max(constraints.maxHeight, 958.0 * scale);

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      width: width,
                      height: canvasHeight,
                      child: _LanhuProfileCanvas(info: info, scale: scale),
                    ),
                  ),
                ),
                _BottomActions(
                  scale: scale,
                  isFollowing: info.user.isFollowing,
                  isUpdating: state.isUpdatingFollow,
                  onFollow: onFollow,
                  onChat: onChat,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LanhuProfileCanvas extends StatelessWidget {
  const _LanhuProfileCanvas({required this.info, required this.scale});

  final ProfileHomepageInfo info;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final user = info.user;
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: 291 * scale,
          child: _CoverImage(url: user.backgroundUrl),
        ),
        Positioned(
          left: 0,
          top: 204 * scale,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00FFFBFE), Colors.white],
                stops: [0, 0.092],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: 13 * scale,
          top: 212 * scale,
          width: 104 * scale,
          height: 104 * scale,
          child: _FramedAvatar(url: user.avatar, scale: scale),
        ),
        Positioned(
          left: 26 * scale,
          right: 13 * scale,
          top: 326 * scale,
          child: _IdentityBlock(info: info, scale: scale),
        ),
        Positioned(
          left: 26 * scale,
          right: 13 * scale,
          top: 376 * scale,
          child: _BadgeWall(user: user, scale: scale),
        ),
        Positioned(
          left: 18 * scale,
          right: 17 * scale,
          top: 464 * scale,
          child: _MetricRow(info: info, scale: scale),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 538 * scale,
          bottom: 96 * scale,
          child: _ProfileTabSection(info: info, scale: scale),
        ),
      ],
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null) {
      return Image.asset(
        AppAssets.lanhuProfileHomepageBackground,
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Image.asset(
        AppAssets.lanhuProfileHomepageBackground,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar({required this.scale});

  final double scale;

  static const double _toolbarHeight = 48;

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight * scale);

  @override
  Widget build(BuildContext context) {
    final toolbarHeight = _toolbarHeight * scale;

    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: SizedBox(
        height: toolbarHeight,
        child: Padding(
          padding: EdgeInsets.only(left: 18 * scale, right: 20 * scale),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: Image.asset(
                  AppAssets.backWhiteButton,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: Image.asset(
                  AppAssets.lanhuProfileHomepageRank,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 16 * scale),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: Image.asset(
                  AppAssets.lanhuProfileHomepageEdit,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FramedAvatar extends StatelessWidget {
  const _FramedAvatar({required this.scale, this.url});

  final double scale;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = url;
    if (avatarUrl == null) {
      return Image.asset(
        AppAssets.lanhuProfileHomepageAvatarFrame,
        fit: BoxFit.contain,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 92 * scale,
          height: 92 * scale,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF43D7FF), Color(0xFFB94BFF)],
            ),
          ),
        ),
        ClipOval(
          child: Container(
            width: 68 * scale,
            height: 68 * scale,
            color: AppColors.avatarPlaceholder,
            child: CachedNetworkImage(
              imageUrl: avatarUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Image.asset(AppAssets.profileAvatar, fit: BoxFit.cover),
              errorWidget: (_, __, ___) =>
                  Image.asset(AppAssets.profileAvatar, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({required this.info, required this.scale});

  final ProfileHomepageInfo info;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final user = info.user;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CountryFlag(region: user.displayRegion(''), scale: scale),
                  SizedBox(width: 6 * scale),
                  Flexible(
                    child: Text(
                      user.displayName(context.l10n.t('profile.nickname')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  _GenderIcon(gender: user.gender, scale: scale),
                ],
              ),
              SizedBox(height: 12 * scale),
              Row(
                children: [
                  Text(
                    user.displayUserId(),
                    style: TextStyle(
                      color: const Color(0x99212121),
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  Image.asset(
                    AppAssets.lanhuProfileHomepageCopy,
                    width: 13 * scale,
                    height: 14 * scale,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 8 * scale),
        if (info.isInRoom) _PartyStatus(scale: scale),
      ],
    );
  }
}

class _CountryFlag extends StatelessWidget {
  const _CountryFlag({required this.region, required this.scale});

  final String region;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final code = _normalizeCountryCode(region);
    if (code == null) return SizedBox(width: 0, height: 18 * scale);
    return CountryFlag.fromCountryCode(
      code,
      theme: ImageTheme(width: 22 * scale, height: 16 * scale),
    );
  }
}

class _GenderIcon extends StatelessWidget {
  const _GenderIcon({required this.gender, required this.scale});

  final int gender;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (gender == 2) {
      return Image.asset(
        AppAssets.lanhuProfileHomepageGenderFemale,
        width: 18 * scale,
        height: 18 * scale,
      );
    }
    return Container(
      width: 18 * scale,
      height: 18 * scale,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x334A9FFF),
      ),
      child: Icon(
        Icons.male_rounded,
        size: 14 * scale,
        color: Color(0xFF4A9FFF),
      ),
    );
  }
}

class _PartyStatus extends StatelessWidget {
  const _PartyStatus({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85 * scale,
      height: 22 * scale,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 7 * scale),
      decoration: BoxDecoration(
        gradient: AppGradients.sendButton,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(98 * scale),
          topRight: Radius.circular(0),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(98 * scale),
        ),
      ),
      child: Text(
        'Partying',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12 * scale,
          fontWeight: FontWeight.w400,
          height: 1,
        ),
      ),
    );
  }
}

class _BadgeWall extends StatelessWidget {
  const _BadgeWall({required this.user, required this.scale});

  final ProfileHomepageUser user;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2 * scale,
      runSpacing: 6 * scale,
      children: [
        _LevelTag(
          icon: AppAssets.lanhuProfileHomepageWealth,
          text: _level(user.wealthLevel, fallback: '80'),
          gradient: const LinearGradient(
            colors: [Color(0xFFEF0070), Color(0xFF5400FF)],
          ),
          scale: scale,
        ),
        _LevelTag(
          icon: AppAssets.lanhuProfileHomepageCharm,
          text: _level(user.charmLevel, fallback: '10'),
          color: const Color(0xFF7387FF),
          scale: scale,
        ),
        _VipBadge(
          text: _level(user.vipLevel, fallback: '20'),
          scale: scale,
        ),
        _ImageBadge(
          asset: AppAssets.lanhuProfileBadge01,
          width: 20,
          scale: scale,
        ),
        _ImageBadge(
          asset: AppAssets.lanhuProfileBadge02,
          width: 20,
          scale: scale,
        ),
        _ImageBadge(
          asset: AppAssets.lanhuProfileBadge03,
          width: 20,
          scale: scale,
        ),
        _ImageBadge(
          asset: AppAssets.lanhuProfileBadge04,
          width: 20,
          scale: scale,
        ),
        _ImageBadge(
          asset: AppAssets.lanhuProfileBadge05,
          width: 20,
          scale: scale,
        ),
        _TextBadge(text: 'كريز', width: 115, scale: scale),
        _TextBadge(text: 'مدير', width: 74, scale: scale),
        _TextBadge(text: 'آدمن', width: 59, scale: scale),
        _TextBadge(text: 'Fishing No.1', width: 106, scale: scale),
        _TextBadge(text: 'BIG WIN NO.1', width: 102, scale: scale),
      ],
    );
  }
}

class _LevelTag extends StatelessWidget {
  const _LevelTag({
    required this.icon,
    required this.text,
    required this.scale,
    this.gradient,
    this.color,
  });

  final String icon;
  final String text;
  final double scale;
  final Gradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48 * scale,
      height: 20 * scale,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Row(
        children: [
          SizedBox(width: 4 * scale),
          Image.asset(icon, width: 20 * scale, height: 20 * scale),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VipBadge extends StatelessWidget {
  const _VipBadge({required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26 * scale,
      height: 20 * scale,
      child: Stack(
        children: [
          Image.asset(
            AppAssets.lanhuProfileHomepageVip,
            width: 19 * scale,
            height: 20 * scale,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 7 * scale,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Color(0xFFC30000), blurRadius: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({
    required this.asset,
    required this.width,
    required this.scale,
  });

  final String asset;
  final double width;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width * scale,
      height: 20 * scale,
      fit: BoxFit.contain,
    );
  }
}

class _TextBadge extends StatelessWidget {
  const _TextBadge({
    required this.text,
    required this.width,
    required this.scale,
  });

  final String text;
  final double width;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width * scale,
      height: 20 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFDF55), Color(0xFF6A32FF), Color(0xFFFF7CD8)],
        ),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10 * scale,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.info, required this.scale});

  final ProfileHomepageInfo info;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MetricItem(
          label: context.l10n.t('profile.following'),
          value: _formatCompactCount(info.followingNum),
          scale: scale,
        ),
        _MetricItem(
          label: context.l10n.t('profile.followers'),
          value: _formatCompactCount(info.followerNum),
          scale: scale,
        ),
        _MetricItem(
          label: context.l10n.t('profile.visitors'),
          value: _formatCompactCount(info.visitorNum),
          scale: scale,
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.scale,
  });

  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100 * scale,
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24 * scale,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabSection extends StatefulWidget {
  const _ProfileTabSection({required this.info, required this.scale});

  final ProfileHomepageInfo info;
  final double scale;

  @override
  State<_ProfileTabSection> createState() => _ProfileTabSectionState();
}

class _ProfileTabSectionState extends State<_ProfileTabSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final tabs = [
      context.l10n.t('profile.gifts'),
      '${context.l10n.t('profile.honor')}(${widget.info.honors.length})',
      context.l10n.t('profile.homepage'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20 * scale),
          child: SizedBox(
            width: 220 * scale,
            height: 35 * scale,
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final currentIndex = _tabController.index;

                return ExtendedTabBar(
                  controller: _tabController,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  indicator: const BoxDecoration(color: AppColors.transparent),
                  indicatorColor: AppColors.transparent,
                  dividerColor: AppColors.transparent,
                  labelPadding: EdgeInsets.zero,
                  overlayColor: WidgetStateProperty.all(AppColors.transparent),
                  splashFactory: NoSplash.splashFactory,
                  tabs: [
                    for (var index = 0; index < tabs.length; index++)
                      Tab(
                        height: 35 * scale,
                        child: _ProfileTabLabel(
                          text: tabs[index],
                          selected: index == currentIndex,
                          scale: scale,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        SizedBox(height: 24 * scale),
        Expanded(
          child: ExtendedTabBarView(
            controller: _tabController,
            cacheExtent: 1,
            children: [
              ProfileHomepageGiftsView(info: widget.info, scale: scale),
              ProfileHomepageHonorView(info: widget.info, scale: scale),
              ProfileHomepageProfileView(info: widget.info, scale: scale),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTabLabel extends StatelessWidget {
  const _ProfileTabLabel({
    required this.text,
    required this.selected,
    required this.scale,
  });

  final String text;
  final bool selected;
  final double scale;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35 * scale,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : const Color(0x66212121),
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          if (selected)
            Positioned(
              top: 25 * scale,
              child: Container(
                width: 28 * scale,
                height: 4 * scale,
                decoration: BoxDecoration(
                  gradient: AppGradients.sendButton,
                  borderRadius: BorderRadius.circular(98 * scale),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.scale,
    required this.isFollowing,
    required this.isUpdating,
    required this.onFollow,
    required this.onChat,
  });

  final double scale;
  final bool isFollowing;
  final bool isUpdating;
  final Future<void> Function() onFollow;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 36 * scale,
      right: 36 * scale,
      bottom: MediaQuery.of(context).padding.bottom + 22 * scale,
      child: Row(
        children: [
          Expanded(
            child: _GradientActionButton(
              icon: Icons.favorite_rounded,
              label: context.l10n.t(
                isFollowing ? 'profile.followingStatus' : 'profile.follow',
              ),
              busy: isUpdating,
              onTap: isUpdating ? null : () => onFollow(),
              scale: scale,
            ),
          ),
          SizedBox(width: 19 * scale),
          Expanded(
            child: _GradientActionButton(
              icon: Icons.chat_bubble_rounded,
              label: context.l10n.t('profile.chat'),
              onTap: onChat,
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 42 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppGradients.sendButton,
          borderRadius: BorderRadius.circular(98 * scale),
        ),
        child: busy
            ? SizedBox.square(
                dimension: 18 * scale,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 24 * scale),
                  SizedBox(width: 7 * scale),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
                ],
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
    return RefreshIndicator(
      onRefresh: onAction ?? () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.36),
          Center(
            child: Column(
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCompactCount(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

String _level(int value, {required String fallback}) {
  return value <= 0 ? fallback : '$value';
}

String? _normalizeCountryCode(String value) {
  final code = value.trim().toUpperCase();
  if (code.length != 2) return null;
  return RegExp(r'^[A-Z]{2}$').hasMatch(code) ? code : null;
}
