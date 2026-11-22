import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

abstract final class RoomFirstRechargeTheme {
  static const surface = AppColors.roomGiftPopupSurface;
  static const card = AppColors.roomGiftTargetSurface;
  static const accent = AppColors.primaryPink;
  static const radius = AppRadius.roomShareSheetBorder;
  static const cardRadius = AppRadius.cardBorder;
  static const maxHeightRatio = .82;
  static const padding = 16.0, gap = 12.0, smallGap = 6.0;
  static const rewardSize = 44.0, closeSize = 24.0, actionHeight = 48.0;
  static const headerWidth = 150.0, headerHeight = 40.0;
  static const title = AppTextStyles.roomMoreSectionTitle;
  static const body = AppTextStyles.roomGiftTarget;
  static const amount = AppTextStyles.roomGiftBalance;
  static final originalPrice = body.copyWith(
    decoration: TextDecoration.lineThrough,
  );
}
