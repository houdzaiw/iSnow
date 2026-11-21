import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class RoomBarrageTheme {
  static const height = 64.0;
  static const edge = 12.0;
  static const top = 8.0;
  static const avatar = 34.0;
  static const icon = 36.0;
  static const radius = BorderRadius.all(Radius.circular(24));
  static const background = AppColors.giftBannerBackground;
  static const title = AppTextStyles.giftEffectTitle;
  static const detail = AppTextStyles.giftEffectSubtitle;
  static const prizePadding = 24.0;
  static const prizeImage = 64.0;
  static const enterDuration = Duration(milliseconds: 400);
  static const visibleDuration = Duration(seconds: 4);
  static const initializationTimeout = Duration(seconds: 10);
}
