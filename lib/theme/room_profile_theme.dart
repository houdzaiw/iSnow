import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

/// Lanhu room profile, member card and Party history visual tokens.
abstract final class RoomProfileTheme {
  static const surface = AppColors.cardBackground;
  static const ink = Color(0xFF44484E);
  static const titleInk = Color(0xFF222222);
  static const muted = Color(0xFF888888);
  static const inactive = Color(0xFFA4A4A4);
  static const field = Color(0xFFF3F3F3);
  static const actionSurface = Color(0xFFF1F2F6);
  static const pink = Color(0xFFFF32BF);
  static const badgeScrim = Color(0x66000000);
  static const cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE3F2), surface, surface],
    stops: [0, 0.3, 1],
  );
  static const giftGradient = LinearGradient(
    colors: [Color(0xFFFF43BD), Color(0xFFFF5277)],
  );
  static const wealthGradient = LinearGradient(
    colors: [Color(0xFFEF0070), Color(0xFF5400FF)],
  );
  static const charmGradient = LinearGradient(
    colors: [Color(0xFF7387FF), Color(0xFF7387FF)],
  );
  static const activeGradient = LinearGradient(
    colors: [Color(0xFFFFB046), Color(0xFFFF675D)],
  );
  static const sheetRadius = BorderRadius.vertical(top: Radius.circular(24));
  static const memberRadius = BorderRadius.vertical(top: Radius.circular(10));
  static const cardRadius = BorderRadius.all(Radius.circular(12));
  static const imageRadius = BorderRadius.all(Radius.circular(10));
  static const actionRadius = BorderRadius.all(Radius.circular(10));
  static const flagRadius = BorderRadius.all(Radius.circular(4));
  static const pillRadius = BorderRadius.all(Radius.circular(40));
  static const shadows = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const detailHeight = 535.0, historyHeight = 639.0;
  static const memberHeight = 417.0, avatarLift = 56.0;
  static const headerHeight = 54.0, rowHeight = 54.0, touch = 44.0;
  static const cover = 48.0, avatar = 104.0, avatarFrame = 135.0;
  static const avatarTop = 0.0,
      avatarInset = (avatarFrame - avatar) / 2,
      memberInfoTop = 146.0;
  static const gap = 8.0, smallGap = 4.0, mediumGap = 12.0, section = 16.0;
  static const wideGap = 20.0, memberPadding = 24.0;
  static const icon = 24.0, smallIcon = 14.0, giftIcon = 28.0;
  static const flagWidth = 31.0, flagHeight = 18.0, gender = 18.0;
  static const badgeHeight = 16.0, badgeMaxWidth = 110.0;
  static const memberActionsHeight = 40.0, giftHeight = 50.0;
  static const giftBottom = 12.0, cardPadding = 8.0, creatorAvatar = 22.0;
  static const partyCoverRatio = 325 / 122, shareWidth = 49.0;
  static const shareHeight = 22.0, indicatorWidth = 15.0;
  static const indicatorHeight = 4.0, tabHorizontalPadding = 14.0;
  static const tabLabel = 48.0;
  static const rowSwitchScale = 0.82;
  static const paginationThreshold = 120.0;
  static const descriptionMinHeight = 46.0, rowValueMaxWidth = 150.0;
  static const editHeight = historyHeight, editCover = 90.0;
  static const editHandleArea = 10.0,
      editHandleWidth = 36.0,
      editHandleHeight = 5.0;
  static const editFormStart = 20.0, editFormEnd = 14.0, editCoverGap = 27.0;
  static const editLabelGap = 10.0, editFieldGap = 21.0;
  static const editNameHeight = 37.0, editDescriptionHeight = 151.0;
  static const editCameraWidth = 30.0, editCameraHeight = 27.0;
  static const editConfirmHeight = 50.0, editProgressSize = 18.0;
  static const editProgressStroke = 2.0;
  static const editDisabledOpacity = 0.45, editCounterWidth = 40.0;
  static const editHandleColor = Color(0xFFC4C4C4);
  static const editCounterColor = Color(0xFF9D9D9D);
  static const editPlaceholderColor = Color(0xFFBDBDBD);
  static const editFieldBorder = InputBorder.none;

  static TextStyle get editLabel =>
      TextStyle(color: titleInk, fontSize: 16.sp, fontWeight: FontWeight.w700);
  static TextStyle get editInput =>
      TextStyle(color: titleInk, fontSize: 16.sp, height: 1.2);
  static TextStyle get editCounter =>
      TextStyle(color: editCounterColor, fontSize: 12.sp);
  static TextStyle get editHint =>
      editInput.copyWith(color: editPlaceholderColor);
  static TextStyle get editError =>
      editCounter.copyWith(color: AppColors.danger);
  static TextStyle get editConfirm => TextStyle(
    color: AppColors.textInverse,
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get heading => TextStyle(
    fontFamily: 'Roboto',
    color: titleInk,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle get title =>
      TextStyle(color: titleInk, fontSize: 16.sp, fontWeight: FontWeight.w700);
  static TextStyle get body =>
      TextStyle(color: ink, fontSize: 16.sp, height: 1.4);
  static TextStyle get secondary => TextStyle(color: muted, fontSize: 14.sp);
  static TextStyle get description =>
      TextStyle(color: ink, fontSize: 13.sp, height: 1.4);
  static TextStyle get small =>
      TextStyle(color: titleInk, fontSize: 12.sp, fontWeight: FontWeight.w500);
  static TextStyle get tiny =>
      TextStyle(color: AppColors.textInverse, fontSize: 11.sp);
  static TextStyle get button => TextStyle(
    color: AppColors.textInverse,
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle get action => TextStyle(color: ink, fontSize: 16.sp);
  static TextStyle get link =>
      TextStyle(color: AppColors.primaryPink, fontSize: 14.sp);
}
