import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pag/pag.dart';
import 'package:project/classes/room/gift/effects/room_gift_asset_resolver.dart';
import 'package:project/classes/room/gift/effects/room_gift_effect_player.dart';
import 'package:project/classes/room/gift/effects/room_gift_playback_barrier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_pag_plugin');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets(
    'PAG exposes pending controller and binds events before onInit starts it',
    (tester) async {
      final pending = Completer<Object?>();
      PAGViewState? controller;
      var started = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'initPag') return pending.future;
        if (call.method == 'start') {
          expect(PAGViewState.callbackHandlers[31], isNotEmpty);
          PAGViewState.callbackHandlers[31]!.values.single!('onAnimationStart');
        }
        return null;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: PAGView.bytes(
            Uint8List.fromList([1]),
            width: 100,
            height: 100,
            onCreated: (value) => controller = value,
            onInit: () => controller!.start(),
            onAnimationStart: () => started++,
          ),
        ),
      );
      expect(controller, isNotNull);
      expect(started, 0);
      pending.complete({'textureId': 31, 'width': 100, 'height': 100});
      await tester.pumpAndSettle();
      expect(started, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(PAGViewState.callbackHandlers, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'removed PAG retains its lease through pending init and native release',
    (tester) async {
      final pendingInit = Completer<Object?>();
      final pendingRelease = Completer<void>();
      addTearDown(() {
        if (!pendingInit.isCompleted) {
          pendingInit.complete({'textureId': 1, 'width': 100, 'height': 100});
        }
        if (!pendingRelease.isCompleted) pendingRelease.complete();
      });
      var initialized = 0, started = 0;
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'initPag') {
          expect(call.arguments['autoPlay'], isFalse);
          final id = ++initialized;
          calls.add('init:$id');
          if (id == 1) return pendingInit.future;
          return {'textureId': id, 'width': 100, 'height': 100};
        }
        final id = call.arguments['textureId'];
        if (call.method == 'release') {
          calls.add('release:$id');
          if (id == 1) await pendingRelease.future;
        }
        if (call.method == 'start') {
          calls.add('start:$id');
          PAGViewState.callbackHandlers[id]!.values.single!('onAnimationStart');
        }
        return null;
      });
      final barrier = RoomGiftPlaybackBarrier();
      final choice = ValueNotifier(1);
      addTearDown(choice.dispose);
      final clip = RoomGiftAnimationResource(
        format: RoomGiftAnimationFormat.pag,
        videoMode: 1,
        bytes: Uint8List.fromList([1]),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: ValueListenableBuilder<int>(
              valueListenable: choice,
              builder: (_, value, __) => RoomGiftEffectPlayer(
                key: ValueKey(value),
                resource: clip,
                playbackBarrier: barrier,
                repeat: true,
                onEnd: () {},
                onStarted: () => started++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(initialized, 1);
      choice.value = 2;
      await tester.pumpAndSettle();
      expect(initialized, 1);
      pendingInit.complete({'textureId': 1, 'width': 100, 'height': 100});
      await tester.pumpAndSettle();
      expect(calls, ['init:1', 'release:1']);
      expect(started, 0);
      pendingRelease.complete();
      await tester.pumpAndSettle();
      expect(calls, ['init:1', 'release:1', 'init:2', 'start:2']);
      expect(started, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(PAGViewState.callbackHandlers, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
