import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:project/classes/room/more/room_entry_flow.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/localization/app_localizations.dart';

import 'support/room_tools_fakes.dart';

void main() {
  late ToolsRoomFake room;
  late Completer<ToolJson> info;
  var current = true;
  setUp(() {
    room = ToolsRoomFake();
    current = true;
    addTearDown(room.dispose);
  });
  Future<GoRouter> mount(WidgetTester tester) async {
    info = Completer<ToolJson>();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => enterSharedRoom(
                  context,
                  ref,
                  '42',
                  isCurrent: () => current,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/room/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Room ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomRepositoryProvider.overrideWithValue(room),
          roomEntryInfoProvider('42').overrideWith((ref) => info.future),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pump();
    return router;
  }

  testWidgets(
    'room details keeps existing switch confirmation and cancellation',
    (tester) async {
      final router = await mount(tester);
      info.complete({});
      await tester.pumpAndSettle();
      expect(find.text('Switch room'), findsOneWidget);
      expect(router.state.uri.path, '/');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/');
      expect(room.leaves, 0);
    },
  );

  testWidgets('expired info result never opens a switch dialog', (
    tester,
  ) async {
    final router = await mount(tester);
    current = false;
    info.complete({});
    await tester.pumpAndSettle();
    expect(find.text('Switch room'), findsNothing);
    expect(router.state.uri.path, '/');
    expect(room.leaves, 0);
  });

  testWidgets('expired confirmation cannot navigate or leave the room', (
    tester,
  ) async {
    final router = await mount(tester);
    info.complete({});
    await tester.pumpAndSettle();
    current = false;
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/');
    expect(room.leaves, 0);
  });

  testWidgets('password is encoded only after valid confirmation', (
    tester,
  ) async {
    final router = await mount(tester);
    info.complete({'roomLock': true});
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Room password'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a&b=1');
    await tester.tap(find.text('Enter'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/room/42');
    expect(router.state.uri.queryParameters['roomPassword'], 'a&b=1');
    expect(room.leaves, 0);
  });
}
