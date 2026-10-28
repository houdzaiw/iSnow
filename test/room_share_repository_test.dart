import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/more/room_share_repository.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/model/room_share_models.dart';

import 'support/room_share_fakes.dart';
import 'support/room_tools_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ToolsApiFake api;
  late ShareConfigFake config;
  late RoomShareRepository repository;
  setUp(() {
    api = shareApiFake();
    config = ShareConfigFake();
    repository = RoomShareRepository(api, config: config);
  });

  RoomShareContent content(
    RoomShareMaterial material, {
    RoomShareAction? action,
    String code = 'INVITE',
  }) => repository.content(
    material,
    uid: 10,
    nickname: 'A & B/# + 中文',
    roomId: '123',
    inviteCode: code,
    action: action,
  );

  test(
    'materials are typed, sorted, and empty templates are excluded',
    () async {
      api.responses[HttpApi.roomShareMaterials] = [
        shareMaterialJson(2),
        {'id': 0},
        shareMaterialJson(1),
      ];
      final result = await repository.materials('en');
      expect(result.map((material) => material.id), [1, 2]);
      expect(api.calls.single.body, {
        'appScene': 'ROOM_SHARE',
        'sub-scene': 'ROOM_SHARE',
        'language': 'en',
      });
    },
  );

  test(
    'same environment and language share in-flight work and memory cache',
    () async {
      api.heldPath = HttpApi.roomShareMaterials;
      api.gate = Completer<Object?>();
      final first = repository.materials('en');
      final second = repository.materials('en');
      expect(api.count(HttpApi.roomShareMaterials), 1);
      api.gate!.complete([shareMaterialJson(1)]);
      expect((await first).single.id, 1);
      expect((await second).single.id, 1);
      await repository.materials('en');
      expect(api.count(HttpApi.roomShareMaterials), 1);
      api.heldPath = null;
      await repository.materials('zh');
      config.base = 'https://qa.example/simi';
      await repository.materials('en');
      expect(api.count(HttpApi.roomShareMaterials), 3);
    },
  );

  test('empty materials are retryable', () async {
    api.responses[HttpApi.roomShareMaterials] = [];
    expect(await repository.materials('en'), isEmpty);
    api.responses[HttpApi.roomShareMaterials] = [shareMaterialJson(1)];
    expect(await repository.materials('en'), hasLength(1));
    expect(api.count(HttpApi.roomShareMaterials), 2);
  });

  test('failed coalesced requests are removed and can retry', () async {
    api.failingPath = HttpApi.roomShareMaterials;
    await expectLater(repository.materials('en'), throwsStateError);
    api.failingPath = null;
    expect(await repository.materials('en'), hasLength(2));
  });

  test(
    'preview neither shortens nor reports and safely resolves URI components',
    () {
      const material = RoomShareMaterial(
        copyText: r'Join ${nickname}',
        jumpLink:
            r'nady://voice-room/${shareRoomId}?nick=${nickname}&uid=${shareUid}&code=${inviteCode}&keep=a%26b#${nickname}',
      );
      final result = content(material);
      final target = Uri.parse(result.link.queryParameters['og_url']!);
      expect(result.link.path, '/h5/invite');
      expect(result.description, 'Join A & B/# + 中文');
      expect(target.scheme, 'nady');
      expect(target.pathSegments, ['123']);
      expect(target.queryParameters['nick'], 'A & B/# + 中文');
      expect(target.queryParameters['keep'], 'a&b');
      expect(target.queryParameters['uid'], '10');
      expect(Uri.decodeComponent(target.fragment), 'A & B/# + 中文');
      expect(api.calls, isEmpty);
    },
  );

  test(
    'channel attribution belongs to the target link, not the H5 wrapper',
    () {
      for (final action in RoomShareAction.values) {
        final result = content(
          RoomShareMaterial.fromJson(shareMaterialJson(1)),
          action: action,
        );
        expect(
          result.link.queryParameters.containsKey('shareChannel'),
          isFalse,
        );
        expect(
          Uri.parse(
            result.link.queryParameters['og_url']!,
          ).queryParameters['shareChannel'],
          action.channelName,
        );
      }
    },
  );

  test(
    'encoded placeholders resolve without recursively expanding user text',
    () {
      final result = repository.content(
        const RoomShareMaterial(
          copyText: r'Join ${nickname}',
          jumpLink:
              'nady://voice-room?nick=%24%7Bnickname%7D&roomId=%24%7BshareRoomId%7D',
        ),
        uid: 10,
        nickname: r'Name ${shareUid}',
        roomId: '123',
        inviteCode: '',
      );
      expect(result.description, r'Join Name ${shareUid}');
      final target = Uri.parse(result.link.queryParameters['og_url']!);
      expect(target.queryParameters['nick'], r'Name ${shareUid}');
      expect(target.queryParameters['roomId'], '123');
    },
  );

  test('explicit page and scheme overrides preserve query and fragment', () {
    config.invite = 'https://invite.example/welcome?campaign=test#preview';
    config.scheme = 'isnow';
    final result = content(RoomShareMaterial.fromJson(shareMaterialJson(1)));
    expect(result.link.path, '/welcome');
    expect(result.link.queryParameters['campaign'], 'test');
    expect(result.link.fragment, 'preview');
    expect(Uri.parse(result.link.queryParameters['og_url']!).scheme, 'isnow');
  });

  test('H5 query matches Nady encoding and keeps explicit empty values', () {
    const material = RoomShareMaterial(
      imageUrl: 'https://poster.example/a.png?size=42&label=A+B',
      copyText: 'A & B/# + 中文',
      jumpLink: '',
    );
    final result = content(material);
    expect(
      result.link.toString(),
      'https://share.example/h5/invite?og_title=iSnow'
      '&og_description=${Uri.encodeComponent(material.copyText)}'
      '&og_image=${Uri.encodeComponent(material.imageUrl)}'
      '&og_url=',
    );
    expect(result.link.queryParameters['og_description'], material.copyText);
    expect(result.link.queryParameters['og_image'], material.imageUrl);
    expect(result.link.queryParameters['og_url'], '');
    expect(api.calls, isEmpty);
  });

  test('custom H5 queries keep duplicate and empty values with a fragment', () {
    config.invite =
        'https://invite.example/welcome?campaign=&tag=a%2Bb&tag=c%20d#preview';
    final result = content(const RoomShareMaterial(jumpLink: ''));
    expect(result.link.queryParameters['campaign'], '');
    expect(result.link.queryParametersAll['tag'], ['a+b', 'c d']);
    expect(result.link.fragment, 'preview');
    expect(result.link.query, startsWith('campaign=&tag=a%2Bb&tag=c%20d&'));
    expect(result.link.query, endsWith('&og_description=&og_image=&og_url='));
  });

  test('development can use HTTP while release share pages require HTTPS', () {
    config.invite = 'http://dev.example/h5/invite';
    final material = RoomShareMaterial.fromJson(shareMaterialJson(1));
    expect(() => content(material), throwsStateError);
    config.allowHttp = true;
    expect(content(material).link.scheme, 'http');
    config.invite = 'https://user:password@invite.example/h5/invite';
    expect(() => content(material), throwsStateError);
  });

  test(
    'unsafe links and unresolved required placeholders never reach sharing',
    () {
      for (final link in [
        'javascript:alert(1)',
        '//share.example/room',
        'nady://voice-room?room=\${unknown}',
        'https://user:secret@share.example',
      ]) {
        expect(
          () => content(RoomShareMaterial(jumpLink: link)),
          throwsStateError,
        );
      }
      expect(
        () =>
            content(RoomShareMaterial.fromJson(shareMaterialJson(1)), code: ''),
        throwsStateError,
      );
    },
  );

  test(
    'shortening uses only the origin and accepts a valid short link',
    () async {
      final original = content(
        RoomShareMaterial.fromJson(shareMaterialJson(1)),
      );
      final result = await repository.shorten(original);
      expect(result.link.toString(), 'https://share.example/s/abc');
      expect(result.description, original.description);
      expect(api.calls.single.body, {
        'shortBaseUrl': 'https://share.example',
        'originalShareUrls': [original.link.toString()],
      });
    },
  );

  test(
    'custom invitation origin does not change the API short-link origin',
    () async {
      config.base = 'https://api.example:8443/simi';
      config.invite = 'https://invite.example/welcome';
      final original = content(const RoomShareMaterial(jumpLink: ''));
      await repository.shorten(original);
      expect(api.calls.single.body, {
        'shortBaseUrl': 'https://api.example:8443',
        'originalShareUrls': [original.link.toString()],
      });
    },
  );

  test(
    'failure, empty or unsafe short links fall back to the validated long link',
    () async {
      final original = content(
        RoomShareMaterial.fromJson(shareMaterialJson(1)),
      );
      api.failingPath = HttpApi.roomShareShortLinks;
      expect((await repository.shorten(original)).link, original.link);
      api.failingPath = null;
      for (final value in [
        <Object>[],
        [
          {'shortUrl': 'javascript:bad'},
        ],
        [
          {'shortUrl': 'http://unsafe.example/link'},
        ],
        [
          {'shortUrl': 'https://user:pw@share.example'},
        ],
      ]) {
        api.responses[HttpApi.roomShareShortLinks] = value;
        expect((await repository.shorten(original)).link, original.link);
      }
    },
  );

  test('share attempt report failures do not escape', () async {
    api.failingPath = HttpApi.roomShareReport;
    await repository.reportShareAttempt();
    expect(api.calls.single.body, isEmpty);
  });
}
