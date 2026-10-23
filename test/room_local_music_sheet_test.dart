import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/classes/room/music/room_local_music_sheet.dart';
import 'package:project/classes/room/music/room_local_music_view_model.dart';
import 'package:project/classes/room/music/room_music_repository.dart';
import 'package:project/classes/room/music/room_music_sheet.dart';
import 'package:project/localization/app_localizations.dart';

import 'support/room_local_music_fixture.dart';
import 'support/precache_room_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomLocalMusicFixture fixture;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fixture = RoomLocalMusicFixture();
    await fixture.initialize();
  });
  tearDown(() => fixture.dispose());

  Future<void> mount(WidgetTester tester, {bool localOnly = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomMusicRepositoryProvider.overrideWithValue(fixture.room.music),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            theme: ThemeData.dark(),
            locale: const Locale('en'),
            builder: (_, child) => RepaintBoundary(
              key: const ValueKey('music-test-root'),
              child: child!,
            ),
            localizationsDelegates: const [AppLocalizations.delegate],
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => localOnly
                      ? showRoomLocalMusicSheet(context, 'canonical')
                      : showRoomMusicSheet(context, 'canonical'),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 375.0, 800.0]) {
    testWidgets('local sheet at $width fits long names and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.runAsync(() async {
        await fixture.addSource(
          'A very long filename that must never push the selection control outside the screen.m4a',
        );
        await fixture.addSource('Second.FLAC', seed: 2);
      });
      await mount(tester, localOnly: true);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('room-local-music-sheet')))
            .width,
        width,
      );
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('Selected: 1'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'second');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(find.text('Second.FLAC'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Selected: 1'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      expect(tester.takeException(), isNull);
      if (width == 320) {
        await precacheRoomAssets(
          tester,
          tester.element(find.byType(RoomLocalMusicSheet)),
        );
        await expectLater(
          find.byKey(const ValueKey('music-test-root')),
          matchesGoldenFile('goldens/room_local_music_keyboard_320.png'),
        );
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'denied and permanent denial offer correct actions and file import',
    (tester) async {
      fixture.permission = 'permanentlyDenied';
      await mount(tester, localOnly: true);
      expect(find.text('Open settings'), findsOneWidget);
      expect(find.text('Import files'), findsOneWidget);
      expect(find.text('No local music found'), findsNothing);
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(fixture.settingsCalls, 1);
      fixture.permission = 'denied';
      final context = tester.element(find.byType(RoomLocalMusicSheet));
      await ProviderScope.containerOf(
        context,
      ).read(roomLocalMusicViewModelProvider('canonical').notifier).scan();
      await tester.pumpAndSettle();
      expect(find.text('Allow audio access'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('nested picker dismisses alone and preserves current music', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await fixture.room.import();
      await fixture.room.music.play(
        'canonical',
        fixture.room.music.tracks.single,
      );
      await fixture.addSource('Local.mp3');
    });
    await mount(tester);
    await tester.tap(find.byKey(const ValueKey('room-music-add')));
    await tester.pumpAndSettle();
    expect(find.byType(RoomLocalMusicSheet), findsOneWidget);
    expect(fixture.room.pickerCalls, 1);
    await tester.tap(find.byTooltip('Cancel').last);
    await tester.pumpAndSettle();
    expect(find.byType(RoomLocalMusicSheet), findsNothing);
    expect(find.byType(RoomMusicSheet), findsOneWidget);
    expect(fixture.room.engine.stops, 0);
    expect(fixture.room.agora.state.music.title, 'music-0.mp3');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('import completion returns only the local sheet to the player', (
    tester,
  ) async {
    await tester.runAsync(() => fixture.addSource('Local.mp3'));
    await mount(tester);
    await tester.tap(find.byKey(const ValueKey('room-music-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('room-local-music-add')));
      for (var i = 0; i < 200 && fixture.room.music.tracks.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pumpAndSettle();
    expect(find.byType(RoomLocalMusicSheet), findsNothing);
    expect(find.text('Local.mp3'), findsOneWidget);
    expect(fixture.room.engine.starts, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
