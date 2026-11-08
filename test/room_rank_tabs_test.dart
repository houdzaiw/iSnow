import 'dart:async';

import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/interaction/room_interaction_repository.dart';
import 'package:project/classes/room/interaction/room_rank_sheet.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/server_response.dart';

import 'support/room_lobby_harness.dart';

final _tabs = find.byKey(const ValueKey('room-rank-tabs'));
int _category(WidgetTester tester) =>
    tester.widget<ExtendedTabBar>(_tabs).controller!.index;
Finder _periodTabs(WidgetTester tester) => find
    .byKey(ValueKey('room-rank-period-tabs-${_category(tester) == 1}'))
    .hitTestable();
Finder _periodPages(WidgetTester tester) => find
    .byKey(ValueKey('room-rank-period-pages-${_category(tester) == 1}'))
    .hitTestable();
int _period(WidgetTester tester) =>
    tester.widget<ExtendedTabBar>(_periodTabs(tester)).controller!.index;
int _position(WidgetTester tester) => _category(tester) * 3 + _period(tester);
Finder _list(WidgetTester tester) => find
    .descendant(of: _periodPages(tester), matching: find.byType(ListView))
    .hitTestable();
Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _swipe(WidgetTester tester, double dx) async {
  await tester.drag(_periodPages(tester), Offset(dx, 0));
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  RoomLobbyHarness h,
  _RankApi api, {
  double width = 375,
  bool profit = false,
  bool pending = false,
}) async {
  await h.mount(tester, type: 0, width: width, interaction: api);
  final entry = find.byKey(const ValueKey('room-rank-entry'));
  if (profit) {
    await tester.drag(entry, const Offset(0, -45));
    await tester.pumpAndSettle();
  }
  await tester.tap(entry);
  if (pending) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'nested ranks visit all six pages in both directions at $width',
      (tester) async {
        final h = RoomLobbyHarness();
        final api = _RankApi();
        await _open(tester, h, api, width: width);
        expect(_position(tester), 1);
        expect(api.count(false, 4), 1);
        expect(api.listCalls, hasLength(1));
        await _tap(tester, 'Daily');
        for (var target = 1; target < 6; target++) {
          await _swipe(tester, -width * .75);
          expect(_position(tester), target, reason: 'forward step $target');
          final name = api.name(target >= 3, [5, 4, 3][target % 3]);
          expect(find.text('$name user 0').hitTestable(), findsOneWidget);
        }
        await _swipe(tester, -width * .75);
        expect(_position(tester), 5);
        for (var target = 4; target >= 0; target--) {
          await _swipe(tester, width * .75);
          expect(_position(tester), target, reason: 'backward step $target');
        }
        await _swipe(tester, width * .75);
        expect(_position(tester), 0);
        for (final profit in [false, true]) {
          for (final frequency in [5, 4, 3]) {
            expect(api.count(profit, frequency), 1);
          }
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'header profit entry starts weekly; titles restore independent periods and reopening resets',
    (tester) async {
      final h = RoomLobbyHarness();
      final api = _RankApi();
      await _open(tester, h, api, profit: true);
      expect(_position(tester), 4);
      await _tap(tester, 'Daily');
      await _tap(tester, 'Contribution Rank');
      expect(_position(tester), 1);
      await _tap(tester, 'Monthly');
      await _tap(tester, 'Profit Rank');
      expect(_position(tester), 3);
      await _tap(tester, 'Contribution Rank');
      expect(_position(tester), 2);
      h.router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room-rank-entry')));
      await tester.pumpAndSettle();
      expect(_period(tester), 1);
    },
  );

  testWidgets(
    'cancelled boundary drag restores target memory and does not fetch preview data',
    (tester) async {
      final h = RoomLobbyHarness();
      final api = _RankApi();
      await _open(tester, h, api);
      await _tap(tester, 'Profit Rank');
      await _tap(tester, 'Monthly');
      await _tap(tester, 'Contribution Rank');
      await _tap(tester, 'Monthly');
      final gesture = await tester.startGesture(
        tester.getCenter(_periodPages(tester)),
      );
      await gesture.moveBy(const Offset(-55, 0));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(_position(tester), 2);
      expect(api.count(true, 5), 0);
      await _tap(tester, 'Profit Rank');
      expect(_position(tester), 5);
      await _swipe(tester, 280);
      expect(_position(tester), 4);
    },
  );

  testWidgets(
    'title tap during boundary settling preserves target period memory',
    (tester) async {
      final h = RoomLobbyHarness();
      final api = _RankApi();
      await _open(tester, h, api);
      await _tap(tester, 'Profit Rank');
      await _tap(tester, 'Monthly');
      await _tap(tester, 'Contribution Rank');
      await _tap(tester, 'Monthly');
      final gesture = await tester.startGesture(
        tester.getCenter(_periodPages(tester)),
      );
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await _tap(tester, 'Profit Rank');
      expect(_position(tester), 5);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelled reverse boundary drag restores contribution period', (
    tester,
  ) async {
    final h = RoomLobbyHarness();
    final api = _RankApi();
    await _open(tester, h, api, profit: true);
    await _tap(tester, 'Contribution Rank');
    await _tap(tester, 'Daily');
    await _tap(tester, 'Profit Rank');
    await _tap(tester, 'Daily');
    final gesture = await tester.startGesture(
      tester.getCenter(_periodPages(tester)),
    );
    await gesture.moveBy(const Offset(55, 0));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(_position(tester), 3);
    expect(api.count(false, 3), 0);
    await _tap(tester, 'Contribution Rank');
    expect(_position(tester), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all six boards retain independent scroll positions; vertical drag does not change tabs',
    (tester) async {
      final h = RoomLobbyHarness();
      final api = _RankApi();
      await _open(tester, h, api);
      final offsets = <int, double>{};
      for (final category in ['Contribution Rank', 'Profit Rank']) {
        await _tap(tester, category);
        for (final period in ['Daily', 'Weekly', 'Monthly']) {
          await _tap(tester, period);
          final position = _position(tester);
          await tester.drag(_list(tester), Offset(0, -180.0 - position * 25));
          await tester.pumpAndSettle();
          expect(_position(tester), position);
          offsets[position] = tester
              .widget<ListView>(_list(tester))
              .controller!
              .offset;
          expect(offsets[position], greaterThan(0));
        }
      }
      for (final category in ['Contribution Rank', 'Profit Rank']) {
        await _tap(tester, category);
        for (final period in ['Daily', 'Weekly', 'Monthly']) {
          await _tap(tester, period);
          expect(
            tester.widget<ListView>(_list(tester)).controller!.offset,
            closeTo(offsets[_position(tester)]!, .01),
          );
        }
      }
      expect(api.listCalls, hasLength(6));
    },
  );

  testWidgets(
    'rapid drags cannot skip the destination Daily or corrupt controller state',
    (tester) async {
      final h = RoomLobbyHarness();
      final api = _RankApi();
      await _open(tester, h, api);
      await tester.drag(_periodPages(tester), const Offset(-280, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.drag(_periodPages(tester), const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(_position(tester), anyOf(2, 3));
      if (_position(tester) == 2) {
        await _swipe(tester, -280);
      }
      expect(_position(tester), 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('refresh and rules follow the current category and period', (
    tester,
  ) async {
    final h = RoomLobbyHarness();
    final api = _RankApi();
    await _open(tester, h, api);
    await _swipe(tester, -280);
    await _swipe(tester, -280);
    expect(_position(tester), 3);
    await tester.tap(find.byTooltip('Rank rules'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ranked by diamonds received in this room.'),
      findsOneWidget,
    );
    h.router.pop();
    await tester.pumpAndSettle();
    await tester.drag(_list(tester), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(api.count(true, 5), 2);
    expect(api.count(false, 3), 1);
    expect(
      api.calls.where((c) => c.path == HttpApi.roomRankSummary).last.query,
      {'roomId': '123', 'type': 5},
    );
    await _swipe(tester, 280);
    expect(_position(tester), 2);
    await tester.tap(find.byTooltip('Rank rules'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ranked by coins spent on gifts in this room.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'error and empty pages still swipe, retry only refreshes the failed board',
    (tester) async {
      final h = RoomLobbyHarness();
      final api = _RankApi()..failProfit = true;
      await _open(tester, h, api);
      await _tap(tester, 'Profit Rank');
      expect(find.text('Rank unavailable').hitTestable(), findsOneWidget);
      await _swipe(tester, -280);
      expect(_position(tester), 5);
      api.failProfit = false;
      api.empty = true;
      await _tap(tester, 'Retry');
      expect(find.text('No ranked users').hitTestable(), findsOneWidget);
      expect(api.count(true, 3), 2);
      await _swipe(tester, 280);
      expect(_position(tester), 4);
      await _tap(tester, 'Contribution Rank');
      expect(_position(tester), 1);
      expect(api.count(false, 4), 1);
    },
  );

  for (final reason in ['account', 'room', 'close']) {
    testWidgets(
      '$reason isolates late responses and closes only the rank sheet',
      (tester) async {
        final h = RoomLobbyHarness();
        final api = _RankApi()..gate = Completer<void>();
        await _open(tester, h, api, pending: true);
        await _swipe(tester, -280);
        expect(_position(tester), 2);
        await _swipe(tester, -280);
        expect(_position(tester), 3);
        expect(
          find.text('${api.name(true, 5)} user 0').hitTestable(),
          findsOneWidget,
        );
        switch (reason) {
          case 'account':
            h.room.changeAccount(99);
          case 'room':
            h.room.generation++;
            h.room.emitState();
          case 'close':
            h.router.pop();
        }
        await tester.pumpAndSettle();
        api.gate!.complete();
        await tester.pumpAndSettle();
        expect(find.byType(RoomRankSheet), findsNothing);
        expect(h.room.leaves, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _RankApi extends RoomInteractionRepository {
  final calls = <({String path, Map<String, dynamic> query})>[];
  bool failProfit = false, empty = false;
  Completer<void>? gate;
  String name(bool profit, int frequency) =>
      '${profit ? 'Profit' : 'Contribution'} ${{5: 'Daily', 4: 'Weekly', 3: 'Monthly'}[frequency]}';
  Iterable<({String path, Map<String, dynamic> query})> get listCalls =>
      calls.where(
        (c) =>
            c.path == HttpApi.rankCommonly || c.path == HttpApi.roomRankIncome,
      );
  int count(bool profit, int frequency) => listCalls
      .where(
        (c) =>
            c.path ==
                (profit ? HttpApi.roomRankIncome : HttpApi.rankCommonly) &&
            c.query['frequencyType'] == frequency,
      )
      .length;
  @override
  Future<Object?> get(String path, Map<String, dynamic> query) async {
    calls.add((path: path, query: query));
    if (path == HttpApi.roomRankSummary) {
      return {'coinVal': 200, 'diamondVal': 300};
    }
    final profit = path == HttpApi.roomRankIncome;
    if (profit && failProfit) {
      throw const NadyApiException(message: 'Rank unavailable');
    }
    if (!profit && query['frequencyType'] == 4) await gate?.future;
    return {
      'rankVOs': [
        if (!empty)
          for (var i = 0; i < 30; i++)
            {
              'uid': i + 20,
              'nick': '${name(profit, query['frequencyType'] as int)} user $i',
              'seqNo': i + 1,
              'rankVal': 300 - i,
            },
      ],
    };
  }
}
