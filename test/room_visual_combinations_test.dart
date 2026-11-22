import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/effects/room_gift_asset_resolver.dart';
import 'package:project/classes/room/gift/event/room_gift_event_manager.dart';
import 'package:project/classes/room/interaction/room_animated_artwork.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/model/room_user_info.dart';

import 'support/room_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'vehicle starts its real entrance widget and waits for both ends at $width',
      (tester) async {
        final h = RoomVisualHarness()..install();
        addTearDown(() => h.close(tester));
        h.manager.receive(h.entrance('first'));
        h.manager.receive(h.entrance('next', car: false, uid: 30));
        await h.mount(tester, width: width);
        expect(h.calls, contains('start:3'));
        expect(h.manager.snapshot.entrance, isNull);
        expect(find.text('Enter the room'), findsNothing);
        h.event(3, 'onAnimationStart');
        await RoomVisualHarness.flush(tester);
        expect(find.text('QA first العربية中文 long nickname'), findsOneWidget);
        expect(find.text('Enter the room'), findsOneWidget);
        expect(find.byType(RoomAnimatedArtwork), findsOneWidget);
        expect(h.activePlayers(tester), containsAll([2, 3]));
        await tester.tap(find.text('Outside'));
        expect(h.outsideTaps, 1);
        h.event(3, 'onAnimationEnd');
        await RoomVisualHarness.flush(tester);
        expect(h.manager.snapshot.entrance!.key, 'entrance:first');
        expect(h.calls, contains('released:3'));
        await tester.pump(const Duration(seconds: 5));
        // Deliver the first frame beyond the exact animation boundary.
        await tester.pump(const Duration(milliseconds: 16));
        await RoomVisualHarness.flush(tester);
        expect(h.manager.snapshot.entrance!.key, 'entrance:next');
        expect(find.text('QA next العربية中文 long nickname'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'frame survives magic to expression replacement until its own seat changes at $width',
      (tester) async {
        final h = RoomVisualHarness()..install();
        addTearDown(() => h.close(tester));
        h.setSeats([
          const RoomSeatViewData(
            position: 0,
            uid: 20,
            appearance: RoomUserAppearance(
              frameUrl: 'https://qa.invalid/1.pag',
            ),
          ),
        ]);
        h.manager.receive(h.gift('magic', magic: true));
        await h.mount(tester, width: width);
        expect(h.activePlayers(tester), containsAll([1, 4]));
        final old = h.manager.snapshot.micEffects[0]!.key;
        final release = Completer<void>();
        h.pendingRelease[4] = release;
        h.manager.receive(h.expression('face'));
        await RoomVisualHarness.flush(tester);
        expect(h.calls, contains('release:4'));
        expect(h.calls, isNot(contains('init:5')));
        expect(h.calls.where((x) => x == 'init:1'), hasLength(1));
        release.complete();
        await RoomVisualHarness.flush(tester);
        expect(
          h.calls.indexOf('released:4'),
          lessThan(h.calls.indexOf('init:5')),
        );
        h.manager.completeMicEffect(0, old);
        await RoomVisualHarness.flush(tester);
        expect(h.manager.snapshot.micEffects[0]!.key, 'mic-expression:face');
        expect(h.activePlayers(tester), containsAll([1, 5]));
        h.setSeats([const RoomSeatViewData(position: 1, uid: 20)]);
        await RoomVisualHarness.flush(tester);
        expect(h.manager.snapshot.micEffects, isEmpty);
        expect(h.activePlayers(tester), isEmpty);
        expect(h.calls, containsAll(['released:1', 'released:5']));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'no-car track coexists with full-screen and expiry leaves the gift alive',
    (tester) async {
      final h = RoomVisualHarness()..install();
      addTearDown(() => h.close(tester));
      h.manager.receive(h.gift('full'));
      h.manager.receive(h.entrance('walk', car: false));
      await h.mount(tester);
      expect(h.activePlayers(tester), containsAll([2, 6]));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 16));
      await RoomVisualHarness.flush(tester);
      expect(h.manager.snapshot.entrance, isNull);
      expect(h.manager.snapshot.effects.single.key, 'full');
      expect(h.activePlayers(tester), [6]);
      expect(h.calls, contains('released:2'));
      expect(h.calls, isNot(contains('release:6')));
    },
  );

  testWidgets(
    'full-screen hands over to numeric only after its actual release reply',
    (tester) async {
      final h = RoomVisualHarness()..install();
      addTearDown(() => h.close(tester));
      h.manager.receive(h.gift('full'));
      h.manager.receive(h.gift('number', lucky: true));
      await h.mount(tester);
      expect(h.calls, isNot(contains('init:7')));
      final release = Completer<void>();
      h.pendingRelease[6] = release;
      await tester.tap(find.byKey(const ValueKey('room-gift-effect-close')));
      await RoomVisualHarness.flush(tester);
      expect(h.calls, contains('release:6'));
      expect(h.calls, isNot(contains('init:7')));
      release.complete();
      await RoomVisualHarness.flush(tester);
      expect(
        h.calls.indexOf('released:6'),
        lessThan(h.calls.indexOf('init:7')),
      );
      expect(h.activePlayers(tester), [7]);
      h.manager.setVisible(false);
      await RoomVisualHarness.flush(tester);
      h.manager.setVisible(true);
      await RoomVisualHarness.flush(tester);
      expect(h.activePlayers(tester), isEmpty);
      expect(h.manager.snapshot.lucky, isEmpty);
      expect(h.calls.where((x) => x == 'init:7'), hasLength(1));
    },
  );

  testWidgets(
    'Keep during pending vehicle initialization cannot resurrect its track',
    (tester) async {
      final h = RoomVisualHarness()..install();
      addTearDown(() => h.close(tester));
      final init = Completer<Object?>();
      h.pendingInit[3] = init;
      h.manager.receive(h.entrance('pending'));
      await h.mount(tester);
      h.manager.setVisible(false);
      await RoomVisualHarness.flush(tester);
      init.complete();
      await RoomVisualHarness.flush(tester);
      h.manager.setVisible(true);
      await RoomVisualHarness.flush(tester);
      expect(h.calls, contains('released:3'));
      expect(h.calls, isNot(contains('start:3')));
      expect(h.activePlayers(tester), isEmpty);
      expect(find.text('Enter the room'), findsNothing);
    },
  );

  testWidgets(
    'expired temporary effect releases without stopping the avatar frame',
    (tester) async {
      final h = RoomVisualHarness()..install();
      addTearDown(() => h.close(tester));
      h.setSeats([
        const RoomSeatViewData(
          position: 0,
          uid: 20,
          appearance: RoomUserAppearance(frameUrl: 'https://qa.invalid/1.pag'),
        ),
      ]);
      h.manager.receive(h.gift('magic', magic: true));
      await h.mount(tester);
      expect(h.activePlayers(tester), containsAll([1, 4]));
      await tester.pump(const Duration(seconds: 8));
      await tester.pump(const Duration(milliseconds: 16));
      await RoomVisualHarness.flush(tester);
      expect(h.manager.snapshot.micEffects, isEmpty);
      expect(h.activePlayers(tester), [1]);
      expect(h.calls, contains('released:4'));
      expect(h.calls, isNot(contains('release:1')));
    },
  );

  testWidgets(
    'a delayed expression cannot initialize after its target moves seats',
    (tester) async {
      final h = RoomVisualHarness()..install();
      addTearDown(() => h.close(tester));
      h.setSeats([const RoomSeatViewData(position: 0, uid: 20)]);
      final ready = Completer<RoomGiftAnimationResource>();
      h.pendingResources[5] = ready;
      h.manager.receive(h.expression('late'));
      await h.mount(tester);
      expect(h.calls, isNot(contains('init:5')));
      h.setSeats([const RoomSeatViewData(position: 1, uid: 20)]);
      await RoomVisualHarness.flush(tester);
      ready.complete(h.clip(5));
      await RoomVisualHarness.flush(tester);
      expect(h.manager.snapshot.micEffects, isEmpty);
      expect(h.calls, isNot(contains('init:5')));
      expect(h.activePlayers(tester), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a failed temporary resource leaves the frame and outside controls usable',
    (tester) async {
      final h = RoomVisualHarness()..install();
      addTearDown(() => h.close(tester));
      h.setSeats([
        const RoomSeatViewData(
          position: 0,
          uid: 20,
          appearance: RoomUserAppearance(frameUrl: 'https://qa.invalid/1.pag'),
        ),
      ]);
      final ready = Completer<RoomGiftAnimationResource>();
      h.pendingResources[5] = ready;
      h.manager.receive(h.expression('broken'));
      await h.mount(tester);
      ready.completeError(const FormatException('LOCAL QA missing clip'));
      await RoomVisualHarness.flush(tester);
      expect(h.manager.snapshot.micEffects, isEmpty);
      expect(h.activePlayers(tester), [1]);
      expect(h.calls, isNot(contains('init:5')));
      await tester.tap(find.text('Outside'));
      expect(h.outsideTaps, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
