part of 'app_socket_manager.dart';

extension AppSocketAccount on AppSocketManager {
  /// Auth-bound channels survive Keep/Exit; logout releases the connection.
  /// The serialized revision check prevents an old login lookup rebinding later.
  Future<void> bindBarrageAccount(int? uid, {bool reauthenticate = false}) {
    final desired = uid != null && uid > 0 ? uid : null;
    _desiredAccountUid = desired;
    final revision = ++_accountRevision;
    final work = _accountOperation.catchError((Object _) {}).then((_) async {
      if (revision != _accountRevision) return;
      if (_accountUid != desired || reauthenticate) {
        final hadAccount = _accountUid != null;
        _accountUid = null;
        _accountChannels.clear();
        if (hadAccount) await close();
      }
      if (revision != _accountRevision || desired == null) return;
      final endpoint = _socketUrl ?? await _fetchString(HttpApi.longLinkUrl);
      if (revision != _accountRevision) return;
      final uri = Uri.tryParse(endpoint);
      if (uri == null ||
          !{'ws', 'wss'}.contains(uri.scheme) ||
          uri.host.isEmpty) {
        throw const NadyApiException(message: 'Invalid WebSocket endpoint');
      }
      _accountUid = desired;
      _accountChannels.addAll({
        'global',
        'global:$desired',
        'global_lobby',
        'room',
      });
      await connect(url: endpoint);
      if (revision != _accountRevision) return;
      final client = _client;
      if (client == null) return;
      await _restoreBarrageChannels(revision);
      _syncConnectedState();
    });
    _accountOperation = work;
    return work;
  }

  Future<void> _restoreBarrageChannels(int revision) async {
    final client = _client;
    if (client == null ||
        _accountUid == null ||
        _accountUid != _desiredAccountUid) {
      return;
    }
    for (final channel in _accountChannels.toList()) {
      if (revision != _accountRevision) return;
      try {
        await _subscribeChannel(client, channel);
      } catch (error) {
        _log('account channel=$channel failed: $error');
      }
    }
  }
}
