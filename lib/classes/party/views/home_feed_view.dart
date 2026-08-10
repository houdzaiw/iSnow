part of '../party_page.dart';

class _HomeFeedView extends ConsumerWidget {
  const _HomeFeedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_homeFeedViewModelProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        debugPrint('[HomeFeed] page failed: $error\n$stackTrace');
        return _StateList(
          text: context.l10n.t('home.feedLoadFailed'),
          actionLabel: context.l10n.t('app.retry'),
          onAction: () =>
              ref.read(_homeFeedViewModelProvider.notifier).reload(),
        );
      },
      data: (state) => _HomeFeedContent(
        state: state,
        onRefresh: () =>
            ref.read(_homeFeedViewModelProvider.notifier).refreshFeed(),
        onSelectCountry: (countryCode) {
          ref
              .read(_homeFeedViewModelProvider.notifier)
              .selectCountry(countryCode);
        },
      ),
    );
  }
}

class _HomeFeedContent extends StatelessWidget {
  const _HomeFeedContent({
    required this.state,
    required this.onRefresh,
    required this.onSelectCountry,
  });

  final _HomeFeedState state;
  final Future<void> Function() onRefresh;
  final ValueChanged<String?> onSelectCountry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryPink,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          const SizedBox(height: 6),
          _HomeBanner(banners: state.banners),
          const SizedBox(height: 16),
          _FriendsActivityHeader(),
          const SizedBox(height: 10),
          _FriendsPlayingStrip(friends: state.friends),
          const SizedBox(height: 12),
          _CountryFilterBar(
            countries: state.hotCountries,
            selectedCountryCode: state.selectedCountryCode,
            onSelect: onSelectCountry,
          ),
          const SizedBox(height: 14),
          _HomeRoomGrid(rooms: state.rooms),
        ],
      ),
    );
  }
}

class _HomeBanner extends StatelessWidget {
  const _HomeBanner({required this.banners});

  final List<_HomeBannerItem> banners;

  @override
  Widget build(BuildContext context) {
    final visibleBanners = banners
        .where((banner) => banner.imageUrl != null)
        .toList(growable: false);
    if (visibleBanners.isEmpty) {
      return const _HomeBannerFallback();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 106,
          child: Swiper(
            itemCount: visibleBanners.length,
            autoplay: visibleBanners.length > 1,
            autoplayDelay: 4000,
            duration: 320,
            loop: visibleBanners.length > 1,
            itemBuilder: (context, index) {
              return _PartyImage(
                url: visibleBanners[index].imageUrl,
                assetName: AppAssets.lanhuHomeRoomBanner,
                width: double.infinity,
                height: 106,
              );
            },
            pagination: visibleBanners.length > 1
                ? SwiperPagination(
                    alignment: Alignment.bottomCenter,
                    margin: const EdgeInsets.only(bottom: 8),
                    builder: DotSwiperPaginationBuilder(
                      color: Colors.white.withValues(alpha: 0.48),
                      activeColor: Colors.white.withValues(alpha: 0.96),
                      size: 5,
                      activeSize: 14,
                      space: 4,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _HomeBannerFallback extends StatelessWidget {
  const _HomeBannerFallback();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          AppAssets.lanhuHomeRoomBanner,
          width: double.infinity,
          height: 106,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _FriendsActivityHeader extends StatelessWidget {
  const _FriendsActivityHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.t('home.friendsActivity'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            context.l10n.t('home.all'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _FriendsPlayingStrip extends StatelessWidget {
  const _FriendsPlayingStrip({required this.friends});

  final List<_HomeFriendItem> friends;

  @override
  Widget build(BuildContext context) {
    final visibleFriends = friends.isEmpty
        ? List.generate(5, _HomeFriendItem.placeholder)
        : friends.take(12).toList();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: visibleFriends.length,
        separatorBuilder: (_, __) => const SizedBox(width: 28),
        itemBuilder: (context, index) {
          return _FriendAvatar(item: visibleFriends[index], index: index);
        },
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.item, required this.index});

  final _HomeFriendItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: _PartyImage(
              url: item.avatar,
              assetName: AppAssets.lanhuPartyAvatar,
              width: 60,
              height: 60,
            ),
          ),
          Positioned(
            right: -2,
            bottom: 0,
            child: Image.asset(
              _friendBadgeAsset(item.type, index),
              width: 22,
              height: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryFilterBar extends StatelessWidget {
  const _CountryFilterBar({
    required this.countries,
    required this.selectedCountryCode,
    required this.onSelect,
  });

  final List<CountryInfo> countries;
  final String? selectedCountryCode;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final visibleCountries = countries.take(5).toList();
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _HotCountryChip(
            selected: selectedCountryCode == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          for (final country in visibleCountries) ...[
            _CountryChip(
              country: country,
              selected: selectedCountryCode == country.isoCode.toUpperCase(),
              onTap: () => onSelect(country.isoCode.toUpperCase()),
            ),
            const SizedBox(width: 8),
          ],
          _FilterChipButton(onTap: () {}),
        ],
      ),
    );
  }
}

class _HotCountryChip extends StatelessWidget {
  const _HotCountryChip({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: AppGradients.sendButton,
          borderRadius: AppRadius.pillBorder,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.lanhuHomeHotIcon, width: 16, height: 16),
            const SizedBox(width: 4),
            Text(
              context.l10n.t('home.hot'),
              style: const TextStyle(
                color: AppColors.textInverse,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final CountryInfo country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: AppRadius.pillBorder,
          border: selected
              ? Border.all(color: AppColors.primaryPink, width: 1.5)
              : null,
        ),
        child: CountryFlag.fromCountryCode(
          country.isoCode,
          theme: ImageTheme(width: 24, height: 16, shape: RoundedRectangle(3)),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 28,
        child: Center(
          child: Image.asset(
            AppAssets.lanhuHomeFilterIcon,
            width: 20,
            height: 16,
          ),
        ),
      ),
    );
  }
}

class _HomeRoomGrid extends StatelessWidget {
  const _HomeRoomGrid({required this.rooms});

  final List<_HomeRoomItem> rooms;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: _StateList(text: context.l10n.t('home.roomsEmpty')),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: rooms.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 8,
        childAspectRatio: 175 / 188,
      ),
      itemBuilder: (context, index) {
        return _HomeRoomCard(room: rooms[index]);
      },
    );
  }
}

class _HomeRoomCard extends StatelessWidget {
  const _HomeRoomCard({required this.room});

  final _HomeRoomItem room;

  @override
  Widget build(BuildContext context) {
    final tagType = room.tagType;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: _PartyImage(
              url: room.cover,
              assetName: AppAssets.lanhuHomeRoomBanner,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          const Positioned.fill(child: _RoomCardGradient()),
          if (tagType != null)
            Positioned(
              top: 12,
              right: 8,
              child: _RoomTag(
                label: _homeRoomTagLabel(tagType),
                assetName: _homeRoomTagAsset(tagType),
              ),
            ),
          Positioned(
            left: 13,
            bottom: 45,
            child: _RoomCountryBadge(countryCode: room.countryCode),
          ),
          Positioned(
            right: 10,
            bottom: 45,
            child: _RoomOnlineBadge(text: room.onlineText),
          ),
          Positioned(
            left: 13,
            right: 8,
            bottom: 18,
            child: _RoomTitle(title: room.title),
          ),
        ],
      ),
    );
  }
}

class _RoomCardGradient extends StatelessWidget {
  const _RoomCardGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(0, 0, 0, 0),
            Color.fromRGBO(0, 0, 0, 0.08),
            Color.fromRGBO(0, 0, 0, 0.56),
          ],
          stops: [0, 0.58, 1],
        ),
      ),
    );
  }
}

class _RoomTag extends StatelessWidget {
  const _RoomTag({required this.label, required this.assetName});

  final String label;
  final String assetName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        gradient: AppGradients.sendButton,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetName, width: 22, height: 17),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textInverse,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCountryBadge extends StatelessWidget {
  const _RoomCountryBadge({required this.countryCode});

  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    final code = countryCode?.toUpperCase();
    return Container(
      width: 31,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      clipBehavior: Clip.antiAlias,
      child: code == null || code.isEmpty
          ? const DecoratedBox(
              decoration: BoxDecoration(color: AppColors.avatarPlaceholder),
            )
          : CountryFlag.fromCountryCode(
              code,
              theme: ImageTheme(
                width: 31,
                height: 18,
                shape: RoundedRectangle(4),
              ),
            ),
    );
  }
}

class _RoomOnlineBadge extends StatelessWidget {
  const _RoomOnlineBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _HomeAudioBars(),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textInverse,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HomeAudioBars extends StatelessWidget {
  const _HomeAudioBars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _HomeAudioBar(height: 8),
          _HomeAudioBar(height: 14),
          _HomeAudioBar(height: 10),
        ],
      ),
    );
  }
}

class _HomeAudioBar extends StatelessWidget {
  const _HomeAudioBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BorderRadius.circular(
        2,
      ).toBoxDecoration(color: const Color(0xFFE13BFF)),
    );
  }
}

class _RoomTitle extends StatelessWidget {
  const _RoomTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.isEmpty
        ? context.l10n.t('party.untitled')
        : title;
    return Row(
      children: [
        const Icon(Icons.local_florist, color: Color(0xFFFF79A7), size: 16),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textInverse,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

String _friendBadgeAsset(int type, int index) {
  final normalized = type == 0 ? index : type;
  return switch (normalized % 4) {
    0 => AppAssets.lanhuHomeBadgeBigWin,
    1 => AppAssets.lanhuHomeBadgeVoice,
    2 => AppAssets.lanhuHomeBadgeMining,
    _ => AppAssets.lanhuHomeBadgePk,
  };
}

String _homeRoomTagLabel(_HomeRoomTagType type) {
  return switch (type) {
    _HomeRoomTagType.pk => 'PK',
    _HomeRoomTagType.lucky => 'Lucky',
    _HomeRoomTagType.bigWin => 'Big Win',
  };
}

String _homeRoomTagAsset(_HomeRoomTagType type) {
  return switch (type) {
    _HomeRoomTagType.pk => AppAssets.lanhuHomeBadgePk,
    _HomeRoomTagType.lucky => AppAssets.lanhuHomeBadgeMining,
    _HomeRoomTagType.bigWin => AppAssets.lanhuHomeBadgeBigWin,
  };
}
