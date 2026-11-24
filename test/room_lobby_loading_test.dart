import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/manager/http_api.dart';

import 'support/room_lobby_harness.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test/fixtures/fonts/Roboto-Regular.ttf',
    ).readAsBytes();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  });
  late RoomLobbyHarness h;
  setUp(() => h = RoomLobbyHarness());
  final pendant = find.byKey(const ValueKey('room-lobby-pendant'));

  testWidgets('initial lobby loading is not reported as an empty list', (
    tester,
  ) async {
    await h.mount(tester, type: 0);
    h.api.heldPath = HttpApi.roomLobbyRecords;
    h.api.gate = Completer();
    addTearDown(() {
      if (!h.api.gate!.isCompleted) h.api.gate!.complete([]);
    });
    h.room.event('RoomLobbyStatusEvent', {'status': 1, 'lobbyType': 1});
    await tester.pump();
    await tester.tap(pendant);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('No records yet'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    h.api.gate!.complete([]);
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('No records yet'), findsOneWidget);
    expect(h.api.count(HttpApi.lobbyOpen), 0);
  });

  testWidgets('lobby retry clears its error and requests only lobby records', (
    tester,
  ) async {
    await h.mount(tester);
    h.api.failingPath = HttpApi.roomLobbyRecords;
    await tester.tap(pendant);
    await tester.pumpAndSettle();
    expect(find.text('Bad state: Server failed'), findsOneWidget);
    h.api.failingPath = null;
    h.api.calls.clear();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Bad state: Server failed'), findsNothing);
    expect(find.text('No records yet'), findsOneWidget);
    expect(h.api.calls, isNotEmpty);
    expect(
      h.api.calls.every((call) => call.path == HttpApi.roomLobbyRecords),
      isTrue,
    );
    expect(h.api.count(HttpApi.lobbyOpen), 0);
  });

  testWidgets('a failed refresh retains records while retry is loading', (
    tester,
  ) async {
    await h.mount(tester);
    h.api.responses[HttpApi.roomLobbyRecords] = [
      {'uid': 20, 'nick': 'Existing win', 'win': 7},
    ];
    await tester.tap(pendant);
    await tester.pumpAndSettle();
    expect(find.text('Existing win'), findsOneWidget);
    h.api.failingPath = HttpApi.roomLobbyRecords;
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('Bad state: Server failed'), findsOneWidget);
    expect(find.text('Existing win'), findsOneWidget);
    expect(find.text('No records yet'), findsNothing);
    h.api.failingPath = null;
    h.api.heldPath = HttpApi.roomLobbyRecords;
    h.api.gate = Completer();
    addTearDown(() {
      if (!h.api.gate!.isCompleted) h.api.gate!.complete([]);
    });
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Existing win'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Bad state: Server failed'), findsNothing);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Refresh'))
          .onPressed,
      isNull,
    );
    h.api.gate!.complete([
      {'uid': 21, 'nick': 'New win', 'win': 8},
    ]);
    await tester.pumpAndSettle();
    expect(find.text('New win'), findsOneWidget);
    expect(find.text('Existing win'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(h.api.count(HttpApi.lobbyOpen), 0);
  });
}
