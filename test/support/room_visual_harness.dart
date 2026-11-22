import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pag/pag.dart';
import 'package:project/classes/room/gift/effects/room_gift_asset_resolver.dart';
import 'package:project/classes/room/gift/effects/room_gift_effect_layer.dart';
import 'package:project/classes/room/gift/effects/room_gift_effect_player.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/gift/event/room_gift_event_provider.dart';
import 'package:project/classes/room/gift/event/room_gift_room_id_provider.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/models/room_lucky_animation_policy.dart';
import 'package:project/classes/room/gift/views/room_entrance_track.dart';
import 'package:project/classes/room/gift/views/room_lucky_gift_layer.dart';
import 'package:project/classes/room/gift/views/room_mic_decorations.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/theme/app_theme.dart';

import 'precache_room_assets.dart';

/// Real room widgets and manager; only asset loading and native replies are fake.
class RoomVisualHarness extends RoomGiftAssetResolver {
  RoomVisualHarness() {
    manager = RoomGiftEventManager(
      roomId: 'local-visual',
      startTimer: false,
      now: () => now,
    );
  }
  late final RoomGiftEventManager manager;
  DateTime now = DateTime.now();
  final seats = ValueNotifier<List<RoomSeatViewData>>([]);
  final calls = <String>[];
  final markers = <int, int>{};
  final pendingInit = <int, Completer<Object?>>{};
  final pendingRelease = <int, Completer<void>>{};
  final pendingResources = <int, Completer<RoomGiftAnimationResource>>{};
  int _serial = 0, outsideTaps = 0;
  static const _channel = MethodChannel('flutter_pag_plugin');

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          if (call.method == 'initPag') {
            final marker = (call.arguments['bytesData'] as Uint8List).first;
            final texture = ++_serial;
            markers[texture] = marker;
            calls.add('init:$marker');
            if (pendingInit[marker] case final gate?) {
              await gate.future;
            }
            return {'textureId': texture, 'width': 100, 'height': 100};
          }
          final marker = markers[call.arguments['textureId']];
          calls.add('${call.method}:$marker');
          if (call.method == 'release') {
            await pendingRelease[marker]?.future;
            calls.add('released:$marker');
          }
          return null;
        });
  }

  void event(int marker, String event) {
    final ids = markers.entries.where((e) => e.value == marker).toList();
    expect(ids, isNotEmpty);
    final callbacks = PAGViewState.callbackHandlers[ids.last.key];
    expect(callbacks, isNotNull);
    for (final notify in callbacks!.values.toList()) {
      notify?.call(event);
    }
  }

  void setSeats(List<RoomSeatViewData> value) {
    manager.syncMicOccupants({
      for (final seat in value)
        if (seat.uid case final int uid) seat.position: uid,
    });
    seats.value = value;
  }

  @override
  Future<RoomGiftAnimationResource> resolveSource(
    String source, {
    RoomGiftAnimationFormat? format,
    int mode = 1,
  }) async {
    final marker = int.parse(
      Uri.parse(source).pathSegments.last.split('.').first,
    );
    return pendingResources[marker]?.future ?? clip(marker);
  }

  @override
  Future<RoomGiftAnimationResource> resolve(RoomGift gift) =>
      resolveSource(gift.animationUrl!);

  @override
  Future<RoomGiftAnimationResource?> resolveLucky(
    RoomLuckyGiftResult result, {
    required RoomLuckyBubbleConfig config,
    required int? currentUid,
  }) async => clip(7);

  RoomGiftAnimationResource clip(int marker) => RoomGiftAnimationResource(
    format: RoomGiftAnimationFormat.pag,
    videoMode: 1,
    bytes: Uint8List.fromList([marker]),
  );

  RoomSocketMessage entrance(String key, {bool car = true, int uid = 20}) =>
      RoomSocketMessage(
        channel: 'global',
        event: 'RoomUserPropInfoEvent',
        msgId: key,
        receivedAt: now,
        raw: const {},
        payload: {
          'roomId': 'local-visual',
          'userBaseInfo': {
            'uid': uid,
            'nick': 'QA $key العربية中文 long nickname',
            'specialEffects': {'animationUrl': 'https://qa.invalid/2.pag'},
            if (car) 'vehicle': {'animationUrl': 'https://qa.invalid/3.pag'},
          },
        },
      );

  RoomSocketMessage expression(String key, {int uid = 20}) => RoomSocketMessage(
    channel: 'room:local-visual',
    event: 'RoomScreenExpressionEvent',
    msgId: key,
    receivedAt: now,
    raw: const {},
    payload: {
      'roomId': 'local-visual',
      'from': {'uid': uid},
      'msg': {'dynamicPic': 'https://qa.invalid/5.pag', 'type': 1},
    },
  );

  RoomSocketMessage gift(
    String key, {
    bool magic = false,
    bool lucky = false,
  }) => RoomSocketMessage(
    channel: 'room:local-visual',
    event: 'roomScreenSendGiftComboEvent',
    msgId: key,
    receivedAt: now,
    raw: const {},
    payload: {
      'roomId': 'local-visual',
      'uid': 10,
      'userInfo': {'uid': 10, 'nick': 'LOCAL QA'},
      'gift': {
        'id': lucky ? 31 : 30,
        'name': 'LOCAL QA',
        'giftType': magic ? 2 : 0,
        if (!lucky) 'animationUrl': 'https://qa.invalid/${magic ? 4 : 6}.pag',
      },
      'uids': [20],
      'sendType': 1,
      'giftCount': 1,
      'comboId': key,
      'isLuckyGift': lucky,
      if (lucky) 'totalGiftCount': 10,
    },
  );

  Future<void> mount(WidgetTester tester, {double width = 375}) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomGiftEventManagerProvider(
            'local-visual',
          ).overrideWith((ref) => manager),
          roomGiftRoomIdProvider('').overrideWithValue('local-visual'),
          roomGiftAssetResolverProvider.overrideWithValue(this),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(
                    roomGiftEventManagerProvider('local-visual'),
                  );
                  return Stack(
                    children: [
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: TextButton(
                          onPressed: () => outsideTaps++,
                          child: const Text('Outside'),
                        ),
                      ),
                      ValueListenableBuilder<List<RoomSeatViewData>>(
                        valueListenable: seats,
                        builder: (_, value, __) => Stack(
                          children: [
                            for (final seat in value)
                              Positioned(
                                top: 20,
                                left: 20 + seat.position * 80,
                                width: 60,
                                height: 60,
                                child: RoomMicDecorations(seat: seat),
                              ),
                          ],
                        ),
                      ),
                      const Positioned(
                        top: 100,
                        left: 0,
                        right: 0,
                        child: RoomEntranceTrack(roomId: 'local-visual'),
                      ),
                      if (state.isVisible && state.canPlayFullscreen)
                        Positioned.fill(
                          child: RoomGiftFullScreenEffectLayer(
                            tasks: state.effects,
                            stopRequestedKey: state.stopEffectKey,
                            onStarted: manager.startEntranceVehicle,
                            onCompleted: manager.completeEffect,
                          ),
                        ),
                      if (state.isVisible &&
                          state.canPlayLucky &&
                          state.lucky.isNotEmpty)
                        Positioned.fill(
                          child: RoomLuckyGiftLayer(
                            key: ValueKey(state.lucky.first.key),
                            result: state.lucky.first,
                            currentUid: manager.currentUid,
                            stopRequested:
                                state.stopLuckyKey == state.lucky.first.key,
                            onEnd: () =>
                                manager.completeLucky(state.lucky.first.key),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await flush(tester);
    await precacheRoomAssets(tester, tester.element(find.byType(Scaffold)));
  }

  static Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump();
    }
  }

  List<int> activePlayers(WidgetTester tester) => tester
      .widgetList<RoomGiftEffectPlayer>(find.byType(RoomGiftEffectPlayer))
      .map((p) => p.resource.bytes!.first)
      .toList();

  Future<void> close(WidgetTester tester) async {
    for (final gate in pendingInit.values) {
      if (!gate.isCompleted) gate.complete();
    }
    for (final gate in pendingRelease.values) {
      if (!gate.isCompleted) gate.complete();
    }
    for (final entry in pendingResources.entries) {
      if (!entry.value.isCompleted) entry.value.complete(clip(entry.key));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await flush(tester);
    seats.dispose();
    if (manager.isAlive) manager.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }
}
