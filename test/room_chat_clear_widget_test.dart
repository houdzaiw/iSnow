import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/model/room_socket_message.dart';

import 'support/room_lifecycle_fakes.dart';

void main() {
  for (final width in [320.0, 375.0, 430.0]) {
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
      overrides: [roomRepositoryProvider.overrideWithValue(repository)],
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
