import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/chat/room_public_message_text.dart';
import 'package:project/classes/room/interaction/room_mention.dart';

void main() {
  testWidgets('system HTML shows a clickable user without source markup', (
    tester,
  ) async {
    final opened = <int>[];
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: RoomPublicMessageText(
                text:
                    '<p><a href="nady://?action=1&amp;uid=12594212">lihei</a></p>',
                system: true,
                onUserTap: opened.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('lihei', findRichText: true), findsOneWidget);
    await tester.tap(find.byType(RoomPublicMessageText));
    expect(opened, [12594212]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

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
