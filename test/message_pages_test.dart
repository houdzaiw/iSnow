import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/message/chat_page.dart';
import 'package:project/classes/message/im_repository.dart';
import 'package:project/classes/message/message_page.dart';
import 'package:project/classes/message/message_view_model.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/theme/app_theme.dart';

import 'support/im_fakes.dart';

void main() {
  late ImSdkFake sdk;
  late ImHttpAdapter http;
  late ImRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'nady.pubUid': 10,
      'nady.oauthToken': 'test',
    });
    sdk = ImSdkFake();
    http = ImHttpAdapter();
    final manager = HttpDioManager();
    final previous = manager.getDio().httpClientAdapter;
    manager.getDio().httpClientAdapter = http;
    final auth = ImAuthFake();
    repository = ImRepository(manager, auth, sdk: sdk);
    addTearDown(() {
      repository.dispose();
      auth.dispose();
      manager.getDio().httpClientAdapter = previous;
    });
  });

  Future<GoRouter> mount(WidgetTester tester, {double width = 375}) async {
    tester.view.physicalSize = Size(width, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/messages',
      routes: [
        GoRoute(path: '/messages', builder: (_, _) => const MessagePage()),
        GoRoute(
          path: '/chat-view',
          builder: (_, state) => ChatPage(
            targetUID: state.uri.queryParameters['targetUID']!,
            title: state.uri.queryParameters['title'],
          ),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [imRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('zh')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets(
      'inbox summaries update and localize without reading at $width',
      (tester) async {
        final title =
            'System notice ${List.filled(25, 'long title').join(' ')}';
        sdk.conversations.rows = [
          imConversation('10000', pinned: true)
            ..lastMessage = imCustom({
              'type': 'SystemComplexIMMsg',
              'payload': {
                'titleMap': {'en': title, 'zh': '系统通知标题'},
                'textMap': {'en': 'Do not show body'},
              },
            }, uid: '10000'),
          imConversation('20', unread: 2)
            ..lastMessage = imCustom({
              'type': 'TextIMMsg',
              'payload': {'text': 'Hello\nfriend 👋'},
            }),
        ];
        await mount(tester, width: width);
        expect(find.text('Hello friend 👋'), findsOneWidget);
        expect(find.text(title), findsOneWidget);
        final summary = tester.widget<Text>(find.text(title));
        expect(summary.maxLines, 1);
        expect(summary.overflow, TextOverflow.ellipsis);
        expect(
          tester.getRect(find.text(title)).right,
          lessThanOrEqualTo(width),
        );
        expect(find.text('2'), findsOneWidget);
        sdk.conversations.emit([
          imConversation('20', unread: 2)
            ..lastMessage = imCustom({
              'type': 'SystemSendGiftStore',
              'payload': {'targetUserId': 10},
            }),
        ]);
        await tester.pumpAndSettle();
        expect(find.text('Sent you'), findsOneWidget);
        expect(find.text('Hello friend 👋'), findsNothing);
        tester.platformDispatcher.localesTestValue = const [Locale('zh')];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        await tester.pumpAndSettle();
        expect(find.text('送给你'), findsOneWidget);
        expect(find.text('系统通知标题'), findsOneWidget);
        expect(find.text('Sent you'), findsNothing);
        expect(find.text('2'), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MessagePage)),
        );
        sdk.conversations.rows = [
          sdk.conversations.rows.firstWhere((c) => c.userID == '10000'),
          imConversation('20', unread: 2)
            ..lastMessage = imCustom({
              'type': 'TextIMMsg',
              'payload': {'text': 'Refreshed server content'},
            }),
        ];
        await container.read(messageViewModelProvider.notifier).refresh();
        await tester.pumpAndSettle();
        expect(find.text('Refreshed server content'), findsOneWidget);
        expect(find.text('送给你'), findsNothing);
        expect(sdk.conversations.reads, isEmpty);
        expect(sdk.conversations.deleted, isEmpty);
        expect(sdk.messages.sent, isEmpty);
        expect(sdk.conversations.listeners, hasLength(1));
        expect(http.requests, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('main inbox and full chat share one IM login and unread state', (
    tester,
  ) async {
    final router = await mount(tester);
    expect(sdk.conversations.reads, isEmpty);
    await tester.tap(find.text('Friend 20'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/chat-view');
    expect(find.byType(ChatPage), findsOneWidget);
    expect(sdk.conversations.reads, contains('c2c_20'));
    final input = find.byKey(const ValueKey('private-chat-input'));
    await tester.enterText(input, 'Mock-only regression message');
    http.audit = false;
    await tester.tap(find.byKey(const ValueKey('private-chat-send')));
    await tester.pumpAndSettle();
    expect(sdk.messages.sent, isEmpty);
    expect(tester.widget<TextField>(input).controller!.text, isNotEmpty);
    http.audit = true;
    await tester.tap(find.byKey(const ValueKey('private-chat-send')));
    await tester.pumpAndSettle();
    expect(sdk.messages.sent, hasLength(1));
    expect(tester.widget<TextField>(input).controller!.text, isEmpty);
    await tester.tap(find.image(const AssetImage(AppAssets.lanhuNavBack)));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/messages');
    expect(sdk.conversations.listeners, hasLength(1));
    expect(sdk.messages.listeners, isEmpty);
    expect(sdk.inits, 1);
    expect(sdk.logins, ['10']);
    expect(sdk.conversations.deleted, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system full-page chat stays read-only and cleans up on return', (
    tester,
  ) async {
    final router = await mount(tester);
    await tester.tap(find.text('Friend 10000'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);
    expect(find.byKey(const ValueKey('private-chat-input')), findsNothing);
    expect(find.byKey(const ValueKey('private-chat-send')), findsNothing);
    expect(sdk.conversations.reads, contains('c2c_10000'));
    router.pop();
    await tester.pumpAndSettle();
    expect(sdk.messages.listeners, isEmpty);
    expect(sdk.messages.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
