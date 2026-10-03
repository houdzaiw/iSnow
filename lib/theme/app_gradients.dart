import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  const AppGradients._();

  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.warmBackground, AppColors.warmBackgroundEnd],
  );

  static const LinearGradient authBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFEAB1), Color(0xFFFFE7E5)],
  );

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF75460), AppColors.primaryPinkDeep],
  );

  static const LinearGradient sendButton = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFE21B7A), Color(0xFFFB274A)],
  );

  static const LinearGradient voiceBubble = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.voiceBubbleStart, AppColors.voiceBubbleEnd],
  );

  static const LinearGradient createRoomConfirmButton = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [AppColors.voiceBubbleStart, AppColors.voiceBubbleEnd],
  );

  static const LinearGradient roomBottomBar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.transparent, Color(0xFC000000)],
  );

  static const LinearGradient roomGiftSend = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFAD8A64), Color(0xFFFFDE8F), Color(0xFFC49E72)],
  );

  static const LinearGradient partyCoverScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x66000000)],
  );

  static const LinearGradient walletSelectedProduct = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDF7EF), Color(0xFFFCEFDE)],
  );

  static const LinearGradient walletSelectedPrice = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [AppColors.walletSelectedBorder, Color(0xFFEBA33C)],
  );
}
