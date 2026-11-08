part of '../party_page.dart';

class _CountryFilterBar extends StatelessWidget {
  const _CountryFilterBar({
    required this.tabController,
    required this.tabs,
    required this.onSelect,
    required this.onMore,
  });
  final TabController tabController;
  final List<_CountryFilterTab> tabs;
  final ValueChanged<String?> onSelect;
  final VoidCallback onMore;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: HomeActivityTheme.countryTabHeight.h,
    child: Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: tabController,
            builder: (context, _) => ExtendedTabBar(
              controller: tabController,
              isScrollable: true,
              padding: EdgeInsets.only(left: HomeActivityTheme.mediumGap.w),
              labelPadding: EdgeInsets.only(right: HomeActivityTheme.gap.w),
              indicator: const BoxDecoration(color: AppColors.transparent),
              indicatorColor: AppColors.transparent,
              dividerColor: AppColors.transparent,
              overlayColor: WidgetStateProperty.all(AppColors.transparent),
              splashFactory: NoSplash.splashFactory,
              onTap: (index) => onSelect(tabs[index].countryCode),
              tabs: [
                for (int i = 0; i < tabs.length; i++)
                  Tab(
                    height: HomeActivityTheme.countryTabHeight.h,
                    child: _CountryFilterTabView(
                      item: tabs[i],
                      selected: i == tabController.index,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: HomeActivityTheme.mediumGap.w),
          child: Semantics(
            button: true,
            label: context.l10n.t('home.countries'),
            child: InkWell(
              key: const ValueKey('home-more-countries'),
              onTap: onMore,
              child: SizedBox(
                width: HomeActivityTheme.moreWidth.w,
                height: HomeActivityTheme.countryChipHeight.h,
                child: Center(
                  child: HomeActivityIcon(
                    AppAssets.lanhuHomeFilterIcon,
                    width: HomeActivityTheme.icon.w,
                    height: HomeActivityTheme.flagHeight.h,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

List<_CountryFilterTab> _buildCountryFilterTabs(List<CountryInfo> countries) =>
    [
      const _CountryFilterTab.hot(),
      for (final c in countries) _CountryFilterTab.country(c),
    ];
int _countryFilterSelectedIndex(List<_CountryFilterTab> tabs, String? code) {
  final index = tabs.indexWhere(
    (t) => t.countryCode == normalizeHomeCountryCode(code),
  );
  return index < 0 ? 0 : index;
}

class _CountryFilterTab {
  const _CountryFilterTab.hot() : country = null;
  const _CountryFilterTab.country(this.country);
  final CountryInfo? country;
  String? get countryCode => normalizeHomeCountryCode(country?.isoCode);
}

class _CountryFilterTabView extends StatelessWidget {
  const _CountryFilterTabView({required this.item, required this.selected});
  final _CountryFilterTab item;
  final bool selected;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    label: item.country == null
        ? context.l10n.t('home.hot')
        : countryDisplayName(context, item.country!),
    child: Container(
      key: ValueKey('home-country-${item.countryCode ?? 'hot'}'),
      width:
          (item.country == null
                  ? HomeActivityTheme.hotChipWidth
                  : HomeActivityTheme.countryChipWidth)
              .w,
      height: HomeActivityTheme.countryChipHeight.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? null : HomeActivityTheme.field,
        gradient: selected ? AppGradients.sendButton : null,
        borderRadius: HomeActivityTheme.pill,
      ),
      child: item.country != null
          ? HomeCountryFlag(country: item.country!)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HomeActivityIcon(
                  AppAssets.lanhuHomeHotIcon,
                  size: HomeActivityTheme.flagHeight.r,
                ),
                SizedBox(width: HomeActivityTheme.smallGap.w),
                Text(
                  context.l10n.t('home.hot'),
                  style: HomeActivityTheme.hotLabel(selected),
                ),
              ],
            ),
    ),
  );
}
