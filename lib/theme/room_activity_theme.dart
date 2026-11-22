import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

abstract final class RoomActivityTheme {
  static const surface = Color(0xFF222128),
      panel = Color(0xFF302C36),
      red = Color(0xFFFF4378),
      blue = Color(0xFF6296FF),
      gold = Color(0xFFFFD38C),
      luckySurface = Color(0xFFFFF4E0),
      luckyText = Color(0xFF7F3825);
  static const scrim = AppColors.modalScrimStrong,
      white = AppColors.textInverse;
  static const radius = AppRadius.roomShareSheetBorder,
      cardRadius = AppRadius.cardBorder;
  static const edge = 16.0,
      gap = 8.0,
      avatar = 44.0,
      choiceSize = 18.0,
      icon = 24.0,
      action = 48.0,
      winnerAvatar = 100.0;
  static const resultTitleWidth = 212.0,
      resultTitleHeight = 70.0,
      resultAvatar = 64.0;
  static const pkHeight = 100.0,
      multiWidth = 311.0,
      multiHeight = 340.0,
      miniWidth = 120.0,
      miniHeight = 163.0,
      sheetRatio = .78,
      luckyCard = 76.0,
      goldIcon = 36.0;
  static const title = AppTextStyles.roomMoreSectionTitle,
      body = AppTextStyles.roomGiftStatus,
      amount = AppTextStyles.roomGiftBalance;
  static final darkBody = body.copyWith(color: luckyText),
      darkTitle = title.copyWith(color: luckyText);
  static final criticalTitle = title.copyWith(color: red);
  static const countdownPulse = Duration(seconds: 1);
  static const countdownMinScale = .96, countdownMaxScale = 1.5;
  static final winnerText = title.copyWith(fontSize: 42, color: white);
}
