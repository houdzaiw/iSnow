import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/message/im_repository.dart';
import 'package:project/classes/room/more/room_entry_flow.dart';
import 'package:project/classes/room/more/room_game_view_model.dart';
import 'package:project/classes/room/more/room_report_view_model.dart';
import 'package:project/classes/room/more/room_share_view_model.dart';
import 'package:project/classes/room/more/room_tools_models.dart';
import 'package:project/classes/web/web_bridge_repository.dart';
import 'package:project/classes/web/web_bridge_view_model.dart';
import 'package:project/classes/room/more/room_tools_config.dart';
import 'package:project/configs/app_device.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/room_models.dart';

import 'support/room_tools_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ToolsRoomFake room;
  late ToolsApiFake api;
  setUp(() {
    room = ToolsRoomFake();
    api = ToolsApiFake();
  });
  tearDown(() => room.dispose());
  test(
    'untrusted H5 cannot read authenticated data through relative apiCaller',
    () async {
      final repository = _RecordingBridge();
      final vm = WebBridgeViewModel(repository, AppDevice());
      final blocked = await vm.callApi({
        'method': 'GET',
        'url': '/api/user/mine',
      }, sourceUri: Uri.parse('https://untrusted.example/page'));
      expect(blocked.isSuccess, isFalse);
      expect(repository.calls, 0);
      final allowed = await vm.callApi({
        'method': 'GET',
        'url': '/api/user/mine',
      }, sourceUri: Uri.parse(const RoomToolsConfig().apiBase));
      expect(allowed.isSuccess, isTrue);
      expect(repository.calls, 1);
    },
  );

  test('room card is double-encoded and always strips room passwords', () {
    final decoded = decodeRoomInvitation(
      '{"type":"shareRoom","payload":"{\\"roomId\\":123,\\"roomPasswd\\":\\"secret\\",\\"roomLock\\":true}"}',
    );
    expect(decoded?['roomId'], 123);
    expect(decoded?['roomPasswd'], '');
    expect(decoded?['roomLock'], isTrue);
    expect(decodeRoomInvitation('garbage'), isNull);
    expect(
      decodeRoomInvitation('{"type":"shareRoom","payload":"bad"}'),
      isNull,
    );
  });
  test('share card takes canonical room fields, never nested tokens', () async {
    room.current = room.current.copyWith(
      roomInfo: const RoomInfo(
        roomId: '123',
        raw: {
          'roomInfoDTO': {
            'roomId': 123,
            'roomPasswd': 'secret',
            'roomLock': true,
            'title': 'My room',
          },
          'agoraToken': 'private',
        },
      ),
    );
    final im = _Im();
    final vm = RoomShareViewModel(
      (roomId: '123', language: 'en'),
      api,
      room,
      im,
    );
    addTearDown(vm.dispose);
    final card = vm.roomCard();
    expect(card['roomPasswd'], '');
    expect(card['title'], 'My room');
    expect(card.containsKey('agoraToken'), isFalse);
    expect(await vm.invite(20), isTrue);
    expect(im.target, '20');
    expect(im.card?['roomPasswd'], '');
  });
  test(
    'VIP no-disturb and SDK failure never report invitation success',
    () async {
      final im = _Im();
      final vm = RoomShareViewModel(
        (roomId: '123', language: 'en'),
        api,
        room,
        im,
      );
      addTearDown(vm.dispose);
      api.responses[HttpApi.userHomepage] = {
        'info': {
          'userBaseInfo': {
            'userLevel': {'vipLevel': 5},
          },
        },
      };
      api.responses[HttpApi.userVipSetting] = {
        'noDisturb': {'open': true},
      };
      expect(await vm.invite(20), isFalse);
      expect(im.target, isNull);
      api.responses[HttpApi.userVipSetting] = {
        'noDisturb': {'open': false},
      };
      im.fail = true;
      expect(await vm.invite(20), isFalse);
      expect(vm.state.error, isNotNull);
    },
  );
  test(
    'report requires a reason, preserves form on submission failure',
    () async {
      final repository = _Report(api);
      final vm = RoomReportViewModel('123', repository, room);
      addTearDown(vm.dispose);
      expect(await vm.submit(), isFalse);
      expect(repository.submits, 0);
      vm.selectReason(3);
      vm.describe('Details');
      repository.failSubmit = true;
      expect(await vm.submit(), isFalse);
      expect(vm.state.reason, 3);
      expect(vm.state.description, 'Details');
      repository.failSubmit = false;
      expect(await vm.submit(), isTrue);
      expect(repository.body?['reportId'], 123);
      expect(repository.body?['categoriesList'], [3]);
    },
  );
  test(
    'report retries only failed uploads and never submits partial images',
    () async {
      final repository = _Report(api)..failUpload = 'b';
      final vm = RoomReportViewModel('123', repository, room);
      addTearDown(vm.dispose);
      vm.selectReason(1);
      await vm.pickPhotos();
      expect(vm.state.photos.length, 4);
      expect(await vm.submit(), isFalse);
      expect(repository.submits, 0);
      repository.failUpload = null;
      expect(await vm.submit(), isTrue);
      expect(repository.uploads.where((path) => path == 'a').length, 1);
      expect(repository.body?['photosList'], [
        'oss/a',
        'oss/b',
        'oss/c',
        'oss/d',
      ]);
    },
  );
  test(
    'game bridge rejects arbitrary absolute origins and protocol-relative URLs',
    () async {
      final bridge = WebBridgeRepository(HttpDioManager());
      for (final url in [
        'https://untrusted.example/api/user/mine',
        '//untrusted.example/api/user/mine',
        'file:///api/user/mine',
      ]) {
        expect(
          () => bridge.callApi(
            WebBridgeApiRequest(
              method: 'GET',
              url: url,
              param: {},
              keys: 'params',
            ),
          ),
          throwsA(isA<WebBridgeApiRequestException>()),
        );
      }
      expect(gameHeightRatio('1.4'), 1.4);
      expect(gameHeightRatio(0), isNull);
      expect(gameHeightRatio('Infinity'), isNull);
    },
  );
}

class _RecordingBridge extends WebBridgeRepository {
  _RecordingBridge() : super(HttpDioManager());
  int calls = 0;
  @override
  Future<dynamic> callApi(WebBridgeApiRequest request) async {
    calls++;
    return {'code': 200};
  }
}

class _Im implements ImRepository {
  String? target;
  ToolJson? card;
  bool fail = false;
  @override
  Future<void> sendRoomInvitation({
    required String targetUID,
    required Map<String, dynamic> room,
  }) async {
    if (fail) throw StateError('SDK rejected');
    target = targetUID;
    card = room;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Report extends RoomReportRepository {
  _Report(super.api);
  String? failUpload;
  bool failSubmit = false;
  final uploads = <String>[];
  int submits = 0;
  ToolJson? body;
  @override
  Future<List<String>> pick(int remaining) async =>
      ['a', 'b', 'c', 'd', 'e'].take(remaining).toList();
  @override
  Future<List<ToolJson>> uploadParams(int count) async =>
      List.generate(count, (_) => {});
  @override
  Future<String> upload(String path, ToolJson param) async {
    uploads.add(path);
    if (path == failUpload) throw StateError('Upload failed');
    return 'oss/$path';
  }

  @override
  Future<void> submit(ToolJson value) async {
    submits++;
    if (failSubmit) throw StateError('Submit failed');
    body = value;
  }
}
