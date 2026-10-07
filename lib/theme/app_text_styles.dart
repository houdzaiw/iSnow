import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle giftEffectTitle = TextStyle(
    color: AppColors.roomGiftGold,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle giftEffectSubtitle = TextStyle(
    color: AppColors.roomGiftText,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle giftComboCount = TextStyle(
    color: AppColors.roomGiftGold,
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle giftLuckyAmount = TextStyle(
    color: AppColors.roomGiftGold,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );
  const AppTextStyles._();

  static const TextStyle navTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle navTitleStrong = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sheetTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle button = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textBody,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    color: AppColors.textBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyStrong = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyStrongSmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle formLabel = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle requiredMark = TextStyle(
    color: AppColors.requiredMark,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle formHelper = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle formFieldHint = TextStyle(
    color: AppColors.formPlaceholder,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle sheetInput = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle sheetPlaceholder = TextStyle(
    color: AppColors.sheetPlaceholder,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle sheetCounter = TextStyle(
    color: AppColors.sheetCounter,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle chip = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle chipSelected = TextStyle(
    color: AppColors.chipSelectedText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle primaryButtonLarge = TextStyle(
    color: AppColors.textInverse,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle primaryButtonCompact = TextStyle(
    color: AppColors.textInverse,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle menuItem = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.textPlaceholder,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle hint = TextStyle(
    color: AppColors.textPlaceholder,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle hintLarge = TextStyle(
    color: AppColors.textPlaceholder,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle timeTiny = TextStyle(
    color: AppColors.textPlaceholder,
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle walletNavigationTitle = TextStyle(
    color: AppColors.textInverse,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle walletTradingTitle = TextStyle(
    color: AppColors.textInverse,
    fontSize: 20,
    height: 22 / 20,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle walletBalance = TextStyle(
    color: AppColors.textInverse,
    fontSize: 40,
    height: 1,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle walletPaymentTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    height: 16 / 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle walletProductAmount = TextStyle(
    color: AppColors.walletProductText,
    fontSize: 14,
    height: 1,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle walletProductAmountSelected = TextStyle(
    color: AppColors.walletSelectedAmount,
    fontSize: 14,
    height: 1,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle walletProductSubtitle = TextStyle(
    color: AppColors.walletProductText,
    fontSize: 10,
    height: 1,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.lineThrough,
  );

  static const TextStyle walletProductSubtitleSelected = TextStyle(
    color: AppColors.walletSelectedSubtitle,
    fontSize: 10,
    height: 1,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.lineThrough,
  );

  static const TextStyle walletProductPrice = TextStyle(
    color: AppColors.walletProductPriceDisabled,
    fontSize: 14,
    height: 1,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle walletProductPriceSelected = TextStyle(
    color: AppColors.textInverse,
    fontSize: 14,
    height: 1,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle walletPromotion = TextStyle(
    color: AppColors.textInverse,
    fontSize: 11,
    height: 1,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle walletTransfer = TextStyle(
    color: AppColors.textInverse,
    fontSize: 20,
    height: 23 / 20,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle walletContact = TextStyle(
    color: AppColors.walletBrandOrange,
    fontSize: 12,
    height: 14 / 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle walletGuide = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle calendarDay = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomChatTab = TextStyle(
    color: AppColors.roomChatTab,
    fontSize: 14,
    height: 1,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomChatTabSelected = TextStyle(
    color: AppColors.roomChatTabSelected,
    fontSize: 14,
    height: 1,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle roomAction = TextStyle(
    color: AppColors.textInverse,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle roomMoreSectionTitle = TextStyle(
    color: AppColors.roomMoreSectionTitle,
    fontSize: 16,
    height: 1,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle roomMoreTool = TextStyle(
    color: AppColors.roomMoreToolText,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle roomMoreHint = TextStyle(
    color: AppColors.roomMoreToolSubtle,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomMoreTag = TextStyle(
    color: AppColors.textInverse,
    fontSize: 8,
    height: 1,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle roomGiftTarget = TextStyle(
    color: AppColors.roomGiftText,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomGiftTargetCount = TextStyle(
    color: AppColors.roomGiftAccent,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomGiftTab = TextStyle(
    color: AppColors.roomGiftTextMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomGiftTabSelected = TextStyle(
    color: AppColors.textInverse,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle roomGiftName = TextStyle(
    color: AppColors.roomGiftText,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomGiftPrice = TextStyle(
    color: AppColors.roomGiftTextMuted,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomGiftCornerMark = TextStyle(
    color: AppColors.textInverse,
    fontSize: 8,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle roomGiftBalance = TextStyle(
    color: AppColors.textInverse,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomGiftCount = TextStyle(
    color: AppColors.roomGiftAccent,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomGiftCountInactive = TextStyle(
    color: AppColors.roomGiftCountMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roomGiftSend = TextStyle(
    color: AppColors.roomGiftSendText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle roomGiftStatus = TextStyle(
    color: AppColors.roomGiftTextMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}
