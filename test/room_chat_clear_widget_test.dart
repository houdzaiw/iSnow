import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/interaction/room_interaction_repository.dart';
import 'package:project/classes/room/interaction/room_member_card_content.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/theme/app_theme.dart';

import 'support/room_lifecycle_fakes.dart';

void main() {
  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('opens room profile, party and sender card at $width', (
      tester,
    ) async {
      final api = _EntryApi();
      final fixture = await _openRoom(
        tester,
        width: width,
        interactionApi: api,
      );
      await tester.tap(find.byKey(const ValueKey('room-cover-details')));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
      expect(find.bySemanticsLabel('Edit info'), findsOneWidget);
      await tester.tap(find.text('Party'));
      await tester.pumpAndSettle();
      expect(find.text('Party History'), findsOneWidget);
      expect(api.partyQueries.single, {
        'roomId': 'first',
        'history': false,
        'pageNum': 1,
      });
      await tester.tap(find.text('Party History'));
      await tester.pumpAndSettle();
      expect(api.partyQueries.last['history'], isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      fixture.socket.controller.add(
        const RoomSocketMessage(
          channel: 'room:first',
          event: 'RoomScreenMessageEvent',
          raw: {},
          msgId: 'card-test',
          payload: {
            'from': {'uid': 20, 'nick': 'Peer'},
            'msg': 'Hello',
          },
        ),
      );
      await tester.pump();
      final avatar = find.byKey(const ValueKey('room-chat-avatar-card-test'));
      await tester.tap(avatar);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(RoomMemberCardContent),
          matching: find.text('Peer'),
        ),
        findsOneWidget,
      );
      expect(find.text('ID:20002'), findsOneWidget);
      expect(find.text('Send Gift'), findsOneWidget);
      expect(find.text('Set as Admin'), findsNothing);
      await tester.tap(find.byTooltip('Manage member'));
      await tester.pumpAndSettle();
      expect(find.text('Set as Admin'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(api.userQueries.single, {'roomId': 'first', 'targetUid': 20});
      await tester.tap(find.bySemanticsLabel('@'));
      await tester.pumpAndSettle();
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.controller!.text, '@Peer ');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('chat input loads the supplied send artwork at $width', (
      tester,
    ) async {
      await _openRoom(tester, width: width);
      await tester.tap(
        find.image(const AssetImage(AppAssets.lanhuRoomBottomChat)),
      );
      await tester.pumpAndSettle();
      final send = find.image(const AssetImage(AppAssets.roomChatSend));
      expect(send, findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.decoration!.filled, isTrue);
      expect(input.decoration!.fillColor, AppColors.roomMessageBubble);
      expect(input.style!.color, AppColors.textInverse);
      expect(input.cursorColor, AppColors.textInverse);
      expect(tester.getSize(send).width, tester.getSize(send).height);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('clear asset confirms, cancels and clears the list at $width', (
      tester,
    ) async {
      final fixture = await _openRoom(tester, width: width);
      _emitChat(fixture, 'old message');
      await tester.pump();
      expect(find.text('old message', findRichText: true), findsWidgets);
      final clear = find.byKey(const ValueKey('room-chat-clear'));
      expect(clear, findsOneWidget);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('room-chat-clear-dialog')),
        findsOneWidget,
      );
      expect(fixture.http.clearMessagesRequests, isEmpty);
      await tester.tap(find.byKey(const ValueKey('room-chat-clear-cancel')));
      await tester.pumpAndSettle();
      expect(find.text('old message', findRichText: true), findsWidgets);
      expect(fixture.http.clearMessagesRequests, isEmpty);

      await tester.tap(clear);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room-chat-clear-confirm')));
      await tester.pumpAndSettle();
      expect(fixture.http.clearMessagesRequests, [
        {'roomId': 'first'},
      ]);
      expect(find.text('old message', findRichText: true), findsNothing);
      expect(
        find.text(
          'Violations may lead to account restrictions.',
          findRichText: true,
        ),
        findsNothing,
      );
      expect(find.byType(RoomPage), findsOneWidget);
      _emitChat(fixture, 'new message');
      await tester.pump();
      expect(find.text('new message', findRichText: true), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('audience has no server clear button', (tester) async {
    await _openRoom(tester, ownerUid: 20);
    expect(find.byKey(const ValueKey('room-chat-clear')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pending clear disables re-entry without hiding messages early', (
    tester,
  ) async {
    final fixture = await _openRoom(tester);
    fixture.http.clearMessagesGate = Completer<void>();
    _emitChat(fixture, 'waiting');
    await tester.pump();
    final clear = find.byKey(const ValueKey('room-chat-clear'));
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room-chat-clear-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('waiting', findRichText: true), findsWidgets);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room-chat-clear-dialog')), findsNothing);
    expect(fixture.http.clearMessagesRequests, hasLength(1));
    fixture.http.clearMessagesGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('waiting', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<RoomLifecycleFixture> _openRoom(
  WidgetTester tester, {
  double width = 375,
  int ownerUid = 10,
  RoomInteractionRepository? interactionApi,
}) async {
  tester.view.physicalSize = Size(width, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fixture = RoomLifecycleFixture();
  fixture.http.roomOwnerUid = ownerUid;
  addTearDown(fixture.dispose);
  await tester.runAsync(() => fixture.enter());
  final repository = RoomRepository(
    roomManager: fixture.manager,
    socketManager: fixture.socket,
    agoraManager: fixture.agora,
    authSession: fixture.auth,
    httpManager: fixture.http,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        roomRepositoryProvider.overrideWithValue(repository),
        if (interactionApi != null)
          roomInteractionRepositoryProvider.overrideWithValue(interactionApi),
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
          home: RoomPage(roomId: 'first'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fixture;
}

void _emitChat(RoomLifecycleFixture fixture, String text) =>
    fixture.socket.controller.add(
      RoomSocketMessage(
        channel: 'room:first',
        event: 'RoomScreenMessageEvent',
        payload: {'msg': text},
        raw: const {},
      ),
    );

class _EntryApi extends RoomInteractionRepository {
  final partyQueries = <Map<String, dynamic>>[];
  final userQueries = <Map<String, dynamic>>[];

  @override
  Future<Object?> get(String path, Map<String, dynamic> query) async {
    if (path == HttpApi.roomUserInfo) {
      userQueries.add(query);
      return {
        'userBase': {'uid': 20, 'userNo': 20002, 'nick': 'Peer'},
        'roomIdentity': 'ROOM_AUDIENCE',
      };
    }
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<Object?> post(String path, Map<String, dynamic> body) async {
    if (path == HttpApi.roomPartyList) {
      partyQueries.add(body);
      return [];
    }
    throw StateError('Unexpected POST $path');
  }
}
