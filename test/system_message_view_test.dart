import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/message/chat_page.dart';
import 'package:project/classes/message/chat_view_model.dart';
import 'package:project/classes/message/im_repository.dart';
import 'package:project/classes/message/message_view_model.dart';
import 'package:project/classes/message/system/system_message_image.dart';
import 'package:project/classes/message/system/system_message_navigation.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/system_message_card_data.dart';
import 'package:project/theme/app_theme.dart';

import 'support/im_fakes.dart';
import 'support/precache_room_assets.dart';
import 'support/room_more_settings_fixture.dart';
import 'support/system_message_fixture.dart';

class _NavigationFake extends SystemMessageNavigator {
  final actions = <SystemMessageAction>[];
  final rooms = <String>[];
  bool fail = false, roomCompleted = false;
  Completer<void>? roomGate;
  @override
  Widget destination(SystemMessageAction action) {
    actions.add(action);
    if (fail) throw StateError('Native navigation failed');
    return action.destination == SystemMessageDestination.image
        ? super.destination(action)
        : Scaffold(body: Text('Destination: ${action.destination.name}'));
  }

  @override
  Future<void> enterRoom(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    bool Function() current,
  ) async {
    rooms.add(roomId);
    await roomGate?.future;
    if (current()) roomCompleted = true;
  }
}

void main() {
  late ImSdkFake sdk;
  late ImAuthFake auth;
  late ImRepository im;
  late SystemImageCacheFake cache;
  late _NavigationFake navigation;
  setUpAll(() async {
    final loader = FontLoader('Roboto')
      ..addFont(
        File(
          'test/fixtures/fonts/Roboto-Regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await loader.load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'nady.pubUid': 10,
      'nady.oauthToken': 'test',
    });
    sdk = ImSdkFake();
    sdk.messages.history = [systemNotice('notice')];
    auth = ImAuthFake();
    final manager = HttpDioManager();
    final previous = manager.getDio().httpClientAdapter;
    manager.getDio().httpClientAdapter = ImHttpAdapter();
    im = ImRepository(manager, auth, sdk: sdk);
    cache = SystemImageCacheFake();
    await cache.prepare();
    navigation = _NavigationFake();
    addTearDown(() {
      im.dispose();
      auth.dispose();
      manager.getDio().httpClientAdapter = previous;
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });
  });

  List<Override> overrides() => [
    systemMessageImageCacheProvider.overrideWithValue(cache),
    systemMessageNavigatorProvider.overrideWithValue(navigation),
  ];
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
    }
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    double width = 375,
  }) async {
    tester.view.physicalSize = Size(width, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [imRepositoryProvider.overrideWithValue(im), ...overrides()],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('zh')],
          home: const RepaintBoundary(
            key: ValueKey('system-snapshot'),
            child: ChatPage(targetUID: '10000', title: 'System'),
          ),
        ),
      ),
    );
    await settle(tester);
    return ProviderScope.containerOf(tester.element(find.byType(ChatPage)));
  }

  Future<RoomMoreSettingsFixture> half(
    WidgetTester tester, {
    double width = 375,
  }) async {
    final fixture = await mountRoomMoreSettings(
      tester,
      im: im,
      width: width,
      overrides: overrides(),
    );
    await tester.tap(find.byKey(const ValueKey('room-message-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room-conversation-10000')));
    await settle(tester);
    return fixture;
  }

  final image = find.byKey(const ValueKey('system-message-image-notice'));
  final history = find.byKey(const ValueKey('system-message-history'));

  for (final content in ['text', 'image']) {
    testWidgets('$content-only card omits unused elements', (tester) async {
      sdk.messages.history = [
        systemNotice(
          'notice',
          payload: {
            if (content == 'text')
              'textMap': {'en': 'Plain text\n\nWith paragraphs'},
            if (content == 'image')
              'picUrl': 'https://images.example.test/image.png',
          },
        ),
      ];
      await mount(tester, width: 320);
      expect(image, content == 'image' ? findsOneWidget : findsNothing);
      expect(
        find.text('Plain text\n\nWith paragraphs'),
        content == 'text' ? findsOneWidget : findsNothing,
      );
      expect(find.text('Details'), findsNothing);
      expect(find.text('A message for you'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 375.0, 430.0]) {
    for (final mode in ['full', 'half']) {
      testWidgets('system detail $mode layout at $width', (tester) async {
        if (mode == 'full') {
          await mount(tester, width: width);
        } else {
          await half(tester, width: width);
        }
        await precacheRoomAssets(tester, tester.element(history));
        expect(find.text('A message for you'), findsOneWidget);
        expect(
          find.text('First paragraph.\n\nSecond paragraph.'),
          findsOneWidget,
        );
        expect(find.text('[Custom message]'), findsNothing);
        expect(find.byKey(const ValueKey('private-chat-input')), findsNothing);
        expect(
          find.image(const AssetImage(AppAssets.moreButton)),
          findsNothing,
        );
        expect(tester.getRect(image).width, width - 64);
        expect(
          tester.getRect(image).height,
          closeTo((width - 64) / (311 / 120), 0.01),
        );
        expect(sdk.messages.listeners, hasLength(1));
        expect(
          cache.requestHeaders.every((h) => h == null || h.isEmpty),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(
            ValueKey(
              mode == 'full' ? 'system-snapshot' : 'room-settings-snapshot',
            ),
          ),
          matchesGoldenFile(
            'goldens/system_message_detail_${mode}_${width.toInt()}.png',
          ),
        );
      });
    }
  }

  testWidgets('image retry refetches without auth and does not open links', (
    tester,
  ) async {
    cache.fail = true;
    await mount(tester);
    expect(
      find.byKey(const ValueKey('system-message-image-retry')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage(AppAssets.lanhuRoomIconMissing)),
      findsOneWidget,
    );
    expect(cache.requests, hasLength(1));
    cache.fail = false;
    await tester.tap(find.byKey(const ValueKey('system-message-image-retry')));
    await settle(tester);
    expect(cache.requests, hasLength(2));
    expect(
      find.byKey(const ValueKey('system-message-image-retry')),
      findsNothing,
    );
    expect(navigation.actions, isEmpty);
    expect(cache.requestHeaders.every((h) => h == null || h.isEmpty), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'image root preview consumes tap, zooms, returns to same offset',
    (tester) async {
      sdk.messages.history = [
        for (var i = 0; i < 8; i++) systemNotice('old-$i'),
        systemNotice('notice'),
      ];
      await mount(tester);
      await tester.drag(history, const Offset(0, 80));
      await settle(tester);
      final scroll = tester
          .widget<Scrollable>(
            find.descendant(of: history, matching: find.byType(Scrollable)),
          )
          .controller!;
      final offset = scroll.offset;
      await tester.tap(image);
      await settle(tester);
      expect(
        find.byKey(const ValueKey('system-message-image-preview')),
        findsOneWidget,
      );
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(navigation.actions.map((a) => a.destination), [
        SystemMessageDestination.image,
      ]);
      Navigator.of(tester.element(find.byType(InteractiveViewer))).pop();
      await settle(tester);
      expect(scroll.offset, offset);
      await tester.tap(find.text('Details').last);
      await settle(tester);
      expect(navigation.actions.last.destination, SystemMessageDestination.web);
      expect(navigation.actions.last.uri!.queryParameters['language'], 'en');
    },
  );

  testWidgets(
    'safe unsupported fallback, no fake time, language and long content',
    (tester) async {
      sdk.messages.history = [
        systemNotice('unknown', type: 'Reward', timestamp: null)..timestamp = 0,
      ];
      await mount(tester, width: 320);
      expect(
        find.text('This system message is not supported yet.'),
        findsOneWidget,
      );
      expect(find.text('Details'), findsNothing);
      expect(find.textContaining('2023.'), findsNothing);
      sdk.messages.listeners.single.onRecvNewMessage(
        systemNotice(
          'live',
          payload: {
            'titleMap': {
              'en': List.filled(30, 'Long title').join(' '),
              'zh': '中文标题',
            },
            'textMap': {
              'en': List.filled(15, 'Paragraph.\n\n').join(),
              'zh': '正文\n\n第二段',
            },
          },
        ),
      );
      await settle(tester);
      expect(find.textContaining('Long title'), findsOneWidget);
      tester.platformDispatcher.localesTestValue = const [Locale('zh')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await settle(tester);
      expect(find.text('中文标题'), findsOneWidget);
      expect(find.text('正文\n\n第二段'), findsOneWidget);
      expect(sdk.messages.listeners, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'duplicate details opens once; failure is localized and retryable',
    (tester) async {
      await mount(tester);
      navigation.fail = true;
      await tester.tap(find.text('Details'));
      await settle(tester);
      expect(find.text('Unable to open this message.'), findsOneWidget);
      navigation.fail = false;
      final tap = tester
          .widget<InkWell>(
            find
                .ancestor(
                  of: find.text('Details'),
                  matching: find.byType(InkWell),
                )
                .first,
          )
          .onTap!;
      tap();
      tap();
      await settle(tester);
      expect(navigation.actions, hasLength(2));
      expect(find.text('Destination: web'), findsOneWidget);
      expect(sdk.messages.sent, isEmpty);
      expect(sdk.conversations.deleted, isEmpty);
    },
  );

  for (final boundary in ['exit', 'room', 'account']) {
    testWidgets('$boundary removes owned preview and both sheets', (
      tester,
    ) async {
      final fixture = await half(tester);
      await tester.tap(image);
      await settle(tester);
      expect(
        find.byKey(const ValueKey('system-message-image-preview')),
        findsOneWidget,
      );
      if (boundary == 'exit') {
        await fixture.room.leaveRoom();
      } else if (boundary == 'room') {
        fixture.room.generation++;
        fixture.room.emitState();
      } else {
        fixture.room.changeAccount(30);
      }
      await settle(tester);
      expect(
        find.byKey(const ValueKey('system-message-image-preview')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('room-private-chat-sheet')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('room-message-sheet')), findsNothing);
      expect(sdk.messages.listeners, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('account switch closes full-page owned preview', (tester) async {
    await mount(tester);
    await tester.tap(image);
    await settle(tester);
    auth.change(30);
    await settle(tester);
    expect(
      find.byKey(const ValueKey('system-message-image-preview')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'account switch removes wallet destination but keeps unrelated route',
    (tester) async {
      sdk.messages.history = [
        systemNotice(
          'notice',
          payload: {
            'textMap': {'en': 'Wallet notice'},
            'linkUrl': 'nady://main/me-wallet',
          },
        ),
      ];
      await mount(tester);
      await tester.tap(find.text('Details'));
      await settle(tester);
      expect(
        navigation.actions.single.destination,
        SystemMessageDestination.wallet,
      );
      final navigator = Navigator.of(
        tester.element(find.text('Destination: wallet')),
      );
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Unrelated page')),
          ),
        ),
      );
      await settle(tester);
      auth.change(30);
      await settle(tester);
      expect(find.text('Unrelated page'), findsOneWidget);
      navigator.pop();
      await settle(tester);
      expect(find.text('Destination: wallet'), findsNothing);
      expect(find.byType(ChatPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small half sheet with keyboard and safe area remains scrollable',
    (tester) async {
      await mountRoomMoreSettings(
        tester,
        im: im,
        width: 320,
        height: 568,
        inset: 200,
        bottom: 24,
        overrides: overrides(),
      );
      await tester.tap(find.byKey(const ValueKey('room-message-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room-conversation-10000')));
      await settle(tester);
      expect(history, findsOneWidget);
      expect(tester.getRect(history).bottom, lessThanOrEqualTo(568 - 200 - 24));
      await tester.drag(history, const Offset(0, -250));
      await settle(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pending room action cannot switch after closing or account change',
    (tester) async {
      sdk.messages.history = [
        systemNotice(
          'notice',
          payload: {
            'textMap': {'en': 'Visit room'},
            'linkUrl': 'nady://main/voice-room?roomId=42',
          },
        ),
      ];
      final container = await mount(tester);
      navigation.roomGate = Completer<void>();
      await tester.tap(find.text('Details'));
      await tester.pump();
      expect(navigation.rooms, ['42']);
      container.read(chatViewModelProvider('10000').notifier).close();
      navigation.roomGate!.complete();
      await settle(tester);
      expect(navigation.roomCompleted, isFalse);
      expect(navigation.actions, isEmpty);
    },
  );
}
