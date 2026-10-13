import 'package:flutter/material.dart';
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
      await precacheImage(image, context);
    }
  });
  await tester.pump();
}
