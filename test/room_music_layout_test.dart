import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/room/music/room_music_overlay.dart';
import 'package:project/classes/room/music/room_music_repository.dart';
import 'package:project/classes/room/music/room_music_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/room_system_volume_manager.dart';
import 'package:project/theme/app_theme.dart';

import 'support/room_music_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RoomMusicFixture fixture;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fixture = RoomMusicFixture();
    await fixture.initialize();
  });
  tearDown(() => fixture.dispose());

  for (final (name, size, padding, keyboard, bottomHeight) in [
    (
      'safe area',
      const Size(375, 812),
      const EdgeInsets.fromLTRB(20, 44, 12, 34),
      0.0,
      54.0,
    ),
    (
      'keyboard',
      const Size(375, 812),
      const EdgeInsets.fromLTRB(20, 44, 12, 34),
      360.0,
      54.0,
    ),
    (
      'short viewport',
      const Size(320, 360),
      const EdgeInsets.only(top: 24, bottom: 16),
      200.0,
      54.0,
    ),
    (
      'raised bottom bar',
      const Size(375, 700),
      const EdgeInsets.only(top: 24, bottom: 20),
      0.0,
      400.0,
    ),
  ]) {
    testWidgets('centered music box respects $name', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = FakeViewPadding(
        left: padding.left,
        top: padding.top,
        right: padding.right,
        bottom: padding.bottom,
      );
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewInsets);
      final root = GlobalKey();
      final bottom = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomMusicRepositoryProvider.overrideWithValue(fixture.music),
            roomSystemVolumeManagerProvider.overrideWithValue(_SystemVolume()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: const [AppLocalizations.delegate],
              home: Scaffold(
                resizeToAvoidBottomInset: false,
                body: SafeArea(
                  bottom: false,
                  child: Stack(
                    key: root,
                    children: [
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: bottomHeight,
                        child: SizedBox(key: bottom),
                      ),
                      RoomMusicOverlay(
                        roomId: 'canonical',
                        rootKey: root,
                        bottomBarKey: bottom,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RoomMusicOverlay)),
      );
      container.read(roomMusicViewModelProvider('canonical').notifier).expand();
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byKey(const ValueKey('room-music-box')));
      expect(rect.left, greaterThanOrEqualTo(padding.left));
      expect(rect.top, greaterThanOrEqualTo(padding.top));
      expect(rect.right, lessThanOrEqualTo(size.width - padding.right));
      expect(rect.bottom, lessThan(tester.getTopLeft(find.byKey(bottom)).dy));
      expect(rect.bottom, lessThan(size.height - keyboard));
      expect(
        rect.width / rect.height,
        closeTo(AppSpacing.musicBoxWidth / AppSpacing.musicBoxHeight, .01),
      );
      expect(
        rect.center.dx,
        closeTo((padding.left + size.width - padding.right) / 2, .01),
      );
      if (name == 'raised bottom bar') {
        expect(
          rect.bottom,
          closeTo(size.height - bottomHeight - AppSpacing.musicBoxEdge.w, .01),
        );
      } else {
        final visibleBottom =
            size.height -
            (keyboard > padding.bottom ? keyboard : padding.bottom);
        expect(rect.center.dy, closeTo((padding.top + visibleBottom) / 2, .01));
      }
      if (name == 'short viewport') {
        expect(rect.width, lessThan(AppSpacing.musicBoxWidth.w));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}

class _SystemVolume implements RoomSystemVolumeManager {
  @override
  Stream<double> get changes => Stream<double>.value(.6);
  @override
  Future<void> setVolume(double value) async {}
  @override
  Future<void> dispose() async {}
}
