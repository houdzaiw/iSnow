import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/more/room_share_repository.dart';
import 'package:project/classes/room/more/room_share_view_model.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_share_models.dart';

import 'support/room_share_fakes.dart';
import 'support/room_tools_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ToolsRoomFake room;
  late ToolsApiFake api;
  late SharePlatformFake platform;
  late RoomShareViewModel vm;
  const origin = Rect.fromLTWH(10, 300, 40, 40);
  final direct = RoomShareAction.values.where(
    (action) =>
        action != RoomShareAction.copy && action != RoomShareAction.system,
  );
  setUp(() {
    room = ToolsRoomFake();
    api = shareApiFake();
    platform = SharePlatformFake();
    vm = RoomShareViewModel(
      (roomId: '123', language: 'en'),
      api,
      room,
      ShareImFake(),
      sharing: RoomShareRepository(api, config: ShareConfigFake()),
      platform: platform,
    );
  });
  tearDown(() {
    vm.dispose();
    room.dispose();
  });

  for (final action in direct) {
    test(
      '$action copies the correct payload, attributes and opens once',
      () async {
        await vm.load();
        expect(await vm.share(action, origin: origin), RoomShareOutcome.opened);
        expect(platform.opened.single.action, action);
        expect(
          platform.copied.single,
          action.linkOnlyClipboard
              ? 'https://share.example/s/abc'
              : 'Join Tester 1\nhttps://share.example/s/abc',
        );
        expect(platform.shares, isEmpty);
        expect(api.count(HttpApi.roomShareShortLinks), 1);
        expect(api.count(HttpApi.roomShareReport), 1);
        final request = api.calls.firstWhere(
          (call) => call.path == HttpApi.roomShareShortLinks,
        );
        final wrapper = Uri.parse(
          (request.body['originalShareUrls'] as List).single as String,
        );
        expect(
          Uri.parse(
            wrapper.queryParameters['og_url']!,
          ).queryParameters['shareChannel'],
          action.channelName,
        );
        expect(vm.state.error, isNull);
        expect(vm.state.busy, isFalse);
      },
    );
  }

  test(
    'a launch failure retains the active panel without system fallback',
    () async {
      await vm.load();
      platform.opens = false;
      expect(
        await vm.share(RoomShareAction.snapchat, origin: origin),
        RoomShareOutcome.failed,
      );
      expect(vm.state.error, 'Unable to open Snapchat');
      expect(vm.state.isActive, isTrue);
      expect(vm.state.busy, isFalse);
      expect(platform.shares, isEmpty);
    },
  );

  test('double taps cannot duplicate a pending direct launch', () async {
    await vm.load();
    platform.openGate = Completer<bool>();
    final pending = vm.share(RoomShareAction.telegram, origin: origin);
    await flushTools();
    expect(
      await vm.share(RoomShareAction.telegram, origin: origin),
      RoomShareOutcome.stale,
    );
    platform.openGate!.complete(true);
    expect(await pending, RoomShareOutcome.opened);
    expect(platform.opened, hasLength(1));
    expect(api.count(HttpApi.roomShareReport), 1);
  });

  test(
    'shortening failure keeps a real long link for the selected channel',
    () async {
      await vm.load();
      api.failingPath = HttpApi.roomShareShortLinks;
      expect(
        await vm.share(RoomShareAction.whatsapp, origin: origin),
        RoomShareOutcome.opened,
      );
      final link = platform.opened.single.content.link;
      expect(link.path, '/h5/invite');
      expect(
        Uri.parse(
          link.queryParameters['og_url']!,
        ).queryParameters['shareChannel'],
        'WhatsApp',
      );
    },
  );

  for (final afterCopy in [false, true]) {
    for (final close in [false, true]) {
      test(
        '${close ? 'close' : 'account switch'} after ${afterCopy ? 'copy' : 'shortening'} prevents a direct launch',
        () async {
          await vm.load();
          if (afterCopy) {
            platform.copyGate = Completer<void>();
          } else {
            api.heldPath = HttpApi.roomShareShortLinks;
            api.gate = Completer<Object?>();
          }
          final pending = vm.share(RoomShareAction.x, origin: origin);
          await flushTools();
          if (close) {
            vm.close();
          } else {
            room.changeAccount(99);
          }
          if (afterCopy) {
            platform.copyGate!.complete();
          } else {
            api.gate!.complete([
              {'shortUrl': 'https://share.example/s/late'},
            ]);
          }
          expect(await pending, RoomShareOutcome.stale);
          expect(platform.opened, isEmpty);
          expect(platform.shares, isEmpty);
          expect(api.count(HttpApi.roomShareReport), 0);
          if (!afterCopy) expect(platform.copied, isEmpty);
        },
      );
    }
  }
}
