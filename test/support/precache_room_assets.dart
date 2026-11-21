import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/theme/app_theme.dart';

Future<void> precacheRoomAssets(
  WidgetTester tester,
  BuildContext context,
) async {
  final images = <AssetImage>{
    ...tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>(),
    const AssetImage(AppAssets.roomExitKeep),
    const AssetImage(AppAssets.roomExitClose),
    const AssetImage(AppAssets.roomMiniClose),
    const AssetImage(AppAssets.lanhuRoomIconMissing),
  };
  await tester.runAsync(() async {
    for (final image in images) {
      if (image.assetName == AppAssets.roomGiftButtonAnimation ||
          image.assetName == AppAssets.roomMemberGiftAnimation) {
        // Animated WebP emits on a scheduled frame. Awaiting precacheImage in
        // runAsync would deadlock without a pump. Warm its first frame without
        // waiting on a scheduled stream; codec animation has its own test.
        final key = await image.obtainKey(
          createLocalImageConfiguration(context),
        );
        final bytes = await rootBundle.load(image.assetName);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        var inserted = false;
        PaintingBinding.instance.imageCache.putIfAbsent(key, () {
          inserted = true;
          return OneFrameImageStreamCompleter(
            Future.value(ImageInfo(image: frame.image)),
          );
        });
        if (!inserted) frame.image.dispose();
        continue;
      }
      await precacheImage(image, context);
    }
  });
  await tester.pump();
}
