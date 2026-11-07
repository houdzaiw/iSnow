import 'package:flutter/material.dart';

/// Nady membership visual tokens, adapted to the project's existing font.
class MembershipTheme {
  const MembershipTheme._();
  static const background = Color(0xFF191410);
  static const panel = Color(0xFF292018);
  static const gold = Color(0xFFFFE2B8);
  static const goldDeep = Color(0xFFEAB96C);
  static const brown = Color(0xFF583916);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0x99FFFFFF);
  static const transparent = Color(0x00000000);
  static const barrier = Color(0x99000000);
  static const danger = Color(0xFFFF4343);
  static const gradient = LinearGradient(colors: [goldDeep, Color(0xFFFFECCE)]);
  static const vipCardGradient = LinearGradient(
    colors: [Color(0xFF86602C), Color(0xFF282723)],
  );
  static const nobleCardGradient = LinearGradient(
    colors: [Color(0xFFFFCF40), Color(0xFFE68A00)],
  );
  static const padding = EdgeInsets.all(16);
  static const rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const cardPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 16);
  static const smallPadding = EdgeInsets.all(8);
  static const zero = EdgeInsets.zero;
  static const radius = BorderRadius.all(Radius.circular(16));
  static const pill = BorderRadius.all(Radius.circular(24));
  static const sheetRadius = BorderRadius.vertical(top: Radius.circular(24));
  static const border = Border.fromBorderSide(
    BorderSide(color: gold, width: 0.5),
  );
  static const title = TextStyle(
    color: gold,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const heading = TextStyle(
    color: gold,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(color: white, fontSize: 14, height: 1.4);
  static const caption = TextStyle(color: muted, fontSize: 12, height: 1.4);
  static const tiny = TextStyle(color: gold, fontSize: 10, height: 1.3);
  static const button = TextStyle(
    color: brown,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const cardTitle = TextStyle(
    color: gold,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
  );
  static const cardDetail = TextStyle(color: white, fontSize: 10, height: 1.3);
  static const strike = TextStyle(
    color: muted,
    fontSize: 12,
    decoration: TextDecoration.lineThrough,
  );
  static const s = 4.0, m = 8.0, l = 12.0, xl = 16.0, section = 24.0;
  static const icon = 24.0, touch = 44.0, badge = 56.0, avatar = 40.0;
  static const homeHeight = 68.0, homeGap = 5.0, homeBadge = 42.0;
  static const heroHeight = 224.0, heroCardHeight = 176.0, preview = 160.0;
  static const tabHeight = 56.0,
      perkWidth = 88.0,
      perkImage = 44.0,
      perkHeight = 120.0;
  static const sheetFraction = 0.85, modalWidth = 420.0, previewHeight = 320.0;
  static const galleryRatio = 247 / 120, titleRatio = 311 / 120;
  static const dialogGap = SizedBox(height: l);
  static const gap = SizedBox(height: m);
  static const sectionGap = SizedBox(height: section);
  static const rowGap = SizedBox(width: m);
  static const faded = 0.45;
  static const heroViewport = 0.88, heroScale = 0.92;
  static const homeImageSize = Size(688, 272);
  static const homeVipLogo = Rect.fromLTWH(65, 65, 150, 150);
  static const homeNobleLogo = Rect.fromLTWH(0, 40, 195, 195);
}
