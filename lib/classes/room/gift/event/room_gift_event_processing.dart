part of 'room_gift_event_manager.dart';

extension RoomGiftEventProcessing on RoomGiftEventManager {
  void _receiveGift(RoomGiftEvent event, {bool render = true}) {
    final gift = event.gift!;
    if (gift.comboId.isNotEmpty && _ended.containsKey(gift.comboId)) return;
    final key = gift.comboId.isEmpty ? event.key : gift.comboKey;
    final previous = _combos[key];
    if (previous != null &&
        gift.comboCount <= previous.comboCount &&
        gift.displayCount <= previous.displayCount &&
        gift.totalCoinCount <= previous.totalCoinCount) {
      return;
    }
    _combos[key] = gift;
    while (_combos.length > 300) {
      _combos.remove(_combos.keys.first);
    }
    final now = _now();
    final numberLevel = gift.isLuckyGift
        ? _numberPolicy.advance(key, gift.totalGiftCount)
        : null;
    if (render && _effects.gift) _slotQueue.add(gift, event.key, now);
    if (render && _effects.gift && gift.gift.giftType == 2) {
      for (final uid in gift.targetUids) {
        _replaceMicEffect(uid, gift.gift, 'magic:${event.key}:$uid');
      }
    }
    if (gift.uid == currentUid) onSelfGift?.call(gift, event.createdAt);
    final public = RoomGiftPublicMessage(
      key: gift.comboId.isEmpty ? key : gift.comboId,
      gift: gift.gift,
      sender: gift.userInfo,
      count: gift.displayCount,
      targetLabel: gift.targetLabel,
      createdAt: event.createdAt,
      sendType: gift.sendType,
    );
    if (!render) {
      _emit(
        publicMessages: _merge(
          snapshot.publicMessages,
          public,
          (item) => item.key,
          80,
        ),
      );
      return;
    }
    final delta = gift.displayCount - (previous?.displayCount ?? 0);
    final coinDelta = gift.totalCoinCount - (previous?.totalCoinCount ?? 0);
    final task = RoomGiftEffectTask(
      key: event.key,
      message: gift,
      createdAt: now,
    );
    // Counts come from cumulative gift events. Win bubbles come only from the
    // dedicated multiplier events; fanning coin deltas into both duplicates wins.
    final lucky =
        gift.isLuckyGift && !gift.isHideLuckyGift && numberLevel != null
        ? RoomLuckyGiftResult(
            key: '$key:number:$numberLevel',
            comboId: gift.comboId,
            sender: gift.userInfo,
            amount: 0,
            giftCount: gift.totalGiftCount,
            numberLevel: numberLevel,
            showCoins: false,
          )
        : null;
    if (_effects.bigGift &&
        (previous == null ||
            _fullscreenQueue.tasks.any(
              (item) => item.identity == task.identity,
            )) &&
        gift.gift.giftType != 2 &&
        !(gift.isLuckyGift && gift.isHideLuckyGift) &&
        gift.gift.animationUrl?.isNotEmpty == true) {
      _fullscreenQueue.add(task, now);
    }
    if (_effects.gift &&
        !_cancelledFlights.containsKey('${gift.uid}:${gift.comboId}') &&
        !_cancelledFlights.containsKey('any:${gift.comboId}') &&
        (delta > 0 || gift.comboCount > (previous?.comboCount ?? 0))) {
      _flightQueue.add(task);
    }
    _emit(
      slots: _slotQueue.slots,
      publicMessages:
          snapshot.publicMessages.any(
            (item) => item.key == public.key && item.isFinal,
          )
          ? null
          : _merge(snapshot.publicMessages, public, (item) => item.key, 80),
      lucky: lucky == null
          ? null
          : _merge(snapshot.lucky, lucky, (item) => item.key, 8),
    );
    if (gift.isJackpot && (delta > 0 || coinDelta > 0)) {
      final jackpot = RoomLuckyGiftResult(
        key: event.key,
        sender: gift.userInfo,
        amount: coinDelta.clamp(0, gift.totalCoinCount),
        isJackpot: true,
      );
      _queueSpecialEffect(
        event,
        RoomGiftAssetResolver.luckyAnimation(jackpot),
        gift.userInfo,
        prize: true,
      );
    }
  }

  void _receivePublic(RoomGiftPublicMessage message) {
    // Nady's SendGiftMsgModel does not require comboId. Reconcile its public
    // message with the provisional animation entry rather than showing both.
    final previous = snapshot.publicMessages
        .where(
          (item) =>
              item.key == message.key ||
              !item.isFinal &&
                  message.sender.uid > 0 &&
                  item.sender.uid == message.sender.uid &&
                  item.gift.id == message.gift.id &&
                  item.sendType == message.sendType,
        )
        .lastOrNull;
    final merged = RoomGiftPublicMessage(
      key: previous?.key ?? message.key,
      gift: message.gift,
      count: message.count,
      targetLabel: message.targetLabel.isEmpty
          ? previous?.targetLabel ?? ''
          : message.targetLabel,
      createdAt: message.createdAt,
      sender: message.sender.uid > 0
          ? message.sender
          : previous?.sender ?? message.sender,
      sendType: message.sendType,
      isFinal: true,
      winAmount: message.winAmount,
      multiplier: message.multiplier,
    );
    _emit(
      publicMessages: _merge(
        snapshot.publicMessages,
        merged,
        (item) => item.key,
        80,
      ),
    );
  }

  void _queueSpecialEffect(
    RoomGiftEvent event,
    RoomGift gift,
    RoomGiftUser sender, {
    bool prize = false,
  }) {
    final task = RoomGiftEffectTask(
      key: 'special-${event.key}',
      kind: prize ? RoomGiftEffectKind.prize : RoomGiftEffectKind.gift,
      createdAt: _now(),
      giftIcon: event.gift?.gift.icon ?? event.banner?.gift.icon,
      message: RoomScreenGiftMsg(
        gift: gift,
        uid: sender.uid,
        userInfo: sender,
        comboId: event.comboId,
        roomId: roomId,
        giftCount: 1,
      ),
    );
    enqueueFullscreen(task);
  }

  void _finishCombo(RoomGiftEvent event) {
    _flightQueue.cancelCombo(event.comboId);
    _ended[event.comboId] = _now();
    while (_ended.length > 300) {
      _ended.remove(_ended.keys.first);
    }
    onComboEnd?.call(event.comboId);
    final finalMessage = event.publicMessage!;
    final old = snapshot.publicMessages
        .where((item) => item.key == event.comboId)
        .firstOrNull;
    final merged = RoomGiftPublicMessage(
      key: finalMessage.key,
      gift: finalMessage.gift,
      count: finalMessage.count,
      targetLabel: finalMessage.targetLabel.isEmpty
          ? old?.targetLabel ?? ''
          : finalMessage.targetLabel,
      createdAt: finalMessage.createdAt,
      sender: finalMessage.sender.uid > 0
          ? finalMessage.sender
          : old?.sender ?? finalMessage.sender,
      sendType: finalMessage.sendType,
      isFinal: true,
      winAmount: finalMessage.winAmount,
      multiplier: finalMessage.multiplier,
    );
    _emit(
      publicMessages: old == null
          ? null
          : _merge(snapshot.publicMessages, merged, (item) => item.key, 80),
      lucky: snapshot.lucky
          .where(
            (item) =>
                item.numberLevel > 0 ||
                item.comboId != event.comboId ||
                item.key == _activeLucky,
          )
          .toList(),
    );
  }
}
