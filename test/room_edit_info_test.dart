import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/interaction/room_edit_info_sheet.dart';
import 'package:project/classes/room/interaction/room_management_view_model.dart';
import 'package:project/model/room_models.dart';
import 'package:project/theme/app_theme.dart';

import 'support/room_edit_info_fakes.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Roboto')..addFont(
          File(
            'test/fixtures/fonts/Roboto-Regular.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });
  late EditHarness h;
  setUp(() => h = EditHarness());
  tearDown(() => h.room.dispose());

  testWidgets('initial room data and correct labels, camera and limits', (
    tester,
  ) async {
    await h.pump(tester);
    expect(find.text('Room Management'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(h.text(tester, h.name), 'Happy!');
    expect(h.text(tester, h.description), 'Welcome to my room');
    expect(find.text('6/30'), findsOneWidget);
    expect(find.text('18/200'), findsOneWidget);
    expect(
      find.image(const AssetImage(AppAssets.roomEditCamera)),
      findsOneWidget,
    );
    expect(h.api.posts, isEmpty);
    expect(h.upload.paths, isEmpty);
  });

  testWidgets('limits count emoji graphemes and reserve counter space', (
    tester,
  ) async {
    await h.pump(tester);
    const emoji = '👨‍👩‍👧‍👦';
    await tester.enterText(h.name, List.filled(31, emoji).join());
    await tester.pump();
    expect(h.text(tester, h.name).characters.length, 30);
    expect(find.text('30/30'), findsOneWidget);
    await tester.enterText(h.description, List.filled(201, emoji).join());
    await tester.pump();
    expect(h.text(tester, h.description).characters.length, 200);
    expect(find.text('200/200'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty room name disables Confirm', (tester) async {
    await h.pump(tester);
    await tester.enterText(h.name, '   ');
    await tester.pump();
    expect(tester.widget<InkWell>(h.confirm).onTap, isNull);
    expect(h.api.posts, isEmpty);
  });

  testWidgets('picker cancellation keeps current cover and draft', (
    tester,
  ) async {
    await h.pump(tester);
    await tester.enterText(h.name, 'Draft');
    await tester.tap(find.bySemanticsLabel('Change cover'));
    await tester.pumpAndSettle();
    expect(h.pickerCalls, 1);
    expect(h.text(tester, h.name), 'Draft');
    expect(h.upload.paths, isEmpty);
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is FileImage),
      findsNothing,
    );
  });

  testWidgets(
    'local preview uploads on Confirm, preserves API contract and refreshes',
    (tester) async {
      await h.pump(tester);
      await h.selectCover(tester);
      expect(
        find.byWidgetPredicate((w) => w is Image && w.image is FileImage),
        findsOneWidget,
      );
      expect(h.upload.paths, isEmpty);
      await tester.enterText(h.name, ' New name ');
      await tester.enterText(h.description, ' New description ');
      await tester.tap(h.confirm);
      await tester.pumpAndSettle();
      expect(h.upload.paths, [h.picked]);
      expect(h.api.posts.single, {
        'roomId': '123',
        'roomLock': false,
        'title': 'New name',
        'roomDesc': 'New description',
        'avatar': 'https://example.com/uploaded.png',
      });
      expect(h.room.refreshes, 1);
      expect(find.byType(RoomEditInfoSheet), findsNothing);
    },
  );

  for (final uploadFailure in [true, false]) {
    testWidgets(
      '${uploadFailure ? 'upload' : 'save'} failure preserves preview and input for retry',
      (tester) async {
        await h.pump(tester);
        await h.selectCover(tester);
        h.upload.fail = uploadFailure;
        h.api.fail = !uploadFailure;
        await tester.enterText(h.name, 'Retained draft');
        await tester.enterText(h.description, 'Still editable');
        await tester.tap(h.confirm);
        await tester.pumpAndSettle();
        expect(
          find.text(uploadFailure ? 'Cover upload denied' : 'Room save denied'),
          findsOneWidget,
        );
        expect(h.text(tester, h.name), 'Retained draft');
        expect(h.text(tester, h.description), 'Still editable');
        expect(
          find.byWidgetPredicate((w) => w is Image && w.image is FileImage),
          findsOneWidget,
        );
        expect(h.api.posts.length, uploadFailure ? 0 : 1);
        h.upload.fail = h.api.fail = false;
        await tester.tap(h.confirm);
        await tester.pumpAndSettle();
        expect(find.byType(RoomEditInfoSheet), findsNothing);
        expect(h.room.refreshes, 1);
      },
    );
  }

  testWidgets(
    'save busy blocks duplicate submission, fields, picker and location',
    (tester) async {
      await h.pump(tester);
      h.api.gate = Completer<void>();
      await tester.tap(h.confirm);
      await tester.pump();
      await tester.tap(h.confirm);
      await tester.pump();
      expect(h.api.posts, hasLength(1));
      expect(tester.widget<TextField>(h.name).enabled, false);
      expect(
        tester
            .widget<PopupMenuButton<RoomManagementSection>>(
              find.byType(PopupMenuButton<RoomManagementSection>),
            )
            .enabled,
        false,
      );
      h.api.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(RoomEditInfoSheet), findsNothing);
    },
  );

  testWidgets(
    'location roundtrip retains draft without submitting either page',
    (tester) async {
      await h.pump(tester);
      await tester.enterText(h.name, 'My draft');
      await tester.enterText(h.description, 'Line one\nLine two');
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();
      expect(find.text('Show room location'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(h.text(tester, h.name), 'My draft');
      expect(h.text(tester, h.description), 'Line one\nLine two');
      expect(h.api.posts, isEmpty);
    },
  );

  for (final outside in [true, false]) {
    testWidgets(
      '${outside ? 'outside' : 'back'} dismiss discards draft on reopen',
      (tester) async {
        await h.pump(tester);
        await tester.enterText(h.name, 'Unsaved');
        tester.testTextInput.hide();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        if (outside) {
          await tester.tapAt(const Offset(30, 50));
        } else {
          await tester.tap(find.bySemanticsLabel('Back'));
        }
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open editor'));
        await tester.pumpAndSettle();
        expect(h.text(tester, h.name), 'Happy!');
        expect(h.api.posts, isEmpty);
      },
    );
  }

  for (final invalidation in ['leave', 'account', 'role', 'room']) {
    testWidgets(
      '$invalidation closes editor and its menu without changing room',
      (tester) async {
        if (invalidation == 'role') {
          h.room.current = h.room.current.copyWith(
            roomInfo: RoomInfo.fromJson({
              'roomId': '123',
              'roomUid': 99,
              'roomLock': false,
            }),
          );
          h.room.setRole(UserRoomIdentity.manager);
        }
        await h.pump(tester);
        await tester.tap(find.byTooltip('More options'));
        await tester.pumpAndSettle();
        switch (invalidation) {
          case 'leave':
            await h.room.leaveRoom();
          case 'account':
            h.room.changeAccount(99);
          case 'role':
            h.room.setRole(UserRoomIdentity.audience);
          case 'room':
            h.room.generation++;
            h.room.emitState();
        }
        await tester.pumpAndSettle();
        expect(find.text('Location'), findsNothing);
        expect(find.byType(RoomEditInfoSheet), findsNothing);
        expect(h.api.posts, isEmpty);
      },
    );
  }

  testWidgets(
    'closing during cover upload ignores result and does not submit',
    (tester) async {
      await h.pump(tester);
      await h.selectCover(tester);
      h.upload.gate = Completer<void>();
      await tester.tap(h.confirm);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      h.upload.gate!.complete();
      await tester.pumpAndSettle();
      expect(h.api.posts, isEmpty);
      expect(h.room.refreshes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('edit info Lanhu v1 at $width', (tester) async {
      await h.pump(tester, width: width, direct: true, bottom: 34);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('edit-golden')),
        matchesGoldenFile(
          'goldens/room_edit_info_lanhu_v1/edit_${width.toInt()}.png',
        ),
      );
    });
  }

  testWidgets(
    'short viewport, keyboard and long description keep controls reachable',
    (tester) async {
      await h.pump(tester, width: 320, height: 568, bottom: 16);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(h.description, List.filled(180, '文').join());
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(h.confirm).dy, lessThanOrEqualTo(328));
      await tester.ensureVisible(h.description);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('180/200'), findsOneWidget);
      expect(h.api.posts, isEmpty);
    },
  );
}
