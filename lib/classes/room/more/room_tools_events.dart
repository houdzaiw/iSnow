part of 'room_tools_controller.dart';

extension RoomToolsEvents on RoomToolsController {
  void receive(RoomSocketMessage message) {
    if (!active) return;
    final channel = message.channel;
    if (![
      'room',
      'room:$roomId',
      'global_lobby',
      'global',
      'global:$uid',
    ].contains(channel)) {
      return;
    }
    final roomEvent = channel == 'room' || channel == 'room:$roomId';
    final payload = toolDecode(message.payload);
    final map = toolMap(payload);
    if (map['roomId'] != null &&
        '${map['roomId']}' != roomId &&
        message.event != 'WorldLuckyBagEvent') {
      return;
    }
    final id = message.msgId ?? map['msgID']?.toString() ?? '';
    final key =
        '${message.event}:${id.isEmpty ? 'local:${_value.revision}' : id}';
    if (id.isNotEmpty && !_seen.add(key)) return;
    while (_seen.length > 300) {
      _seen.remove(_seen.first);
    }
    try {
      switch (message.event) {
        case 'RoomUserPropInfoEvent':
          if (channel != 'global' ||
              '${map['roomId']}' != roomId ||
              !visible ||
              !_freshVisual(message) ||
              !_value.effects.car) {
            return;
          }
          final user = toolMap(map['userBaseInfo']);
          if (toolMap(user['vehicle'])['animationUrl'] == null &&
              toolMap(user['specialEffects'])['animationUrl'] == null) {
            return;
          }
          final vehicles = [
            ..._value.vehicleEffects,
            {...user, '_key': key},
          ];
          if (vehicles.length > 8) vehicles.removeAt(1);
          _value = _value.copy(vehicleEffects: vehicles);
        case 'RoomMicCharmIsEnableEvent':
          if (!roomEvent || payload is! bool) return;
          _snapshotVersions['charm'] = (_snapshotVersions['charm'] ?? 0) + 1;
          _value = _value.copy(charmEnabled: payload);
        case 'RoomMicCharmUpdate':
          if (roomEvent && [1, 2].contains(toolInt(payload))) {
            _snapshotVersions['currency'] =
                (_snapshotVersions['currency'] ?? 0) + 1;
            _value = _value.copy(currency: toolInt(payload));
          }
        case 'RoomPkInfoUpdate':
          if (!roomEvent) return;
          _snapshotVersions['pk'] = (_snapshotVersions['pk'] ?? 0) + 1;
          _applyPk(map);
        case 'RoomLobbyStatusEvent':
          if (!roomEvent || !map.containsKey('status')) return;
          final type = toolInt(map['status']) == 1
              ? toolInt(map['lobbyType'], 1)
              : 0;
          _snapshotVersions['mode'] = (_snapshotVersions['mode'] ?? 0) + 1;
          _snapshotVersions['lobby'] = (_snapshotVersions['lobby'] ?? 0) + 1;
          _lobbyInsert?.cancel();
          _value = _value.copy(
            lobbyType: type,
            lobbyVisible:
                [1, 2].contains(type) &&
                _value.config.enabled(type, 2) &&
                visible,
            lobbyRecords: [],
            treasureGifts: [],
            lobbyAwards: [],
          );
          unawaited(loadLobby());
        case 'RoomGameAwardEvent':
        case 'RoomGameAwardEvent2':
          if (!roomEvent || map.isEmpty) return;
          _snapshotVersions['lobby'] = (_snapshotVersions['lobby'] ?? 0) + 1;
          final type = message.event == 'RoomGameAwardEvent2' ? 2 : 1;
          if (_value.lobbyType != type) return;
          final records = [map, ..._value.lobbyRecords];
          _value = _value.copy(
            lobbyRecords: records.length > 100
                ? records.take(90).toList()
                : records,
          );
          if (visible &&
              _freshVisual(message) &&
              _value.lobbyVisible &&
              _value.effects.gift &&
              _value.config.enabled(type, 1) &&
              toolInt(toolMap(map['userBaseInfo'])['uid']) > 0) {
            final previous = _value.lobbyAwards;
            if (previous.length == 1) {
              final head = '${previous.first['_key']}';
              _awardRemoval?.cancel();
              final generation = _generation;
              _awardRemoval = Timer(const Duration(seconds: 2), () {
                if (active && generation == _generation) completeAward(head);
              });
            }
            _value = _value.copy(
              lobbyAwards: [
                for (final award in previous) {...award, '_duration': 3},
                {...map, '_key': key, '_type': type, '_duration': 60},
              ].take(16).toList(),
            );
          }
        case 'RoomScreenLuckyBagSendEvent':
        case 'RoomScreenLuckyBagReciveEvent':
          if (!roomEvent) return;
          _value = _value.copy(
            luckyMessages: [
              ..._value.luckyMessages,
              {
                ...map,
                '_key': key,
                '_event': message.event,
                '_receivedAt': DateTime.now().millisecondsSinceEpoch,
              },
            ].takeLast(80),
          );
          unawaited(refreshBags());
        case 'WorldLuckyBagEvent':
          if (!roomEvent ||
              !visible ||
              !_freshVisual(message) ||
              !_value.effects.screen ||
              map.isEmpty) {
            return;
          }
          _value = _value.copy(
            worldBanners: [
              ..._value.worldBanners,
              {...map, '_key': id.isEmpty ? '${_value.revision}' : id},
            ].take(8).toList(),
          );
        case 'RoomLobbyBigWinStatusEvent':
          if (channel != 'global_lobby' || !_value.config.enabled(8, 17)) {
            return;
          }
          _snapshotVersions['bigWin'] = (_snapshotVersions['bigWin'] ?? 0) + 1;
          final matching =
              _gameOpened && _gameId != null && '${map['gameId']}' == _gameId;
          final delay =
              matching &&
              toolInt(_value.bigWin['status']) == 2 &&
              toolInt(map['userWinCoins']) > 0;
          _prizeDelay?.cancel();
          void apply() {
            if (!active) return;
            if (visible &&
                _value.effects.screen &&
                toolBool(map['showScreen'])) {
              _value = _value.copy(prize: map);
            }
            unawaited(refreshBigWin());
          }
          if (delay) {
            final generation = _generation;
            _prizeDelay = Timer(const Duration(seconds: 15), () {
              if (active && generation == _generation) apply();
            });
          } else {
            apply();
          }
        case 'RoomLobbyBigWinPrizeEvent':
          if (channel != 'global:$uid' || !_value.config.enabled(8, 17)) return;
          if (_value.effects.screen) _value = _value.copy(prize: map);
          unawaited(refreshBalance());
          unawaited(refreshBigWin());
        case 'RoomMusicPlaybackStatusEvent':
          if (!roomEvent) return;
          final status = payload is String
              ? payload
              : '${map['msg'] ?? map['status'] ?? map['data'] ?? ''}';
          if (['PLAYING', 'PAUSED', 'STOPPED', 'FAILED'].contains(status)) {
            _value = _value.copy(musicStatus: status);
          }
        case 'RoomScreenSystemClear':
          if (roomEvent) clearLuckyPublicMessages();
        case 'RoomConfigUpdateEvent':
          if (roomEvent) unawaited(refresh());
        default:
          break;
      }
    } catch (error) {
      debugPrint('[RoomTools] Dropped ${message.event}: $error');
    }
  }

  void _applyPk(ToolJson value) {
    if (value.isEmpty) return;
    final pk = RoomPkSnapshot(value);
    if (pk.eventType == 0 && _value.pk.terminal) return;
    if (pk.id.isNotEmpty && _terminalPks.contains(pk.id)) return;
    if (pk.terminal && pk.id.isNotEmpty) {
      _terminalPks.add(pk.id);
      if (_terminalPks.length > 100) _terminalPks.remove(_terminalPks.first);
    }
    _value = _value.copy(pk: pk, pkVisible: true);
  }

  bool _freshVisual(RoomSocketMessage message) {
    final timestamp = message.timestamp;
    final time = timestamp == null
        ? message.receivedAt ?? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(
            timestamp > 100000000000 ? timestamp : timestamp * 1000,
          );
    return (_visualAfter == null || !time.isBefore(_visualAfter!)) &&
        DateTime.now().difference(time) <= const Duration(seconds: 10);
  }
}

extension<T> on List<T> {
  List<T> takeLast(int count) =>
      length > count ? sublist(length - count) : this;
}
