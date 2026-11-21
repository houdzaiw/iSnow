import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/gift/effects/room_gift_asset_resolver.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/models/room_gift_panel_models.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_panel_view_model.dart';
import 'package:project/classes/room/gift/views/room_gift_panel_extras.dart';
import 'package:project/classes/room/gift/views/room_gift_preview.dart';
import 'package:project/localization/app_localizations.dart';

import 'support/precache_room_assets.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(
        File(
          'test/fixtures/fonts/Roboto-Regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await font.load();
  });
  const gift = RoomGift(
    id: 99,
    name: 'Preview',
    icon: '',
    price: 1,
    tabId: 1,
    isCombo: 0,
    animationUrl: 'https://fixture.invalid/99.pag',
  );
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    double width = 375,
    String language = 'en',
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomGiftAnimationProvider(gift).overrideWith(
            (ref) async => throw const FormatException('Fixture decoder error'),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
            locale: const Locale('en'),
            theme: ThemeData(fontFamily: 'Roboto'),
            localizationsDelegates: const [AppLocalizations.delegate],
            supportedLocales: const [Locale('en')],
            home: Scaffold(
              backgroundColor: Colors.black,
              body: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 640),
                  textScaler: TextScaler.linear(textScale),
                ),
                child: Directionality(
                  textDirection: language == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: RepaintBoundary(
                    key: const ValueKey('extras-snapshot'),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await precacheRoomAssets(tester, tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('real lucky snapshot and SUPER amount fit $width', (
      tester,
    ) async {
      await mount(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: RoomGiftPanelExtras(
            animate: false,
            onRetry: () {},
            state: const RoomGiftPanelState(
              snapshots: [
                RoomGiftBannerSnapshot(
                  giftId: 99,
                  senderUid: 7,
                  senderName: 'Long actual winner name that must truncate',
                  senderAvatar: '',
                  multiple: 1000,
                  winAmount: 99999999,
                ),
              ],
              jackpot: RoomJackpotInfo(
                enabled: true,
                mode: 'SUPER',
                displayAmount: 123456789012,
              ),
            ),
          ),
        ),
        width: width,
      );
      expect(find.text('123456789012'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('extras-snapshot')),
        matchesGoldenFile(
          'goldens/room_gift_panel_v3/extras_${width.toInt()}.png',
        ),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('small preview handles RTL large-text error, retry and close', (
    tester,
  ) async {
    var retries = 0, closes = 0;
    await mount(
      tester,
      Center(
        child: SizedBox(
          width: 150,
          height: 100,
          child: RoomGiftPreview(
            gift: gift,
            onRetry: () => retries++,
            onClose: () => closes++,
          ),
        ),
      ),
      width: 320,
      language: 'ar',
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(TextButton));
    await tester.tap(find.byType(TextButton));
    expect(retries, 1);
    await tester.tap(
      find.descendant(
        of: find.bySemanticsLabel('Close gift preview'),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pump();
    expect(closes, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
