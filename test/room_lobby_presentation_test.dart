import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/more/room_lobby_page.dart';
import 'package:project/classes/room/more/room_tools_controller.dart';
import 'package:project/classes/room/more/room_tools_strip.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_models.dart';
import 'package:project/theme/app_theme.dart';

import 'support/room_lobby_harness.dart';
import 'support/precache_room_assets.dart';

void main() {
  setUpAll(() async {
    final font = await File(
      'test/fixtures/fonts/Roboto-Regular.ttf',
    ).readAsBytes();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.sublistView(font)))).load();
  });
  late RoomLobbyHarness h;
  setUp(() => h = RoomLobbyHarness());
  final pendant = find.byKey(const ValueKey('room-lobby-pendant'));

  testWidgets(
    'open server mode starts folded, without any public strip space',
    (tester) async {
      await h.mount(tester, role: UserRoomIdentity.audience);
      expect(h.vm.snapshot.lobbyVisible, isFalse);
      expect(h.vm.showLobbyPendant, isTrue);
      expect(pendant, findsOneWidget);
      expect(find.text('Win'), findsNothing);
      expect(tester.getSize(find.byType(RoomToolsStrip)).height, 0);
      expect(h.api.count(HttpApi.lobbyOpen), 0);
    },
  );

  for (final role in UserRoomIdentity.values) {
    for (final position in [2, 7]) {
      testWidgets('position $position lobby access for $role', (tester) async {
        await h.mount(tester, role: role, positions: [position]);
        final permitted = position == 2 || role != UserRoomIdentity.audience;
        expect(pendant, permitted ? findsOneWidget : findsNothing);
      });
    }
  }

  testWidgets('closed or unconfigured lobbies have no pendant', (tester) async {
    await h.mount(tester, type: 0, positions: []);
    expect(pendant, findsNothing);
    h.room.event('RoomLobbyStatusEvent', {'status': 1, 'lobbyType': 1});
    await tester.pumpAndSettle();
    expect(pendant, findsNothing);
    expect(h.vm.beginLobbyPanel(), isNull);
  });

  testWidgets(
    'repeated open, minimize, restore and back never change server mode',
    (tester) async {
      await h.mount(tester);
      final records = h.api.count(HttpApi.roomLobbyRecords);
      await tester.tap(pendant);
      expect(h.vm.beginLobbyPanel(), isNull);
      await tester.pumpAndSettle();
      expect(find.byType(RoomLobbyPage), findsOneWidget);
      expect(h.vm.snapshot.lobbyVisible, isTrue);
      expect(h.vm.showLobbyPendant, isFalse);
      expect(h.api.count(HttpApi.roomLobbyRecords), records + 1);
      await tester.tap(find.text('Minimize'));
      await tester.pumpAndSettle();
      expect(find.byType(RoomLobbyPage), findsNothing);
      expect(pendant, findsOneWidget);
      await tester.tap(pendant);
      await tester.pumpAndSettle();
      h.router.pop();
      await tester.pumpAndSettle();
      expect(h.vm.snapshot.lobbyVisible, isFalse);
      expect(pendant, findsOneWidget);
      expect(h.api.count(HttpApi.lobbyOpen), 0);
      expect(h.room.leaves, 0);
    },
  );

  testWidgets(
    'More uses the same page and selected mode does not submit again',
    (tester) async {
      await h.mount(tester);
      await tester.tap(
        find.image(const AssetImage(AppAssets.lanhuRoomBottomMore)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Win'));
      await tester.pumpAndSettle();
      expect(find.byType(RoomLobbyPage), findsOneWidget);
      expect(find.byKey(const ValueKey('room-more-tools-sheet')), findsNothing);
      h.router.pop();
      await tester.pumpAndSettle();
      expect(pendant, findsOneWidget);
      expect(h.api.count(HttpApi.lobbyOpen), 0);
    },
  );

  testWidgets(
    'Socket updates do not auto open; an open page tracks modes and closes',
    (tester) async {
      await h.mount(tester, type: 0);
      h.room.event('RoomLobbyStatusEvent', {
        'status': 1,
        'lobbyType': 1,
      }, id: 'open');
      await tester.pumpAndSettle();
      expect(find.byType(RoomLobbyPage), findsNothing);
      expect(pendant, findsOneWidget);
      await tester.tap(pendant);
      await tester.pumpAndSettle();
      h.room.event('RoomLobbyStatusEvent', {
        'status': 1,
        'lobbyType': 2,
      }, id: 'treasure');
      await tester.pumpAndSettle();
      expect(find.byType(RoomLobbyPage), findsOneWidget);
      expect(find.text('Treasure'), findsOneWidget);
      expect(h.api.count(HttpApi.roomTreasureRecords), 1);
      h.room.event('RoomLobbyStatusEvent', {
        'status': 0,
        'lobbyType': 2,
      }, id: 'close');
      await tester.pumpAndSettle();
      expect(find.byType(RoomLobbyPage), findsNothing);
      expect(pendant, findsNothing);
      expect(h.api.count(HttpApi.lobbyOpen), 0);
    },
  );

  testWidgets('a new award opens through the shared local navigation', (
    tester,
  ) async {
    await h.mount(tester);
    h.room.event('RoomGameAwardEvent', {
      'userBaseInfo': {'uid': 20, 'nick': 'Winner'},
      'multiple': 3,
      'winAmount': 100,
    }, id: 'award');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Winner x3  100'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomLobbyPage), findsOneWidget);
    expect(h.vm.snapshot.lobbyAwards, isEmpty);
    expect(h.api.count(HttpApi.lobbyOpen), 0);
  });

  testWidgets('a queued record refresh follows the latest Socket mode', (
    tester,
  ) async {
    await h.mount(tester);
    h.api.heldPath = HttpApi.roomLobbyRecords;
    h.api.gate = Completer();
    final pending = h.vm.loadLobby();
    h.api.responses[HttpApi.roomTreasureRecords] = {
      'giftIocs': [],
      'playTos': [
        {'uid': 20, 'nick': 'Current mode'},
      ],
    };
    h.room.event('RoomLobbyStatusEvent', {
      'status': 1,
      'lobbyType': 2,
    }, id: 'latest');
    h.api.heldPath = null;
    h.api.gate!.complete([
      {'uid': 99, 'nick': 'Old mode'},
    ]);
    await pending;
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(h.api.count(HttpApi.roomTreasureRecords), 1);
    expect(h.vm.snapshot.lobbyRecords.single['nick'], 'Current mode');
    expect(h.vm.snapshot.lobbyVisible, isFalse);
  });

  testWidgets('losing manager-only access closes the owned page', (
    tester,
  ) async {
    await h.mount(tester, positions: [7]);
    await tester.tap(pendant);
    await tester.pumpAndSettle();
    h.room.setRole(UserRoomIdentity.audience);
    await tester.pumpAndSettle();
    expect(find.byType(RoomLobbyPage), findsNothing);
    expect(pendant, findsNothing);
    expect(h.api.count(HttpApi.lobbyOpen), 0);
  });

  for (final action in ['Keep', 'leave', 'account', 'new session']) {
    testWidgets('$action invalidates only the owned lobby and late results', (
      tester,
    ) async {
      await h.mount(tester);
      await tester.tap(pendant);
      await tester.pumpAndSettle();
      final owner = h.vm;
      h.api.heldPath = HttpApi.roomLobbyRecords;
      h.api.gate = Completer();
      final pending = owner.loadLobby();
      switch (action) {
        case 'Keep':
          h.room.minimizeRoom();
        case 'leave':
          await h.room.leaveRoom();
        case 'account':
          h.room.changeAccount(99);
        case 'new session':
          h.room.generation++;
          h.room.emitState();
      }
      await tester.pumpAndSettle();
      expect(find.byType(RoomLobbyPage), findsNothing);
      h.api.gate!.complete([
        {'uid': 999, 'nick': 'Stale'},
      ]);
      await pending;
      await tester.pumpAndSettle();
      if (owner.mounted) expect(owner.snapshot.lobbyVisible, isFalse);
      expect(h.api.count(HttpApi.lobbyOpen), 0);
      if (action == 'Keep') {
        h.room.restoreRoom();
        h.router.go('/room/123');
        await tester.pumpAndSettle();
        expect(pendant, findsOneWidget);
        expect(h.room.leaves, 0);
      }
    });
  }

  testWidgets('closing an owned page preserves a newer Wallet route', (
    tester,
  ) async {
    await h.mount(tester);
    await tester.tap(pendant);
    await tester.pumpAndSettle();
    h.router.push('/wallet');
    await tester.pumpAndSettle();
    h.room.event('RoomLobbyStatusEvent', {'status': 0}, id: 'close');
    await tester.pumpAndSettle();
    expect(find.text('Wallet sentinel'), findsOneWidget);
    h.router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(RoomLobbyPage), findsNothing);
  });

  testWidgets('old page completion cannot hide a new session page', (
    tester,
  ) async {
    await h.mount(tester);
    final first = h.vm.beginLobbyPanel()!;
    h.room.generation++;
    h.room.emitState();
    await tester.pumpAndSettle();
    final next = h.vm.beginLobbyPanel()!;
    h.vm.endLobbyPanel(first);
    expect(h.vm.ownsLobbyPanel(next), isTrue);
    h.vm.endLobbyPanel(next);
    expect(h.vm.showLobbyPendant, isTrue);
  });

  for (final width in [320.0, 375.0, 430.0]) {
    for (final type in [1, 2]) {
      testWidgets('lobby pendant v1 type $type at $width', (tester) async {
        await h.mount(tester, width: width, type: type, bigWin: true);
        h.room.event('RoomBigRocketStatusEvent', {
          'roomId': '123',
          'showStatus': 1,
          'level': 1,
          'progress': .25,
        });
        await tester.pumpAndSettle();
        // Use the real empty Gift filter so unrelated public-message rich text
        // does not depend on the engine test font in these pendant snapshots.
        await tester.tap(find.text('Gift').first);
        await tester.pumpAndSettle();
        await precacheForGolden(tester);
        final rocket = find.byKey(const ValueKey('room-rocket-pendant'));
        final bigWin = find.byKey(const ValueKey('room-big-win-pendant'));
        expect(rocket, findsOneWidget);
        expect(bigWin, findsOneWidget);
        expect(
          tester.getTopLeft(rocket).dy,
          lessThan(tester.getTopLeft(bigWin).dy),
        );
        expect(
          tester.getTopLeft(bigWin).dy,
          lessThan(tester.getTopLeft(pendant).dy),
        );
        expect(find.text(type == 1 ? 'Win' : 'Treasure'), findsNothing);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/room_header_adaptive_width_v3/regression/lobby_type_${type}_${width.toInt()}.png',
          ),
        );
      });
    }
  }

  testWidgets('keyboard hides the pendant and it returns without rejoining', (
    tester,
  ) async {
    await h.mount(tester, width: 320, height: 568);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.pumpAndSettle();
    expect(pendant, findsNothing);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(pendant, findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(h.room.leaves, 0);
  });
}

Future<void> precacheForGolden(WidgetTester tester) async {
  await precacheRoomAssets(tester, tester.element(find.byType(MaterialApp)));
  await tester.pumpAndSettle();
}
