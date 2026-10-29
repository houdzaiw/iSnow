part of 'room_tools_controller.dart';

extension RoomToolsOperations on RoomToolsController {
  Future<void> _restoreSpeaker() async {
    final userId = uid;
    final generation = _generation;
    if (!active || userId == null) return;
    final muted = await repository.speakerMuted(userId, roomId);
    if (active &&
        generation == _generation &&
        room.agoraState.mutedSpeaker != muted) {
      await room.muteSpeaker(muted);
    }
  }

  Future<bool> toggleVoice() => perform('voice', (current) async {
    final userId = uid;
    if (userId == null) {
      throw const NadyApiException(message: 'Please log in first');
    }
    final old = room.agoraState.mutedSpeaker;
    await room.muteSpeaker(!old);
    if (!current()) return;
    if (room.agoraState.mutedSpeaker == old) {
      throw const NadyApiException(message: 'Agora audio is not ready');
    }
    try {
      await repository.saveSpeaker(userId, roomId, !old);
    } catch (_) {
      if (current()) await room.muteSpeaker(old);
      rethrow;
    }
  });

  /// Retry local preferences without resetting the active room session.
  Future<bool> reloadEffectPreferences() => perform('effects', (current) async {
    final userId = await room.currentUid();
    if (!current()) return;
    if (userId == null) {
      throw const NadyApiException(message: 'Please log in first');
    }
    final prefs = await repository.effects(userId);
    if (!current()) return;
    uid = userId;
    _value = _value.copy(effects: prefs, preferencesReady: true);
  });

  Future<bool> setEffect(String key, bool value) =>
      perform('effects', (current) async {
        if (!_value.preferencesReady || uid == null) {
          throw const NadyApiException(message: 'Preferences are loading');
        }
        final next = _value.effects.change(key, value);
        await repository.saveEffects(uid!, next);
        if (current()) {
          _value = _value.copy(
            effects: next,
            lobbyAwards: next.gift ? null : [],
            vehicleEffects: next.car ? null : [],
            worldBanners: next.screen ? null : [],
            prize: next.screen ? null : {},
          );
        }
      });

  Future<void> refreshCharmStatus() =>
      _load('charm', () => repository.charmEnabled(roomId), (data) {
        _snapshotVersions.putIfAbsent('charm', () => 0);
        _value = _value.copy(charmEnabled: data as bool);
      });

  Future<bool> toggleCharmCounter() async {
    if (!active || !canManage || charmStatusBusy) return false;
    final generation = _generation;
    if (!charmStatusReady) await refreshCharmStatus();
    if (!active || generation != _generation || !charmStatusReady) return false;
    return setCharmEnabled(!_value.charmEnabled);
  }

  Future<bool> setCharmEnabled(bool enabled) =>
      perform('charm', (current) async {
        if (charmStatusReady && _value.charmEnabled == enabled) return;
        final version = _snapshotVersions['charm'] ?? 0;
        final data = await repository.updateCharmStatus(roomId, enabled);
        if (current() && version == (_snapshotVersions['charm'] ?? 0)) {
          // A completed write supersedes any older in-flight status read.
          _snapshotVersions['charm'] = version + 1;
          _value = _value.copy(charmEnabled: data);
        }
      }, manager: true);

  Future<bool> setCurrency(int value) => perform('currency', (current) async {
    if (value != 1 && value != 2) {
      throw const NadyApiException(message: 'Choose Coins or Diamonds');
    }
    if (_value.currency == value) return;
    final version = _snapshotVersions['currency'] ?? 0;
    await repository.switchCharmCurrency(roomId, value);
    if (current() && version == (_snapshotVersions['currency'] ?? 0)) {
      _snapshotVersions['currency'] = version + 1;
      _value = _value.copy(currency: value);
    }
    if (current()) {
      await _load('micCurrency', () async {
        await room.refreshRoomData();
        return null;
      }, (_) {});
    }
  }, manager: true);

  Future<ToolJson> charmRank(int targetUid) async {
    if (!active) return {};
    final generation = _generation;
    final result = toolMap(
      await repository.get(HttpApi.roomCharmRank, {
        'roomId': roomId,
        'targetUid': targetUid,
      }),
    );
    return active && generation == _generation ? result : {};
  }

  Future<bool> selectMode(int type) => perform('mode', (current) async {
    final version = _snapshotVersions['mode'] ?? 0;
    if (!_value.config.moreModes.contains(type)) {
      throw const NadyApiException(message: 'Room mode is unavailable');
    }
    if (type != 0 && _value.lobbyType == type) {
      _value = _value.copy(lobbyVisible: true);
      await loadLobby();
      return;
    }
    await repository.post(HttpApi.lobbyOpen, {
      'roomId': roomId,
      'status': type == 0 ? 0 : 1,
      'lobbyType': type == 0 ? 1 : type,
    });
    if (!current()) return;
    if (version != (_snapshotVersions['mode'] ?? 0)) {
      if (_value.lobbyType == type && type != 0) {
        _value = _value.copy(lobbyVisible: true);
        await loadLobby();
      }
      return;
    }
    _lobbyInsert?.cancel();
    _value = _value.copy(
      lobbyType: type,
      lobbyVisible: type != 0,
      lobbyRecords: [],
      treasureGifts: [],
      lobbyAwards: [],
    );
    if (type != 0) await loadLobby();
  }, manager: true);

  void foldLobby() {
    if (active) _value = _value.copy(lobbyVisible: false, lobbyAwards: []);
  }

  void restoreLobby() {
    if (active && _value.lobbyType != 0) {
      _value = _value.copy(lobbyVisible: true, lobbyAwards: []);
      unawaited(loadLobby());
    }
  }

  Future<void> loadLobby() async {
    final type = _value.lobbyType;
    if (![1, 2].contains(type)) return;
    await _load(
      'lobby',
      () => repository.get(
        type == 2 ? HttpApi.roomTreasureRecords : HttpApi.roomLobbyRecords,
        {'roomId': roomId},
      ),
      (data) {
        if (type != _value.lobbyType) return;
        final map = toolMap(data);
        _value = _value.copy(
          lobbyRecords: [],
          treasureGifts: toolList(map['giftIocs']),
        );
        _insertLobbyRecords(
          type == 2 ? toolList(map['playTos']) : toolList(data),
          type,
        );
      },
    );
  }

  Future<bool> beginPk(
    List<int> uids,
    int duration, {
    required bool oneOnOne,
  }) => perform('pk', (current) async {
    if (_value.pk.active) {
      throw const NadyApiException(message: 'PK is already active');
    }
    final selected = uids.toSet();
    if (selected.length < 2 ||
        oneOnOne && selected.length != 2 ||
        ![3, 5, 10, 20, 30, 40, 50, 60].contains(duration)) {
      throw const NadyApiException(
        message: 'Choose valid PK participants and duration',
      );
    }
    final seats = room.roomState.micList;
    final participants = <ToolJson>[];
    for (final userId in selected) {
      final mic = seats.where((seat) => seat.uid == userId).firstOrNull;
      if (mic == null) {
        throw const NadyApiException(
          message: 'The microphone seats have changed',
        );
      }
      participants.add({
        'uid': userId,
        'identity': participants.length < 2 ? participants.length + 1 : null,
        'micIndex': mic.position,
      });
    }
    await repository.post(HttpApi.roomPkBegin, {
      'roomId': roomId,
      'duration': duration,
      'pkUserList': participants,
    });
    if (!current()) return;
    await _load(
      'pk',
      () => repository.get(HttpApi.roomPkInfo, {'roomId': roomId}),
      (data) => _applyPk(toolMap(data)),
    );
  }, manager: true);

  Future<bool> endPk() => perform('pk', (current) async {
    await repository.post(HttpApi.roomPkOver, {'roomId': roomId});
    if (!current()) return;
    // The broadcast/snapshot owns the terminal score and result, not the button.
    await _load(
      'pk',
      () => repository.get(HttpApi.roomPkInfo, {'roomId': roomId}),
      (data) => _applyPk(toolMap(data)),
    );
  }, manager: true);
  void showPk(bool show) {
    if (active) _value = _value.copy(pkVisible: show);
  }

  Future<void> refreshBalance() => _load(
    'balance',
    () => repository.get(HttpApi.walletPurse),
    (data) => _value = _value.copy(balance: toolInt(toolMap(data)['coin'])),
  );
  Future<void> refreshBags() => _load(
    'bags',
    () => repository.get(HttpApi.roomLuckyList, {'roomId': roomId}),
    (data) => _value = _value.copy(
      bags: toolList(data)
          .map((json) => RoomLuckyBag.parse(json, DateTime.now()))
          .where((bag) => bag.id.isNotEmpty && !_claimedBags.contains(bag.id))
          .toList(),
    ),
  );
  bool get canSendLucky => canManage || toolBool(_value.luckyConfig['visible']);
  Future<bool> needsLuckyConfirmation() async =>
      uid == null || !await repository.luckyConfirmed(uid!);
  Future<bool> sendLucky({
    required int type,
    required int gold,
    required int recipients,
    required int countdown,
    required bool confirmed,
  }) => perform('luckySend', (current) async {
    if (!canSendLucky || uid == null) {
      throw const NadyApiException(message: 'Lucky Box is unavailable');
    }
    final config = toolMap(_value.luckyConfig[type == 0 ? 'room' : 'world']);
    final amounts = toolList(config['configuration']);
    final amount = amounts
        .where((value) => toolInt(value['goldQuantiry']) == gold)
        .firstOrNull;
    if (![0, 1].contains(type) ||
        amount == null ||
        !(amount['numberOfRecipients'] is List &&
            (amount['numberOfRecipients'] as List)
                .map(toolInt)
                .contains(recipients)) ||
        !(config['countdown'] is List &&
            (config['countdown'] as List).map(toolInt).contains(countdown))) {
      throw const NadyApiException(message: 'Lucky Box configuration changed');
    }
    if (await needsLuckyConfirmation()) {
      if (!current()) return;
      if (!confirmed) {
        throw const NadyApiException(message: 'Confirmation required');
      }
      await repository.confirmLucky(uid!);
    }
    if (!current() || !canSendLucky) return;
    await repository.post(HttpApi.roomLuckyPush, {
      'roomId': roomId,
      'type': type,
      'gold': gold,
      'numberOfRecipients': recipients,
      'countdown': countdown,
    });
    if (!current()) return;
    await refreshBalance();
    await refreshBags();
  });

  Future<ToolJson?> grabLucky(String id) async {
    ToolJson? result;
    final success = await perform('grab:$id', (current) async {
      final bag = _value.bags.where((value) => value.id == id).firstOrNull;
      if (bag == null ||
          bag.remaining(DateTime.now()) > 0 ||
          _claimedBags.contains(id)) {
        throw const NadyApiException(message: 'Lucky Box is not ready');
      }
      final response = await repository.post(HttpApi.roomLuckyGrab, {
        'luckyBagId': bag.raw['id'],
      });
      if (!current()) return;
      if (response == null) {
        throw const NadyApiException(message: 'No Lucky Box result received');
      }
      result = toolMap(response);
      if (!result!.containsKey('count') ||
          int.tryParse('${result!['count']}') == null) {
        throw const NadyApiException(message: 'Invalid Lucky Box result');
      }
      if (current()) {
        _claimedBags.add(id);
        _value = _value.copy(
          bags: _value.bags.where((bag) => bag.id != id).toList(),
        );
      }
      await refreshBalance();
    });
    return success ? result : null;
  }

  Future<void> refreshBigWin() => _load(
    'bigWin',
    () => repository.get(HttpApi.gameBigWinShow),
    (data) => _value = _value.copy(bigWin: toolMap(data)),
  );
  Future<ToolJson> bigWinRank(int round) async {
    final info = toolMap(_value.bigWin['gameBigWinInfoVO']);
    final max = toolInt(info['winRoundCount']);
    if (!active || round < 1 || round > max) return {};
    final generation = _generation;
    final result = toolMap(
      await repository.post(HttpApi.gameBigWinRank, {
        'gameBigWinId': info['gameBigWinId'],
        'round': round,
      }),
    );
    return active && generation == _generation ? result : {};
  }

  void dismissWorld(String key) => _value = _value.copy(
    worldBanners: _value.worldBanners
        .where((item) => item['_key'] != key)
        .toList(),
  );
  void dismissPrize() => _value = _value.copy(prize: {});

  List<ToolJson> get lobbyRecords => _value.lobbyRecords.where((record) {
    final codes = record['countryCodes'];
    if (codes == null || codes == '' || codes is List && codes.isEmpty) {
      return true;
    }
    final values = codes is List
        ? codes.map((value) => '$value')
        : '$codes'.split(',');
    return _countryCode != null &&
        values.any(
          (value) => value.toUpperCase() == _countryCode!.toUpperCase(),
        );
  }).toList();

  void _insertLobbyRecords(List<ToolJson> records, int type) {
    _lobbyInsert?.cancel();
    final generation = _generation;
    if (!visible) {
      _value = _value.copy(lobbyRecords: records.take(90).toList());
      return;
    }
    var index = 0;
    _lobbyInsert = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!active ||
          generation != _generation ||
          type != _value.lobbyType ||
          index >= records.length) {
        timer.cancel();
        return;
      }
      final next = [..._value.lobbyRecords, records[index++]];
      _value = _value.copy(
        lobbyRecords: next.length > 100 ? next.take(90).toList() : next,
      );
    });
  }

  void completeAward(String key) {
    if (active) {
      _value = _value.copy(
        lobbyAwards: _value.lobbyAwards
            .where((award) => award['_key'] != key)
            .toList(),
      );
    }
  }

  void gameOpened(String? gameId) {
    _gameOpened = true;
    _gameId = gameId;
  }

  void gameClosed() {
    _gameOpened = false;
    _gameId = null;
  }

  void deferBag(String id) {
    if (!active) return;
    _value = _value.copy(
      bags: [
        ..._value.bags.where((bag) => bag.id != id),
        ..._value.bags.where((bag) => bag.id == id),
      ],
    );
  }

  void completeVehicle(String key) {
    if (active) {
      _value = _value.copy(
        vehicleEffects: _value.vehicleEffects
            .where((item) => item['_key'] != key)
            .toList(),
      );
    }
  }

  void clearLuckyPublicMessages() {
    if (active) _value = _value.copy(luckyMessages: []);
  }
}
