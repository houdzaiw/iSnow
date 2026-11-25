import 'dart:convert';
import 'dart:ui';

import '../../manager/api_error_message.dart';
import '../profile/mine/profile_menu_item.dart';
import '../profile/tools/profile_feature_repository.dart';
import '../profile/tools/profile_menu_repository.dart';
import '../profile/tools/profile_tools_config.dart';
import '../wallet/wallet_models.dart';
import '../room/more/room_tools_config.dart';
import 'profile_web_actions.dart';
import 'web_share_models.dart';
import 'web_bridge_view_model.dart';

enum WebNativeKind {
  close,
  closeDialog,
  bar,
  picture,
  share,
  payment,
  target,
  game,
  lobby,
}

class WebNativeRequest {
  const WebNativeRequest(
    this.kind, {
    this.title,
    this.hide = false,
    this.share,
    this.product,
    this.destination,
    this.roomId,
    this.lobbyType = 0,
    this.isCurrent,
  });
  final WebNativeKind kind;
  final String? title, roomId;
  final bool hide;
  final WebShareRequest? share;
  final WalletRechargeProduct? product;
  final ProfileDestination? destination;
  final int lobbyType;
  final bool Function()? isCurrent;
  WebNativeRequest guarded(bool Function() current) => WebNativeRequest(
    kind,
    title: title,
    hide: hide,
    share: share,
    product: product,
    destination: destination,
    roomId: roomId,
    lobbyType: lobbyType,
    isCurrent: current,
  );
}

/// Parses the legacy H5 protocol and owns its session and navigation epochs.
/// UI navigation is delegated as typed requests; no widgets or routes live here.
class WebPageBridge {
  WebPageBridge({
    required this.api,
    required this.actions,
    required this.native,
    required this.callback,
    required this.notice,
    required this.statusBarHeight,
    required this.shareOrigin,
    required Uri? source,
  }) : _source = source;
  final WebBridgeViewModel api;
  final ProfileWebActions actions;
  final Future<Object?> Function(WebNativeRequest) native;
  final Future<void> Function(String, String, Object?) callback;
  final void Function(Object?, String?) notice;
  final double Function() statusBarHeight;
  final Rect Function() shareOrigin;
  Uri? _source;
  int _epoch = 0;
  bool _alive = true, _busy = false;
  bool _navigationBusy = false;
  bool get alive => _alive;
  void navigate(String url) {
    _source = Uri.tryParse(url);
    _epoch++;
  }

  void dispose() {
    _alive = false;
    _epoch++;
  }

  static Map<String, dynamic> decodeMap(Object? raw) {
    try {
      final value = raw is String ? jsonDecode(raw) : raw;
      return membershipMap(value);
    } on FormatException {
      return const {};
    }
  }

  Future<void> handle(String raw) async {
    final envelope = decodeMap(raw);
    final type = membershipString(envelope['type']);
    if (type.isEmpty || type == 'log' || !_alive) return;
    final key = '${envelope['key'] ?? ''}';
    final value = envelope['data'];
    final data = decodeMap(value);
    final epoch = _epoch;
    bool current() => _alive && epoch == _epoch;
    MembershipIdentity? capturedAccount;
    var ownsNavigation = false;
    try {
      final source = _source ?? Uri();
      if (!api.trustedSource(source)) {
        throw StateError('This page is not authorized to use native actions');
      }
      final account = await actions.features.identity();
      capturedAccount = account;
      Future<bool> active() async {
        await actions.features.check(account);
        return current();
      }

      Future<void> emit(
        String name,
        Object? payload, [
        String? callbackKey,
      ]) async {
        if (await active()) await callback(name, callbackKey ?? key, payload);
      }

      if (!await active()) return;
      if (const {
        'jumpNativePage',
        'jumpGamePage',
        'openSystemBrowser',
      }.contains(type)) {
        if (_navigationBusy) return;
        _navigationBusy = ownsNavigation = true;
      }
      Future<Object?> dispatch(WebNativeRequest request) async {
        if (!await active()) return null;
        return native(request.guarded(current));
      }

      switch (type) {
        case 'apiCaller':
          final result = await api.callApi(
            data,
            language: source.queryParameters['language'],
            sourceUri: source,
            account: account,
            isCurrent: current,
          );
          await emit(
            result.isSuccess ? type : 'apiCallerError',
            result.isSuccess ? result.data : result.error,
          );
        case 'getAppInfo':
          final info = api.appInfo(statusBarHeight: statusBarHeight());
          if (const ProfileToolsConfig().trusted(source)) {
            info['isNotCommon'] = await actions.auditing();
          }
          await emit(type, info);
        case 'getUserInfo':
          await emit(type, await actions.userInfo());
        case 'paymentList':
          await emit(type, await actions.paymentList('${data['type'] ?? ''}'));
        case 'changeAppBar':
          await dispatch(
            WebNativeRequest(
              WebNativeKind.bar,
              title: data['title']?.toString(),
              hide: data['hide'] == true || data['hide'] == 1,
            ),
          );
        case 'close':
          await dispatch(const WebNativeRequest(WebNativeKind.close));
        case 'closeSmartDialog':
          await dispatch(const WebNativeRequest(WebNativeKind.closeDialog));
        case 'jumpGamePage':
          final url = value is String ? value : '${data['url'] ?? ''}';
          final game = Uri.tryParse(url);
          if (game == null ||
              !const RoomToolsConfig().trustedGame(game) ||
              actions.roomId().isEmpty) {
            throw StateError('Game is unavailable in the current room');
          }
          await dispatch(
            WebNativeRequest(
              WebNativeKind.game,
              roomId: actions.roomId(),
              title: url,
            ),
          );
        case 'openSystemBrowser':
          if (!await actions.openExternal(
            value is String ? value : '${data['url'] ?? ''}',
          )) {
            throw StateError('Unable to open this URL');
          }
        case 'jumpNativePage':
          final url = value is String ? value : '${data['url'] ?? ''}';
          final destination = ProfileMenuRepository.parseDestination(url);
          final uri = Uri.tryParse(url);
          if (destination != null) {
            await dispatch(
              WebNativeRequest(WebNativeKind.target, destination: destination),
            );
          } else if (uri?.scheme == 'nady' && uri?.path == '/main/voice-room') {
            final id = uri!.queryParameters['roomId'];
            if (id == null || id.isEmpty) throw StateError('Missing room ID');
            await dispatch(WebNativeRequest(WebNativeKind.target, roomId: id));
          } else if (uri?.scheme == 'nady' &&
              uri?.path == '/main/show_game_play') {
            final lobby = uri!.queryParameters['openBigWin'] == '1'
                ? 1
                : uri.queryParameters['openTreasure'] == '1'
                ? 2
                : 0;
            final roomId = await actions.ownRoom();
            await dispatch(
              WebNativeRequest(
                WebNativeKind.lobby,
                roomId: roomId,
                lobbyType: lobby,
              ),
            );
          } else {
            throw StateError('Unsupported native target');
          }
        case 'share':
        case 'commonShare':
        case 'selectPicture':
        case 'saveImage':
        case 'paymentCaller':
          if (_busy) return;
          _busy = true;
          try {
            switch (type) {
              case 'share':
                await actions.shareContent(
                  '${data['appName'] ?? 'system'}',
                  data,
                  shareOrigin(),
                  isCurrent: current,
                );
              case 'commonShare':
                final selected = await dispatch(
                  WebNativeRequest(
                    WebNativeKind.share,
                    share: WebShareRequest.fromJson(data),
                  ),
                );
                if (selected != null) {
                  await emit('commonShareSelectUser', selected);
                }
              case 'selectPicture':
                final camera = await dispatch(
                  const WebNativeRequest(WebNativeKind.picture),
                );
                if (camera is! bool || !await active()) return;
                final url = await actions.selectPicture(
                  camera: camera,
                  isCurrent: current,
                );
                if (url != null) await emit(type, url);
              case 'saveImage':
                await actions.media.save(
                  value is String ? value : '${data['url'] ?? ''}',
                  isCurrent: current,
                );
                if (await active()) notice(null, 'tools.saved');
              case 'paymentCaller':
                final sku = '${data['skuID'] ?? data['id'] ?? ''}';
                final payload = await actions.paymentList(
                  '${data['type'] ?? ''}',
                );
                final json = membershipList(
                  payload['list'],
                  (j) => j,
                ).where((j) => '${j['id']}' == sku).firstOrNull;
                if (json == null) {
                  throw StateError('Payment product unavailable');
                }
                final product = WalletRechargeProduct.fromJson({
                  ...json,
                  'countryRechargeChannelConfigId':
                      '${data['countryRechargeChannelConfigId'] ?? ''}',
                });
                if (!await active()) return;
                final paid = await dispatch(
                  WebNativeRequest(WebNativeKind.payment, product: product),
                );
                if (paid == true) {
                  await emit('paymentCallerSuccess', const {}, '');
                }
            }
          } finally {
            _busy = false;
          }
        default:
          throw StateError('Unsupported native action');
      }
    } catch (error) {
      if (capturedAccount != null) {
        try {
          await actions.features.check(capturedAccount);
        } catch (_) {
          return;
        }
      }
      if (current()) {
        // Errors contain no raw H5 message, account credentials, or upload data.
        final message = userFacingErrorMessage(error);
        await callback('${type}Error', key, {'message': message});
        notice(error, null);
      }
    } finally {
      if (ownsNavigation) _navigationBusy = false;
    }
  }
}
