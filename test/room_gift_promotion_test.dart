import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/views/room_gift_promotion_bar.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/theme/app_theme.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    RoomGiftPromotionBar bar, {
    double width = 375,
  }) async {
    tester.view.physicalSize = Size(width, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          theme: AppTheme.light,
          home: Scaffold(
            body: Align(alignment: Alignment.topCenter, child: bar),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> image(WidgetTester tester, String url) async {
    final info = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        await File(AppAssets.lanhuRoomGiftCoin).readAsBytes(),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return ImageInfo(image: frame.image);
    });
    PaintingBinding.instance.imageCache.putIfAbsent(
      CachedNetworkImageProvider(url),
      () => OneFrameImageStreamCompleter(Future.value(info!)),
    );
    addTearDown(PaintingBinding.instance.imageCache.clear);
  }

  testWidgets(
    'unknown/non-first and no banner collapses whole row and never shows sample campaign',
    (tester) async {
      await mount(tester, const RoomGiftPromotionBar(bannerUrl: '  '));
      expect(tester.getSize(find.byType(RoomGiftPromotionBar)).height, 0);
      expect(find.byType(Image), findsNothing);
    },
  );
  testWidgets('eligible badge calls first pack action only', (tester) async {
    var calls = 0;
    await mount(
      tester,
      RoomGiftPromotionBar(
        showFirstRecharge: true,
        onOpenFirstRecharge: () => calls++,
      ),
    );
    await tester.tap(find.bySemanticsLabel('First Recharge'));
    expect(calls, 1);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });
  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'real campaign and first badge coexist and tap correct action at $width',
      (tester) async {
        const url = 'https://fixture.example/campaign.png';
        await image(tester, url);
        var first = 0, campaign = 0;
        await mount(
          tester,
          RoomGiftPromotionBar(
            showFirstRecharge: true,
            bannerUrl: url,
            onOpenFirstRecharge: () => first++,
            onOpenCampaign: () => campaign++,
          ),
          width: width,
        );
        await tester.tap(find.byType(CachedNetworkImage));
        expect(campaign, 1);
        expect(first, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('image without a link remains display-only', (tester) async {
    const url = 'https://fixture.example/no-link.png';
    await image(tester, url);
    await mount(tester, const RoomGiftPromotionBar(bannerUrl: url));
    await tester.tap(find.byType(CachedNetworkImage));
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('First Recharge'), findsNothing);
  });
}
