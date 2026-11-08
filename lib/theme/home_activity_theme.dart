import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

class HomeActivityTheme {
  const HomeActivityTheme._();
  static const fontFamily = 'Roboto';
  static const background = AppColors.pageBackground;
  static const surface = AppColors.cardBackground;
  static const field = AppColors.fieldBackground;
  static const ink = AppColors.textPrimary;
  static const muted = AppColors.textSecondary;
  static const pink = AppColors.primaryPink;
  static const radius = BorderRadius.all(Radius.circular(12));
  static const sheetRadius = BorderRadius.vertical(top: Radius.circular(20));
  static const pill = BorderRadius.all(Radius.circular(40));
  static const double pagePadding = 16, gap = 8, smallGap = 4, mediumGap = 12;
  static const double sectionGap = 16, largeGap = 24, touch = 44;
  static const double avatar = 48, homeAvatar = 60, stripHeight = 64;
  static const double badge = 22, back = 14, icon = 20;
  static const double tabHeight = 46, indicator = 3, banner = 106;
  static const double countryTabHeight = 32, countryChipHeight = 28;
  static const double countryChipWidth = 46, hotChipWidth = 65, moreWidth = 32;
  static const double flagWidth = 24, flagHeight = 16, flagRadius = 3;
  static const double countryRatio = 106 / 44, sheetHeightRatio = .6;
  static const double pagingThreshold = 120, bottomPadding = 110;
  static const double emptyHeight = 120, progress = 22;
  static const double statusPadding = 6;
  static TextStyle get title => TextStyle(
    fontFamily: fontFamily,
    color: ink,
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle get body =>
      TextStyle(fontFamily: fontFamily, color: ink, fontSize: 16.sp);
  static TextStyle get roomTitle => body.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get secondary => TextStyle(
    fontFamily: fontFamily,
    color: muted,
    fontSize: 13.sp,
    height: 1.3,
  );
  static TextStyle get status => TextStyle(
    fontFamily: fontFamily,
    color: pink,
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle get error => secondary.copyWith(color: AppColors.danger);
  static TextStyle get tab => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle countryLabel(bool selected) => TextStyle(
    fontFamily: fontFamily,
    color: selected ? AppColors.textInverse : ink,
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle hotLabel(bool selected) =>
      countryLabel(selected).copyWith(fontSize: 15.sp);
}
