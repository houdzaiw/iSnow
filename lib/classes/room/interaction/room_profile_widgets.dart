import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_theme.dart';

class RoomProfileSheet extends StatelessWidget {
  const RoomProfileSheet({
    super.key,
    required this.height,
    required this.child,
    this.header,
    this.gradient,
  });
  final double height;
  final Widget child;
  final Widget? header;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      final available = math.max(0.0, constraints.maxHeight - keyboard);
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Container(
          height: math.min(height.h, available),
          decoration: BoxDecoration(
            color: RoomProfileTheme.surface,
            gradient: gradient,
            borderRadius: RoomProfileTheme.sheetRadius,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                if (header != null) header!,
                Expanded(child: child),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class RoomProfileAsset extends StatelessWidget {
  const RoomProfileAsset({
    super.key,
    required this.asset,
    this.size,
    this.width,
    this.height,
    this.color,
  });
  final String asset;
  final double? size, width, height;
  final Color? color;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: width ?? size ?? RoomProfileTheme.icon.r,
    height: height ?? size ?? RoomProfileTheme.icon.r,
    color: color,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    errorBuilder: (_, __, ___) => Image.asset(
      AppAssets.iconMissing,
      width: width ?? size ?? RoomProfileTheme.icon.r,
      height: height ?? size ?? RoomProfileTheme.icon.r,
      color: AppColors.missingAsset,
      excludeFromSemantics: true,
    ),
  );
}

class RoomProfilePicture extends StatelessWidget {
  const RoomProfilePicture({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });
  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget missing() => const RoomProfileAsset(
      asset: AppAssets.iconMissing,
      color: AppColors.missingAsset,
    );
    final source = url?.trim() ?? '';
    if (source.isEmpty) return missing();
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: fit,
        errorBuilder: (_, __, ___) => missing(),
      );
    }
    final uri = Uri.tryParse(source);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      return missing();
    }
    return CachedNetworkImage(
      imageUrl: source,
      fit: fit,
      placeholder: (_, __) => const ColoredBox(color: RoomProfileTheme.field),
      errorWidget: (_, __, ___) => missing(),
    );
  }
}

class RoomProfileCountry extends StatelessWidget {
  const RoomProfileCountry({super.key, required this.code});
  final String? code;

  @override
  Widget build(BuildContext context) {
    final country = code?.toUpperCase();
    if (country == null || !RegExp(r'^[A-Z]{2}$').hasMatch(country)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(end: RoomProfileTheme.smallGap.w),
      child: ClipRRect(
        borderRadius: RoomProfileTheme.flagRadius,
        child: CountryFlag.fromCountryCode(
          country,
          theme: ImageTheme(
            width: RoomProfileTheme.flagWidth.w,
            height: RoomProfileTheme.flagHeight.h,
          ),
        ),
      ),
    );
  }
}

class RoomProfileHeader extends StatelessWidget {
  const RoomProfileHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: RoomProfileTheme.headerHeight.h,
    child: Row(
      children: [
        SizedBox(width: RoomProfileTheme.section.w),
        Semantics(
          label: MaterialLocalizations.of(context).backButtonTooltip,
          button: true,
          child: InkWell(
            onTap: onBack,
            child: SizedBox.square(
              dimension: RoomProfileTheme.touch.r,
              child: Center(
                child: RoomProfileAsset(
                  asset: AppAssets.roomPartyHistoryBack,
                  size: RoomProfileTheme.smallIcon.r,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: RoomProfileTheme.heading,
          ),
        ),
        SizedBox(
          width: (RoomProfileTheme.section + RoomProfileTheme.touch).w,
          child: trailing == null
              ? null
              : Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: RoomProfileTheme.section.w,
                  ),
                  child: trailing,
                ),
        ),
      ],
    ),
  );
}
