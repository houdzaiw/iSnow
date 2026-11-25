import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/web/profile_web_actions.dart';
import 'package:project/classes/web/web_bridge_repository.dart';
import 'package:project/classes/web/web_bridge_view_model.dart';
import 'package:project/classes/web/web_page_bridge.dart';
import 'package:project/classes/web/web_share_models.dart';
import 'package:project/classes/profile/tools/profile_feature_repository.dart';
import 'package:project/classes/profile/tools/profile_tools_config.dart';
import 'package:project/configs/app_device.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'support/profile_tools_fakes.dart';

class _Api extends WebBridgeRepository {
  _Api() : super(HttpDioManager());
  final requests = <WebBridgeApiRequest>[];
  @override
  Future<dynamic> callApi(WebBridgeApiRequest request) async {
    requests.add(request);
    return {'code': 200, 'data': null};
  }
}

class _Actions implements ProfileWebActions {
  _Actions(this.features);
  @override
  final ProfileFeatureRepository features;
  Completer<Map<String, dynamic>>? pendingUser;
  Map<String, dynamic> productList = {
    'list': [
      {
        'id': 'sku.valid',
        'name': 'Coins',
        'coinAmount': 100,
        'currencyAmount': 99,
        'currency': 'USD',
      },
    ],
  };
  String? room = '31';
  @override
  String Function() get roomId =>
      () => '31';
  @override
  Future<String?> ownRoom() async => room;
  @override
  Future<bool> auditing() async => false;
  @override
  Future<Map<String, dynamic>> userInfo() async => pendingUser == null
      ? {
          'userInfo': {'uid': 10},
          'currentRoomID': '31',
        }
      : pendingUser!.future;
  @override
  Future<Map<String, dynamic>> paymentList(String type) async => productList;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProfileToolsFake f;
  late _Api api;
  late _Actions actions;
  late WebPageBridge bridge;
  late List<({String type, String key, Object? data})> results;
  late List<WebNativeRequest> native;
  Completer<Object?>? pendingNative;
  Object? nativeResult;
  Future<void> send(String type, Object? data, {String key = 'key'}) =>
      bridge.handle(jsonEncode({'type': type, 'key': key, 'data': data}));
  setUp(() {
    f = ProfileToolsFake();
    api = _Api();
    actions = _Actions(f.features);
    results = [];
    native = [];
    pendingNative = null;
    nativeResult = null;
    bridge = WebPageBridge(
      api: WebBridgeViewModel(api, AppDevice()),
      actions: actions,
      native: (r) async {
        native.add(r);
        return pendingNative != null ? pendingNative!.future : nativeResult;
      },
      callback: (type, key, data) async =>
          results.add((type: type, key: key, data: data)),
      notice: (_, _) {},
      statusBarHeight: () => 24,
      shareOrigin: () => const Rect.fromLTWH(1, 1, 100, 100),
      source: Uri.parse(
        '${const ProfileToolsConfig().origin}/h5/agent/index.html?language=zh',
      ),
    );
  });
  tearDown(() => bridge.dispose());

  test(
    'legacy JSON string data and map data reach one guarded API path',
    () async {
      await send(
        'apiCaller',
        jsonEncode({
          'url': '/api/example',
          'method': 'POST',
          'param': {'id': 1},
        }),
      );
      expect(api.requests.single.body, {'id': 1, 'language': 'zh'});
      expect(api.requests.single.extra[HttpDioManager.expectedAuthUid], 10);
      expect(
        api.requests.single.extra[HttpDioManager.expectedAuthToken],
        'fixture',
      );
      expect(results.single.data, {'code': 200, 'data': null});
      bridge.navigate('https://evil.test/h5');
      await send('apiCaller', {'url': '/api/example'});
      expect(api.requests.length, 1);
      expect(results.last.type, 'apiCallerError');
    },
  );
  test(
    'pending response is discarded after navigation, disposal or account change',
    () async {
      for (final action in ['navigate', 'account']) {
        actions.pendingUser = Completer<Map<String, dynamic>>();
        final pending = send('getUserInfo', {});
        await Future<void>.delayed(Duration.zero);
        if (action == 'navigate') {
          bridge.navigate('${const ProfileToolsConfig().origin}/new');
        } else {
          f.account = (uid: 20, token: 'other', generation: 2);
        }
        actions.pendingUser!.complete({
          'userInfo': {'uid': 10},
        });
        await pending;
        expect(results, isEmpty);
      }
    },
  );
  test(
    'native request retains navigation epoch; no callback after page changes',
    () async {
      pendingNative = Completer<Object?>();
      final pending = send('commonShare', {
        'shareList': [],
        'isShowShareTab': true,
      });
      await Future<void>.delayed(Duration.zero);
      final request = native.single;
      expect(request.isCurrent!(), isTrue);
      bridge.navigate('${const ProfileToolsConfig().origin}/new');
      expect(request.isCurrent!(), isFalse);
      pendingNative!.complete({
        'type': 'friend',
        'data': {'uid': 88},
      });
      await pending;
      expect(results, isEmpty);
    },
  );
  test(
    'commonShare merges repeated clicks and passes exact selected-user callback',
    () async {
      pendingNative = Completer<Object?>();
      final one = send('commonShare', {
        'isShowShareTab': true,
        'shareList': [
          {
            'title': 'Invite',
            'imageUrl': 'https://images.test/a.png',
            'linkUrl': 'https://link.test/',
          },
        ],
      });
      await Future<void>.delayed(Duration.zero);
      await send('commonShare', {});
      expect(native, hasLength(1));
      expect(native.single.share!.materials.single.title, 'Invite');
      final selected = {
        'type': 'friend',
        'data': {'uid': 88, 'nick': 'Receiver', 'avatar': ''},
      };
      pendingNative!.complete(selected);
      await one;
      expect(results.single.type, 'commonShareSelectUser');
      expect(results.single.data, selected);
      expect(f.calls, isEmpty); // H5 selection must not send an IM invitation.
    },
  );
  test(
    'unknown SKU never opens checkout; cancel does not report payment success',
    () async {
      await send('paymentCaller', {'skuID': 'attacker', 'coinAmount': 99999});
      expect(native, isEmpty);
      expect(results.single.type, 'paymentCallerError');
      results.clear();
      nativeResult = false;
      await send('paymentCaller', {
        'skuID': 'sku.valid',
        'coinAmount': 99999,
        'countryRechargeChannelConfigId': 'config1',
      });
      expect(native.single.product!.coinAmount, 100);
      expect(native.single.product!.countryRechargeChannelConfigId, 'config1');
      expect(results, isEmpty);
      nativeResult = true;
      await send('paymentCaller', {'skuID': 'sku.valid'});
      expect(results.single.type, 'paymentCallerSuccess');
      expect(results.single.key, '');
    },
  );
  test(
    'own-room game target keeps requested mode without executing mutation',
    () async {
      await send('jumpNativePage', 'nady:///main/show_game_play?openBigWin=1');
      expect(native.single.kind, WebNativeKind.lobby);
      expect(native.single.roomId, '31');
      expect(native.single.lobbyType, 1);
      expect(f.calls, isEmpty);
      native.clear();
      await send('jumpNativePage', 'nady:///main/me-backpack');
      expect(native.single.destination!.target, '/backpack');
    },
  );
  test('malformed envelopes are safe and share defaults match Nady', () async {
    await bridge.handle('garbage');
    await bridge.handle('null');
    expect(results, isEmpty);
    final request = WebShareRequest.fromJson({});
    expect(request.showShare, isFalse);
    expect(request.showRecent && request.showFriends, isTrue);
    await send('jumpNativePage', 'javascript:alert(1)');
    expect(results.single.type, 'jumpNativePageError');
    expect(native, isEmpty);
  });
}
