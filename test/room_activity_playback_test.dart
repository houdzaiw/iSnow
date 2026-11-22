import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/activities/room_activity_widgets.dart';
import 'package:project/classes/room/gift/effects/room_gift_asset_resolver.dart';

import 'support/room_visual_harness.dart';

void main() {
  testWidgets('activity replacement waits for the previous native release', (
    tester,
  ) async {
    final harness = RoomVisualHarness()..install();
    final container = ProviderContainer(
      overrides: [roomGiftAssetResolverProvider.overrideWithValue(harness)],
    );
    Future<void> scene(int id) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: RoomActivityArtwork(
                source: 'https://fixture.example/$id.pag',
                repeat: true,
                fullscreen: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
    }

    await scene(51);
    expect(harness.calls, contains('init:51'));
    harness.pendingRelease[51] = Completer<void>();
    await scene(52);
    expect(harness.calls, contains('release:51'));
    expect(harness.calls, isNot(contains('init:52')));
    harness.pendingRelease[51]!.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(harness.calls, contains('init:52'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(harness.calls, contains('released:52'));
    container.dispose();
    await harness.close(tester);
  });
}
