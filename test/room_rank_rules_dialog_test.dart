import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/interaction/room_interaction_repository.dart';
import 'package:project/classes/room/interaction/room_rank_sheet.dart';

import 'support/room_lobby_harness.dart';

final _dialog = find.byKey(const ValueKey('room-rank-rules-dialog'));
final _card = find.byKey(const ValueKey('room-rank-rules-card'));

Future<void> _openRank(
  WidgetTester tester,
  RoomLobbyHarness h, {
  double width = 375,
  double height = 812,
}) async {
  await h.mount(
    tester,
    type: 0,
    width: width,
    height: height,
    interaction: _RulesApi(),
  );
  await tester.tap(find.byKey(const ValueKey('room-rank-entry')));
  await tester.pumpAndSettle();
}

Future<void> _openRules(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Rank rules'));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(320, 812),
    const Size(375, 812),
    const Size(430, 812),
    const Size(320, 480),
  ]) {
    testWidgets(
      'rules center within the rank sheet and close without resetting it at $size',
      (tester) async {
        final h = RoomLobbyHarness();
        await _openRank(tester, h, width: size.width, height: size.height);
        final sheet = tester.getRect(
          find.byKey(const ValueKey('room-rank-sheet')),
        );
        await _openRules(tester);
        expect(_dialog, findsOneWidget);
        final card = tester.getRect(_card);
        expect(card.center.dx, closeTo(sheet.center.dx, .5));
        expect(card.center.dy, closeTo(sheet.center.dy, .5));
        expect(card.left, greaterThan(sheet.left));
        expect(card.right, lessThan(sheet.right));
        expect(card.top, greaterThan(sheet.top));
        expect(card.bottom, lessThan(sheet.bottom));
        expect(
          find.text('Ranked by coins spent on gifts in this room.'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('room-rank-rules-close')));
        await tester.pumpAndSettle();
        expect(_dialog, findsNothing);
        expect(find.byType(RoomRankSheet), findsOneWidget);
        expect(
          tester
              .widget<ExtendedTabBar>(
                find.byKey(const ValueKey('room-rank-period-tabs-false')),
              )
              .controller!
              .index,
          1,
        );
        expect(h.room.leaves, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'duplicate taps open one dialog; outside and back only close rules',
    (tester) async {
      final h = RoomLobbyHarness();
      await _openRank(tester, h);
      final help = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Rank rules',
        ),
      );
      help.onPressed!();
      help.onPressed!();
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);
      final card = tester.getRect(_card);
      await tester.tapAt(Offset(card.left - 8, card.center.dy));
      await tester.pumpAndSettle();
      expect(_dialog, findsNothing);
      expect(find.byType(RoomRankSheet), findsOneWidget);
      await _openRules(tester);
      h.router.pop();
      await tester.pumpAndSettle();
      expect(_dialog, findsNothing);
      expect(find.byType(RoomRankSheet), findsOneWidget);
      expect(h.room.leaves, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final reason in ['account', 'room']) {
    testWidgets(
      '$reason invalidation removes both rules and their rank sheet',
      (tester) async {
        final h = RoomLobbyHarness();
        await _openRank(tester, h);
        await _openRules(tester);
        if (reason == 'account') {
          h.room.changeAccount(99);
        } else {
          h.room.generation++;
          h.room.emitState();
        }
        await tester.pumpAndSettle();
        expect(_dialog, findsNothing);
        expect(find.byType(RoomRankSheet), findsNothing);
        expect(h.room.leaves, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _RulesApi extends RoomInteractionRepository {
  @override
  Future<Object?> get(String path, Map<String, dynamic> query) async => {
    'rankVOs': [],
  };
}
