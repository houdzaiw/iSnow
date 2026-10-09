import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/room_socket_message.dart';
import '../models/room_gift_event_models.dart';
import '../models/room_gift_models.dart';
import '../effects/room_gift_asset_resolver.dart';
import '../queue/room_gift_slot_queue.dart';
import 'room_gift_event_parser.dart';

class RoomGiftEffectTask {
  const RoomGiftEffectTask({
    required this.key,
    required this.message,
    required this.createdAt,
  });
  final String key;
  final RoomScreenGiftMsg message;
  final DateTime createdAt;
}

class RoomGiftEventState {
  const RoomGiftEventState({
    this.slots = const [null, null],
    this.publicMessages = const [],
    this.flights = const [],
    this.banners = const [],
    this.effects = const [],
    this.lucky = const [],
    this.roomWeekVal = 0,
    this.isVisible = true,
  });
  final List<RoomGiftSlot?> slots;
  final List<RoomGiftPublicMessage> publicMessages;
  final List<RoomGiftEffectTask> flights, effects;
  final List<RoomGiftBanner> banners;
  final List<RoomLuckyGiftResult> lucky;
  final int roomWeekVal;
  final bool isVisible;
}

/// Consumes each broadcast once and exposes independently bounded visual lanes.
class RoomGiftEventManager extends StateNotifier<RoomGiftEventState> {
  RoomGiftEventManager({
    required this.roomId,
    Stream<RoomSocketMessage>? messages,
    DateTime Function()? now,
    this.onSelfGift,
    this.onComboEnd,
    bool startTimer = true,
  }) : _now = now ?? DateTime.now,
       super(const RoomGiftEventState()) {
    _subscription = messages?.listen(
      receive,
      onError: (Object error) => _log('$error'),
    );
    if (startTimer) {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => expire());
    }
  }
  final String roomId;
  bool get isAlive => mounted;
  RoomGiftEventState get snapshot => state;
  final DateTime Function() _now;
  final void Function(RoomScreenGiftMsg, DateTime)? onSelfGift;
  final void Function(String)? onComboEnd;
  final _parser = RoomGiftEventParser();
  final _slotQueue = RoomGiftSlotQueue();
  final LinkedHashMap<String, DateTime> _seen = LinkedHashMap();
  final LinkedHashMap<String, RoomScreenGiftMsg> _combos = LinkedHashMap();
  final LinkedHashMap<String, DateTime> _ended = LinkedHashMap();
  StreamSubscription<RoomSocketMessage>? _subscription;
  Timer? _timer;
  DateTime? _acceptAfter;
  int? get currentUid => _slotQueue.currentUid;
  set currentUid(int? uid) => _slotQueue.currentUid = uid;

  void receive(RoomSocketMessage message) {
    if (!mounted || !RoomGiftEventParser.events.contains(message.event)) return;
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
      if (!state.isVisible ||
          (_acceptAfter != null && event.createdAt.isBefore(_acceptAfter!)) ||
          now.difference(event.createdAt) > const Duration(seconds: 10)) {
        _log(
          'drop event=${message.event} msgId=${message.msgId} '
          'visible=${state.isVisible} ageMs=${now.difference(event.createdAt).inMilliseconds} '
          'acceptAfter=${_acceptAfter?.millisecondsSinceEpoch}',
        );
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
        case RoomGiftEventKind.banner:
          _emit(
            banners: _merge(
              state.banners,
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
            _emit(
              lucky: _merge(state.lucky, event.lucky!, (item) => item.key, 8),
            );
            if (event.lucky!.isJackpot) {
              _queueSpecialEffect(
                event,
                RoomGiftAssetResolver.luckyAnimation(event.lucky!),
                event.lucky!.sender,
              );
            }
          }
        case RoomGiftEventKind.stream:
          break;
      }
    } catch (error) {
      _log('Discard ${message.event}: $error');
    }
  }

  void _receiveGift(RoomGiftEvent event) {
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
    _slotQueue.add(gift, event.key, now);
    if (gift.uid == currentUid) onSelfGift?.call(gift, event.createdAt);
    final public = RoomGiftPublicMessage(
      key: gift.comboId.isEmpty ? key : gift.comboId,
      gift: gift.gift,
      sender: gift.userInfo,
      count: gift.displayCount,
      targetLabel: gift.targetLabel,
      createdAt: event.createdAt,
    );
    final delta = gift.displayCount - (previous?.displayCount ?? 0);
    final coinDelta = gift.totalCoinCount - (previous?.totalCoinCount ?? 0);
    final task = RoomGiftEffectTask(
      key: event.key,
      message: gift,
      createdAt: now,
    );
    final lucky =
        gift.isLuckyGift &&
            !gift.isHideLuckyGift &&
            (delta > 0 || coinDelta > 0)
        ? RoomLuckyGiftResult(
            key: key,
            sender: gift.userInfo,
            amount: coinDelta.clamp(0, gift.totalCoinCount),
            giftCount: delta.clamp(0, gift.displayCount),
            showCoins: gift.playWinGoldCount,
            isJackpot: gift.isJackpot,
          )
        : null;
    final pendingEffectIndex = gift.comboId.isEmpty
        ? -1
        : state.effects.indexWhere(
            (item) => item.message.comboKey == gift.comboKey,
          );
    final effects = [...state.effects];
    if (pendingEffectIndex > 0) {
      final existing = effects[pendingEffectIndex];
      effects[pendingEffectIndex] = RoomGiftEffectTask(
        key: existing.key,
        message: gift,
        createdAt: existing.createdAt,
      );
    }
    _emit(
      slots: _slotQueue.slots,
      publicMessages: _merge(
        state.publicMessages,
        public,
        (item) => item.key,
        80,
      ),
      flights: delta > 0 ? [...state.flights, task].takeLast(32) : null,
      effects:
          previous == null &&
              !(gift.isLuckyGift && gift.isHideLuckyGift) &&
              (gift.gift.animationUrl?.isNotEmpty == true ||
                  gift.sendType == 3 ||
                  gift.sendType == 4)
          ? _merge(effects, task, _effectKey, 12)
          : effects,
      lucky: lucky == null
          ? null
          : _merge(state.lucky, lucky, (item) => item.key, 8),
    );
    if (lucky?.isJackpot == true) {
      _queueSpecialEffect(
        event,
        RoomGiftAssetResolver.luckyAnimation(lucky!),
        lucky.sender,
      );
    }
  }

  void _queueSpecialEffect(
    RoomGiftEvent event,
    RoomGift gift,
    RoomGiftUser sender,
  ) {
    final task = RoomGiftEffectTask(
      key: 'special-${event.key}',
      createdAt: _now(),
      message: RoomScreenGiftMsg(
        gift: gift,
        uid: sender.uid,
        userInfo: sender,
        comboId: event.comboId,
        roomId: roomId,
        giftCount: 1,
      ),
    );
    _emit(effects: _merge(state.effects, task, _effectKey, 12));
  }

  String _effectKey(RoomGiftEffectTask task) =>
      task.message.comboId.isEmpty ? task.key : task.message.comboKey;

  void _finishCombo(RoomGiftEvent event) {
    _ended[event.comboId] = _now();
    while (_ended.length > 300) {
      _ended.remove(_ended.keys.first);
    }
    onComboEnd?.call(event.comboId);
    final finalMessage = event.publicMessage!;
    final old = state.publicMessages
        .where((item) => item.key == event.comboId)
        .firstOrNull;
    final merged = RoomGiftPublicMessage(
      key: finalMessage.key,
      gift: finalMessage.gift,
      count: finalMessage.count,
      targetLabel: old?.targetLabel ?? finalMessage.targetLabel,
      createdAt: finalMessage.createdAt,
      sender: old?.sender ?? finalMessage.sender,
      isFinal: true,
      winAmount: finalMessage.winAmount,
    );
    _emit(
      publicMessages: _merge(
        state.publicMessages,
        merged,
        (item) => item.key,
        80,
      ),
      lucky: state.lucky
          .where(
            (item) =>
                item.key != event.comboId &&
                !item.key.endsWith(':${event.comboId}'),
          )
          .toList(),
    );
  }

  void completeEffect(String key) =>
      _emit(effects: state.effects.where((item) => item.key != key).toList());
  void completeFlight(String key) =>
      _emit(flights: state.flights.where((item) => item.key != key).toList());
  void completeBanner(String key) =>
      _emit(banners: state.banners.where((item) => item.key != key).toList());
  void completeLucky(String key) =>
      _emit(lucky: state.lucky.where((item) => item.key != key).toList());

  void setVisible(bool visible) {
    if (visible == state.isVisible) return;
    reset(visible: visible);
  }

  void reset({bool? visible, bool clearHistory = false}) {
    _slotQueue.clear();
    // Socket timestamps can be second-resolution; accept fresh same-second events.
    final time = _now().millisecondsSinceEpoch;
    _acceptAfter = DateTime.fromMillisecondsSinceEpoch(time ~/ 1000 * 1000);
    onComboEnd?.call('');
    state = RoomGiftEventState(
      isVisible: visible ?? state.isVisible,
      roomWeekVal: clearHistory ? 0 : state.roomWeekVal,
      publicMessages: clearHistory ? const [] : state.publicMessages,
    );
  }

  void expire() {
    if (!mounted) return;
    final now = _now();
    _slotQueue.expire(now);
    _seen.removeWhere(
      (_, time) => now.difference(time) > const Duration(minutes: 2),
    );
    _ended.removeWhere(
      (_, time) => now.difference(time) > const Duration(seconds: 60),
    );
    _emit(
      slots: _slotQueue.slots,
      flights: state.flights
          .where(
            (task) =>
                now.difference(task.createdAt) < const Duration(seconds: 2),
          )
          .toList(),
    );
  }

  void _emit({
    List<RoomGiftSlot?>? slots,
    List<RoomGiftPublicMessage>? publicMessages,
    List<RoomGiftEffectTask>? flights,
    List<RoomGiftEffectTask>? effects,
    List<RoomGiftBanner>? banners,
    List<RoomLuckyGiftResult>? lucky,
    int? roomWeekVal,
  }) {
    if (!mounted) return;
    state = RoomGiftEventState(
      slots: slots ?? state.slots,
      publicMessages: publicMessages ?? state.publicMessages,
      flights: flights ?? state.flights,
      effects: effects ?? state.effects,
      banners: banners ?? state.banners,
      lucky: lucky ?? state.lucky,
      roomWeekVal: roomWeekVal ?? state.roomWeekVal,
      isVisible: state.isVisible,
    );
  }

  List<T> _merge<T>(List<T> queue, T value, String Function(T) key, int limit) {
    final next = [...queue];
    final index = next.indexWhere((item) => key(item) == key(value));
    if (index >= 0) {
      next[index] = value;
    } else {
      next.add(value);
    }
    // Keep the active head; discard the oldest waiting task when full.
    if (next.length > limit) next.removeAt(limit == 80 ? 0 : 1);
    return List.unmodifiable(next);
  }

  void _log(String message) => debugPrint('[RoomGift][$roomId] $message');

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

extension<T> on List<T> {
  List<T> takeLast(int count) =>
      length > count ? sublist(length - count) : this;
}
