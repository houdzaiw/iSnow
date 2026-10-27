import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/models/room_more_tools_models.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/music/room_music_repository.dart';
import 'package:project/classes/room/music/room_music_sheet.dart';
import 'package:project/classes/room/music/room_music_view_model.dart';
import 'package:project/classes/room/room_more_tools_repository.dart';
import 'package:project/classes/room/room_page.dart';
import 'package:project/classes/room/viewmodel/room_more_tools_view_model.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/room_system_volume_manager.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/theme/app_theme.dart';

import 'support/room_music_fixture.dart';
import 'support/room_tools_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomMusicFixture fixture;
  late RoomMusicRepository music;
  late RoomSystemVolumeManager system;
  var pageMounted = false;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fixture = RoomMusicFixture();
    pageMounted = false;
    await fixture.initialize();
    fixture.http.roomOwnerUid = 10;
    await fixture.manager.refreshRoomInfo();
    music = _EntryMusicRepository(room: fixture.room, library: fixture.library);
    await music.load();
    system = _SystemVolume();
  });
  tearDown(() async {
    music.dispose();
    await fixture.dispose();
    await system.dispose();
  });

  Future<void> unmount(WidgetTester tester) async {
    if (!pageMounted) return;
    pageMounted = false;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final disposing = system.dispose();
    await tester.pump();
    await disposing;
  }

  Future<RoomMusicFixture> mount(
    WidgetTester tester, {
    bool onMic = false,
    double width = 375,
  }) async {
    tester.view.physicalSize = Size(width, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => unmount(tester));
    pageMounted = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomRepositoryProvider.overrideWithValue(fixture.room),
          roomMusicRepositoryProvider.overrideWithValue(music),
          roomSystemVolumeManagerProvider.overrideWithValue(system),
          roomToolsRepositoryProvider.overrideWithValue(ToolsApiFake()),
          roomGiftRepositoryProvider.overrideWithValue(_Gifts()),
          roomMoreToolsRepositoryProvider.overrideWithValue(_Banners()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [AppLocalizations.delegate],
            home: RoomPage(roomId: 'canonical'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (!onMic) {
      fixture.micUpdate([20]);
      await tester.pumpAndSettle();
    }
    return fixture;
  }

  final musicTool = find.image(const AssetImage(AppAssets.lanhuRoomMoreMusic));
  final musicEntry = find.byKey(const ValueKey('room-music-entry'));
  final musicBox = find.byKey(const ValueKey('room-music-box'));
  Future<void> openMore(WidgetTester tester) async {
    await tester.tap(
      find.image(const AssetImage(AppAssets.lanhuRoomBottomMore)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> dismissMore(WidgetTester tester) async {
    Navigator.of(
      tester.element(find.byKey(const ValueKey('room-more-tools-sheet'))),
    ).pop();
    await tester.pumpAndSettle();
  }

  Future<void> activateMusic(WidgetTester tester) async {
    await openMore(tester);
    expect(musicTool, findsOneWidget);
    await tester.tap(musicTool);
    await tester.pumpAndSettle();
    expect(musicEntry, findsOneWidget);
    expect(musicBox, findsOneWidget);
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('hidden strip keeps audience right-aligned at $width', (
      tester,
    ) async {
      await mount(tester, width: width);
      expect(musicEntry, findsNothing);
      final audience = find.byKey(const ValueKey('room-audience-entry'));
      final before = tester.getRect(audience);
      expect(before.right, closeTo(width - AppSpacing.xl.w, .01));
      // The hidden music area must not retain an invisible tap target.
      await tester.tapAt(Offset(AppSpacing.xl.w, before.center.dy));
      await tester.pumpAndSettle();
      expect(musicBox, findsNothing);
      await activateMusic(tester);
      expect(tester.getRect(audience), before);
      expect(tester.getCenter(musicBox).dx, closeTo(width / 2, .01));
      expect(tester.getCenter(musicBox).dy, closeTo(812 / 2, .01));
      expect(fixture.http.opens, isEmpty);
      expect(fixture.engine.starts, isEmpty);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  for (final fromMore in [false, true]) {
    testWidgets(
      'off-mic owner opens music from ${fromMore ? 'More' : 'activated strip'} without playback',
      (tester) async {
        final fixture = await mount(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(RoomPage)),
        );
        expect(
          container.read(roomViewModelProvider('canonical')).isOnMic,
          isFalse,
        );
        expect(musicEntry, findsNothing);
        await activateMusic(tester);
        if (!fromMore) {
          await tester.tap(find.byKey(const ValueKey('room-music-collapse')));
          await tester.pumpAndSettle();
          await tester.tap(musicEntry);
        }
        await tester.pumpAndSettle();
        final box = find.byKey(const ValueKey('room-music-box'));
        expect(box, findsOneWidget);
        expect(
          find.text('You need to take the mic to play music'),
          findsNothing,
        );
        expect(find.byType(SnackBar), findsNothing);
        expect(fixture.http.opens, isEmpty);
        expect(fixture.engine.starts, isEmpty);

        // A different audience/mic update must not collapse an off-mic browser.
        fixture.micUpdate([20, 30]);
        await tester.pumpAndSettle();
        expect(box, findsOneWidget);
        expect(
          container.read(roomMusicViewModelProvider('canonical')).expanded,
          isTrue,
        );
        await tester.tap(find.byKey(const ValueKey('room-music-playlist')));
        await tester.pumpAndSettle();
        expect(find.byType(RoomMusicSheet), findsOneWidget);
        expect(fixture.http.opens, isEmpty);
        expect(fixture.engine.starts, isEmpty);
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(RoomMusicSheet))).pop();
        await tester.pumpAndSettle();
        expect(
          container.read(roomMusicViewModelProvider('canonical')).isOpened,
          isTrue,
        );
        await unmount(tester);
      },
    );
  }

  testWidgets('leaving a microphone still collapses the open box', (
    tester,
  ) async {
    final fixture = await mount(tester, onMic: true);
    await activateMusic(tester);
    expect(find.byKey(const ValueKey('room-music-box')), findsOneWidget);
    fixture.micUpdate([20]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room-music-box')), findsNothing);
    expect(musicEntry, findsOneWidget);
    await openMore(tester);
    expect(musicTool, findsOneWidget);
    await dismissMore(tester);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('closing hides only the strip; More can always reactivate it', (
    tester,
  ) async {
    await mount(tester);
    expect(musicEntry, findsNothing);
    await activateMusic(tester);
    await openMore(tester);
    expect(musicTool, findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RoomPage)),
    );
    // Also verifies that the currently mounted More sheet reacts to closure.
    final closing = container
        .read(roomMusicViewModelProvider('canonical').notifier)
        .close();
    await tester.pumpAndSettle();
    await closing;
    expect(musicTool, findsOneWidget);
    expect(musicEntry, findsNothing);
    await dismissMore(tester);
    expect(musicBox, findsNothing);
    await activateMusic(tester);
    await tester.tap(find.byKey(const ValueKey('room-music-close')));
    await tester.pumpAndSettle();
    await openMore(tester);
    expect(musicTool, findsOneWidget);
    expect(musicEntry, findsNothing);
    await dismissMore(tester);
    await activateMusic(tester);
    await openMore(tester);
    expect(musicTool, findsOneWidget);
    await dismissMore(tester);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('only owner or manager can activate Music from More', (
    tester,
  ) async {
    await tester.runAsync(() async {
      fixture.http.roomOwnerUid = 20;
      await fixture.manager.refreshRoomInfo();
    });
    await mount(tester);
    expect(musicEntry, findsNothing);
    await openMore(tester);
    expect(musicTool, findsNothing);
    void setIdentity(int identity) => fixture.socket.controller.add(
      RoomSocketMessage(
        channel: 'room:canonical',
        event: 'RoomIdentityUpdateEvent',
        raw: const {},
        payload: {'uid': 10, 'roomIdentity': identity},
      ),
    );
    await tester.runAsync(() async {
      setIdentity(1000);
      await fixture.flush();
    });
    await tester.pumpAndSettle();
    expect(musicTool, findsOneWidget);
    await tester.tap(musicTool);
    await tester.pumpAndSettle();
    expect(musicEntry, findsOneWidget);
    expect(musicBox, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('room-music-collapse')));
    await tester.pumpAndSettle();
    await openMore(tester);
    await tester.runAsync(() async {
      setIdentity(0);
      await fixture.flush();
    });
    await tester.pumpAndSettle();
    expect(musicTool, findsNothing);
    await dismissMore(tester);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('stopping and closing the playlist keep the strip activated', (
    tester,
  ) async {
    await mount(tester);
    await activateMusic(tester);
    await tester.tap(find.byKey(const ValueKey('room-music-playlist')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RoomPage)),
    );
    final stopping = container
        .read(roomMusicViewModelProvider('canonical').notifier)
        .stop();
    await tester.pumpAndSettle();
    await stopping;
    Navigator.of(tester.element(find.byType(RoomMusicSheet))).pop();
    await tester.pumpAndSettle();
    expect(musicEntry, findsOneWidget);
    expect(musicBox, findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Keep restores the strip but not the expanded box', (
    tester,
  ) async {
    await mount(tester);
    await activateMusic(tester);
    await unmount(tester);
    fixture.manager.minimizeRoom();
    // The mini-room navigation restores the session before opening RoomPage.
    fixture.manager.restoreRoom();
    await mount(tester);
    expect(musicEntry, findsOneWidget);
    expect(musicBox, findsNothing);
    await tester.tap(musicEntry);
    await tester.pumpAndSettle();
    expect(musicBox, findsOneWidget);
    expect(fixture.http.opens, isEmpty);
    await unmount(tester);
  });
}

// Native stop/lease races are exercised by the music box and lifecycle tests.
class _EntryMusicRepository extends RoomMusicRepository {
  _EntryMusicRepository({super.room, super.library});
  @override
  Future<void> stop() async {}
}

class _Banners extends RoomMoreToolsRepository {
  @override
  Future<List<RoomToolBanner>> fetchBanners({
    required RoomMoreBannerPosition position,
    required String roomId,
  }) async => [];
}

class _SystemVolume implements RoomSystemVolumeManager {
  @override
  Stream<double> get changes => Stream<double>.value(.6);
  @override
  Future<void> setVolume(double value) async {}
  @override
  Future<void> dispose() async {}
}

class _Gifts extends RoomGiftRepository {
  @override
  Future<RoomGiftCatalog> fetchCatalog() async =>
      const RoomGiftCatalog(tabs: [], balance: 1000, canSendSelf: false);
  @override
  Future<int> fetchBalance() async => 1000;
  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async =>
      const RoomGiftSendResult();
}
