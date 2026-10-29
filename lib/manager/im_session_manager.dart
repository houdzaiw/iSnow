import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/log_level_enum.dart';
import 'package:tencent_cloud_chat_sdk/manager/v2_tim_manager.dart';

import '../model/im_models.dart';
import '../model/server_response.dart';
import '../model/tim_token_data.dart';
import 'api_error_message.dart';
import 'auth_session.dart';

/// One SDK login queue is shared by the main inbox, room inbox and room sharing.
class ImSessionManager extends ChangeNotifier {
  ImSessionManager({
    required this.sdk,
    required this.auth,
    required this.loadToken,
  }) {
    auth.addListener(_authChanged);
  }

  final V2TIMManager sdk;
  final AuthSession auth;
  final Future<TimTokenData> Function() loadToken;
  ImConnectionState _state = const ImConnectionState();
  ImConnectionState get state => _state;
  int get revision => _revision;
  int _revision = 0;
  int? _loggedUid;
  int? _appId;
  bool _disposed = false;
  Future<void>? _pending;
  Future<void> _queue = Future.value();

  bool isCurrent(int revision) => !_disposed && revision == _revision;

  void _publish(ImConnectionStatus status, {String? error, int? uid}) {
    if (_disposed) return;
    _state = ImConnectionState(
      status: status,
      uid: uid ?? _loggedUid,
      revision: _revision,
      error: error,
    );
    notifyListeners();
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final next = _queue.then((_) => operation());
    _queue = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  void _check(int revision) {
    if (!isCurrent(revision)) {
      throw const NadyApiException(message: 'IM session changed');
    }
  }

  void _authChanged() {
    _revision++;
    _loggedUid = null;
    _pending = null;
    _publish(ImConnectionStatus.disconnected);
    if (_appId != null) {
      unawaited(
        _serialize(() async {
          await sdk.logout();
        }).catchError((Object _) {}),
      );
    }
  }

  Future<void> ensureReady() async {
    final revision = _revision;
    final uid = await auth.uid();
    _check(revision);
    if (uid == null) {
      throw const NadyApiException(message: 'Please log in first');
    }
    if (_loggedUid == uid && _state.status == ImConnectionStatus.connected) {
      return;
    }
    if (_loggedUid != null && _loggedUid != uid) {
      _authChanged();
      return ensureReady();
    }
    var pending = _pending;
    if (pending == null) {
      pending = _serialize(() => _connect(uid, revision));
      _pending = pending;
    }
    try {
      await pending;
      _check(revision);
    } finally {
      if (identical(_pending, pending)) _pending = null;
    }
  }

  Future<void> reconnect() async {
    if (_state.status == ImConnectionStatus.connecting) {
      return ensureReady();
    }
    _authChanged();
    await ensureReady();
  }

  Future<void> _connect(int uid, int revision) async {
    _check(revision);
    _publish(ImConnectionStatus.connecting, uid: uid);
    try {
      final token = await loadToken();
      _check(revision);
      if (token.appId <= 0 || token.token.isEmpty) {
        throw const NadyApiException(message: 'Invalid IM token');
      }
      if (_appId != token.appId) {
        if (_appId != null) await sdk.unInitSDK();
        _check(revision);
        final result = await sdk.initSDK(
          sdkAppID: token.appId,
          loglevel: LogLevelEnum.V2TIM_LOG_WARN,
          listener: V2TimSDKListener(
            onConnecting: () {
              if (_loggedUid != null) _publish(ImConnectionStatus.connecting);
            },
            onConnectSuccess: () {
              if (_loggedUid != null) _publish(ImConnectionStatus.connected);
            },
            onConnectFailed: (_, error) =>
                _publish(ImConnectionStatus.error, error: error),
            onKickedOffline: () =>
                _invalidate('IM logged in on another device'),
            onUserSigExpired: () => _invalidate('IM session expired'),
          ),
        );
        _check(revision);
        if (result.code != 0) throw NadyApiException(message: result.desc);
        _appId = token.appId;
      }
      final result = await sdk.login(userID: '$uid', userSig: token.token);
      _check(revision);
      if (result.code != 0) throw NadyApiException(message: result.desc);
      _loggedUid = uid;
      _publish(ImConnectionStatus.connected);
    } catch (error) {
      if (isCurrent(revision)) {
        _publish(
          ImConnectionStatus.error,
          error: userFacingErrorMessage(error),
        );
      }
      rethrow;
    }
  }

  void _invalidate(String message) {
    if (_disposed) return;
    _revision++;
    _pending = null;
    _loggedUid = null;
    _publish(ImConnectionStatus.error, error: message);
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    auth.removeListener(_authChanged);
    super.dispose();
  }
}
