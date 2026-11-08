import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/country_info.dart';
import '../../../theme/app_theme.dart';
import '../friends_activity/friends_activity_widgets.dart';
import '../friends_activity/home_activity_navigation.dart';
import '../viewmodel/home_feed_controller.dart';

Future<void> showHomeCountriesSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: HomeActivityTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: HomeActivityTheme.sheetRadius,
      ),
      builder: (_) => const HomeCountriesSheet(),
    );

class HomeCountriesSheet extends ConsumerWidget {
  const HomeCountriesSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeFeedProvider);
    listenHomeSessionRoute(context, ref);
    return SafeArea(
      top: false,
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context).height *
            HomeActivityTheme.sheetHeightRatio,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(HomeActivityTheme.pagePadding.r),
              child: Text(
                context.l10n.t('home.countries'),
                style: HomeActivityTheme.title,
              ),
            ),
            if (state.countriesLoading) const LinearProgressIndicator(),
            if (state.countriesError != null)
              HomeActivityNotice(
                text: state.countriesError!,
                error: true,
                retry: state.countriesLoading
                    ? null
                    : () => ref
                          .read(homeFeedProvider.notifier)
                          .refreshCountries(),
              ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(HomeActivityTheme.pagePadding.r),
                itemCount: state.countries.length + 1,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: HomeActivityTheme.gap.w,
                  mainAxisSpacing: HomeActivityTheme.mediumGap.h,
                  childAspectRatio: HomeActivityTheme.countryRatio,
                ),
                itemBuilder: (context, index) {
                  final country = index == 0
                      ? null
                      : state.countries[index - 1];
                  final selected =
                      state.selectedCountryCode == country?.isoCode;
                  return Semantics(
                    button: true,
                    selected: selected,
                    child: InkWell(
                      key: ValueKey(
                        'country-more-${country?.isoCode ?? 'hot'}',
                      ),
                      onTap: () {
                        ref
                            .read(homeFeedProvider.notifier)
                            .selectCountry(country?.isoCode);
                        Navigator.pop(context);
                      },
                      borderRadius: HomeActivityTheme.radius,
                      child: Container(
                        padding: EdgeInsets.all(HomeActivityTheme.smallGap.r),
                        decoration: BoxDecoration(
                          color: selected ? null : HomeActivityTheme.field,
                          gradient: selected ? AppGradients.sendButton : null,
                          borderRadius: HomeActivityTheme.radius,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (country == null)
                              HomeActivityIcon(
                                AppAssets.lanhuHomeHotIcon,
                                size: HomeActivityTheme.flagHeight.r,
                              )
                            else
                              HomeCountryFlag(country: country),
                            SizedBox(width: HomeActivityTheme.smallGap.w),
                            Flexible(
                              child: Text(
                                country == null
                                    ? context.l10n.t('home.hot')
                                    : countryDisplayName(context, country),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: HomeActivityTheme.countryLabel(selected),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String countryDisplayName(BuildContext context, CountryInfo country) =>
    Localizations.localeOf(context).languageCode == 'ar' &&
        country.arName.isNotEmpty
    ? country.arName
    : country.name.isNotEmpty
    ? country.name
    : country.isoCode;

class HomeCountryFlag extends StatelessWidget {
  const HomeCountryFlag({super.key, required this.country});
  final CountryInfo country;
  @override
  Widget build(BuildContext context) => CountryFlag.fromCountryCode(
    country.isoCode,
    theme: ImageTheme(
      width: HomeActivityTheme.flagWidth.w,
      height: HomeActivityTheme.flagHeight.h,
      shape: const RoundedRectangle(HomeActivityTheme.flagRadius),
    ),
  );
}
