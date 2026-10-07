import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/gift/effects/room_gift_asset_resolver.dart';
import 'package:project/classes/room/gift/effects/room_gift_effect_layer.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/gift/event/room_gift_event_provider.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/trajectory/room_gift_seat_registry.dart';
import 'package:project/classes/room/gift/trajectory/room_gift_trajectory_layer.dart';
import 'package:project/classes/room/gift/trajectory/room_gift_trajectory_task.dart';
import 'package:project/classes/room/gift/views/room_gift_image.dart';
import 'package:project/classes/room/gift/views/room_gift_overlay.dart';
import 'package:project/classes/room/gift/views/room_gift_slot_layer.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/theme/app_theme.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('animation resolver preserves query URL, type and orientation', () {
    final gift = sample().message.gift;
    expect(
      RoomGiftAssetResolver.formatFor(
        gift.copyWith(animationUrl: 'https://cdn.test/x.PAG?v=1'),
      ),
      RoomGiftAnimationFormat.pag,
    );
    expect(
      RoomGiftAssetResolver.formatFor(
        gift.copyWith(animationUrl: 'https://cdn.test/x.mp4?v=1'),
      ),
      RoomGiftAnimationFormat.vap,
    );
    final mp4 = RoomGift.fromJson({
      'id': 1,
      'animationUrl': 'https://cdn.test/x.mp4',
      'animationType': 6,
    }, fallbackTabId: 0);
    expect(RoomGiftAssetResolver.formatFor(mp4), RoomGiftAnimationFormat.mp4);
    expect(gift, gift.copyWith());
    expect(gift.hashCode, gift.copyWith().hashCode);
  });

  test(
    'SVGA decoder compiles and decodes the Nady fixture with protobuf 6',
    () async {
      final movie = await SVGAParser.shared.decodeFromBuffer(
        await File('test/fixtures/room_gift_sample.svga').readAsBytes(),
      );
      expect(movie.params.frames, greaterThan(0));
      expect(movie.params.fps, greaterThan(0));
      movie.dispose();
    },
  );

  test(
    'trajectory splits only registered targets and uses fresh coordinates',
    () {
      final coordinates = <int, RoomGiftSeatCoordinate>{
        10: const RoomGiftSeatCoordinate(
          uid: 10,
          position: 0,
          offset: Offset(10, 20),
        ),
        20: const RoomGiftSeatCoordinate(
          uid: 20,
          position: 1,
          offset: Offset(100, 20),
        ),
      };
      final tasks = RoomGiftTrajectoryTask.fromEvent(
        sample(),
        (uid) => coordinates[uid],
      );
      expect(tasks, hasLength(1));
      expect(tasks.single.target.uid, 20);
      coordinates[20] = const RoomGiftSeatCoordinate(
        uid: 20,
        position: 2,
        offset: Offset(200, 40),
      );
      expect(
        RoomGiftTrajectoryTask.fromEvent(
          sample(),
          (uid) => coordinates[uid],
        ).single.target.offset,
        const Offset(200, 40),
      );
      coordinates.remove(10);
      expect(
        RoomGiftTrajectoryTask.fromEvent(sample(), (uid) => coordinates[uid]),
        isEmpty,
      );
    },
  );

  testWidgets(
    'trajectory completes and cancels after a seat moves or is removed',
    (tester) async {
      final root = GlobalKey();
      final registry = RoomGiftSeatRegistry(root);
      var consumed = 0;
      Widget scene({double left = 200, bool target = true}) => app(
        Stack(
          key: root,
          children: [
            Positioned(
              left: 20,
              top: 80,
              child: RoomGiftSeatAnchor(
                uid: 10,
                position: 0,
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
            if (target)
              Positioned(
                left: left,
                top: 80,
                child: RoomGiftSeatAnchor(
                  uid: 20,
                  position: 1,
                  child: const SizedBox(width: 40, height: 40),
                ),
              ),
            Positioned.fill(
              child: RoomGiftTrajectoryLayer(
                events: [sample()],
                registry: registry,
                onConsumed: (_) => consumed++,
              ),
            ),
          ],
        ),
        registry: registry,
      );
      await tester.pumpWidget(scene());
      await tester.pump(const Duration(milliseconds: 200));
      expect(consumed, 1);
      expect(find.byType(RoomGiftImage), findsOneWidget);
      await tester.pumpWidget(scene(left: 220));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.byType(RoomGiftImage), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed animation advances the full-screen queue; completion releases next',
    (tester) async {
      final manager = RoomGiftEventManager(roomId: '123', startTimer: false);
      manager.receive(message(id: 'broken', giftId: 31));
      manager.receive(message(id: 'next', giftId: 32));
      await tester.pumpWidget(
        app(
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(roomGiftEventManagerProvider('123'));
              return Stack(
                children: [
                  Positioned.fill(
                    child: RoomGiftFullScreenEffectLayer(
                      tasks: state.effects,
                      onCompleted: manager.completeEffect,
                    ),
                  ),
                ],
              );
            },
          ),
          manager: manager,
          resolver: _Resolver(failId: 31),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(manager.state.effects, hasLength(1));
      expect(manager.state.effects.single.message.gift.id, 32);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(manager.state.effects, isEmpty);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 375.0]) {
    testWidgets(
      'gift layers fit ${width.toInt()}px and clear when backgrounded',
      (tester) async {
        tester.view.physicalSize = Size(width, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final manager = RoomGiftEventManager(roomId: '123', startTimer: false);
        manager.receive(
          message(id: 'gift', name: 'A very long gift name and sender name'),
        );
        final root = GlobalKey();
        final registry = RoomGiftSeatRegistry(root);
        await tester.pumpWidget(
          app(
            Consumer(
              builder: (context, ref, _) {
                final gifts = ref.watch(roomGiftEventManagerProvider('123'));
                return RepaintBoundary(
                  key: const ValueKey('gift-effects'),
                  child: Stack(
                    key: root,
                    children: [
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 260,
                        child: RoomGiftSlotLayer(
                          slots: gifts.slots,
                          roomId: '123',
                        ),
                      ),
                      Positioned.fill(
                        child: RoomGiftOverlay(
                          roomId: '123',
                          registry: registry,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            registry: registry,
            manager: manager,
            resolver: _Resolver(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('x1'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('gift-effects')),
          matchesGoldenFile('goldens/room_gift_effects_${width.toInt()}.png'),
        );
        manager.setVisible(false);
        await tester.pump();
        expect(find.byType(RoomGiftImage), findsNothing);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }
}

RoomGiftEffectTask sample() => RoomGiftEffectTask(
  key: 'event',
  createdAt: DateTime.now(),
  message: RoomScreenGiftMsg(
    gift: const RoomGift(
      id: 31,
      name: 'Rose',
      icon: AppAssets.lanhuRoomBottomGift,
      price: 20,
      isCombo: 1,
      tabId: 1,
    ),
    uid: 10,
    userInfo: const RoomGiftUser(uid: 10),
    giftCount: 1,
    uids: const [20, 30],
  ),
);

RoomSocketMessage message({
  required String id,
  int giftId = 31,
  String name = 'Rose',
}) => RoomSocketMessage(
  channel: 'room:123',
  event: 'roomScreenSendGiftComboEvent',
  msgId: id,
  raw: const {},
  payload: {
    'roomId': '123',
    'uid': 10,
    'userInfo': {
      'uid': 10,
      'nick': name,
      'avatar': AppAssets.lanhuRoomAvatarSample,
    },
    'gift': {
      'id': giftId,
      'name': name,
      'icon': AppAssets.lanhuRoomBottomGift,
      'animationUrl': 'https://cdn.test/a.svga',
    },
    'giftCount': 1,
    'comboId': id,
    'sendType': 6,
    'uids': [20, 30],
  },
);

Widget app(
  Widget child, {
  RoomGiftSeatRegistry? registry,
  RoomGiftEventManager? manager,
  RoomGiftAssetResolver? resolver,
}) => ProviderScope(
  overrides: [
    if (manager != null)
      roomGiftEventManagerProvider('123').overrideWith((ref) => manager),
    if (resolver != null)
      roomGiftAssetResolverProvider.overrideWithValue(resolver),
  ],
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.giftBannerBackground,
        body: registry == null
            ? child
            : RoomGiftSeatScope(registry: registry, child: child),
      ),
    ),
  ),
);

class _Resolver extends RoomGiftAssetResolver {
  _Resolver({this.failId});
  final int? failId;
  @override
  Future<RoomGiftAnimationResource> resolve(RoomGift gift) async {
    if (gift.id == failId) throw const FormatException('Missing animation');
    return const RoomGiftAnimationResource(
      format: RoomGiftAnimationFormat.native,
      videoMode: 1,
    );
  }
}
