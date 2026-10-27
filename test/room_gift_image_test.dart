import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/views/room_gift_image.dart';
import 'package:project/classes/room/gift/views/room_gift_pages.dart';
import 'package:project/theme/app_theme.dart';

import 'support/precache_room_assets.dart';
import 'support/room_gift_platform_fixture.dart';

void main() {
  testWidgets(
    'local catalog gift is decoded as an asset without touching the cache plugin',
    (tester) async {
      final platform = RoomGiftPlatformFixture()..install();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        platform.uninstall();
      });
      const gift = RoomGift(
        id: 31,
        name: 'Gift',
        icon: AppAssets.lanhuRoomBottomGift,
        price: 5,
        isCombo: 1,
        tabId: 1,
      );
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: RoomGiftPages(
                gifts: const [gift],
                selectedGiftKey: gift.selectionKey,
                onGiftSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await precacheRoomAssets(
        tester,
        tester.element(find.byType(RoomGiftPages)),
      );
      expect(
        find.image(const AssetImage(AppAssets.lanhuRoomBottomGift)),
        findsOneWidget,
      );
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(platform.unexpected, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid image sources use the red placeholder without native calls',
    (tester) async {
      for (final source in ['', '/tmp/gift.png', 'javascript:alert(1)']) {
        await tester.pumpWidget(
          MaterialApp(home: RoomGiftImage(source: source, size: 56)),
        );
        await precacheRoomAssets(
          tester,
          tester.element(find.byType(RoomGiftImage)),
        );
        expect(
          find.image(const AssetImage(AppAssets.lanhuRoomIconMissing)),
          findsOneWidget,
        );
        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'remote images retain cache support and the supplied loading state',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final context = tester.element(find.byType(Scaffold));
      const spinner = CircularProgressIndicator();
      final image = RoomGiftImage(
        source: 'https://cdn.example/gift.png',
        size: 56,
        placeholderBuilder: (_) => spinner,
      ).build(context);
      expect(image, isA<CachedNetworkImage>());
      final remote = image as CachedNetworkImage;
      expect(remote.imageUrl, 'https://cdn.example/gift.png');
      expect(remote.placeholder!(context, remote.imageUrl), same(spinner));
    },
  );
}
