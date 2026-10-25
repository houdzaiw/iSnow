import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/room/music/room_music_overlay.dart';
import 'package:project/classes/room/music/room_music_repository.dart';
import 'package:project/classes/room/music/room_music_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/room_system_volume_manager.dart';
import 'package:project/model/room_music_state.dart';

import 'support/precache_room_assets.dart';
import 'support/room_music_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(
        File(
          'test/fixtures/fonts/Roboto-Regular.ttf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    await font.load();
  });
  late RoomMusicFixture fixture;
  late RoomSystemVolumeManager system;
  late StreamController<double> hardware;
  late List<double> systemWrites;
  var systemValue = .6;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fixture = RoomMusicFixture();
    await fixture.initialize();
    hardware = StreamController<double>.broadcast();
    systemWrites = [];
    systemValue = .6;
    system = RoomSystemVolumeManager(
      read: () async => systemValue,
      observe: () => hardware.stream,
      write: (value) async {
        systemWrites.add(value);
        systemValue = value;
      },
    );
  });
  tearDown(() async {
    await fixture.dispose();
    await system.dispose();
    await hardware.close();
  });

  RoomMusicViewModel model() {
    final value = RoomMusicViewModel(
      repository: fixture.music,
      roomId: 'canonical',
      systemVolume: system,
    );
    addTearDown(value.dispose);
    return value;
  }

  test(
    'expand never acquires player; collapse and Keep keep playback, restore collapsed',
    () async {
      await fixture.import();
      final vm = model();
      await fixture.flush();
      vm.expand();
      expect(vm.state.expanded, isTrue);
      expect(fixture.http.opens, isEmpty);
      expect(fixture.engine.starts, isEmpty);
      await vm.toggle();
      vm.collapse();
      expect(fixture.agora.state.music.status, RoomMusicPlayback.playing);
      expect(fixture.engine.stops, 0);
      vm.expand();
      fixture.manager.minimizeRoom();
      expect(vm.state.expanded, isFalse);
      fixture.manager.restoreRoom();
      expect(vm.state.expanded, isFalse);
      expect(fixture.agora.state.music.status, RoomMusicPlayback.playing);
    },
  );

  test('close bypasses busy and cancels pending server acquisition', () async {
    await fixture.import();
    final vm = model();
    await fixture.flush();
    vm.expand();
    final gate = Completer<void>();
    fixture.http.openGate = gate;
    final playing = vm.toggle();
    await _until(() => fixture.http.opens.isNotEmpty);
    expect(vm.state.busy, isTrue);
    final closing = vm.close();
    expect(vm.state.expanded, isFalse);
    expect(vm.state.closing, isTrue);
    gate.complete();
    await playing;
    await closing;
    expect(fixture.engine.starts, isEmpty);
    expect(fixture.http.closes, ['canonical']);
    expect(vm.state.busy, isFalse);
  });

  test(
    'close during SDK preparation drains mixing and ignores late playing callback',
    () async {
      await fixture.import();
      final vm = model();
      await fixture.flush();
      final gate = Completer<void>();
      fixture.engine.startGate = gate;
      final playing = vm.toggle();
      await _until(() => fixture.engine.starts.isNotEmpty);
      expect(vm.state.playback.status, RoomMusicPlayback.preparing);
      final closing = vm.close();
      gate.complete();
      await playing;
      await closing;
      fixture.engine.musicState(AudioMixingStateType.audioMixingStatePlaying);
      expect(fixture.engine.stops, 1);
      expect(vm.state.playback.status, RoomMusicPlayback.stopped);
      expect(fixture.http.closes, ['canonical']);
    },
  );

  test('server release failure cannot leave sound and exposes error', () async {
    await fixture.import();
    final vm = model();
    await fixture.flush();
    await vm.toggle();
    fixture.http.failClose = true;
    await vm.close();
    expect(vm.state.playback.status, RoomMusicPlayback.stopped);
    expect(fixture.engine.stops, 1);
    expect(vm.state.error, contains('close failed'));
    expect(vm.state.closing, isFalse);
  });

  test(
    'modes cycle, independent volumes sync hardware and release listener on collapse',
    () async {
      final vm = model();
      await fixture.flush();
      vm.expand();
      await fixture.flush();
      expect(vm.state.systemVolume, .6);
      vm.cycleMode();
      expect(vm.state.mode.name, 'single');
      vm.cycleMode();
      expect(vm.state.mode.name, 'shuffle');
      vm.cycleMode();
      expect(vm.state.mode.name, 'loop');
      await vm.volume(73);
      expect(vm.state.playback.volume, 73);
      expect(systemWrites, isEmpty);
      await vm.systemVolume(.8);
      expect(vm.state.playback.volume, 73);
      expect(systemWrites, [.8]);
      hardware.add(.2);
      await fixture.flush();
      expect(vm.state.systemVolume, .2);
      vm.collapse();
      await fixture.flush();
      expect(hardware.hasListener, isFalse);
      expect(systemValue, .8);
    },
  );

  test(
    'shared volume coalesces in-flight writes and retains the released value',
    () async {
      await fixture.import();
      final vm = model();
      await vm.toggle();
      final gate = Completer<void>();
      fixture.engine.volumeGate = gate;
      final first = vm.volume(11);
      await _until(() => fixture.engine.volumes.last == 11);
      final middle = vm.volume(45);
      final last = vm.volume(93);
      gate.complete();
      await first;
      await middle;
      await last;
      expect(
        fixture.engine.volumes.sublist(fixture.engine.volumes.length - 2),
        [11, 93],
      );
      expect(fixture.engine.publishVolumes.last, 93);
      expect(vm.state.playback.volume, 93);
    },
  );

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'compact box at $width overlays, fits long names and leaves room interactive',
      (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await tester.runAsync(() => fixture.import());
        await tester.runAsync(
          () => fixture.room.playMusic(
            roomId: 'canonical',
            path: '${fixture.directory.path}/music-0.mp3',
            title:
                'Over_the_Horizon_a_very_long_recording_that_must_ellipsis.m4a',
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roomMusicRepositoryProvider.overrideWithValue(fixture.music),
              roomSystemVolumeManagerProvider.overrideWithValue(system),
            ],
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, _) => MaterialApp(
                locale: const Locale('en'),
                localizationsDelegates: const [AppLocalizations.delegate],
                home: const _RoomHarness(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final anchorBefore = tester.getTopLeft(
          find.byKey(const ValueKey('anchor')),
        );
        await tester.tap(find.text('Music'));
        await tester.pumpAndSettle();
        final box = find.byKey(const ValueKey('room-music-box'));
        expect(
          tester.getTopLeft(find.byKey(const ValueKey('anchor'))),
          anchorBefore,
        );
        final rect = tester.getRect(box);
        final bottom = tester.getRect(find.byKey(const ValueKey('bottom-bar')));
        expect(rect.bottom, lessThan(bottom.top));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
        expect(find.byType(Icon), findsNothing);
        expect(find.byKey(const ValueKey('room-music-progress')), findsNothing);
        await tester.tap(find.text('Outside'));
        await tester.pump();
        expect(find.text('Outside 1'), findsOneWidget);
        expect(box, findsOneWidget);
        await precacheRoomAssets(tester, tester.element(box));
        await expectLater(
          find.byKey(const ValueKey('room-box-root')),
          matchesGoldenFile('goldens/room_music_box_${width.toInt()}.png'),
        );
        await tester.tap(find.byKey(const ValueKey('room-music-mode')));
        await tester.pumpAndSettle();
        expect(fixture.music.mode.name, 'single');
        await tester.tap(find.byKey(const ValueKey('room-music-playlist')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('room-music-progress')),
          findsOneWidget,
        );
        // A nested local picker and playlist can be dismissed without stopping.
        Navigator.of(
          tester.element(find.byKey(const ValueKey('room-music-sheet'))),
        ).pop();
        await tester.pumpAndSettle();
        expect(fixture.engine.stops, 0);
        for (final rows in [0, 1, 4]) {
          await tester.tap(find.text('Seats'));
          tester.view.viewInsets = FakeViewPadding(bottom: rows == 4 ? 250 : 0);
          await tester.pumpAndSettle();
          expect(
            tester.getRect(box).bottom,
            lessThan(
              tester.getRect(find.byKey(const ValueKey('bottom-bar'))).top,
            ),
          );
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byKey(const ValueKey('room-music-collapse')));
        await tester.pumpAndSettle();
        expect(box, findsNothing);
        expect(fixture.engine.stops, 0);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.runAsync(system.dispose);
      },
    );
  }
}

class _RoomHarness extends ConsumerStatefulWidget {
  const _RoomHarness();
  @override
  ConsumerState<_RoomHarness> createState() => _RoomHarnessState();
}

class _RoomHarnessState extends ConsumerState<_RoomHarness> {
  final root = GlobalKey();
  final anchor = GlobalKey();
  final bottom = GlobalKey();
  int outside = 0;
  int rows = 1;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const ValueKey('room-box-root'),
    child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF59545F),
      body: Stack(
        key: root,
        children: [
          Column(
            children: [
              SizedBox(height: 70.0 + rows * 60),
              SizedBox(
                key: anchor,
                height: 48,
                child: Row(
                  children: [
                    TextButton(
                      key: const ValueKey('anchor'),
                      onPressed: () => ref
                          .read(
                            roomMusicViewModelProvider('canonical').notifier,
                          )
                          .expand(),
                      child: const Text('Music'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => outside++),
                      child: Text(
                        outside == 0 ? 'Outside' : 'Outside $outside',
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => rows = (rows + 1) % 5),
                child: const Text('Seats'),
              ),
              SizedBox(
                key: bottom,
                height: 54,
                child: const Center(
                  key: ValueKey('bottom-bar'),
                  child: Text('Room controls'),
                ),
              ),
            ],
          ),
          RoomMusicOverlay(
            roomId: 'canonical',
            rootKey: root,
            anchorKey: anchor,
            bottomBarKey: bottom,
          ),
        ],
      ),
    ),
  );
}

Future<void> _until(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}
