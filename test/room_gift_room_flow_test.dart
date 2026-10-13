import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:project/classes/room/gift/event/room_gift_event_provider.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_send_controller.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_view_model.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_state.dart';
import 'package:project/classes/room/gift/views/room_gift_combo_button.dart';
import 'package:project/classes/room/gift/views/room_gift_sheet.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/manager/app_socket_manager.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/model/room_models.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/user_profile.dart';
import 'package:project/theme/app_theme.dart';

import 'support/precache_room_assets.dart';

const _gift = RoomGift(
  id: 31,
  name: '88',
  icon: AppAssets.lanhuRoomBottomGift,
  price: 5,
  isCombo: 1,
  tabId: 1,
);
const _catalog = RoomGiftCatalog(
  balance: 10000,
  canSendSelf: true,
  tabs: [
    RoomGiftTab(id: 1, name: 'Popular', gifts: [_gift]),
  ],
);

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(
        File(
          'test/fixtures/fonts/Roboto-Regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await font.load();
  });
  // HTTP acknowledgement IDs from the four supplied Nady logs. Broadcasts
  // below are contract fixtures, not fabricated captures from those logs.
  final cases = [
    (
      name: 'own-empty',
      owner: 10,
      seats: <int>[],
      combo: '2026101107494134555285',
    ),
    (
      name: 'other-empty',
      owner: 20,
      seats: <int>[],
      combo: '2026101107510243813091',
    ),
    (
      name: 'own-occupied',
      owner: 10,
      seats: [10, 20],
      combo: '2026101107580728023988',
    ),
    (
      name: 'other-occupied',
      owner: 20,
      seats: [20, 30],
      combo: '2026101108042012777946',
    ),
  ];
  for (final width in [320.0, 375.0, 430.0]) {
    for (final scenario in cases) {
      testWidgets(
        'room -> panel -> HTTP -> combo -> socket ${scenario.name} at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final room = _RoomRepository(scenario.owner, scenario.seats);
          final gifts = _GiftRepository(scenario.combo);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                roomRepositoryProvider.overrideWithValue(room),
                roomGiftRepositoryProvider.overrideWithValue(gifts),
              ],
              child: ScreenUtilInit(
                designSize: const Size(375, 812),
                builder: (_, __) => const MaterialApp(
                  localizationsDelegates: [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: [Locale('en')],
                  home: RepaintBoundary(
                    key: ValueKey('room-flow'),
                    child: RoomPage(roomId: 'route-alias'),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();
          await precacheRoomAssets(
            tester,
            tester.element(find.byType(RoomPage)),
          );
          final container = ProviderScope.containerOf(
            tester.element(find.byType(RoomPage)),
          );
          final runtime = container.read(
            roomGiftEventManagerProvider('canonical').notifier,
          );
          expect(runtime.snapshot.isVisible, isTrue);
          await tester.tap(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Image &&
                  widget.image is AssetImage &&
                  (widget.image as AssetImage).assetName ==
                      AppAssets.lanhuRoomBottomGift,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump();
          expect(find.byType(RoomGiftSheet), findsOneWidget);
          expect(
            container.read(roomGiftViewModelProvider('canonical')).status,
            RoomGiftLoadStatus.ready,
          );
          await tester.tap(find.text('Send'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump();
          expect(find.byType(RoomGiftSheet), findsNothing);
          expect(find.byType(SnackBar), findsNothing);
          expect(find.text('Gift sent'), findsNothing);
          final combo = find.byKey(const ValueKey('room-gift-confirmed-combo'));
          expect(combo, findsOneWidget);
          expect(find.byType(RoomGiftComboButton), findsOneWidget);
          expect(tester.getCenter(combo).dx, closeTo(width / 2, 0.1));
          expect(gifts.requests.single.roomId, 'canonical');
          final sender = container.read(
            roomGiftSendControllerProvider('canonical').notifier,
          );
          expect(sender.snapshot.comboId, scenario.combo);

          room.socket = const AppSocketState(
            status: AppSocketStatus.ready,
            roomChannelSubscribed: true,
          );
          room.notifyListeners();
          room.socket = const AppSocketState(
            status: AppSocketStatus.connecting,
          );
          room.notifyListeners();
          await tester.pump();
          expect(combo, findsOneWidget);

          final targetUids = scenario.seats.isEmpty
              ? [scenario.owner]
              : scenario.seats;
          room.emit('roomScreenSendGiftComboEvent', {
            'roomId': 'canonical',
            'uid': 10,
            'userInfo': {'uid': 10, 'nick': 'Sender'},
            'gift': {'id': 31, 'name': '88', 'icon': _gift.icon, 'isCombo': 1},
            'count': 1,
            'giftCount': 1,
            'comboCount': 1,
            'giftSource': 1,
            'sendType': gifts.requests.single.sendType.value,
            'uids': targetUids,
            'comboId': scenario.combo,
          }, 'animation');
          await tester.pump();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(
            find.byKey(const ValueKey('gift-reveal-animation')),
            findsOneWidget,
          );
          if (width == 375 && scenario.name.startsWith('other')) {
            await expectLater(
              find.byKey(const ValueKey('room-flow')),
              matchesGoldenFile(
                'goldens/room_flow_${scenario.name}_reveal.png',
              ),
            );
          }
          await tester.pump(const Duration(milliseconds: 650));
          if (scenario.seats.isEmpty) {
            for (var i = 0; i < 8; i++) {
              expect(
                find.byKey(ValueKey('gift-flight-animation:scatter:$i')),
                findsOneWidget,
              );
            }
          } else {
            for (final uid in targetUids) {
              expect(
                find.byKey(ValueKey('gift-flight-animation:$uid:0')),
                findsOneWidget,
              );
            }
          }
          room.emit(
            'RoomSendGiftComboPublicScreenEvent',
            jsonEncode({
              'from': {'uid': 10, 'nick': 'Sender'},
              'msg': jsonEncode({
                'giftId': 31,
                'giftName': '{"en":"88"}',
                'giftIcon': _gift.icon,
                'giftNum': 1,
                'comboTimes': 1,
                'sendType': gifts.requests.single.sendType.value,
                'isCombo': 1,
                'isLucky': true,
                'winAmount': 150,
              }),
            }),
            'public',
          );
          await tester.pump();
          expect(
            find.text(
              scenario.seats.isEmpty
                  ? 'sent all room 88 x1'
                  : 'sent all mic 88 x1',
            ),
            findsOneWidget,
          );
          expect(find.text('win 150 coins'), findsOneWidget);
          expect(combo, findsOneWidget);
          if (width == 375 && scenario.name.startsWith('other')) {
            await expectLater(
              find.byKey(const ValueKey('room-flow')),
              matchesGoldenFile(
                'goldens/room_flow_${scenario.name}_flight.png',
              ),
            );
          }
          await tester.tap(combo);
          await tester.pump();
          expect(gifts.requests.last.comboId, scenario.combo);
          expect(gifts.requests.last.comboCount, 1);
          expect(gifts.requests, hasLength(2));
          expect(find.text('5.0s'), findsOneWidget);
          await tester.pump(const Duration(seconds: 6));
          await tester.pump();
          expect(combo, findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          room.room = const RoomState();
          room.notifyListeners();
          await tester.pump();
          await room.messages.close();
          room.dispose();
        },
      );
    }
  }
}

class _GiftRepository extends RoomGiftRepository {
  _GiftRepository(this.comboId);
  final String comboId;
  final requests = <SendRoomGiftRequest>[];
  @override
  RoomGiftCatalog get cachedCatalog => _catalog;
  @override
  Future<RoomGiftCatalog> fetchCatalog() async => _catalog;
  @override
  Future<int> fetchBalance() async => _catalog.balance;
  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async {
    requests.add(request);
    return RoomGiftSendResult.fromJson(comboId);
  }

  @override
  void recordGiftSent({
    required RoomGift gift,
    required int totalCount,
    required int balance,
  }) {}
}

class _RoomRepository extends ChangeNotifier implements RoomRepository {
  _RoomRepository(int owner, List<int> seats) {
    room = RoomState(
      currentRoomId: 'canonical',
      isInRoom: true,
      status: RoomStatus.ready,
      roomInfo: RoomInfo(
        roomId: 'canonical',
        raw: const {},
        title: 'Room',
        roomOwnerUid: owner,
        audienceCount: seats.isEmpty ? 1 : 3,
      ),
      micList: [
        for (var i = 0; i < 4; i++)
          RoomMicModel(
            position: i,
            raw: const {},
            uid: i < seats.length ? seats[i] : null,
            userInfo: i < seats.length
                ? {'uid': seats[i], 'nick': 'User ${seats[i]}'}
                : null,
          ),
      ],
    );
  }
  late RoomState room;
  AppSocketState socket = const AppSocketState();
  final messages = StreamController<RoomSocketMessage>.broadcast(sync: true);
  void emit(String event, Object payload, String id) => messages.add(
    RoomSocketMessage(
      channel: 'room:canonical',
      event: event,
      payload: payload,
      raw: const {},
      msgId: id,
      timestamp: DateTime.now()
          .subtract(const Duration(hours: 12))
          .millisecondsSinceEpoch,
      receivedAt: DateTime.now(),
    ),
  );
  @override
  Stream<RoomSocketMessage> get socketMessages => messages.stream;
  @override
  RoomState get roomState => room;
  @override
  AppSocketState get socketState => socket;
  @override
  RoomAgoraState get agoraState => const RoomAgoraState();
  @override
  Future<int?> currentUid() async => 10;
  @override
  Future<UserData?> currentUser() async => null;
  @override
  Future<void> enterRoom({
    required String roomId,
    String roomPassword = '',
    int followUid = 0,
  }) async {}
  @override
  RoomGiftAudience giftAudience(String roomId) => RoomGiftAudience(
    isInRoom: room.isInRoom && room.currentRoomId == roomId,
    onlineCount: room.roomInfo?.audienceCount ?? 0,
    recipients: [
      for (final mic in room.micList)
        if (mic.uid != null)
          RoomGiftRecipient(
            uid: mic.uid!,
            nickname: 'User ${mic.uid}',
            seatPosition: mic.position,
          ),
    ],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
