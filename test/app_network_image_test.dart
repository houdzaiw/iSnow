import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/widgets/app_network_image.dart';

void main() {
  final cases = <({String name, double? extent, int? pixels})>[
    (name: 'unspecified', extent: null, pixels: null),
    (name: 'infinity', extent: double.infinity, pixels: null),
    (name: 'negative infinity', extent: double.negativeInfinity, pixels: null),
    (name: 'NaN', extent: double.nan, pixels: null),
    (name: 'zero', extent: 0, pixels: null),
    (name: 'negative', extent: -24, pixels: null),
    (name: 'subpixel rounds to zero', extent: 0.2, pixels: null),
    (name: 'one decoded pixel', extent: 0.5, pixels: 1),
    (name: 'fractional', extent: 100.75, pixels: 201),
    (name: 'normal', extent: 48, pixels: 96),
    (name: 'scaled overflow', extent: double.maxFinite, pixels: null),
  ];
  for (final sample in cases) {
    testWidgets('cache dimensions: ${sample.name}', (tester) async {
      late CachedNetworkImage image;
      // Inspect configuration only: NaN/negative sizes are not legal layout
      // constraints. This tests cache conversion without mounting those sizes.
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final clip =
                AppNetworkImage(
                      url: 'https://example.test/image.png',
                      width: sample.extent,
                      height: sample.extent,
                    ).build(context)
                    as ClipRRect;
            image = clip.child! as CachedNetworkImage;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(tester.takeException(), isNull);
      expect(image.memCacheWidth, sample.pixels);
      expect(image.memCacheHeight, sample.pixels);
      if (sample.extent?.isNaN == true) {
        expect(image.width!.isNaN, isTrue);
        expect(image.height!.isNaN, isTrue);
      } else {
        expect(image.width, sample.extent);
        expect(image.height, sample.extent);
      }
    });
  }

  testWidgets('unbounded width does not discard finite height cache hint', (
    tester,
  ) async {
    late CachedNetworkImage image;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          final clip =
              const AppNetworkImage(
                    url: 'https://example.test/image.png',
                    width: double.infinity,
                    height: 120,
                  ).build(context)
                  as ClipRRect;
          image = clip.child! as CachedNetworkImage;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(tester.takeException(), isNull);
    expect(image.width, double.infinity);
    expect(image.memCacheWidth, isNull);
    expect(image.memCacheHeight, 240);
  });
}
