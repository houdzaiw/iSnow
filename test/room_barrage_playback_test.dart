import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pag/pag.dart';
import 'package:project/classes/room/barrage/room_barrage_banner.dart';
import 'package:project/classes/room/barrage/room_barrage_models.dart';
import 'package:project/classes/room/gift/effects/room_gift_asset_resolver.dart';

void main() {
  const channel = MethodChannel('flutter_pag_plugin');
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'banner completion waits for native release before rendering next',
    (tester) async {
      final release = Completer<void>();
      var initialized = 0, released = 0, completed = 0, presented = 0;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'initPag') {
          return {'textureId': ++initialized, 'width': 100, 'height': 100};
        }
        if (call.method == 'release') {
          if (++released == 1) await release.future;
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      RoomBarragePrepared task(int id) => RoomBarragePrepared(
        RoomBarrageTask(
          key: '$id',
          kind: RoomBarrageKind.gift,
          createdAt: DateTime.now(),
          texts: const {'en': 'Gift'},
        ),
        background: RoomGiftAnimationResource(
          format: RoomGiftAnimationFormat.pag,
          videoMode: 1,
          bytes: Uint8List.fromList([1]),
        ),
      );
      var current = task(1);
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) => RoomBarrageBanner(
                    key: ValueKey(current.task.key),
                    prepared: current,
                    onPresented: () => presented++,
                    onTap: () {},
                    onEnd: () {
                      completed++;
                      setState(() => current = task(2));
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(initialized, 1);
      expect(presented, 0);
      PAGViewState.callbackHandlers[1]!.values.single!('onAnimationStart');
      await tester.pump();
      expect(presented, 1);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(released, 1);
      expect(completed, 0);
      expect(initialized, 1);
      release.complete();
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(initialized, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
