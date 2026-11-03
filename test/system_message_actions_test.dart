import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

import 'package:project/classes/message/chat_view_model.dart';
import 'package:project/classes/message/im_repository.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/system_message_card_data.dart';

import 'support/im_fakes.dart';
import 'support/system_message_fixture.dart';

void main() {
  late ImSdkFake sdk;
  late ImAuthFake auth;
  late ImRepository im;
  late ChatViewModel vm;
  var current = true;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'nady.pubUid': 10,
      'nady.oauthToken': 'test',
    });
    current = true;
    sdk = ImSdkFake();
    sdk.messages.history = [systemNotice('notice')];
    auth = ImAuthFake();
    final manager = HttpDioManager();
    final previous = manager.getDio().httpClientAdapter;
    manager.getDio().httpClientAdapter = ImHttpAdapter();
    im = ImRepository(manager, auth, sdk: sdk);
    vm = ChatViewModel(
      targetUID: '10000',
      repository: im,
      isCurrent: () => current,
    );
    while (vm.state.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    addTearDown(() {
      vm.dispose();
      im.dispose();
      auth.dispose();
      manager.getDio().httpClientAdapter = previous;
    });
  });
  SystemMessageActionRequest? begin() =>
      vm.beginSystemAction('notice', SystemMessageActionKind.details, 'en');

  test(
    'duplicate guard releases after return; hidden view cannot start actions',
    () {
      final request = begin()!;
      expect(begin(), isNull);
      vm.setVisible(false);
      expect(vm.isSystemActionCurrent(request), isTrue);
      vm.finishSystemAction(request);
      expect(begin(), isNull);
      vm.setVisible(true);
      expect(begin(), isNotNull);
      expect(sdk.messages.listeners, hasLength(1));
    },
  );

  for (final boundary in ['close', 'account', 'room']) {
    test('$boundary invalidates pending actions without late writes', () async {
      final request = begin()!;
      if (boundary == 'close') {
        vm.close();
      } else if (boundary == 'account') {
        auth.change(30);
      } else {
        current = false;
      }
      await Future<void>.delayed(Duration.zero);
      expect(vm.isSystemActionCurrent(request), isFalse);
      vm.finishSystemAction(request);
      expect(begin(), isNull);
      expect(sdk.messages.sent, isEmpty);
      expect(sdk.conversations.deleted, isEmpty);
    });
  }

  test('invalidation listeners are removable and close is idempotent', () {
    var retained = 0, removed = 0;
    vm.addActionInvalidationListener(() => retained++);
    final remove = vm.addActionInvalidationListener(() => removed++);
    remove();
    vm.close();
    vm.close();
    expect(retained, 1);
    expect(removed, 0);
  });

  test(
    'history pagination and live updates use the same SDK listener and cache',
    () async {
      sdk.messages.history = [
        for (var i = 0; i < 20; i++) systemNotice('recent-$i'),
      ];
      sdk.messages.older = [systemNotice('older'), systemNotice('recent-0')];
      await vm.load();
      expect(vm.state.hasMore, isTrue);
      await vm.loadMore();
      expect(vm.systemCards('en').map((c) => c.id).toSet(), hasLength(22));
      sdk.messages.listeners.single.onRecvNewMessage(systemNotice('live'));
      expect(vm.systemCards('en').last.id, 'live');
      expect(sdk.messages.listeners, hasLength(1));
      expect(sdk.messages.cursors.whereType<String>(), isNotEmpty);
    },
  );

  test('closed pending history result cannot repopulate state', () async {
    sdk.messages.historyGate = Completer<List<V2TimMessage>>();
    final pending = vm.load();
    await Future<void>.delayed(Duration.zero);
    final original = vm.state.messages;
    vm.close();
    sdk.messages.historyGate!.complete([systemNotice('late')]);
    await pending;
    expect(vm.state.messages, original);
    expect(vm.systemCards('en').any((c) => c.id == 'late'), isFalse);
  });
}
