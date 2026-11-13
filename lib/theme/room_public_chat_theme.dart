import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';
import 'room_profile_theme.dart';

/// Lanhu cc03dc0c / group_28 and its following message bubble, at 375px.
abstract final class RoomPublicChatTheme {
  static const leading = 5.0, trailing = 75.0;
  static const systemLeading = 14.0, systemTrailing = 70.0;
  static const avatar = 40.0, avatarInset = 4.0, avatarGap = 3.0;
  static const nameMaxWidth = 102.0, nameGap = 3.0;
  static const badgeHeight = 16.0, badgeMaxWidth = 110.0;
  static const badgeGap = 2.0, badgeRunGap = 4.0, badgeNumberInset = 4.0;
  static const badgeMinWidth = 38.0, gender = 11.0;
  static const flagWidth = 13.0, flagHeight = 10.0;
  static const bubbleMaxWidth = 223.0, bodyGap = 6.0, bubblePadding = 8.0;
  static const rowGap = 8.0, firstGap = 4.0, listBottom = 10.0;
  static const media = 128.0, expression = 80.0, gift = 26.0;
  static const bubble = Color(0x66000000), systemBubble = Color(0x8C000000);
  static const bodyColor = AppColors.textInverse;
  static const noticeColor = Color(0xFFFF83DA),
      mentionColor = Color(0xFFFF5CD8);
  static const giftColor = Color(0xFFFFD86B);
  static const maleBorder = Color(0xFF5894EE), femaleBorder = Color(0xFFFF83DA);
  static const genderBorder = 0.6;
  static const levelRadius = BorderRadius.all(Radius.circular(20));
  static const genderRadius = BorderRadius.all(Radius.circular(20));
  static const systemRadius = BorderRadius.all(Radius.circular(10));
  static const bubbleRadius = BorderRadiusDirectional.only(
    topStart: Radius.circular(6),
    topEnd: Radius.circular(16),
    bottomStart: Radius.circular(16),
    bottomEnd: Radius.circular(16),
  );
  static const wealthGradient = RoomProfileTheme.wealthGradient;
  static const charmGradient = RoomProfileTheme.charmGradient;
  static const activeGradient = RoomProfileTheme.activeGradient;

  static TextStyle get name => TextStyle(
    color: bodyColor,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 1.15,
  );
  static TextStyle get body => TextStyle(
    color: bodyColor,
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    height: 1.16,
  );
  static TextStyle get notice => body.copyWith(color: noticeColor);
  static TextStyle get mention => body.copyWith(color: mentionColor);
  static TextStyle get giftText => body.copyWith(color: giftColor);
  static TextStyle get level => TextStyle(
    color: bodyColor,
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    height: 1,
  );
}
