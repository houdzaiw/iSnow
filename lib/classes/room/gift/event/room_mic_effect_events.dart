part of 'room_gift_event_manager.dart';

extension RoomMicEffectEvents on RoomGiftEventManager {
  /// Moving to another seat also clears the old visual, even for the same UID.
  void syncMicOccupants(Map<int, int> occupants) {
    _seatOccupants = Map.unmodifiable(occupants);
    final before = _micEffects.length;
    _micEffects.removeWhere(
      (_, effect) => occupants[effect.position] != effect.uid,
    );
    if (before != _micEffects.length) _emit();
  }

  void completeMicEffect(int position, String key) {
    if (!mounted || _micEffects[position]?.key != key) return;
    _micEffects.remove(position);
    _emit();
  }

  void _replaceMicEffect(int uid, RoomGift gift, String key) {
    final position = _seatOccupants.entries
        .where((e) => e.value == uid)
        .firstOrNull
        ?.key;
    if (position == null || gift.animationUrl?.isNotEmpty != true) return;
    _micEffects[position] = RoomMicEffect(
      key: key,
      uid: uid,
      position: position,
      gift: gift,
      expiresAt: _now().add(const Duration(seconds: 8)),
    );
  }

  void _receiveMicExpression(RoomSocketMessage message) {
    if (!snapshot.isVisible ||
        !_effects.gift ||
        !['room:$roomId', 'room'].contains(message.channel)) {
      return;
    }
    try {
      final data = _parser.decodePayload(message.payload);
      if (data['roomId'] != null && '${data['roomId']}' != roomId) return;
      if (message.channel == 'room' && '${data['roomId']}' != roomId) return;
      final timestamp = message.timestamp;
      final time =
          message.receivedAt ??
          (timestamp == null
              ? _now()
              : DateTime.fromMillisecondsSinceEpoch(
                  timestamp < 1000000000000 ? timestamp * 1000 : timestamp,
                ));
      if (_now().difference(time) > const Duration(seconds: 10)) return;
      final key = 'mic-expression:${message.msgId ?? data.toString()}';
      if (_seen.containsKey(key)) return;
      final face = _parser.decodePayload(data['msg']);
      final source = '${face['dynamicPic'] ?? ''}';
      final uri = Uri.tryParse(source);
      if (uri == null || !['http', 'https'].contains(uri.scheme)) return;
      final user = giftMap(data['from']);
      final uid = giftInt(user['uid']);
      if (uid <= 0) return;
      _seen[key] = _now();
      while (_seen.length > 300) {
        _seen.remove(_seen.keys.first);
      }
      _replaceMicEffect(
        uid,
        RoomGift(
          id: -1,
          name: '',
          icon: source,
          price: 0,
          isCombo: 0,
          tabId: 0,
          animationUrl: source,
        ),
        key,
      );
      _emit();
    } catch (error) {
      _log('Discard mic expression: $error');
    }
  }
}
