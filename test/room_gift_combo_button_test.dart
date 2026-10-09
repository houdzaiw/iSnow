import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/gift/event/room_gift_event_provider.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/trajectory/room_gift_seat_registry.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_send_controller.dart';
import 'package:project/classes/room/gift/views/room_gift_combo_button.dart';
import 'package:project/classes/room/gift/views/room_gift_overlay.dart';
import 'package:project/classes/room/gift/views/room_gift_slot_layer.dart';

import 'room_gift_events_test.dart' show payload, socket;

const gift = RoomGift(
  id: 31,
  name: 'Rose',
  icon: '',
  price: 20,
  isCombo: 1,
  tabId: 1,
);
const catalog = RoomGiftCatalog(
  balance: 1000,
  canSendSelf: true,
  tabs: [
    RoomGiftTab(id: 1, name: 'Popular', gifts: [gift]),
  ],
);
const request = SendRoomGiftRequest(
  targetUids: [20, 30],
  sendType: RoomGiftSendType.multi,
  roomId: '123',
  giftId: 31,
  giftCount: 1,
  giftSource: 1,
  comboId: '',
  comboCount: 1,
  price: 20,
);

void main() {
  for (final width in [320.0, 375.0]) {
    testWidgets('HTTP alone exposes a tappable combo at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository();
      final sender = RoomGiftSendController(repository, '123');
      final manager = RoomGiftEventManager(roomId: '123', startTimer: false);
      await sender.send(
        request: request,
        gift: gift,
        targetCount: 2,
        catalog: catalog,
      );
      await tester.pumpWidget(scene(sender, manager));
      await tester.pump();
      final button = find.byKey(const ValueKey('room-gift-confirmed-combo'));
      expect(button, findsOneWidget);
      expect(tester.getRect(button).right, lessThanOrEqualTo(width));
      expect(manager.snapshot.publicMessages, isEmpty);
      expect(manager.snapshot.effects, isEmpty);
      expect(manager.snapshot.flights, isEmpty);
      repository.pending = Completer();
      await tester.tap(find.text('Combo'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(repository.requests, hasLength(2));
      expect(repository.requests.last.comboId, 'server-combo');
      expect(repository.requests.last.comboCount, 1);
      repository.pending!.complete(
        const RoomGiftSendResult(comboId: 'server-combo'),
      );
      await tester.pump();
      expect(find.text('Combo'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(button, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'matching socket slot replaces the standalone combo without duplicates',
    (tester) async {
      final sender = RoomGiftSendController(_Repository(), '123');
      final manager = RoomGiftEventManager(roomId: '123', startTimer: false);
      await sender.send(
        request: request,
        gift: gift,
        targetCount: 2,
        catalog: catalog,
      );
      await tester.pumpWidget(scene(sender, manager));
      await tester.pump();
      expect(find.byType(RoomGiftComboButton), findsOneWidget);
      manager.receive(
        socket({
          ...payload(combo: 'server-combo'),
          'gift': {'id': 31, 'name': 'Rose', 'isCombo': 1},
        }, id: 'echo'),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('room-gift-confirmed-combo')),
        findsNothing,
      );
      expect(find.byType(RoomGiftComboButton), findsOneWidget);
      expect(manager.snapshot.publicMessages, hasLength(1));
      expect(find.text('x1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Widget scene(RoomGiftSendController sender, RoomGiftEventManager manager) {
  final root = GlobalKey();
  final registry = RoomGiftSeatRegistry(root);
  return ProviderScope(
    overrides: [
      roomGiftSendControllerProvider('123').overrideWith((ref) => sender),
      roomGiftEventManagerProvider('123').overrideWith((ref) => manager),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(roomGiftEventManagerProvider('123'));
              return Stack(
                key: root,
                children: [
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 260,
                    child: RoomGiftSlotLayer(slots: state.slots, roomId: '123'),
                  ),
                  Positioned.fill(
                    child: RoomGiftOverlay(roomId: '123', registry: registry),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _Repository extends RoomGiftRepository {
  final List<SendRoomGiftRequest> requests = [];
  Completer<RoomGiftSendResult>? pending;
  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async {
    requests.add(request);
    return pending == null
        ? const RoomGiftSendResult(comboId: 'server-combo')
        : await pending!.future;
  }

  @override
  Future<RoomGiftCatalog> fetchCatalog() async => catalog;
  @override
  Future<int> fetchBalance() async => catalog.balance;
  @override
  void recordGiftSent({
    required RoomGift gift,
    required int totalCount,
    required int balance,
  }) {}
}
