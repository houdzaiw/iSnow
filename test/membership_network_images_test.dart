import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/profile/membership/membership_models.dart';
import 'package:project/classes/profile/membership/membership_repository.dart';
import 'package:project/classes/profile/membership/membership_view_model.dart';
import 'package:project/classes/profile/membership/views/membership_page.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/widgets/app_network_image.dart';

import 'support/membership_fakes.dart';
import 'support/system_message_fixture.dart';

class _PreviewCache extends SystemImageCacheFake {
  Completer<void>? gate;

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    await gate?.future;
    yield* super.getFileStream(
      url,
      key: key,
      headers: headers,
      withProgress: withProgress,
    );
  }
}

void main() {
  const preview = 'https://example.test/vip-preview.png';
  const detail = 'https://example.test/vip-privilege.png';
  late MembershipFixture fixture;
  late _PreviewCache cache;

  setUp(() async {
    fixture = MembershipFixture();
    final vip = membershipVip();
    for (final level in vip['vipInfos'] as List) {
      level['showIconUrl'] = preview;
      for (final perk in level['privilegeInfoVOS'] as List) {
        perk['detail']['image'] = detail;
      }
    }
    fixture.api.responses[HttpApi.membershipVip] = vip;
    cache = _PreviewCache();
    await cache.prepare();
    // Do not read the lazy default: it starts the real disk cache and platform
    // plugins. This test isolate uses only decoded fixture files.
    CachedNetworkImageProvider.defaultCacheManager = cache;
    addTearDown(() {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
    }
    await tester.pumpAndSettle();
  }

  Future<void> mount(
    WidgetTester tester, {
    double width = 375,
    MembershipKind kind = MembershipKind.vip,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membershipRepositoryProvider.overrideWithValue(fixture.repository),
          membershipClockProvider.overrideWithValue(() => membershipNow),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('en')],
          home: MembershipPage(kind: kind),
        ),
      ),
    );
    // Do not settle an intentionally pending image's progress animation.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder network(String url) => find.byWidgetPredicate(
    (widget) => widget is AppNetworkImage && widget.url == url,
  );

  Finder decoded(String url) => find.descendant(
    of: network(url),
    matching: find.byWidgetPredicate(
      (widget) => widget is RawImage && widget.image != null,
    ),
  );

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('VIP remote preview loads full width at $width', (
      tester,
    ) async {
      cache.gate = Completer<void>();
      await mount(tester, width: width);
      expect(tester.takeException(), isNull);
      expect(network(preview), findsOneWidget);
      expect(
        find.descendant(
          of: network(preview),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      cache.gate!.complete();
      await settle(tester);
      expect(decoded(preview), findsOneWidget);
      expect(tester.getSize(network(preview)).width, width);
      expect(tester.takeException(), isNull);
      expect(fixture.api.calls.where((call) => call.method == 'POST'), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('VIP remote privilege detail fills bounded aspect ratio', (
    tester,
  ) async {
    await mount(tester);
    await settle(tester);
    final perk = find.text('Exclusive membership privilege 1');
    await tester.ensureVisible(perk);
    await tester.tap(perk);
    await settle(tester);
    expect(find.text('Privilege details'), findsOneWidget);
    expect(decoded(detail), findsOneWidget);
    final size = tester.getSize(network(detail));
    expect(size.width.isFinite && size.height.isFinite, isTrue);
    expect(
      size.width / size.height,
      closeTo(MembershipTheme.galleryRatio, .01),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(network(detail), findsNothing);
    expect(decoded(preview), findsOneWidget);
    expect(fixture.api.calls.where((call) => call.method == 'POST'), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Noble remote static preview also decodes without layout errors',
    (tester) async {
      const noblePreview = 'https://example.test/noble-preview.png';
      fixture.api.responses[HttpApi.membershipNoble] = [
        for (final noble in membershipNobles())
          {...noble, 'mp4Url': noblePreview},
      ];
      await mount(tester, kind: MembershipKind.noble);
      await settle(tester);
      expect(decoded(noblePreview), findsWidgets);
      expect(find.text('Aristocracy'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(fixture.api.calls.where((call) => call.method == 'POST'), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('VIP unavailable remote image shows existing missing asset', (
    tester,
  ) async {
    cache.fail = true;
    await mount(tester);
    await settle(tester);
    expect(cache.requests, contains(preview));
    expect(
      find.descendant(
        of: network(preview),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == AppAssets.iconMissing,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('VIP Center'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
