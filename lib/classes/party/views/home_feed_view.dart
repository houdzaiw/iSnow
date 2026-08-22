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
        onRefreshRooms: () =>
            ref.read(_homeFeedViewModelProvider.notifier).refreshRooms(),
        onSelectCountry: (countryCode) {
          ref
              .read(_homeFeedViewModelProvider.notifier)
              .selectCountry(countryCode);
        },
      ),
    );
  }
}

class _HomeFeedContent extends HookWidget {
  const _HomeFeedContent({
    required this.state,
    required this.onRefreshRooms,
    required this.onSelectCountry,
  });

  final _HomeFeedState state;
  final Future<void> Function() onRefreshRooms;
  final ValueChanged<String?> onSelectCountry;

  @override
  Widget build(BuildContext context) {
    final countryTabs = _buildCountryFilterTabs(state.hotCountries);
    final selectedIndex = _countryFilterSelectedIndex(
      countryTabs,
      state.selectedCountryCode,
    );
    final tabController = useTabController(
      initialLength: countryTabs.length,
      initialIndex: selectedIndex,
      keys: [countryTabs.length],
    );
    final lastSelectedIndex = useRef(selectedIndex);

    useEffect(() {
      if (tabController.index != selectedIndex) {
        lastSelectedIndex.value = selectedIndex;
        tabController.index = selectedIndex;
      }
      return null;
    }, [selectedIndex, countryTabs.length, tabController]);

    useEffect(() {
      void handleTabSettled() {
        if (tabController.indexIsChanging) return;
        if (tabController.offset.abs() > 0.001) return;

        final index = tabController.index;
        if (index < 0 || index >= countryTabs.length) return;
        if (lastSelectedIndex.value == index) return;

        lastSelectedIndex.value = index;
        onSelectCountry(countryTabs[index].countryCode);
      }

      tabController.addListener(handleTabSettled);
      return () => tabController.removeListener(handleTabSettled);
    }, [tabController, countryTabs, onSelectCountry]);

    return Column(
      children: [
        const SizedBox(height: 6),
        _HomeBanner(banners: state.banners),
        const SizedBox(height: 16),
        _FriendsActivityHeader(),
        const SizedBox(height: 10),
        _FriendsPlayingStrip(friends: state.friends),
        const SizedBox(height: 12),
        _CountryFilterBar(
          tabController: tabController,
          tabs: countryTabs,
          onSelect: (countryCode) {
            lastSelectedIndex.value = _countryFilterSelectedIndex(
              countryTabs,
              countryCode,
            );
            onSelectCountry(countryCode);
          },
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _HomeFeedListView(
            tabController: tabController,
            tabs: countryTabs,
            rooms: state.rooms,
            onRefresh: onRefreshRooms,
          ),
        ),
      ],
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
          Image.asset(
            AppAssets.lanhuCreatePartyChevronRight,
            width: AppSpacing.iconSizeXs,
            height: AppSpacing.iconSizeSm,
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

String _friendBadgeAsset(int type, int index) {
  final normalized = type == 0 ? index : type;
  return switch (normalized % 4) {
    0 => AppAssets.lanhuHomeBadgeBigWin,
    1 => AppAssets.lanhuHomeBadgeVoice,
    2 => AppAssets.lanhuHomeBadgeMining,
    _ => AppAssets.lanhuHomeBadgePk,
  };
}
