import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../model/room_user_info.dart';
import '../../../theme/app_theme.dart';
import 'room_profile_widgets.dart';

class RoomMemberBadgeWall extends StatelessWidget {
  const RoomMemberBadgeWall({super.key, required this.appearance});
  final RoomUserAppearance appearance;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: RoomProfileTheme.smallGap.w,
    runSpacing: RoomProfileTheme.smallGap.h,
    children: [
      for (final level in appearance.levels)
        Container(
          height: RoomProfileTheme.badgeHeight.h,
          padding: EdgeInsets.symmetric(
            horizontal: RoomProfileTheme.smallGap.w,
          ),
          decoration: BoxDecoration(
            borderRadius: RoomProfileTheme.pillRadius,
            gradient: switch (level.kind) {
              RoomUserLevelKind.wealth => RoomProfileTheme.wealthGradient,
              RoomUserLevelKind.charm => RoomProfileTheme.charmGradient,
              RoomUserLevelKind.active => RoomProfileTheme.activeGradient,
            },
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: RoomProfileTheme.badgeHeight.r,
                child: RoomProfilePicture(url: level.icon, fit: BoxFit.contain),
              ),
              SizedBox(width: RoomProfileTheme.smallGap.w),
              Text('${level.level}', style: RoomProfileTheme.tiny),
            ],
          ),
        ),
      for (final url in [...appearance.badges, ...appearance.identityBadges])
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: RoomProfileTheme.badgeMaxWidth.w,
          ),
          child: SizedBox(
            height: RoomProfileTheme.badgeHeight.h,
            child: RoomProfilePicture(url: url, fit: BoxFit.contain),
          ),
        ),
    ],
  );
}
