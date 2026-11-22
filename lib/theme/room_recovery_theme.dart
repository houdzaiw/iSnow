import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

abstract final class RoomRecoveryTheme {
  static const maxWidth = 340.0, edge = 16.0, padding = 20.0;
  static const gap = 12.0, buttonHeight = 44.0;
  static const surface = AppColors.cardBackground;
  static const border = AppRadius.cardBorder;
  static const shadows = [
    BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const title = AppTextStyles.navTitle;
  static const body = AppTextStyles.body;
  static const accent = AppColors.primaryPink;
}
