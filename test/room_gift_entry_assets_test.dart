import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/theme/app_theme.dart';

void main() {
  for (final asset in [
    AppAssets.roomGiftButtonAnimation,
    AppAssets.roomMemberGiftAnimation,
  ]) {
    testWidgets('gift entry decodes animated WebP: $asset', (tester) async {
      await tester.runAsync(() async {
        final data = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        try {
          expect(codec.frameCount, 10);
          final first = await codec.getNextFrame();
          final second = await codec.getNextFrame();
          try {
            expect(first.duration, greaterThan(Duration.zero));
            final firstPixels = await first.image.toByteData();
            final secondPixels = await second.image.toByteData();
            expect(
              firstPixels!.buffer.asUint8List(),
              isNot(orderedEquals(secondPixels!.buffer.asUint8List())),
            );
          } finally {
            first.image.dispose();
            second.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      });
    });
  }
}
