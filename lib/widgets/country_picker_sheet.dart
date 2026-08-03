import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../model/country_info.dart';
import '../theme/app_theme.dart';

class CountryDialOption {
  const CountryDialOption({
    required this.name,
    required this.countryCode,
    required this.areaCode,
  });

  final String name;
  final String countryCode;
  final String areaCode;

  factory CountryDialOption.fromCountryInfo(CountryInfo country) {
    return CountryDialOption(
      name: country.name,
      countryCode: country.isoCode.toUpperCase(),
      areaCode: country.areaCode,
    );
  }

  CountryDialOption copyWith({
    String? name,
    String? countryCode,
    String? areaCode,
  }) {
    return CountryDialOption(
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      areaCode: areaCode ?? this.areaCode,
    );
  }
}

class CountryFlagIcon extends StatelessWidget {
  const CountryFlagIcon({
    super.key,
    required this.countryCode,
    this.width = 20,
    this.height = 15,
    this.circular = false,
    this.borderRadius = 2,
  });

  final String countryCode;
  final double width;
  final double height;
  final bool circular;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final shape = circular ? const Circle() : RoundedRectangle(borderRadius);
    return CountryFlag.fromCountryCode(
      countryCode,
      theme: ImageTheme(width: width, height: height, shape: shape),
    );
  }
}

class CountryPickerSheet extends StatelessWidget {
  const CountryPickerSheet({
    super.key,
    required this.countries,
    required this.selectedCountryCode,
  });

  final List<CountryDialOption> countries;
  final String selectedCountryCode;

  static Future<CountryDialOption?> show(
    BuildContext context, {
    required List<CountryDialOption> countries,
    required String selectedCountryCode,
  }) {
    return showModalBottomSheet<CountryDialOption>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return CountryPickerSheet(
          countries: countries,
          selectedCountryCode: selectedCountryCode,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedSelectedCode = selectedCountryCode.toUpperCase();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutralLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.t('auth.countryCode'),
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: countries.length,
              itemBuilder: (context, index) {
                final country = countries[index];
                final isSelected =
                    country.countryCode.toUpperCase() == normalizedSelectedCode;
                return ListTile(
                  minLeadingWidth: 24,
                  leading: CountryFlagIcon(countryCode: country.countryCode),
                  title: Text(country.name, style: AppTextStyles.body),
                  trailing: Text(
                    '+${country.areaCode}',
                    style: AppTextStyles.bodyStrongSmall.copyWith(
                      color: isSelected
                          ? AppColors.primaryPink
                          : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
