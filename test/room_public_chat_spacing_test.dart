import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/chat/room_public_message.dart';
import 'package:project/model/room_user_info.dart';
import 'package:project/theme/app_theme.dart';

import 'support/precache_room_assets.dart';

void main() {
  for (final width in [320.0, 375.0, 430.0]) {
    for (final rtl in [false, true]) {
      for (final decoration in ['none', 'level', 'multiline']) {
        testWidgets('compact $decoration sender at $width, rtl=$rtl', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          final appearance = switch (decoration) {
            'level' => const RoomUserAppearance(
              levels: [
                RoomUserLevelBadge(
                  kind: RoomUserLevelKind.wealth,
                  level: 3,
                  icon: AppAssets.lanhuProfileHomepageWealth,
                ),
              ],
            ),
            'multiline' => RoomUserAppearance(
              badges: List.filled(30, AppAssets.membershipVipBadge),
            ),
            _ => const RoomUserAppearance(),
          };
          await tester.pumpWidget(
            ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, __) => MaterialApp(
                home: Scaffold(
                  body: Directionality(
                    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                    child: ListView(
                      children: [
                        RoomPublicMessageFrame(
                          name: 'Peer',
                          avatar: AppAssets.lanhuRoomAvatarSample,
                          avatarKey: const ValueKey('sender-avatar'),
                          appearance: appearance,
                          child: Text('Hi', style: RoomPublicChatTheme.body),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await precacheRoomAssets(
            tester,
            tester.element(find.byType(Scaffold)),
          );
          final avatar = tester.getRect(
            find.byKey(const ValueKey('sender-avatar')),
          );
          final identity = tester.getRect(
            find.byKey(const ValueKey('room-public-sender-identity')),
          );
          final bubble = tester.getRect(
            find.byKey(const ValueKey('room-public-message-bubble')),
          );
          expect(identity.top, closeTo(avatar.top, 0.01));
          expect(
            bubble.top - identity.bottom,
            closeTo(RoomPublicChatTheme.bodyGap.h, 0.01),
          );
          expect(
            rtl ? bubble.right : bubble.left,
            closeTo(rtl ? identity.right : identity.left, 0.01),
          );
          expect(
            rtl ? avatar.left - identity.right : identity.left - avatar.right,
            closeTo(RoomPublicChatTheme.avatarGap.w, 0.01),
          );
          expect(
            bubble.width,
            lessThanOrEqualTo(RoomPublicChatTheme.bubbleMaxWidth.w),
          );
          if (decoration == 'multiline') {
            expect(identity.height, greaterThan(avatar.height));
            expect(bubble.top, greaterThan(avatar.bottom));
          } else {
            // Short identity blocks no longer wait for the avatar's bottom.
            expect(bubble.top, lessThan(avatar.bottom));
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
