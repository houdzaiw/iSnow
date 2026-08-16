import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../profile_homepage_models.dart';
import '../profile_homepage_state.dart';

class ProfileHomepageContentView extends StatelessWidget {
  const ProfileHomepageContentView({
    super.key,
    required this.state,
    required this.onRefresh,
  });

  final ProfileHomepageState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final info = state.info;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(context.l10n.t('profile.homepage')),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: Builder(
          builder: (context) {
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

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
              children: [
                _HomepageHeader(info: info),
                const SizedBox(height: 12),
                _MetricCard(info: info),
                const SizedBox(height: 12),
                _AboutCard(info: info),
                const SizedBox(height: 12),
                _PhotoCard(photos: info.photos),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomepageHeader extends StatelessWidget {
  const _HomepageHeader({required this.info});

  final ProfileHomepageInfo info;

  @override
  Widget build(BuildContext context) {
    final user = info.user;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1F5), Color(0xFFFFFBDE)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(url: user.avatar, size: 86),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName(
                                context.l10n.t('profile.nickname'),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _GenderTag(gender: user.gender),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            user.displayUserId(),
                            style: const TextStyle(
                              color: Color(0x99000000),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          _CountryFlag(region: user.displayRegion('')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _LevelTags(user: user),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _displayBio(context, user),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xCC000000),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.info});

  final ProfileHomepageInfo info;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        value: _formatCompactCount(info.followingNum),
        title: context.l10n.t('profile.following'),
      ),
      _MetricData(
        value: _formatCompactCount(info.followerNum),
        title: context.l10n.t('profile.followers'),
      ),
      _MetricData(
        value: _formatCompactCount(info.visitorNum),
        title: context.l10n.t('profile.visitors'),
      ),
      _MetricData(
        value: _formatCompactCount(info.receiveGiftValue),
        title: context.l10n.t('profile.giftValue'),
      ),
    ];

    return _WhiteCard(
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                children: [
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
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

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.info});

  final ProfileHomepageInfo info;

  @override
  Widget build(BuildContext context) {
    final user = info.user;
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(text: context.l10n.t('profile.about')),
          const SizedBox(height: 14),
          _InfoRow(
            label: context.l10n.t('profile.countryRegion'),
            value: user.displayRegion(context.l10n.t('profile.notSet')),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: context.l10n.t('profile.bio'),
            value: _displayBio(context, user),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.photos});

  final List<ProfileHomepagePhoto> photos;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(text: context.l10n.t('profile.album')),
          const SizedBox(height: 14),
          if (photos.isEmpty)
            SizedBox(
              height: 82,
              child: Center(
                child: Text(
                  context.l10n.t('profile.noPhotos'),
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length > 6 ? 6 : photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: photos[index].url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: AppColors.avatarPlaceholder),
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: AppColors.avatarPlaceholder),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, this.url});

  final double size;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = url;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
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

class _GenderTag extends StatelessWidget {
  const _GenderTag({required this.gender});

  final int gender;

  @override
  Widget build(BuildContext context) {
    final asset = gender == 2
        ? AppAssets.profileFemaleIcon
        : AppAssets.profileMaleIcon;
    final colors = gender == 2
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

class _CountryFlag extends StatelessWidget {
  const _CountryFlag({required this.region});

  final String region;

  @override
  Widget build(BuildContext context) {
    final countryCode = _normalizeCountryCode(region);
    if (countryCode == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: CountryFlag.fromCountryCode(
        countryCode,
        theme: ImageTheme(width: 18, height: 18, shape: const Circle()),
      ),
    );
  }
}

class _LevelTags extends StatelessWidget {
  const _LevelTags({required this.user});

  final ProfileHomepageUser user;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _LevelTag(
          text: user.wealthLevel == 0 ? '0' : user.wealthLevel.toString(),
          gradient: const LinearGradient(
            colors: [Color(0xFFEF0070), Color(0xFF5400FF)],
          ),
        ),
        _LevelTag(
          text: user.charmLevel == 0 ? '0' : user.charmLevel.toString(),
          color: const Color(0xFF7387FF),
        ),
        _LevelTag(
          text: user.vipLevel == 0 ? '0' : user.vipLevel.toString(),
          color: const Color(0xFFFF7CD8),
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
          fontWeight: FontWeight.w600,
          height: 1,
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.32),
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
    );
  }
}

class _MetricData {
  const _MetricData({required this.value, required this.title});

  final String value;
  final String title;
}

String _displayBio(BuildContext context, ProfileHomepageUser user) {
  final bio = user.userDesc?.trim();
  if (bio == null || bio.isEmpty) return context.l10n.t('profile.bioEmpty');
  return bio;
}

String _formatCompactCount(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

String? _normalizeCountryCode(String value) {
  final code = value.trim().toUpperCase();
  if (code.length != 2) return null;
  return RegExp(r'^[A-Z]{2}$').hasMatch(code) ? code : null;
}
