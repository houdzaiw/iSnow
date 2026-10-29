import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/message/im_repository.dart';
import 'package:project/classes/message/message_view_model.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/theme/app_theme.dart';

import 'support/im_fakes.dart';
import 'support/room_more_settings_fixture.dart';
import 'support/precache_room_assets.dart';
import 'support/room_tools_fakes.dart';

void main() {
  late ImSdkFake sdk;
  late ImHttpAdapter http;
  late ImRepository im;
  final inbox = find.byKey(const ValueKey('room-message-sheet'));
  final chat = find.byKey(const ValueKey('room-private-chat-sheet'));
  final button = find.byKey(const ValueKey('room-message-button'));

  setUpAll(() async {
    final loader = FontLoader('Roboto')
      ..addFont(
        File(
          'test/fixtures/fonts/Roboto-Regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await loader.load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'nady.pubUid': 10,
      'nady.oauthToken': 'test',
    });
    sdk = ImSdkFake();
    http = ImHttpAdapter();
    final manager = HttpDioManager();
    final previous = manager.getDio().httpClientAdapter;
    manager.getDio().httpClientAdapter = http;
    final auth = ImAuthFake();
    im = ImRepository(manager, auth, sdk: sdk);
    addTearDown(() {
      im.dispose();
      auth.dispose();
      manager.getDio().httpClientAdapter = previous;
    });
  });

  Future<RoomMoreSettingsFixture> mount(
    WidgetTester tester, {
    double width = 375,
    double height = 812,
    double inset = 0,
    double bottom = 0,
  }) => mountRoomMoreSettings(
    tester,
    im: im,
    width: width,
    height: height,
    inset: inset,
    bottom: bottom,
  );

  Future<void> open(WidgetTester tester) async {
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(inbox, findsOneWidget);
  }

  Future<void> openChat(WidgetTester tester, {String uid = '20'}) async {
    await open(tester);
    await tester.tap(find.byKey(ValueKey('room-conversation-$uid')));
    await tester.pumpAndSettle();
    expect(chat, findsOneWidget);
  }

  testWidgets('entry binds the new session only after entering completes', (
    tester,
  ) async {
    final room = _EnteringRoom();
    await mountRoomMoreSettings(tester, im: im, room: room, settle: false);
    expect(room.roomState.status, RoomStatus.entering);
    expect(inbox, findsNothing);
    room.entered.complete();
    await tester.pumpAndSettle();
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('room-conversation-20')));
    await tester.pumpAndSettle();
    expect(chat, findsOneWidget);
    expect(room.generation, 1);
    expect(room.leaves, 0);
    expect(room.speaker, isFalse);
  });

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'room message entry and two half sheets preserve audio at $width',
      (tester) async {
        final f = await mount(tester, width: width);
        expect(
          find.byKey(const ValueKey('room-message-unread')),
          findsOneWidget,
        );
        await open(tester);
        expect(tester.getSize(inbox).width, width);
        expect(
          tester.getSize(inbox).height,
          closeTo(812 * AppSpacing.roomMessageHeightRatio, 1),
        );
        expect(sdk.conversations.reads, isEmpty);
        expect(sdk.conversations.listeners, hasLength(1));
        await precacheRoomAssets(tester, tester.element(inbox));
        await expectLater(
          find.byKey(const ValueKey('room-settings-snapshot')),
          matchesGoldenFile('goldens/room_message_inbox_${width.toInt()}.png'),
        );
        await tester.tap(find.byKey(const ValueKey('room-conversation-20')));
        await tester.pumpAndSettle();
        expect(chat, findsOneWidget);
        expect(inbox, findsOneWidget);
        await precacheRoomAssets(tester, tester.element(chat));
        await expectLater(
          find.byKey(const ValueKey('room-settings-snapshot')),
          matchesGoldenFile('goldens/room_message_chat_${width.toInt()}.png'),
        );
        expect(sdk.conversations.reads, contains('c2c_20'));
        expect(f.container.read(messageViewModelProvider).totalUnreadCount, 0);
        expect(
          find.byKey(const ValueKey('private-chat-input')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('room-private-chat-back')));
        await tester.pumpAndSettle();
        expect(chat, findsNothing);
        expect(inbox, findsOneWidget);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(inbox, findsNothing);
        expect(f.router.state.uri.path, '/room/123');
        expect(f.room.leaves, 0);
        expect(f.room.speaker, isFalse);
        expect(sdk.messages.sent, isEmpty);
        expect(sdk.conversations.deleted, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('rapid entry taps create one list and one SDK subscription', (
    tester,
  ) async {
    await mount(tester);
    final tap = tester
        .widget<InkWell>(
          find.descendant(of: button, matching: find.byType(InkWell)),
        )
        .onTap!;
    tap();
    tap();
    await tester.pumpAndSettle();
    expect(inbox, findsOneWidget);
    expect(sdk.conversations.listeners, hasLength(1));
    expect(sdk.conversations.reads, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system conversations are readable but cannot send', (
    tester,
  ) async {
    await mount(tester);
    await openChat(tester, uid: '10000');
    expect(find.byKey(const ValueKey('private-chat-input')), findsNothing);
    expect(find.byKey(const ValueKey('private-chat-send')), findsNothing);
    expect(sdk.conversations.reads, contains('c2c_10000'));
    expect(sdk.messages.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text failure retains draft and successful retry clears it', (
    tester,
  ) async {
    await mount(tester);
    await openChat(tester);
    final input = find.byKey(const ValueKey('private-chat-input'));
    http.audit = false;
    await tester.enterText(input, 'Draft message');
    await tester.tap(find.byKey(const ValueKey('private-chat-send')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text, 'Draft message');
    expect(find.text('Message did not pass content review'), findsOneWidget);
    expect(sdk.messages.sent, isEmpty);
    http.audit = true;
    await tester.tap(find.byKey(const ValueKey('private-chat-send')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text, isEmpty);
    expect(sdk.messages.sent, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing a pending send cancels all later SDK sends', (
    tester,
  ) async {
    await mount(tester);
    await openChat(tester);
    http.auditGate = Completer<void>();
    await tester.enterText(
      find.byKey(const ValueKey('private-chat-input')),
      'Cancelled',
    );
    await tester.tap(find.byKey(const ValueKey('private-chat-send')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('room-private-chat-back')));
    await tester.pumpAndSettle();
    http.auditGate!.complete();
    await tester.pumpAndSettle();
    expect(chat, findsNothing);
    expect(inbox, findsOneWidget);
    expect(sdk.messages.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'confirmed deletion updates the shared inbox and failure retains it',
    (tester) async {
      final f = await mount(tester);
      await open(tester);
      sdk.conversations.failDelete = true;
      final row = find.byKey(const ValueKey('room-conversation-20'));
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(row, findsOneWidget);
      expect(find.text('Delete rejected'), findsOneWidget);
      sdk.conversations.failDelete = false;
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(row, findsNothing);
      expect(f.container.read(messageViewModelProvider).totalUnreadCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('short screen keyboard keeps the input visible above safe area', (
    tester,
  ) async {
    await mount(tester, width: 320, height: 568, inset: 200, bottom: 24);
    await openChat(tester);
    final input = find.byKey(const ValueKey('private-chat-input'));
    expect(tester.getRect(input).bottom, lessThanOrEqualTo(568 - 200 - 24));
    await tester.enterText(input, 'Long draft remains visible');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry restores a disconnected private chat with one listener', (
    tester,
  ) async {
    await mount(tester);
    await openChat(tester);
    sdk.listener!.onConnectFailed(1, 'Offline');
    await tester.pumpAndSettle();
    expect(find.text('Offline'), findsWidgets);
    await tester.tap(find.text('Retry').last);
    await tester.pumpAndSettle();
    expect(chat, findsOneWidget);
    expect(sdk.messages.listeners, hasLength(1));
    expect(find.text('Offline'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final boundary in ['exit', 'session', 'account']) {
    testWidgets(
      '$boundary closes both room message sheets without an old callback',
      (tester) async {
        final f = await mount(tester);
        await openChat(tester);
        if (boundary == 'exit') {
          await f.room.leaveRoom();
        } else if (boundary == 'session') {
          f.room.generation++;
          f.room.emitState();
        } else {
          f.room.changeAccount(30);
        }
        await tester.pumpAndSettle();
        expect(chat, findsNothing);
        expect(inbox, findsNothing);
        expect(sdk.messages.sent, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _EnteringRoom extends ToolsRoomFake {
  _EnteringRoom() {
    current = const RoomState();
    generation = 0;
  }

  final entered = Completer<void>();

  @override
  Future<void> enterRoom({
    required String roomId,
    String roomPassword = '',
    int followUid = 0,
  }) async {
    generation++;
    current = RoomState(status: RoomStatus.entering, currentRoomId: roomId);
    emitState();
    await entered.future;
    current = current.copyWith(status: RoomStatus.ready, isInRoom: true);
    emitState();
  }
}
