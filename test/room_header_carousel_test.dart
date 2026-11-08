import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/interaction/room_interaction_repository.dart';
import 'package:project/classes/room/interaction/room_rank_sheet.dart';
import 'package:project/model/room_models.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/theme/app_theme.dart';

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

  final entry = find.byKey(const ValueKey('room-rank-entry'));
  final heat = find.byKey(const ValueKey('room-header-heat'));
  final carousel = find.byKey(const ValueKey('room-header-rank-carousel'));
  Finder valueIn(Finder parent, String value) =>
      find.descendant(of: parent, matching: find.text(value));

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('rank width follows current value and live updates at $width', (
      tester,
    ) async {
      final h = RoomLobbyHarness();
      h.room.current = h.room.current.copyWith(
        roomInfo: RoomInfo.fromJson({
          'roomGiftWeekVal': 0,
          'roomGiftIncomeVal': 123456,
        }),
      );
      await h.mount(tester, type: 0, width: width, interaction: _RankApi());
      final shortWidth = tester.getSize(carousel).width;
      final height = tester.getSize(carousel).height;
      expect(
        shortWidth,
        lessThan(RoomHeaderTheme.metricMaxWidth * width / 375),
      );
      await tester.drag(entry, const Offset(0, -45));
      await tester.pumpAndSettle();
      expect(valueIn(entry, '123.5k'), findsWidgets);
      final longWidth = tester.getSize(carousel).width;
      expect(longWidth, greaterThan(shortWidth));
      expect(
        longWidth,
        lessThanOrEqualTo(RoomHeaderTheme.metricMaxWidth * width / 375),
      );
      expect(tester.getSize(carousel).height, height);
      await tester.drag(entry, const Offset(0, 45));
      await tester.pumpAndSettle();
      expect(tester.getSize(carousel).width, closeTo(shortWidth, .01));
      h.room.current = h.room.current.copyWith(roomWeekVal: 98765);
      h.room.emitState();
      await tester.pumpAndSettle();
      expect(valueIn(entry, '98.8k'), findsWidgets);
      expect(tester.getSize(carousel).width, greaterThan(shortWidth));
      h.room.current = h.room.current.copyWith(roomWeekVal: 0);
      h.room.emitState();
      await tester.pumpAndSettle();
      expect(tester.getSize(carousel).width, closeTo(shortWidth, .01));
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'header adaptive metrics v3 at $width: carousel icon/value and rank target',
      (tester) async {
        final h = RoomLobbyHarness();
        final ranks = _RankApi();
        h.room.headerHeat = 7654;
        h.room.current = h.room.current.copyWith(
          roomInfo: RoomInfo.fromJson({
            'title': 'A long room title that should remain on a single line',
            'roomGiftWeekVal': 123456,
            'roomGiftIncomeVal': 98765,
          }),
        );
        await h.mount(tester, type: 0, width: width, interaction: ranks);
        expect(valueIn(heat, '7.7k'), findsOneWidget);
        expect(valueIn(entry, '123.5k'), findsWidgets);
        expect(
          find.descendant(
            of: heat,
            matching: find.image(const AssetImage(AppAssets.roomHeaderHeat)),
          ),
          findsOneWidget,
        );
        expect(
          find.image(const AssetImage(AppAssets.lanhuRoomHeaderMicSeat)),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Gift').first);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/room_online_adaptive_width_v1/contribution_${width.toInt()}.png',
          ),
        );
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<RoomRankSheet>(find.byType(RoomRankSheet))
              .initialProfit,
          isFalse,
        );
        expect(ranks.paths, contains(HttpApi.rankCommonly));
        h.router.pop();
        await tester.pumpAndSettle();
        await tester.drag(entry, const Offset(0, -45));
        await tester.pumpAndSettle();
        expect(valueIn(entry, '98.8k'), findsWidgets);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/room_online_adaptive_width_v1/profit_${width.toInt()}.png',
          ),
        );
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<RoomRankSheet>(find.byType(RoomRankSheet))
              .initialProfit,
          isTrue,
        );
        expect(ranks.paths, contains(HttpApi.roomRankIncome));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'automatically rotates after five seconds, unknown is not fabricated zero',
    (tester) async {
      final h = RoomLobbyHarness();
      await h.mount(tester, type: 0, interaction: _RankApi());
      expect(valueIn(heat, '0'), findsOneWidget);
      expect(valueIn(entry, '—'), findsWidgets);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(
        tester.widget<RoomRankSheet>(find.byType(RoomRankSheet)).initialProfit,
        isTrue,
      );
    },
  );
}

class _RankApi extends RoomInteractionRepository {
  final paths = <String>[];
  @override
  Future<Object?> get(String path, Map<String, dynamic> query) async {
    paths.add(path);
    return {'rankVOs': [], 'coinVal': 123456, 'diamondVal': 98765};
  }
}
