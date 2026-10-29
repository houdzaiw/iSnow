import 'package:flutter/material.dart';
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

  Future<GoRouter> mount(WidgetTester tester) async {
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
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
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
