import 'package:flutter/material.dart';

import 'app_colors.dart';

class RoomHeaderTheme {
  static const horizontalInset = 11.0, verticalInset = 8.0;
  static const avatar = 66.0, avatarRadius = 14.0;
  static const gap = 6.0, lineGap = 5.0;
  static const metricMaxWidth = 74.0, metricHeight = 20.0;
  static const metricHorizontal = 7.0, metricVertical = 3.0;
  static const metricIcon = 14.0, metricGap = 3.0;
  static const metricSurface = Color(0x7A000000);
  static const metricBorder = BorderRadius.all(Radius.circular(18));
  static const title = TextStyle(
    color: AppColors.textInverse,
    fontSize: 16,
    height: 1,
    fontWeight: FontWeight.w700,
  );
  static const number = TextStyle(
    color: AppColors.textInverse,
    fontSize: 13,
    height: 1,
    fontWeight: FontWeight.w500,
  );
  static const metric = TextStyle(
    color: Color(0xFFFFD86B),
    fontSize: 12,
    height: 1,
    fontWeight: FontWeight.w500,
  );
  static const carouselDelay = 5000, carouselDuration = 500;
}
