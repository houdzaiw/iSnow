import 'package:project/classes/room/gift/models/room_lucky_animation_policy.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pag/pag.dart';
import 'package:project/classes/room/gift/effects/room_gift_asset_resolver.dart';
import 'package:project/classes/room/gift/effects/room_gift_effect_layer.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/gift/event/room_gift_event_provider.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/views/room_gift_overlay.dart';
import 'package:project/classes/room/gift/trajectory/room_gift_seat_registry.dart';
import 'package:project/model/room_socket_message.dart';

import 'room_gift_effects_test.dart' show app, message;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_pag_plugin');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late RoomGiftEventManager manager;
  late Completer<void> release;
  late Completer<Map<String, dynamic>> initialize;
  var initialized = 0, released = 0, outsideTaps = 0;
  var delayInit = false;

  setUp(() {
    initialized = released = outsideTaps = 0;
    delayInit = false;
    manager = RoomGiftEventManager(roomId: '123', startTimer: false);
    manager.receive(message(id: 'first', giftId: 31));
    manager.receive(message(id: 'second', giftId: 32));
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'initPag') {
        initialized++;
        if (delayInit && initialized == 1) return initialize.future;
        return {'textureId': initialized, 'width': 100, 'height': 100};
      }
      if (call.method == 'release') {
        released++;
        if (released == 1) await release.future;
      }
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Widget scene() {
    release = Completer<void>();
    initialize = Completer<Map<String, dynamic>>();
    return app(
      Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(roomGiftEventManagerProvider('123'));
          return Stack(
            children: [
              Center(
                child: TextButton(
                  onPressed: () => outsideTaps++,
                  child: const Text('Outside'),
                ),
              ),
              Positioned.fill(
                child: RoomGiftFullScreenEffectLayer(
                  tasks: state.effects,
                  onCompleted: manager.completeEffect,
                  stopRequestedKey: state.stopEffectKey,
                ),
              ),
            ],
          );
        },
      ),
      manager: manager,
      resolver: _PagResolver(),
    );
  }

  testWidgets('loading PAG is not completion; close waits for native release', (
    tester,
  ) async {
    await tester.pumpWidget(scene());
    await tester.pumpAndSettle();
    expect(initialized, 1);
    expect(manager.snapshot.effects, hasLength(2));
    await tester.tap(find.text('Outside'));
    expect(outsideTaps, 1);
    final close = find.byKey(const ValueKey('room-gift-effect-close'));
    await tester.tap(close);
    await tester.pumpAndSettle();
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(released, 1);
    expect(initialized, 1);
    expect(manager.snapshot.effects.first.key, 'first');
    release.complete();
    await tester.pumpAndSettle();
    expect(manager.snapshot.effects.single.key, 'second');
    expect(initialized, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('prize preemption waits for the old decoder destruction', (
    tester,
  ) async {
    await tester.pumpWidget(scene());
    await tester.pumpAndSettle();
    final source = manager.snapshot.effects.last.message;
    manager.enqueueFullscreen(
      RoomGiftEffectTask(
        key: 'prize',
        createdAt: DateTime.now(),
        kind: RoomGiftEffectKind.prize,
        message: RoomScreenGiftMsg(
          gift: source.gift,
          uid: source.uid,
          userInfo: source.userInfo,
          comboId: 'prize',
          giftCount: 1,
          roomId: '123',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(released, 1);
    expect(initialized, 1);
    expect(manager.snapshot.effects.first.key, 'first');
    release.complete();
    await tester.pumpAndSettle();
    expect(manager.snapshot.effects.first.key, 'prize');
    expect(initialized, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('numeric to full-screen handover waits for native release', (
    tester,
  ) async {
    manager.reset(clearHistory: true);
    final original = message(id: 'lucky', giftId: 31);
    final data = Map<String, dynamic>.from(original.payload as Map);
    data['isLuckyGift'] = true;
    data['totalGiftCount'] = 10;
    data['gift'] = {
      ...Map<String, dynamic>.from(data['gift'] as Map),
      'animationUrl': '',
    };
    manager.receive(
      RoomSocketMessage(
        channel: original.channel,
        event: original.event,
        payload: data,
        raw: const {},
        msgId: original.msgId,
        timestamp: original.timestamp,
        receivedAt: original.receivedAt,
      ),
    );
    release = Completer<void>();
    initialize = Completer<Map<String, dynamic>>();
    final root = GlobalKey();
    final registry = RoomGiftSeatRegistry(root);
    await tester.pumpWidget(
      app(
        Stack(
          key: root,
          children: [
            Positioned.fill(
              child: RoomGiftOverlay(roomId: '123', registry: registry),
            ),
          ],
        ),
        manager: manager,
        registry: registry,
        resolver: _PagResolver(),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }
    expect(initialized, 1);
    manager.receive(message(id: 'full', giftId: 32));
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }
    expect(released, 1);
    expect(initialized, 1);
    expect(manager.snapshot.canPlayFullscreen, isFalse);
    release.complete();
    await tester.pumpAndSettle();
    expect(initialized, 2);
    expect(manager.snapshot.canPlayFullscreen, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('close during init releases the late texture before handover', (
    tester,
  ) async {
    delayInit = true;
    await tester.pumpWidget(scene());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room-gift-effect-close')));
    await tester.pumpAndSettle();
    expect(initialized, 1);
    expect(released, 0);
    initialize.complete({'textureId': 1, 'width': 100, 'height': 100});
    await tester.pumpAndSettle();
    expect(released, 1);
    expect(initialized, 1);
    release.complete();
    await tester.pumpAndSettle();
    expect(initialized, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'release failure holds the queue while external room controls work',
    (tester) async {
      await tester.pumpWidget(scene());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room-gift-effect-close')));
      await tester.pumpAndSettle();
      release.completeError(PlatformException(code: 'release_failed'));
      await tester.pumpAndSettle();
      expect(initialized, 1);
      expect(manager.snapshot.effects, hasLength(2));
      expect(find.textContaining('Unable to release'), findsOneWidget);
      await tester.tap(find.text('Outside'));
      expect(outsideTaps, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving during release never starts the old next task', (
    tester,
  ) async {
    await tester.pumpWidget(scene());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room-gift-effect-close')));
    await tester.pumpWidget(const SizedBox());
    release.complete();
    await tester.pumpAndSettle();
    expect(initialized, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'entrance track starts on native callback, not texture initialization',
    (tester) async {
      manager.reset(clearHistory: true);
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
              'specialEffects': {
                'animationUrl': 'https://cdn.example/entry.svga',
              },
              'vehicle': {'animationUrl': 'https://cdn.example/car.pag'},
            },
          },
        ),
      );
      release = Completer<void>();
      initialize = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(
        app(
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(roomGiftEventManagerProvider('123'));
              return RoomGiftFullScreenEffectLayer(
                tasks: state.effects,
                onCompleted: manager.completeEffect,
                onStarted: manager.startEntranceVehicle,
              );
            },
          ),
          manager: manager,
          resolver: _PagResolver(),
        ),
      );
      await tester.pumpAndSettle();
      expect(initialized, 1);
      expect(manager.snapshot.entrance, isNull);
      final notify = PAGViewState.callbackHandlers[1]!.values.single!;
      notify('onAnimationStart');
      await tester.pump();
      expect(manager.snapshot.entrance!.key, 'entrance:entry');
      notify('onAnimationStart');
      await tester.pump();
      expect(manager.snapshot.entrance!.key, 'entrance:entry');
      release.complete();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

class _PagResolver extends RoomGiftAssetResolver {
  @override
  Future<RoomGiftAnimationResource?> resolveLucky(
    RoomLuckyGiftResult result, {
    required RoomLuckyBubbleConfig config,
    required int? currentUid,
  }) async => resolve(RoomGiftAssetResolver.luckyAnimation(result));

  @override
  Future<RoomGiftAnimationResource> resolve(RoomGift gift) async =>
      RoomGiftAnimationResource(
        format: RoomGiftAnimationFormat.pag,
        videoMode: 1,
        bytes: Uint8List.fromList([1]),
      );
}
