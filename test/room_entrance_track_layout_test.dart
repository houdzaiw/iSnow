import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/gift/event/room_gift_event_provider.dart';
import 'package:project/classes/room/gift/views/room_entrance_track.dart';
import 'package:project/model/room_socket_message.dart';

void main() {
  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('entrance nickname, text and outside taps fit $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final manager = RoomGiftEventManager(roomId: '123', startTimer: false);
      var taps = 0;
      manager.receive(
        const RoomSocketMessage(
          channel: 'global',
          event: 'RoomUserPropInfoEvent',
          msgId: 'entry',
          raw: {},
          payload: {
            'roomId': '123',
            'userBaseInfo': {
              'uid': 20,
              'nick': 'A very long nickname العربية中文',
              'vehicle': {'animationUrl': 'https://cdn.example/car.pag'},
            },
          },
        ),
      );
      manager.startEntranceVehicle('entrance:entry:vehicle');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomGiftEventManagerProvider('123').overrideWith((ref) => manager),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    const RoomEntranceTrack(roomId: '123'),
                    TextButton(
                      onPressed: () => taps++,
                      child: const Text('Outside'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Enter the room'), findsOneWidget);
      await tester.tap(find.text('Outside'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
      manager.completeEffect('entrance:entry:vehicle');
      await tester.pump();
      expect(find.text('Enter the room'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
