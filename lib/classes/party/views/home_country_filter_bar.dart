part of '../party_page.dart';

class _CountryFilterBar extends StatelessWidget {
  const _CountryFilterBar({
    required this.tabController,
    required this.tabs,
    required this.onSelect,
  });

  final TabController tabController;
  final List<_CountryFilterTab> tabs;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                final selectedIndex = tabController.index;
                return ExtendedTabBar(
                  controller: tabController,
                  isScrollable: true,
                  padding: const EdgeInsets.only(left: 12),
                  labelPadding: const EdgeInsets.only(right: 8),
                  indicator: const BoxDecoration(color: AppColors.transparent),
                  indicatorColor: AppColors.transparent,
                  dividerColor: AppColors.transparent,
                  overlayColor: WidgetStateProperty.all(AppColors.transparent),
                  splashFactory: NoSplash.splashFactory,
                  onTap: (index) {
                    if (index < 0 || index >= tabs.length) return;
                    onSelect(tabs[index].countryCode);
                  },
                  tabs: [
                    for (var index = 0; index < tabs.length; index++)
                      Tab(
                        height: 32,
                        child: _CountryFilterTabView(
                          item: tabs[index],
                          selected: index == selectedIndex,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _FilterChipButton(onTap: () {}),
          ),
        ],
      ),
    );
  }
}

List<_CountryFilterTab> _buildCountryFilterTabs(List<CountryInfo> countries) {
  return <_CountryFilterTab>[
    const _CountryFilterTab.hot(),
    for (final country in countries.take(5)) _CountryFilterTab.country(country),
  ];
}

int _countryFilterSelectedIndex(
  List<_CountryFilterTab> tabs,
  String? selectedCountryCode,
) {
  final code = selectedCountryCode?.toUpperCase();
  if (code == null) return 0;
  final index = tabs.indexWhere((tab) => tab.countryCode == code);
  return index < 0 ? 0 : index;
}

class _CountryFilterTab {
  const _CountryFilterTab.hot() : country = null;
  const _CountryFilterTab.country(this.country);

  final CountryInfo? country;

  bool get isHot => country == null;

  String? get countryCode => _normalizeHomeCountryCode(country?.isoCode);
}

class _CountryFilterTabView extends StatelessWidget {
  const _CountryFilterTabView({required this.item, required this.selected});

  final _CountryFilterTab item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (item.isHot) {
      return _HotCountryChip(selected: selected);
    }
    return _CountryChip(country: item.country!, selected: selected);
  }
}

class _HotCountryChip extends StatelessWidget {
  const _HotCountryChip({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? null : const Color(0xFFF0F0F0),
        gradient: selected ? AppGradients.sendButton : null,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppAssets.lanhuHomeHotIcon, width: 16, height: 16),
          const SizedBox(width: 4),
          Text(
            context.l10n.t('home.hot'),
            style: TextStyle(
              color: selected ? AppColors.textInverse : AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({required this.country, required this.selected});

  final CountryInfo country;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? null : const Color(0xFFF0F0F0),
        gradient: selected ? AppGradients.sendButton : null,
        borderRadius: AppRadius.pillBorder,
      ),
      child: CountryFlag.fromCountryCode(
        country.isoCode,
        theme: ImageTheme(width: 24, height: 16, shape: RoundedRectangle(3)),
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
