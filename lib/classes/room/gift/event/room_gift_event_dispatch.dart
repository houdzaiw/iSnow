part of 'room_gift_event_manager.dart';

extension RoomGiftEventDispatch on RoomGiftEventManager {
  void _dispatch(RoomSocketMessage message) {
    if (!isAlive || !_sessionActive) return;
    if (message.event == 'RoomUserPropInfoEvent') {
      _receiveEntrance(message);
      return;
    }
    if (message.event == 'RoomScreenExpressionEvent') {
      _receiveMicExpression(message);
      return;
    }
    if (message.event == 'RoomScreenSystemClear') {
      if (message.channel == 'room:$roomId' || message.channel == 'room') {
        clearPublicMessages();
      }
      return;
    }
    if (RoomFullscreenEventParser.events.contains(message.event)) {
      if (barrageManaged) return;
      if (!snapshot.isVisible) return;
      try {
        for (final task in _externalParser.parse(
          message,
          roomId,
          _now(),
          countryCode: countryCode,
        )) {
          if (_seen.containsKey(task.key)) continue;
          _seen[task.key] = _now();
          while (_seen.length > 300) {
            _seen.remove(_seen.keys.first);
          }
          enqueueFullscreen(task);
        }
      } catch (error) {
        _log('Discard ${message.event}: $error');
      }
      return;
    }
    if (!RoomGiftEventParser.events.contains(message.event)) return;
    try {
      final now = _now();
      final event = _parser.parse(message, roomId, now);
      if (event == null || _seen.containsKey(event.key)) {
        _log(
          'drop event=${message.event} msgId=${message.msgId} '
          'reason=${event == null ? 'channel' : 'duplicate'}',
        );
        return;
      }
      _seen[event.key] = now;
      while (_seen.length > 300) {
        _seen.remove(_seen.keys.first);
      }
      if (event.kind == RoomGiftEventKind.stream) {
        _emit(roomWeekVal: event.roomWeekVal);
        return;
      }
      if (event.kind == RoomGiftEventKind.jackpot) {
        _emit(jackpots: {...snapshot.jackpots, event.giftId!: event.jackpot!});
        final gift = activeJackpotGift?.call(event.giftId!);
        if (!barrageManaged &&
            snapshot.isVisible &&
            event.jackpot!.isSuper &&
            gift != null &&
            now.difference(event.createdAt) <= const Duration(seconds: 10) &&
            (_acceptAfter == null ||
                !event.createdAt.isBefore(_acceptAfter!))) {
          enqueueFullscreen(
            RoomGiftEffectTask(
              key: 'jackpot-${event.key}',
              createdAt: now,
              kind: RoomGiftEffectKind.prize,
              giftIcon: gift.gift.icon,
              message: RoomScreenGiftMsg(
                uid: gift.uid,
                userInfo: gift.userInfo,
                roomId: roomId,
                giftCount: 1,
                gift: RoomGiftAssetResolver.luckyAnimation(
                  RoomLuckyGiftResult(
                    key: event.key,
                    sender: gift.userInfo,
                    amount: event.jackpot!.displayAmount,
                    isJackpot: true,
                  ),
                ),
              ),
            ),
          );
        }
        return;
      }
      if ((_acceptAfter != null && event.createdAt.isBefore(_acceptAfter!)) ||
          now.difference(event.createdAt) > const Duration(seconds: 10)) {
        _log(
          'drop event=${message.event} msgId=${message.msgId} '
          'visible=${snapshot.isVisible} ageMs=${now.difference(event.createdAt).inMilliseconds} '
          'acceptAfter=${_acceptAfter?.millisecondsSinceEpoch}',
        );
        return;
      }
      if (!snapshot.isVisible) {
        // Keep/background preserve acknowledgements and chat, never animations.
        switch (event.kind) {
          case RoomGiftEventKind.gift:
            _receiveGift(event, render: false);
          case RoomGiftEventKind.finalCombo:
            _finishCombo(event);
          case RoomGiftEventKind.publicScreen:
            _receivePublic(event.publicMessage!);
          default:
            break;
        }
        return;
      }
      _log(
        'accept event=${message.event} msgId=${message.msgId} comboId=${event.comboId}',
      );
      switch (event.kind) {
        case RoomGiftEventKind.gift:
          _receiveGift(event);
        case RoomGiftEventKind.finalCombo:
          _finishCombo(event);
        case RoomGiftEventKind.publicScreen:
          _receivePublic(event.publicMessage!);
        case RoomGiftEventKind.banner:
          if (barrageManaged) break;
          _emit(
            banners: _merge(
              snapshot.banners,
              event.banner!,
              (item) => item.key,
              12,
            ),
          );
          final upper = event.banner!.upperEffect;
          if (upper.isNotEmpty) {
            _queueSpecialEffect(
              event,
              event.banner!.gift.copyWith(animationUrl: upper),
              event.banner!.sender,
            );
          }
        case RoomGiftEventKind.lucky:
          if (!_ended.containsKey(event.comboId)) {
            if (event.lucky!.isJackpot) {
              _queueSpecialEffect(
                event,
                RoomGiftAssetResolver.luckyAnimation(event.lucky!),
                event.lucky!.sender,
                prize: true,
              );
            } else if (event.lucky!.amount > 0) {
              _emit(
                lucky: _merge(
                  snapshot.lucky,
                  event.lucky!,
                  (item) => item.key,
                  8,
                ),
              );
            }
          }
        case RoomGiftEventKind.stream:
        case RoomGiftEventKind.jackpot:
          break;
      }
    } catch (error) {
      _log('Discard ${message.event}: $error');
    }
  }
}
