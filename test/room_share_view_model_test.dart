import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/more/room_share_repository.dart';
import 'package:project/classes/room/more/room_share_view_model.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_share_models.dart';
import 'package:project/model/server_response.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';

import 'support/room_share_fakes.dart';
import 'support/room_tools_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ToolsRoomFake room;
  late ToolsApiFake api;
  late ShareImFake im;
  late SharePlatformFake platform;
  late RoomShareRepository sharing;
  late RoomShareViewModel vm;
  const origin = Rect.fromLTWH(20, 300, 60, 40);
  setUp(() {
    room = ToolsRoomFake();
    api = shareApiFake();
    im = ShareImFake();
    platform = SharePlatformFake();
    sharing = RoomShareRepository(api, config: ShareConfigFake());
    vm = RoomShareViewModel(
      (roomId: '123', language: 'en'),
      api,
      room,
      im,
      sharing: sharing,
      platform: platform,
    );
  });
  tearDown(() {
    if (vm.mounted) vm.dispose();
    room.dispose();
  });

  test(
    'Share is default, preview is resolved without shortening or reporting',
    () async {
      await vm.load();
      expect(vm.state.tab, RoomShareTab.share);
      expect(vm.state.materials, hasLength(2));
      expect(vm.state.preview?.description, 'Join Tester 1');
      expect(api.count(HttpApi.roomInviteInfo), 1);
      expect(api.count(HttpApi.roomShareShortLinks), 0);
      expect(api.count(HttpApi.roomShareReport), 0);
      vm.selectMaterial(1);
      expect(vm.state.preview?.description, 'Join Tester 2');
    },
  );

  test('slow materials never block recent conversations or friends', () async {
    api.heldPath = HttpApi.roomShareMaterials;
    api.gate = Completer<Object?>();
    final loading = vm.load();
    await flushTools();
    expect(vm.state.materialsLoading, isTrue);
    expect(vm.state.recentLoading, isFalse);
    expect(vm.state.friendsLoading, isFalse);
    expect(vm.state.recent.single.uid, 20);
    expect(vm.state.friends.single.uid, 20);
    api.gate!.complete([shareMaterialJson(1)]);
    await loading;
  });

  for (final fails in [false, true]) {
    test(
      '${fails ? 'failed' : 'empty'} materials retain Share and retry independently',
      () async {
        if (fails) {
          api.failingPath = HttpApi.roomShareMaterials;
        } else {
          api.responses[HttpApi.roomShareMaterials] = [];
        }
        await vm.load();
        expect(vm.state.tab, RoomShareTab.share);
        expect(vm.state.materialsLoaded, isTrue);
        expect(vm.state.materialsLoading, isFalse);
        expect(vm.state.materials, isEmpty);
        expect(vm.state.preview, isNull);
        expect(vm.state.materialsError != null, fails);
        expect(vm.state.recent, hasLength(1));
        expect(vm.state.friends, hasLength(1));
        final recent = vm.state.recent;
        final friends = vm.state.friends;
        final calls = api.count(HttpApi.userFriends);
        api.failingPath = null;
        api.responses[HttpApi.roomShareMaterials] = [shareMaterialJson(1)];
        await vm.loadMaterials();
        expect(vm.state.materialsError, isNull);
        expect(vm.state.materials, hasLength(1));
        expect(vm.state.preview, isNotNull);
        expect(api.count(HttpApi.userFriends), calls);
        expect(vm.state.recent, same(recent));
        expect(vm.state.friends, same(friends));
        expect(vm.state.tab, RoomShareTab.share);
      },
    );
  }

  for (final tab in [RoomShareTab.recent, RoomShareTab.friends]) {
    for (final result in ['success', 'empty', 'failure']) {
      test('late $result materials preserve $tab, including retry', () async {
        api.heldPath = HttpApi.roomShareMaterials;
        api.gate = Completer<Object?>();
        final loading = vm.load();
        await flushTools();
        vm.selectTab(tab);
        if (result == 'failure') {
          api.gate!.completeError(
            NadyServerResponse<Object?>.fromJson({
              'code': 1003,
              'msg': 'Please retry materials',
              'message': 'Not the preferred message',
            }, null).toException(),
          );
        } else {
          api.gate!.complete(result == 'empty' ? [] : [shareMaterialJson(1)]);
        }
        await loading;
        expect(vm.state.tab, tab);
        if (result == 'failure') {
          expect(vm.state.materialsError, 'Please retry materials');
        }
        final calls = api.count(HttpApi.userFriends);
        api.heldPath = null;
        await vm.loadMaterials();
        expect(vm.state.tab, tab);
        expect(vm.state.materialsError, isNull);
        expect(vm.state.materials, isNotEmpty);
        expect(api.count(HttpApi.userFriends), calls);
      });
    }
  }

  test(
    'copy sends the selected content to clipboard without share reporting',
    () async {
      await vm.load();
      vm.selectMaterial(1);
      expect(
        await vm.share(RoomShareAction.copy, origin: origin),
        RoomShareOutcome.copied,
      );
      expect(
        platform.copied.single,
        'Join Tester 2\nhttps://share.example/s/abc',
      );
      expect(platform.shares, isEmpty);
      expect(api.count(HttpApi.roomShareReport), 0);
      expect(vm.state.busy, isFalse);
    },
  );

  for (final result in [
    RoomShareOutcome.shared,
    RoomShareOutcome.cancelled,
    RoomShareOutcome.unavailable,
  ]) {
    test(
      'system result $result is preserved without pretending delivery',
      () async {
        await vm.load();
        platform.outcome = result;
        expect(await vm.share(RoomShareAction.system, origin: origin), result);
        expect(platform.shares.single.origin, origin);
        expect(api.count(HttpApi.roomShareReport), 1);
        expect(vm.state.error, isNull);
        expect(vm.state.busy, isFalse);
      },
    );
  }

  test(
    'double taps are ignored while preparing or showing system share',
    () async {
      await vm.load();
      platform.gate = Completer<RoomShareOutcome>();
      final first = vm.share(RoomShareAction.system, origin: origin);
      await flushTools();
      expect(
        await vm.share(RoomShareAction.system, origin: origin),
        RoomShareOutcome.stale,
      );
      expect(platform.shares, hasLength(1));
      expect(api.count(HttpApi.roomShareShortLinks), 1);
      platform.gate!.complete(RoomShareOutcome.cancelled);
      expect(await first, RoomShareOutcome.cancelled);
    },
  );

  test(
    'a slow or failed share report cannot block the platform sheet',
    () async {
      await vm.load();
      api.heldPath = HttpApi.roomShareReport;
      api.gate = Completer<Object?>();
      expect(
        await vm.share(RoomShareAction.system, origin: origin),
        RoomShareOutcome.shared,
      );
      expect(platform.shares, hasLength(1));
      api.gate!.completeError(StateError('report failed'));
      await flushTools();
      expect(vm.state.error, isNull);
    },
  );

  test(
    'platform failures release busy and display server message without exception details',
    () async {
      await vm.load();
      platform.failure = const NadyApiException(
        code: 1003,
        message: 'Please try again',
      );
      expect(
        await vm.share(RoomShareAction.system, origin: origin),
        RoomShareOutcome.failed,
      );
      expect(vm.state.error, 'Please try again');
      expect(vm.state.busy, isFalse);
      platform.failure = null;
      expect(
        await vm.share(RoomShareAction.copy, origin: origin),
        RoomShareOutcome.copied,
      );
    },
  );

  for (final scenario in [
    'close',
    'dispose',
    'leave',
    'same-room-reenter',
    'account',
  ]) {
    test(
      '$scenario prevents late short links from copying or opening system share',
      () async {
        await vm.load();
        api.heldPath = HttpApi.roomShareShortLinks;
        api.gate = Completer<Object?>();
        final pending = vm.share(RoomShareAction.system, origin: origin);
        await flushTools();
        switch (scenario) {
          case 'close':
            vm.close();
          case 'dispose':
            vm.dispose();
          case 'leave':
            await room.leaveRoom();
          case 'same-room-reenter':
            room.generation++;
          case 'account':
            room.changeAccount(99);
        }
        api.gate!.complete([
          {'shortUrl': 'https://share.example/s/late'},
        ]);
        expect(await pending, RoomShareOutcome.stale);
        expect(platform.shares, isEmpty);
        expect(platform.copied, isEmpty);
        expect(api.count(HttpApi.roomShareReport), 0);
      },
    );
  }

  test('account mismatch is checked even without a notification', () async {
    await vm.load();
    room.uid = 99;
    expect(
      await vm.share(RoomShareAction.copy, origin: origin),
      RoomShareOutcome.stale,
    );
    expect(platform.copied, isEmpty);
  });

  test(
    'private invite code is not shared between accounts or sheets',
    () async {
      await vm.load();
      room.changeAccount(99);
      api.responses[HttpApi.roomInviteInfo] = {'inviteCode': 'OTHER-ACCOUNT'};
      final other = RoomShareViewModel(
        (roomId: '123', language: 'en'),
        api,
        room,
        im,
        sharing: sharing,
        platform: platform,
      );
      addTearDown(other.dispose);
      await other.load();
      final target = Uri.parse(
        other.state.preview!.link.queryParameters['og_url']!,
      );
      expect(target.queryParameters['uid'], '99');
      expect(target.queryParameters['code'], 'OTHER-ACCOUNT');
      expect(api.count(HttpApi.roomShareMaterials), 1);
      expect(api.count(HttpApi.roomInviteInfo), 2);
    },
  );

  test(
    'recent filters groups, self, system accounts and duplicate users',
    () async {
      im.conversations.addAll([
        for (final id in ['10', '10000', '20', 'invalid'])
          V2TimConversation(conversationID: 'c2c_$id', type: 1, userID: id),
        V2TimConversation(conversationID: 'group', type: 2, userID: '30'),
      ]);
      await vm.load();
      expect(vm.state.recent.map((user) => user.uid), [20]);
      vm.search('FRIEND');
      expect(vm.state.recent, hasLength(1));
      vm.search('no match');
      expect(vm.state.recent, isEmpty);
    },
  );

  test(
    'friends paginate by server page length and deduplicate users',
    () async {
      api.responses[HttpApi.userFriends] = [
        for (var uid = 20; uid < 40; uid++)
          {
            'userBaseInfo': {'uid': uid},
          },
      ];
      await vm.load();
      expect(vm.state.hasMore, isTrue);
      api.responses[HttpApi.userFriends] = [
        {'uid': 39},
        {'uid': 40},
      ];
      await vm.loadFriends();
      expect(vm.state.friends, hasLength(21));
      expect(vm.state.hasMore, isFalse);
      expect(api.calls.last.body['pageNum'], 2);
    },
  );

  test('late friend search cannot overwrite a newer query', () async {
    api.heldPath = HttpApi.userFriends;
    api.gate = Completer<Object?>();
    final old = vm.loadFriends(reset: true);
    await flushTools();
    vm.search('new');
    api.heldPath = null;
    api.responses[HttpApi.userFriends] = [
      {'uid': 30, 'nick': 'new'},
    ];
    await vm.loadFriends(reset: true);
    api.gate!.complete([
      {'uid': 20, 'nick': 'old'},
    ]);
    await old;
    expect(vm.state.friends.single.uid, 30);
  });
}
