import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../model/room_user_info.dart';
import '../../../theme/app_theme.dart';
import '../interaction/room_animated_artwork.dart';
import '../interaction/room_public_media.dart';

/// Shared sender header and Lanhu bubble for text, media, parties and gifts.
class RoomPublicMessageFrame extends StatelessWidget {
  const RoomPublicMessageFrame({
    super.key,
    required this.child,
    this.uid,
    this.name,
    this.avatar,
    this.appearance = const RoomUserAppearance(),
    this.onUserTap,
    this.avatarKey,
  });

  final Widget child;
  final int? uid;
  final String? name, avatar;
  final RoomUserAppearance appearance;
  final ValueChanged<int>? onUserTap;
  final Key? avatarKey;

  @override
  Widget build(BuildContext context) {
    final onTap = (uid ?? 0) > 0 && onUserTap != null
        ? () => onUserTap!(uid!)
        : null;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: RoomPublicChatTheme.leading.w,
        end: RoomPublicChatTheme.trailing.w,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inset =
              RoomPublicChatTheme.avatar.r + RoomPublicChatTheme.avatarGap.w;
          final bodyWidth = math.max(
            0.0,
            math.min(
              RoomPublicChatTheme.bubbleMaxWidth.w,
              constraints.maxWidth - inset,
            ),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                key: avatarKey,
                onTap: onTap,
                child: _SenderAvatar(url: avatar, appearance: appearance),
              ),
              SizedBox(width: RoomPublicChatTheme.avatarGap.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SenderIdentity(
                      key: const ValueKey('room-public-sender-identity'),
                      name: name,
                      appearance: appearance,
                      onTap: onTap,
                    ),
                    SizedBox(height: RoomPublicChatTheme.bodyGap.h),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: bodyWidth),
                      child: Container(
                        key: const ValueKey('room-public-message-bubble'),
                        padding: EdgeInsets.all(
                          RoomPublicChatTheme.bubblePadding.r,
                        ),
                        decoration: const BoxDecoration(
                          color: RoomPublicChatTheme.bubble,
                          borderRadius: RoomPublicChatTheme.bubbleRadius,
                        ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RoomPublicSystemMessage extends StatelessWidget {
  const RoomPublicSystemMessage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: RoomPublicChatTheme.systemLeading.w,
      end: RoomPublicChatTheme.systemTrailing.w,
    ),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: EdgeInsets.all(RoomPublicChatTheme.bubblePadding.r),
        decoration: const BoxDecoration(
          color: RoomPublicChatTheme.systemBubble,
          borderRadius: RoomPublicChatTheme.systemRadius,
        ),
        child: child,
      ),
    ),
  );
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.url, required this.appearance});
  final String? url;
  final RoomUserAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final frame = appearance.frameUrl;
    final inset = frame == null ? 0.0 : RoomPublicChatTheme.avatarInset.r;
    return SizedBox.square(
      dimension: RoomPublicChatTheme.avatar.r,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.all(inset),
            child: ClipOval(
              child: RoomPublicChatImage(source: url, fit: BoxFit.cover),
            ),
          ),
          if (frame != null)
            IgnorePointer(
              child: frame.startsWith('assets/')
                  ? RoomPublicChatImage(source: frame)
                  : RoomAnimatedArtwork(
                      url: frame,
                      preview: appearance.framePreview,
                      repeat: true,
                    ),
            ),
        ],
      ),
    );
  }
}

class _SenderIdentity extends StatelessWidget {
  const _SenderIdentity({
    super.key,
    required this.name,
    required this.appearance,
    required this.onTap,
  });
  final String? name;
  final RoomUserAppearance appearance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final badges = appearance.publicBadges.isNotEmpty
        ? appearance.publicBadges
              .map((badge) => badge.iconForLanguage(language))
              .toList()
        : [...appearance.badges, ...appearance.identityBadges];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: RoomPublicChatTheme.badgeGap.w,
          runSpacing: RoomPublicChatTheme.badgeRunGap.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: RoomPublicChatTheme.nameMaxWidth.w,
              ),
              child: InkWell(
                onTap: onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (appearance.gender case final gender?) ...[
                      _SenderGender(gender: gender),
                      SizedBox(width: RoomPublicChatTheme.nameGap.w),
                    ],
                    if (appearance.countryCode case final country?) ...[
                      CountryFlag.fromCountryCode(
                        country,
                        theme: ImageTheme(
                          width: RoomPublicChatTheme.flagWidth.w,
                          height: RoomPublicChatTheme.flagHeight.h,
                        ),
                      ),
                      SizedBox(width: RoomPublicChatTheme.nameGap.w),
                    ],
                    Flexible(
                      child: Text(
                        name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RoomPublicChatTheme.name,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final level in appearance.levels) _SenderLevel(level: level),
          ],
        ),
        if (badges.isNotEmpty) ...[
          SizedBox(height: RoomPublicChatTheme.badgeRunGap.h),
          Wrap(
            spacing: RoomPublicChatTheme.badgeGap.w,
            runSpacing: RoomPublicChatTheme.badgeRunGap.h,
            children: [
              for (final source in badges)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: RoomPublicChatTheme.badgeMaxWidth.w,
                  ),
                  child: SizedBox(
                    height: RoomPublicChatTheme.badgeHeight.h,
                    child: RoomPublicChatImage(source: source),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SenderGender extends StatelessWidget {
  const _SenderGender({required this.gender});
  final int gender;
  @override
  Widget build(BuildContext context) => Container(
    width: RoomPublicChatTheme.gender.r,
    height: RoomPublicChatTheme.gender.r,
    decoration: BoxDecoration(
      borderRadius: RoomPublicChatTheme.genderRadius,
      border: Border.all(
        color: gender == 1
            ? RoomPublicChatTheme.maleBorder
            : RoomPublicChatTheme.femaleBorder,
        width: RoomPublicChatTheme.genderBorder,
      ),
    ),
    child: Image.asset(
      gender == 1
          ? AppAssets.roomChatGenderMale
          : AppAssets.lanhuProfileHomepageGenderFemale,
    ),
  );
}

class _SenderLevel extends StatelessWidget {
  const _SenderLevel({required this.level});
  final RoomUserLevelBadge level;
  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minWidth: RoomPublicChatTheme.badgeMinWidth.w),
    height: RoomPublicChatTheme.badgeHeight.h,
    padding: EdgeInsetsDirectional.only(
      end: RoomPublicChatTheme.badgeNumberInset.w,
    ),
    decoration: BoxDecoration(
      borderRadius: RoomPublicChatTheme.levelRadius,
      gradient: switch (level.kind) {
        RoomUserLevelKind.wealth => RoomPublicChatTheme.wealthGradient,
        RoomUserLevelKind.charm => RoomPublicChatTheme.charmGradient,
        RoomUserLevelKind.active => RoomPublicChatTheme.activeGradient,
      },
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: RoomPublicChatTheme.badgeHeight.r,
          child: RoomPublicChatImage(source: level.icon),
        ),
        Text('${level.level}', style: RoomPublicChatTheme.level),
      ],
    ),
  );
}

/// Cached public artwork uses no authenticated HTTP headers.
class RoomPublicChatImage extends StatelessWidget {
  const RoomPublicChatImage({
    super.key,
    required this.source,
    this.fit = BoxFit.contain,
  });
  final String? source;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    Widget missing() =>
        Image.asset(AppAssets.lanhuRoomIconMissing, fit: BoxFit.contain);
    if (source?.startsWith('assets/') == true) {
      return Image.asset(
        source!,
        fit: fit,
        errorBuilder: (_, __, ___) => missing(),
      );
    }
    final url = roomMediaUrl(source);
    return url == null
        ? missing()
        : CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            placeholder: (_, __) =>
                SizedBox.square(dimension: RoomPublicChatTheme.badgeHeight.r),
            errorWidget: (_, __, ___) => missing(),
          );
  }
}
