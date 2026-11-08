part of '../party_page.dart';

class HomeFeedView extends ConsumerWidget {
  const HomeFeedView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _HomeFeedContent(
    state: ref.watch(homeFeedProvider),
    onSelectCountry: ref.read(homeFeedProvider.notifier).selectCountry,
  );
}

class _HomeFeedContent extends HookWidget {
  const _HomeFeedContent({required this.state, required this.onSelectCountry});
  final HomeFeedState state;
  final ValueChanged<String?> onSelectCountry;
  @override
  Widget build(BuildContext context) {
    final countryTabs = _buildCountryFilterTabs(state.countries);
    final selectedIndex = _countryFilterSelectedIndex(
      countryTabs,
      state.selectedCountryCode,
    );
    final tabsKey = countryTabs.map((t) => t.countryCode ?? 'hot').join('|');
    final tabController = useTabController(
      initialLength: countryTabs.length,
      initialIndex: selectedIndex,
      keys: [tabsKey],
    );
    final lastSelected = useRef(selectedIndex);
    final moreOpen = useState(false);
    useEffect(() {
      lastSelected.value = selectedIndex;
      if (tabController.index != selectedIndex) {
        tabController.index = selectedIndex;
      }
      return null;
    }, [selectedIndex, tabsKey, tabController]);
    useEffect(() {
      void settled() {
        if (tabController.indexIsChanging ||
            tabController.offset.abs() > .001) {
          return;
        }
        final index = tabController.index;
        if (index == lastSelected.value) return;
        lastSelected.value = index;
        onSelectCountry(countryTabs[index].countryCode);
      }

      tabController.addListener(settled);
      return () => tabController.removeListener(settled);
    }, [tabController, tabsKey, onSelectCountry]);
    return Column(
      children: [
        SizedBox(height: HomeActivityTheme.gap.h),
        _HomeBanner(banners: state.banners),
        SizedBox(height: HomeActivityTheme.sectionGap.h),
        const HomeFriendsActivity(),
        SizedBox(height: HomeActivityTheme.mediumGap.h),
        _CountryFilterBar(
          tabController: tabController,
          tabs: countryTabs,
          onSelect: (code) {
            lastSelected.value = _countryFilterSelectedIndex(countryTabs, code);
            onSelectCountry(code);
          },
          onMore: () async {
            if (moreOpen.value) return;
            moreOpen.value = true;
            try {
              await showHomeCountriesSheet(context);
            } finally {
              if (context.mounted) moreOpen.value = false;
            }
          },
        ),
        SizedBox(height: HomeActivityTheme.mediumGap.h),
        Expanded(
          child: _HomeFeedListView(
            tabController: tabController,
            tabs: countryTabs,
          ),
        ),
      ],
    );
  }
}

class _HomeBanner extends StatelessWidget {
  const _HomeBanner({required this.banners});

  final List<HomeBannerItem> banners;

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
