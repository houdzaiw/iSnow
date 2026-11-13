import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/chat/room_public_message_text.dart';
import 'package:project/classes/room/interaction/room_mention.dart';

void main() {
  testWidgets(
    'a room update during a mention tap retains the gesture and current callback',
    (tester) async {
      final calls = <String>[];
      var revision = 0;
      late StateSetter update;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (_, setState) {
                  update = setState;
                  final currentRevision = revision;
                  return Center(
                    child: RoomPublicMessageText(
                      text: encodeRoomMention('@Friend', (
                        uid: 31,
                        name: 'Friend',
                      )),
                      onUserTap: (uid) => calls.add('$uid:$currentRevision'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(RoomPublicMessageText)),
      );
      update(() => revision++);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(calls, ['31:1']);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
