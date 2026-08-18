part of '../rank_page.dart';

extension _RankCategoryAssets on _RankCategory {
  String get backgroundAsset {
    return switch (this) {
      _RankCategory.wealth => AppAssets.lanhuRankWealthBackground,
      _RankCategory.charm => AppAssets.lanhuRankCharmBackground,
      _RankCategory.room => AppAssets.lanhuRankRoomBackground,
    };
  }

  String get listItemAsset {
    return switch (this) {
      _RankCategory.wealth => AppAssets.lanhuRankWealthListItem,
      _RankCategory.charm => AppAssets.lanhuRankCharmListItem,
      _RankCategory.room => AppAssets.lanhuRankRoomListItem,
    };
  }

  String get meBarAsset {
    return switch (this) {
      _RankCategory.wealth => AppAssets.lanhuRankWealthMeBar,
      _RankCategory.charm => AppAssets.lanhuRankCharmMeBar,
      _RankCategory.room => AppAssets.lanhuRankRoomMeBar,
    };
  }

  String get valueIconAsset {
    return switch (this) {
      _RankCategory.wealth => AppAssets.lanhuRankWealthValueIcon,
      _RankCategory.charm => AppAssets.lanhuRankCharmValueIcon,
      _RankCategory.room => AppAssets.lanhuRankRoomValueIcon,
    };
  }

  double get valueIconSize {
    return switch (this) {
      _RankCategory.wealth => 15,
      _RankCategory.charm => 14,
      _RankCategory.room => 12,
    };
  }
}

class _RankAvatar extends StatelessWidget {
  const _RankAvatar({required this.entry, required this.size});

  final _RankEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatar = entry.avatar;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: entry.uid > 0
          ? () => _openRankProfileHomepage(context, entry)
          : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color.fromRGBO(255, 239, 120, 1),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: avatar == null
            ? const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(254, 229, 190, 1),
                      Color.fromRGBO(99, 75, 51, 1),
                    ],
                  ),
                ),
                child: Icon(Icons.person_rounded, color: Colors.white70),
              )
            : CachedNetworkImage(
                imageUrl: avatar,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.person_rounded, color: Colors.white70),
              ),
      ),
    );
  }
}

class _RankAvatarTapTarget extends StatelessWidget {
  const _RankAvatarTapTarget({required this.entry, required this.size});

  final _RankEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (entry.uid <= 0) return SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _openRankProfileHomepage(context, entry),
      ),
    );
  }
}

void _openRankProfileHomepage(BuildContext context, _RankEntry entry) {
  if (entry.uid <= 0) return;
  context.push('/profile-homepage/${entry.uid}');
}

class _RankBadges extends StatelessWidget {
  const _RankBadges({
    required this.entry,
    required this.category,
    this.compact = false,
  });

  final _RankEntry entry;
  final _RankCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RankCountryBadge(countryCode: entry.country, compact: compact),
        const SizedBox(width: 3),
        _RankLevelBadge(
          level: entry.userLevel?.levelFor(category),
          iconUrl: entry.userLevel?.iconFor(category),
          compact: compact,
        ),
        for (final tagPic in entry.tagPics.take(compact ? 1 : 3)) ...[
          const SizedBox(width: 3),
          _RankRemoteBadge(url: tagPic, compact: compact),
        ],
      ],
    );
  }
}

class _RankCountryBadge extends StatelessWidget {
  const _RankCountryBadge({required this.countryCode, required this.compact});

  final String? countryCode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final code = countryCode?.trim().toUpperCase();
    if (code == null || code.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: compact ? 21 : 28,
      height: compact ? 12 : 16,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(3)),
      child: CountryFlag.fromCountryCode(
        code,
        theme: ImageTheme(
          width: compact ? 21 : 28,
          height: compact ? 12 : 16,
          shape: RoundedRectangle(3),
        ),
      ),
    );
  }
}

class _RankLevelBadge extends StatelessWidget {
  const _RankLevelBadge({
    required this.level,
    required this.iconUrl,
    required this.compact,
  });

  final int? level;
  final String? iconUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 12.0 : 16.0;
    return Container(
      height: height,
      padding: EdgeInsets.only(left: compact ? 3 : 4, right: compact ? 3 : 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromRGBO(239, 0, 112, 1),
            Color.fromRGBO(84, 0, 255, 1),
          ],
        ),
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RankBadgeIcon(
            url: iconUrl,
            size: height,
            fallbackAsset: AppAssets.lanhuRankLevelIcon,
          ),
          const SizedBox(width: 2),
          Text(
            '${level ?? 0}',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 8 : 10,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRemoteBadge extends StatelessWidget {
  const _RankRemoteBadge({required this.url, required this.compact});

  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _RankBadgeIcon(url: url, size: compact ? 12 : 16);
  }
}

class _RankBadgeIcon extends StatelessWidget {
  const _RankBadgeIcon({
    required this.url,
    required this.size,
    this.fallbackAsset,
  });

  final String? url;
  final double size;
  final String? fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl != null && imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final asset = fallbackAsset;
    if (asset == null) return SizedBox(width: size, height: size);
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
  }
}

class _RankValueText extends StatelessWidget {
  const _RankValueText({
    required this.entry,
    required this.category,
    required this.fontSize,
  });

  final _RankEntry entry;
  final _RankCategory category;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final iconSize = category.valueIconSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          category.valueIconAsset,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 3),
        Text(
          entry.valueText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
    );
  }
}
