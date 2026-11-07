import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/room_user_info.dart';
import '../../../theme/app_theme.dart';
import '../more/room_tools_widgets.dart';
import 'room_animated_artwork.dart';
import 'room_member_badges.dart';
import 'room_profile_widgets.dart';

class RoomMemberCardContent extends StatelessWidget {
  const RoomMemberCardContent({
    super.key,
    this.user,
    this.error,
    required this.own,
    required this.following,
    required this.saving,
    required this.loading,
    required this.onProfile,
    required this.onCopy,
    required this.onFollow,
    required this.onMessage,
    required this.onMention,
    required this.onGift,
    required this.onRetry,
    this.managementMenu,
  });
  final RoomUserInfo? user;
  final String? error;
  final bool own, following, saving, loading;
  final VoidCallback onProfile,
      onCopy,
      onFollow,
      onMessage,
      onMention,
      onGift,
      onRetry;
  final Widget? managementMenu;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      final height = math.min(
        RoomProfileTheme.memberHeight.h,
        math.max(0.0, constraints.maxHeight - keyboard),
      );
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: RoomProfileTheme.avatarLift.h,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RoomProfileTheme.cardGradient,
                    borderRadius: RoomProfileTheme.memberRadius,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              RoomProfileTheme.memberPadding.w,
                              (RoomProfileTheme.memberInfoTop -
                                      RoomProfileTheme.avatarLift)
                                  .h,
                              RoomProfileTheme.memberPadding.w,
                              RoomProfileTheme.mediumGap.h,
                            ),
                            children: [
                              if (loading)
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              if (error != null) ...[
                                Text(
                                  error!,
                                  textAlign: TextAlign.center,
                                  style: RoomProfileTheme.secondary,
                                ),
                                TextButton(
                                  onPressed: onRetry,
                                  child: Text(
                                    context.l10n.t('app.retry'),
                                    style: RoomProfileTheme.link,
                                  ),
                                ),
                              ],
                              if (user != null) ...[
                                _MemberIdentity(
                                  user: user!,
                                  onProfile: onProfile,
                                  onCopy: onCopy,
                                ),
                                if (!own) _interactionActions(context),
                              ],
                            ],
                          ),
                        ),
                        if (user != null)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              RoomProfileTheme.section.w,
                              0,
                              RoomProfileTheme.section.w,
                              RoomProfileTheme.giftBottom.h,
                            ),
                            child: _MemberGiftButton(
                              own: own,
                              onTap: own ? onProfile : onGift,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (user != null)
                Positioned(
                  top: RoomProfileTheme.avatarTop,
                  left:
                      (constraints.maxWidth - RoomProfileTheme.avatarFrame.r) /
                      2,
                  child: _MemberAvatar(user: user!, onTap: onProfile),
                ),
              if (managementMenu != null)
                PositionedDirectional(
                  top: RoomProfileTheme.avatarLift.h,
                  end: RoomProfileTheme.gap.w,
                  child: managementMenu!,
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _interactionActions(BuildContext context) => Row(
    children: [
      Expanded(
        child: _MemberAction(
          asset: AppAssets.roomMemberFollow,
          label: following
              ? toolText(context, 'Following', '已关注')
              : context.l10n.t('profile.follow'),
          onTap: saving ? null : onFollow,
        ),
      ),
      SizedBox(width: RoomProfileTheme.mediumGap.w),
      Expanded(
        child: _MemberAction(
          asset: AppAssets.roomMemberChat,
          label: toolText(context, 'Chat', '私聊'),
          onTap: onMessage,
        ),
      ),
      SizedBox(width: RoomProfileTheme.mediumGap.w),
      SizedBox(
        width: RoomProfileTheme.memberActionsHeight.w,
        child: _MemberAction(
          asset: AppAssets.roomMemberMention,
          label: '@',
          iconOnly: true,
          onTap: onMention,
        ),
      ),
    ],
  );
}

class _MemberIdentity extends StatelessWidget {
  const _MemberIdentity({
    required this.user,
    required this.onProfile,
    required this.onCopy,
  });
  final RoomUserInfo user;
  final VoidCallback onProfile, onCopy;

  @override
  Widget build(BuildContext context) {
    final data = user.userBase;
    final appearance = user.appearance;
    return Column(
      children: [
        InkWell(
          onTap: onProfile,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  data.nick,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RoomProfileTheme.title,
                ),
              ),
              if (data.gender == 1 || data.gender == 2) ...[
                SizedBox(width: RoomProfileTheme.smallGap.w),
                RoomProfileAsset(
                  asset: data.gender == 1
                      ? AppAssets.profileMaleIcon
                      : AppAssets.profileFemaleIcon,
                  size: RoomProfileTheme.gender.r,
                ),
              ],
              SizedBox(width: RoomProfileTheme.smallGap.w),
              RoomProfileCountry(code: data.countryCode),
            ],
          ),
        ),
        if (appearance.levels.isNotEmpty ||
            appearance.badges.isNotEmpty ||
            appearance.identityBadges.isNotEmpty) ...[
          SizedBox(height: RoomProfileTheme.gap.h),
          RoomMemberBadgeWall(appearance: appearance),
        ],
        SizedBox(height: RoomProfileTheme.mediumGap.h),
        if (data.userNo != null)
          InkWell(
            onTap: onCopy,
            child: SizedBox(
              height: RoomProfileTheme.touch.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'ID:${data.userNo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RoomProfileTheme.secondary,
                    ),
                  ),
                  SizedBox(width: RoomProfileTheme.gap.w),
                  RoomProfileAsset(
                    asset: AppAssets.roomMemberCopy,
                    size: RoomProfileTheme.smallIcon.r,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.user, required this.onTap});
  final RoomUserInfo user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox.square(
      dimension: RoomProfileTheme.avatarFrame.r,
      child: Stack(
        children: [
          Positioned.fill(
            left: RoomProfileTheme.avatarInset.r,
            right: RoomProfileTheme.avatarInset.r,
            top: RoomProfileTheme.avatarInset.r,
            bottom: RoomProfileTheme.avatarInset.r,
            child: ClipOval(
              child: RoomProfilePicture(url: user.userBase.avatar),
            ),
          ),
          if (user.appearance.frameUrl case final url?)
            Positioned.fill(
              child: IgnorePointer(
                child: RoomAnimatedArtwork(
                  url: url,
                  preview: user.appearance.framePreview,
                  repeat: true,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _MemberAction extends StatelessWidget {
  const _MemberAction({
    required this.asset,
    required this.label,
    required this.onTap,
    this.iconOnly = false,
  });
  final String asset, label;
  final VoidCallback? onTap;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) => Semantics(
    label: iconOnly ? label : null,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: RoomProfileTheme.actionRadius,
      child: Container(
        height: RoomProfileTheme.memberActionsHeight.h,
        padding: EdgeInsets.symmetric(horizontal: RoomProfileTheme.smallGap.w),
        decoration: const BoxDecoration(
          color: RoomProfileTheme.actionSurface,
          borderRadius: RoomProfileTheme.actionRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoomProfileAsset(asset: asset, size: RoomProfileTheme.icon.r),
            if (!iconOnly) ...[
              SizedBox(width: RoomProfileTheme.smallGap.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RoomProfileTheme.action,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _MemberGiftButton extends StatelessWidget {
  const _MemberGiftButton({required this.own, required this.onTap});
  final bool own;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: RoomProfileTheme.pillRadius,
    child: Container(
      height: RoomProfileTheme.giftHeight.h,
      decoration: const BoxDecoration(
        gradient: RoomProfileTheme.giftGradient,
        borderRadius: RoomProfileTheme.pillRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!own) ...[
            RoomProfileAsset(
              asset: AppAssets.roomMemberGift,
              size: RoomProfileTheme.giftIcon.r,
            ),
            SizedBox(width: RoomProfileTheme.mediumGap.w),
          ],
          Text(
            own
                ? context.l10n.t('room.checkProfile')
                : toolText(context, 'Send Gift', '送礼'),
            style: RoomProfileTheme.button,
          ),
        ],
      ),
    ),
  );
}
