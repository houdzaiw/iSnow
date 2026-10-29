import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/classes/message/im_repository.dart';
import 'package:project/classes/message/message_view_model.dart';
import 'package:project/classes/message/chat_view_model.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/im_models.dart';
import 'package:project/model/server_response.dart';

import 'support/im_fakes.dart';

Future<void> flushIm() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ImRepository repo;
  late ImSdkFake sdk;
  late ImAuthFake auth;
  late ImHttpAdapter http;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'nady.pubUid': 10,
      'nady.oauthToken': 'unit-token',
    });
    sdk = ImSdkFake();
    auth = ImAuthFake();
    http = ImHttpAdapter();
    final manager = HttpDioManager();
    final previous = manager.getDio().httpClientAdapter;
    manager.getDio().httpClientAdapter = http;
    repo = ImRepository(manager, auth, sdk: sdk);
    addTearDown(() {
      repo.dispose();
      auth.dispose();
      manager.getDio().httpClientAdapter = previous;
    });
  });

  test('concurrent login is merged and initializes SDK only once', () async {
    await Future.wait([
      repo.ensureReady(),
      repo.ensureReady(),
      repo.ensureReady(),
    ]);
    expect(sdk.inits, 1);
    expect(sdk.logins, ['10']);
    expect(
      http.requests.where((r) => r.path == HttpApi.timToken),
      hasLength(1),
    );
    expect(repo.session.state.status, ImConnectionStatus.connected);
  });

  test(
    'reconnect reports state and logs back in without SDK reinitialization',
    () async {
      await repo.ensureReady();
      sdk.listener!.onConnectFailed(1, 'Disconnected');
      expect(repo.session.state.status, ImConnectionStatus.error);
      await repo.session.reconnect();
      expect(sdk.inits, 1);
      expect(sdk.logins, ['10', '10']);
      expect(sdk.logouts, 1);
      expect(repo.session.state.status, ImConnectionStatus.connected);
    },
  );

  test('account switch discards an old token before SDK login', () async {
    http.tokenGate = Completer<void>();
    final old = repo.ensureReady();
    final rejected = expectLater(old, throwsA(isA<NadyApiException>()));
    await flushIm();
    auth.change(20);
    http.tokenGate!.complete();
    await rejected;
    await repo.ensureReady();
    expect(sdk.logins, ['20']);
    expect(repo.session.state.uid, 20);
  });

  test(
    'shared list has one listener and does not mark conversations read',
    () async {
      final vm = MessageViewModel(repo);
      addTearDown(vm.dispose);
      await vm.load();
      await vm.refresh();
      expect(sdk.conversations.listeners, hasLength(1));
      expect(vm.state.totalUnreadCount, 2);
      expect(sdk.conversations.reads, isEmpty);
      sdk.conversations.emit([imConversation('30', unread: 5, pinned: true)]);
      expect(vm.state.conversations.first.userID, '30');
      expect(vm.state.totalUnreadCount, 7);
    },
  );

  test('live events win over an older pending list snapshot', () async {
    await repo.ensureReady();
    sdk.conversations.fetchGate = Completer();
    final vm = MessageViewModel(repo);
    addTearDown(vm.dispose);
    await flushIm();
    sdk.conversations.emit([imConversation('20', unread: 9)]);
    sdk.conversations.fetchGate!.complete([imConversation('20', unread: 1)]);
    await vm.load();
    expect(vm.state.totalUnreadCount, 9);
  });

  test(
    'delete failure retains a row; success removes it and its unread count',
    () async {
      final vm = MessageViewModel(repo);
      addTearDown(vm.dispose);
      await vm.load();
      sdk.conversations.failDelete = true;
      expect(await vm.deleteConversation('c2c_20'), isFalse);
      expect(vm.state.totalUnreadCount, 2);
      expect(vm.state.errorMessage, 'Delete rejected');
      sdk.conversations.failDelete = false;
      expect(await vm.deleteConversation('c2c_20'), isTrue);
      expect(vm.state.conversations.map((c) => c.userID), ['10000']);
      expect(vm.state.totalUnreadCount, 0);
    },
  );

  test(
    'disposing during listener registration releases the late listener',
    () async {
      sdk.conversations.listenGate = Completer<void>();
      final vm = MessageViewModel(repo);
      await flushIm();
      vm.dispose();
      sdk.conversations.listenGate!.complete();
      await flushIm();
      expect(sdk.conversations.listeners, isEmpty);
    },
  );

  test(
    'account changes clear inbox before new account data is loaded',
    () async {
      final vm = MessageViewModel(repo);
      addTearDown(vm.dispose);
      await vm.load();
      final old = sdk.conversations.listeners.single;
      sdk.conversations.rows = [imConversation('30')];
      auth.change(20);
      expect(vm.state.conversations, isEmpty);
      old.onConversationChanged([imConversation('99', unread: 100)]);
      expect(vm.state.conversations, isEmpty);
      await flushIm();
      expect(vm.state.conversations.map((c) => c.userID), ['30']);
      expect(sdk.conversations.listeners, hasLength(1));
    },
  );

  test(
    'text follows profile, audit and SDK send order with signed JSON',
    () async {
      final message = await repo.sendTextMessage(
        targetUID: '20',
        text: 'hello',
      );
      expect(message.textElem?.text, 'hello');
      expect(http.requests.map((r) => r.path), [
        HttpApi.timToken,
        HttpApi.userHomepage,
        HttpApi.imTextAudit,
      ]);
      final request = http.requests.last;
      expect(request.method, 'POST');
      expect(request.queryParameters, isEmpty);
      expect(request.headers['b'], isNotEmpty);
      expect(request.data, {
        'receiveUid': '20',
        'type': 'text',
        'content': 'hello',
      });
      expect(sdk.messages.sent, hasLength(1));
    },
  );

  for (final rejected in [false, true]) {
    test(
      'audit ${rejected ? 'server msg' : 'false'} prevents all SDK sends',
      () async {
        http.audit = false;
        if (rejected) {
          http.auditError = {
            'code': 1003,
            'message': 'Generic',
            'msg': 'Review rejected',
          };
        }
        await expectLater(
          repo.sendTextMessage(targetUID: '20', text: 'private'),
          throwsA(
            isA<NadyApiException>().having(
              (e) => e.message,
              'message',
              rejected
                  ? 'Review rejected'
                  : 'Message did not pass content review',
            ),
          ),
        );
        expect(sdk.messages.creates, 0);
        expect(sdk.messages.sent, isEmpty);
      },
    );
  }

  test('VIP no-disturb blocks non-mutual contacts before audit', () async {
    http.vip = 5;
    http.noDisturb = true;
    await expectLater(
      repo.sendTextMessage(targetUID: '20', text: 'hello'),
      throwsA(
        isA<NadyApiException>().having(
          (e) => e.message,
          'message',
          contains('Do Not Disturb'),
        ),
      ),
    );
    expect(http.requests.any((r) => r.path == HttpApi.imTextAudit), isFalse);
    expect(sdk.messages.sent, isEmpty);
  });

  test('mutual followers retain the Nady VIP exception', () async {
    http.vip = 8;
    http.noDisturb = true;
    http.relation = 'FOLLOW_MUTUAL';
    await repo.sendTextMessage(targetUID: '20', text: 'hello');
    expect(http.requests.any((r) => r.path == HttpApi.userVipSetting), isFalse);
    expect(sdk.messages.sent, hasLength(1));
  });

  test('closing while audit is pending never sends a late message', () async {
    http.auditGate = Completer<void>();
    var current = true;
    final pending = repo.sendTextMessage(
      targetUID: '20',
      text: 'hello',
      isCurrent: () => current,
    );
    final rejected = expectLater(pending, throwsA(isA<NadyApiException>()));
    await flushIm();
    current = false;
    http.auditGate!.complete();
    await rejected;
    expect(sdk.messages.creates, 0);
    expect(sdk.messages.sent, isEmpty);
  });

  test('system accounts are read-only at the repository boundary', () async {
    await expectLater(
      repo.sendTextMessage(targetUID: '10000', text: 'hello'),
      throwsA(isA<NadyApiException>()),
    );
    expect(sdk.messages.sent, isEmpty);
    expect(http.requests.any((r) => r.path == HttpApi.imTextAudit), isFalse);
  });

  test(
    'tokens and audited content never appear in request or response logs',
    () async {
      final previous = debugPrint;
      final lines = <String>[];
      debugPrint = (String? text, {int? wrapWidth}) {
        if (text != null) lines.add(text);
      };
      addTearDown(() => debugPrint = previous);
      await repo.sendTextMessage(targetUID: '20', text: 'very-private-message');
      expect(lines.join('\n'), isNot(contains('very-private-message')));
      expect(lines.join('\n'), isNot(contains('fake-im-secret')));
    },
  );

  test(
    'history pagination merges duplicates without dropping realtime messages',
    () async {
      sdk.messages.history = [
        for (var i = 0; i < 20; i++) imText('m$i', time: 100 + i),
      ];
      sdk.messages.older = [imText('m0', time: 100), imText('older', time: 1)];
      final vm = ChatViewModel(targetUID: '20', repository: repo);
      addTearDown(vm.dispose);
      await flushIm();
      expect(vm.state.messages, hasLength(20));
      expect(vm.state.hasMore, isTrue);
      sdk.messages.listeners.single.onRecvNewMessage(imText('live', time: 200));
      await vm.loadMore();
      expect(sdk.messages.cursors, [null, 'm0']);
      expect(vm.state.messages, hasLength(22));
      expect(vm.state.messages.first.msgID, 'older');
      expect(vm.state.messages.last.msgID, 'live');
      expect(vm.state.hasMore, isFalse);
    },
  );

  test('hidden chat preserves unread until visible again', () async {
    final vm = ChatViewModel(targetUID: '20', repository: repo);
    addTearDown(vm.dispose);
    await flushIm();
    final before = sdk.conversations.reads.length;
    vm.setVisible(false);
    sdk.messages.listeners.single.onRecvNewMessage(imText('while-hidden'));
    await flushIm();
    expect(sdk.conversations.reads.length, before);
    vm.setVisible(true);
    await flushIm();
    expect(sdk.conversations.reads.length, before + 1);
  });

  test(
    'same-account reconnect restores chat, another account cannot',
    () async {
      final vm = ChatViewModel(targetUID: '20', repository: repo);
      addTearDown(vm.dispose);
      await flushIm();
      await repo.session.reconnect();
      await flushIm();
      expect(sdk.messages.listeners, hasLength(1));
      expect(vm.state.messages, isNotEmpty);
      auth.change(30);
      await repo.ensureReady();
      await flushIm();
      expect(vm.state.messages, isEmpty);
      expect(sdk.messages.listeners, isEmpty);
      expect(await vm.sendText('old chat'), isFalse);
    },
  );

  test('disposing a chat with pending history never marks it read', () async {
    sdk.messages.historyGate = Completer();
    final vm = ChatViewModel(targetUID: '20', repository: repo);
    await flushIm();
    vm.dispose();
    sdk.messages.historyGate!.complete([imText('late')]);
    await flushIm();
    expect(sdk.messages.listeners, isEmpty);
    expect(sdk.conversations.reads, isEmpty);
  });
}
