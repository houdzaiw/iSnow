import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

class ProfileToolsTheme {
  const ProfileToolsTheme._();
  static const padding = EdgeInsets.all(16);
  static const smallPadding = EdgeInsets.all(8);
  static const rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const gap = SizedBox(height: 12);
  static const smallGap = SizedBox(height: 6);
  static const space = SizedBox(width: 12);
  static const icon = 24.0;
  static const badge = 40.0;
  static const largeBadge = 88.0;
  static const appLogo = 100.0;
  static const badgeSlot = 48.0;
  static const medalExtent = 160.0;
  static const previewFraction = .8;
  static const preview = 170.0;
  static const itemExtent = 158.0;
  static const gridSpacing = 12.0;
  static const gridColumns = 3;
  static const menuColumns = 5;
  static const menuItemHeight = 76.0;
  static const disabledOpacity = .5;
  static const dialogWidth = 340.0;
  static const sheetFraction = .72;
  static const decoration = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: AppRadius.cardBorder,
  );
  static const title = AppTextStyles.navTitle;
  static const body = AppTextStyles.body;
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  static const selectedBorder = BorderSide(
    color: AppColors.primaryPink,
    width: 2,
  );
  static const normalBorder = BorderSide(color: AppColors.divider);
  static const progressColor = AppColors.primaryPink;
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const background = AppColors.pageBackground;
  static const tabActive = AppColors.textPrimary;
  static const tabInactive = AppColors.textSecondary;
  static const tabIndicator = AppColors.primaryPink;
  static const error = AppColors.missingAsset;
  static const white = AppColors.cardBackground;
  static const panelHeight = 96.0;
  static const radius = AppRadius.cardBorder;
}
