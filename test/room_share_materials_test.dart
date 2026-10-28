import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/classes/room/more/room_share_repository.dart';
import 'package:project/classes/room/more/room_share_view_model.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/room_share_models.dart';
import 'package:project/model/server_response.dart';

import 'support/room_share_fakes.dart';
import 'support/room_tools_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final http = HttpDioManager();
  late HttpClientAdapter previousAdapter;
  late _MaterialsAdapter adapter;
  late RoomShareRepository sharing;
  late Map<String, dynamic> fixture;

  setUp(() {
    fixture =
        jsonDecode(
              File(
                'test/fixtures/room_share_materials_null_target.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    SharedPreferences.setMockInitialValues({
      'nady.pubUid': 10,
      'nady.oauthToken': 'test-token',
    });
    previousAdapter = http.getDio().httpClientAdapter;
    adapter = _MaterialsAdapter(fixture);
    http.getDio().httpClientAdapter = adapter;
    sharing = RoomShareRepository(
      RoomToolsRepository(http: http),
      config: ShareConfigFake(),
    );
  });
  tearDown(() {
    http.getDio().httpClientAdapter = previousAdapter;
    adapter.close(force: true);
  });

  test(
    'captured success travels through the real HTTP/repository boundary',
    () async {
      final materials = await sharing.materials('en');
      expect(materials, hasLength(1));
      final material = materials.single;
      expect(material.id, 1);
      expect(material.imageUrl, (fixture['data'] as List).single['imageUrl']);
      expect(material.copyText, 'come on！ play game！！');
      expect(material.jumpLink, isEmpty);
      expect(material.subScene, 'ROOM_SHARE');
      expect(material.resolvedLanguage, 'en');
      expect(material.needsInviteCode, isFalse);
      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, HttpApi.roomShareMaterials);
      expect(request.queryParameters, {
        'appScene': 'ROOM_SHARE',
        'sub-scene': 'ROOM_SHARE',
        'language': 'en',
      });
      expect(request.data, isNull);
      expect(request.headers['pub-uid'], 10);
      expect(request.headers['b'], isNotEmpty);
      expect(request.headers['v'], isNotEmpty);
    },
  );

  test('missing, null and blank targets preserve real display content', () {
    final entry = ((fixture['data'] as List).single as Map)
        .cast<String, dynamic>();
    final variants = [
      {...entry}..remove('jumpLink'),
      {...entry, 'jumpLink': null},
      {...entry, 'jumpLink': ''},
      {...entry, 'jumpLink': '  '},
    ];
    for (final json in variants) {
      final material = RoomShareMaterial.fromJson(json);
      expect(material.hasContent, isTrue);
      for (final action in RoomShareAction.values) {
        final content = sharing.content(
          material,
          uid: 10,
          nickname: 'Tester',
          roomId: '123',
          inviteCode: '',
          action: action,
        );
        expect(content.description, entry['copyText']);
        expect(content.link.scheme, 'https');
        expect(content.link.path, '/h5/invite');
        expect(content.link.queryParameters['og_image'], entry['imageUrl']);
        expect(
          content.link.queryParameters['og_description'],
          entry['copyText'],
        );
        expect(content.link.queryParameters['og_url'], '');
        expect(content.link.query, endsWith('&og_url='));
        expect(
          content.link.queryParameters.containsKey('shareChannel'),
          isFalse,
        );
      }
    }
  });

  test(
    'short-link JSON boundary preserves Nady empty-target encoding',
    () async {
      final material = (await sharing.materials('en')).single;
      final original = sharing.content(
        material,
        uid: 10,
        nickname: 'Tester',
        roomId: '123',
        inviteCode: '',
      );
      adapter.shortLinks = {
        'code': 200,
        'data': [
          {
            'shortUrl': 'https://share.example/s/captured',
            'expireAt': 1793778073914,
          },
        ],
      };
      final shortened = await sharing.shorten(original);
      final request = adapter.requests.last;
      expect(request.path, HttpApi.roomShareShortLinks);
      expect(request.method, 'POST');
      expect(request.queryParameters, isEmpty);
      expect(request.contentType, Headers.jsonContentType);
      expect(request.headers['b'], isNotEmpty);
      expect(jsonDecode(adapter.shortRequestBodies.single), {
        'shortBaseUrl': 'https://share.example',
        'originalShareUrls': [
          'https://share.example/h5/invite?og_title=iSnow'
              '&og_description=${Uri.encodeComponent(material.copyText)}'
              '&og_image=${Uri.encodeComponent(material.imageUrl)}'
              '&og_url=',
        ],
      });
      expect(shortened.link.toString(), 'https://share.example/s/captured');
      expect(shortened.description, original.description);

      adapter.shortLinks = {
        'code': 1003,
        'message': 'Server error',
        'msg': 'Server error',
        'traceId': '22bac3bb-8cf8-4951-bb39-1e3d1ed0dd13',
      };
      expect(await sharing.shorten(original), same(original));
      expect(adapter.shortRequestBodies, hasLength(2));
      expect(
        adapter.requests.where((r) => r.path == HttpApi.roomShareReport),
        isEmpty,
      );
    },
  );

  test(
    'text-only and poster-only records survive, fully empty ones do not',
    () async {
      adapter.materials = {
        'code': 200,
        'data': [
          {
            'id': 2,
            'imageUrl': 'https://poster.example/2.png',
            'copyText': null,
            'jumpLink': null,
          },
          {'id': 1, 'copyText': r'Join ${nickname}', 'jumpLink': ''},
          {'id': 3, 'imageUrl': null, 'copyText': '   ', 'jumpLink': null},
        ],
      };
      final materials = await sharing.materials('en');
      expect(materials.map((item) => item.id).toSet(), {1, 2});
      final content = sharing.content(
        materials.firstWhere((item) => item.id == 1),
        uid: 10,
        nickname: 'A & B/#',
        roomId: '123',
        inviteCode: '',
      );
      expect(content.description, 'Join A & B/#');
      expect(content.link.queryParameters['og_description'], 'Join A & B/#');
    },
  );

  test(
    'genuine empty results remain retryable and successful material is cached',
    () async {
      adapter.materials = {'code': 200, 'data': []};
      expect(await sharing.materials('en'), isEmpty);
      adapter.materials = fixture;
      expect(await sharing.materials('en'), hasLength(1));
      expect(await sharing.materials('en'), hasLength(1));
      expect(adapter.requests, hasLength(2));
    },
  );

  test(
    'business errors keep msg instead of becoming empty materials',
    () async {
      adapter.materials = {
        'code': 1003,
        'msg': 'Please retry materials',
        'message': 'Generic',
        'data': fixture['data'],
      };
      await expectLater(
        sharing.materials('en'),
        throwsA(
          isA<NadyApiException>().having(
            (e) => e.message,
            'message',
            'Please retry materials',
          ),
        ),
      );
    },
  );

  test(
    'ViewModel shows the captured poster/text/H5 link and can copy or share it',
    () async {
      final room = ToolsRoomFake();
      final platform = SharePlatformFake();
      final vm = RoomShareViewModel(
        (roomId: '123', language: 'en'),
        RoomToolsRepository(http: http),
        room,
        ShareImFake(),
        sharing: sharing,
        platform: platform,
      );
      addTearDown(() {
        vm.dispose();
        room.dispose();
      });
      await vm.load();
      expect(vm.state.materials, hasLength(1));
      expect(vm.state.materialsError, isNull);
      expect(vm.state.preview?.description, 'come on！ play game！！');
      expect(vm.state.preview?.link.path, '/h5/invite');
      expect(vm.state.tab, RoomShareTab.share);
      expect(
        adapter.requests.where((r) => r.path == HttpApi.roomInviteInfo),
        isEmpty,
      );
      expect(
        adapter.requests.where((r) => r.path == HttpApi.roomShareShortLinks),
        isEmpty,
      );
      const origin = Rect.fromLTWH(0, 0, 60, 32);
      expect(
        await vm.share(RoomShareAction.copy, origin: origin),
        RoomShareOutcome.copied,
      );
      expect(
        platform.copied.single,
        startsWith('come on！ play game！！\nhttps://share.example/h5/invite?'),
      );
      expect(
        Uri.parse(
          platform.copied.single.split('\n').last,
        ).queryParameters['og_url'],
        '',
      );
      expect(
        await vm.share(RoomShareAction.system, origin: origin),
        RoomShareOutcome.shared,
      );
      expect(platform.shares.single.text, platform.copied.last);
      expect(
        await vm.share(RoomShareAction.whatsapp, origin: origin),
        RoomShareOutcome.opened,
      );
      expect(platform.opened.single.content.link.queryParameters['og_url'], '');
      expect(vm.state.error, isNull);
    },
  );
}

class _MaterialsAdapter implements HttpClientAdapter {
  _MaterialsAdapter(this.materials);
  Map<String, dynamic> materials;
  Map<String, dynamic> shortLinks = {'code': 200, 'data': []};
  final requests = <RequestOptions>[];
  final shortRequestBodies = <String>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path == HttpApi.roomShareShortLinks) {
      shortRequestBodies.add(
        utf8.decode(
          await requestStream!.fold<List<int>>(
            [],
            (bytes, part) => bytes..addAll(part),
          ),
        ),
      );
    }
    final response = switch (options.path) {
      HttpApi.roomShareMaterials => materials,
      HttpApi.userFriends => {'code': 200, 'data': []},
      HttpApi.roomShareShortLinks => shortLinks,
      HttpApi.roomShareReport => {'code': 200},
      _ => throw StateError('Unexpected API ${options.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
