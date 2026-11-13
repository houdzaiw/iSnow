import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/chat/room_public_message.dart';
import 'package:project/classes/room/chat/room_public_message_item.dart';
import 'package:project/classes/room/chat/room_public_message_text.dart';
import 'package:project/classes/room/gift/models/room_gift_event_models.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/interaction/room_mention.dart';
import 'package:project/classes/room/interaction/room_animated_artwork.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/model/room_user_info.dart';
import 'package:project/theme/app_theme.dart';

import 'support/precache_room_assets.dart';

final _time = DateTime(2026, 11, 13);
final _appearance = RoomUserAppearance.fromJson({
  'gender': 1,
  'countryCode': 'TR',
  'avatarWidget': {'icon': AppAssets.lanhuProfileHomepageAvatarFrame},
  'userLevel': {
    'wealthLevel': 80,
    'wealthLevelIcon': AppAssets.lanhuProfileHomepageWealth,
    'charmLevel': 10,
    'charmLevelIcon': AppAssets.lanhuProfileHomepageCharm,
    'activeLevel': 20,
    'activeLevelIcon': AppAssets.lanhuRoomBadgeMedal,
    'vipLevel': 4,
    'vipMedal': AppAssets.membershipVipBadge,
    'aristocracyLevel': 3,
    'aristocracyEnIcon': AppAssets.membershipNobleBadge,
    'plaqueEn': AppAssets.lanhuProfileBadge01,
  },
  'userWearMedalVOS': [
    for (var i = 0; i < 5; i++)
      {'icon': AppAssets.lanhuProfileBadge02, 'sortingOrder': i},
  ],
});

RoomChatEntry _message(
  String id, {
  String text = 'Hi',
  RoomUserAppearance? appearance,
  RoomChatEntryKind kind = RoomChatEntryKind.chat,
  String? media,
  int? partyId,
}) => RoomChatEntry(
  id: id,
  kind: kind,
  text: text,
  createdAt: _time,
  senderUid: 20,
  senderName: appearance == null ? 'Peer' : '🇹🇷⭐Anime الشخ very long name',
  senderAvatar: AppAssets.lanhuRoomAvatarSample,
  senderAppearance: appearance ?? const RoomUserAppearance(),
  mediaUrl: media,
  partyId: partyId,
);

List<RoomChatEntry> _overview() => [
  RoomChatEntry.system(
    'Violations may lead to account restrictions. Please respect everyone in the room.',
  ),
  _message(
    'decorated',
    appearance: _appearance,
    text: encodeRoomMention(
      'Of violation,the platform will take measures @such ai block your account.of violation.',
      (uid: 31, name: 'such'),
    ),
  ),
  _message('short'),
  RoomChatEntry(
    id: 'gift',
    kind: RoomChatEntryKind.gift,
    text: '',
    createdAt: _time,
    gift: RoomGiftPublicMessage(
      key: 'gift',
      gift: RoomGift(
        id: 1,
        name: 'Rose',
        icon: AppAssets.membershipCoin,
        price: 1,
        isCombo: 0,
        tabId: 0,
      ),
      count: 2,
      targetLabel: 'all mic',
      createdAt: _time,
      winAmount: 150,
      multiplier: 3,
      sender: RoomGiftUser(
        uid: 20,
        name: 'Sender',
        avatar: AppAssets.lanhuRoomAvatarSample,
        appearance: _appearance,
      ),
    ),
  ),
  _message('enter', text: 'entered the room', kind: RoomChatEntryKind.enter),
];

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('test/fixtures/fonts/Roboto-Regular.ttf').readAsBytesSync(),
          ),
        ),
      );
    await font.load();
  });
  Future<void> pump(
    WidgetTester tester,
    List<RoomChatEntry> messages, {
    double width = 375,
    double keyboard = 0,
    Locale locale = const Locale('en'),
    ValueChanged<int>? onUserTap,
    ValueChanged<String>? onImageTap,
    ValueChanged<int>? onPartyTap,
  }) async {
    tester.view.physicalSize = Size(width, 812);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (_, __) => MaterialApp(
            theme: AppTheme.light.copyWith(
              textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
            ),
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              backgroundColor: AppColors.roomMessageSurface,
              body: RepaintBoundary(
                key: const ValueKey('public-chat-golden'),
                child: ColoredBox(
                  color: const Color(0xFF6F5444),
                  child: ListView.separated(
                    itemCount: messages.length,
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => RoomPublicMessageItem(
                      key: ValueKey(messages[i].id),
                      message: messages[i],
                      onUserTap: onUserTap ?? (_) {},
                      onImageTap: onImageTap ?? (_) {},
                      onPartyTap: onPartyTap ?? (_) {},
                    ),
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
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'media, expression fallback, Party and crowded badges at $width',
      (tester) async {
        final crowded = RoomUserAppearance(
          badges: List.filled(35, AppAssets.membershipVipBadge),
        );
        await pump(tester, [
          _message('crowded', appearance: crowded),
          _message(
            'photo',
            kind: RoomChatEntryKind.image,
            media: AppAssets.lanhuRoomAvatarSample,
          ),
          _message(
            'expression',
            kind: RoomChatEntryKind.expression,
            media: 'unavailable',
          ),
          _message(
            'party-media',
            kind: RoomChatEntryKind.party,
            partyId: 42,
            text: 'A very long Party title that wraps and remains clickable',
          ),
        ], width: width);
        final crowdedFrame = find.byKey(const ValueKey('crowded'));
        expect(
          tester.getSize(crowdedFrame).height,
          greaterThan(
            RoomPublicChatTheme.avatar.r + RoomPublicChatTheme.bodyGap.h + 50,
          ),
        );
        await tester.scrollUntilVisible(
          find.byType(RoomAnimatedArtwork),
          100,
          scrollable: find.byType(Scrollable),
        );
        expect(
          find.image(const AssetImage(AppAssets.lanhuRoomIconMissing)),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.textContaining('A very long Party'),
          100,
          scrollable: find.byType(Scrollable),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('sender decoration and message bubbles at $width', (
      tester,
    ) async {
      await pump(tester, _overview(), width: width);
      expect(tester.takeException(), isNull);
      final decorated = find.byKey(const ValueKey('decorated'));
      final identity = find.descendant(
        of: decorated,
        matching: find.byKey(const ValueKey('room-public-sender-identity')),
      );
      final bubble = find.descendant(
        of: decorated,
        matching: find.byKey(const ValueKey('room-public-message-bubble')),
      );
      expect(
        tester.getRect(bubble).top - tester.getRect(identity).bottom,
        closeTo(RoomPublicChatTheme.bodyGap.h, 0.01),
      );
      expect(
        tester.getRect(bubble).right,
        lessThanOrEqualTo(width - RoomPublicChatTheme.trailing.w),
      );
      final short = find.descendant(
        of: find.byKey(const ValueKey('short')),
        matching: find.byKey(const ValueKey('room-public-message-bubble')),
      );
      expect(
        tester.getSize(short).width,
        lessThan(RoomPublicChatTheme.bubbleMaxWidth.w / 2),
      );
      expect(find.text('sent all mic Rose x2'), findsOneWidget);
      expect(find.text('win 150 coins (3 times)'), findsOneWidget);
      if (const bool.fromEnvironment('PUBLIC_CHAT_PREVIEW')) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('public-chat-golden')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File(
            'build/qa/room_public_chat_compact_v2/overview_${width.toInt()}.png',
          );
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      } else {
        await expectLater(
          find.byKey(const ValueKey('public-chat-golden')),
          matchesGoldenFile(
            'goldens/room_public_chat_compact_v2/overview_${width.toInt()}.png',
          ),
        );
      }
    });

    testWidgets('long body, Arabic and keyboard remain scrollable at $width', (
      tester,
    ) async {
      final long = List.filled(
        18,
        'رسالة طويلة مع كلمات وصور ومعلومات حقيقية',
      ).join('\n');
      await pump(
        tester,
        [_message('long', text: long, appearance: _appearance)],
        width: width,
        keyboard: 280,
        locale: const Locale('ar'),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(RoomPublicMessageText),
          matching: find.byType(Text),
        ),
      );
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'avatar, nickname, mention, image and party retain their target',
    (tester) async {
      final users = <int>[], parties = <int>[];
      final images = <String>[];
      await pump(
        tester,
        [
          _message(
            'mention',
            text: encodeRoomMention('Hello @Friend', (uid: 31, name: 'Friend')),
          ),
          _message(
            'image',
            kind: RoomChatEntryKind.image,
            media: AppAssets.lanhuRoomAvatarSample,
          ),
          _message(
            'party',
            kind: RoomChatEntryKind.party,
            partyId: 42,
            text: 'Party title',
          ),
        ],
        onUserTap: users.add,
        onImageTap: images.add,
        onPartyTap: parties.add,
      );
      await tester.tap(find.byKey(const ValueKey('room-chat-avatar-mention')));
      await tester.tap(find.text('Peer').first);
      await tester.tap(find.textContaining('@Friend', findRichText: true));
      await tester.tap(
        find
            .descendant(
              of: find.byKey(const ValueKey('image')),
              matching: find.byType(InkWell),
            )
            .last,
      );
      await tester.tap(find.text('Party title'));
      expect(users, [20, 20, 31]);
      expect(images, [AppAssets.lanhuRoomAvatarSample]);
      expect(parties, [42]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing decorations hide; unavailable images show the red asset',
    (tester) async {
      await pump(tester, [_message('legacy')]);
      expect(find.text('80'), findsNothing);
      expect(
        find.image(const AssetImage(AppAssets.membershipVipBadge)),
        findsNothing,
      );
      final context = tester.element(find.byType(Scaffold));
      const remote = RoomPublicChatImage(
        source: 'https://example.com/badge.png',
      );
      final image = remote.build(context) as CachedNetworkImage;
      expect(image.httpHeaders, isNull);
      expect(
        image.errorWidget!(context, image.imageUrl, StateError('failed')),
        isA<Image>().having(
          (e) => e.image,
          'red placeholder',
          const AssetImage(AppAssets.lanhuRoomIconMissing),
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 16,
            height: 16,
            child: RoomPublicChatImage(source: 'broken'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.image(const AssetImage(AppAssets.lanhuRoomIconMissing)),
        findsOneWidget,
      );
    },
  );
}
