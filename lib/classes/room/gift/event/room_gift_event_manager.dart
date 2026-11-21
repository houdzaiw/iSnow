import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/room_socket_message.dart';
import '../models/room_gift_event_models.dart';
import '../models/room_gift_models.dart';
import '../effects/room_gift_asset_resolver.dart';
import '../queue/room_gift_slot_queue.dart';
import '../queue/room_fullscreen_queue.dart';
import '../queue/room_flight_queue.dart';
import '../models/room_gift_effect_task.dart';
import '../models/room_gift_panel_models.dart';
import '../models/room_lucky_animation_policy.dart';
import '../models/room_mic_effect.dart';
import '../models/room_entrance.dart';
import '../queue/room_entrance_queue.dart';
import 'room_entrance_parser.dart';
import 'room_gift_event_parser.dart';
import 'room_fullscreen_event_parser.dart';
import '../../more/room_tools_models.dart';

export '../models/room_gift_effect_task.dart';

part 'room_gift_event_dispatch.dart';
part 'room_gift_event_processing.dart';
part 'room_mic_effect_events.dart';
part 'room_entrance_events.dart';

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
    this.stopEffectKey,
    this.stopLuckyKey,
    this.canPlayFullscreen = true,
    this.canPlayLucky = false,
    this.jackpots = const {},
    this.micEffects = const {},
    this.entrance,
  });
  final List<RoomGiftSlot?> slots;
  final List<RoomGiftPublicMessage> publicMessages;
  final List<RoomGiftEffectTask> flights, effects;
  final List<RoomGiftBanner> banners;
  final List<RoomLuckyGiftResult> lucky;
  final int roomWeekVal;
  final bool isVisible;
  final String? stopEffectKey, stopLuckyKey;
  final bool canPlayFullscreen, canPlayLucky;
  final Map<int, RoomJackpotInfo> jackpots;
  final Map<int, RoomMicEffect> micEffects;
  final RoomEntrance? entrance;
}

/// Consumes each broadcast once and exposes independently bounded visual lanes.
class RoomGiftEventManager extends StateNotifier<RoomGiftEventState> {
  RoomGiftEventManager({
    required this.roomId,
    Stream<RoomSocketMessage>? messages,
    DateTime Function()? now,
    this.onSelfGift,
    this.onComboEnd,
    this.activeJackpotGift,
    this.preparePrize,
    this.prepareEntrance,
    this.barrageManaged = false,
    bool startTimer = true,
  }) : _now = now ?? DateTime.now,
       _timersEnabled = startTimer,
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
  final bool barrageManaged;
  bool get isAlive => mounted;
  RoomGiftEventState get snapshot => state;
  final DateTime Function() _now;
  final bool _timersEnabled;
  final void Function(RoomScreenGiftMsg, DateTime)? onSelfGift;
  final void Function(String)? onComboEnd;
  final RoomScreenGiftMsg? Function(int)? activeJackpotGift;
  final Future<void> Function(RoomGiftEffectTask)? preparePrize;
  final Future<void> Function(RoomEntrance)? prepareEntrance;
  final _parser = RoomGiftEventParser();
  final _externalParser = RoomFullscreenEventParser();
  final _slotQueue = RoomGiftSlotQueue();
  final _fullscreenQueue = RoomFullscreenQueue();
  final _flightQueue = RoomFlightQueue();
  final _numberPolicy = RoomLuckyNumberPolicy();
  Map<int, int> _seatOccupants = const {};
  final _micEffects = <int, RoomMicEffect>{};
  final _entrances = RoomEntranceQueue();
  String? _enqueuedEntrance;
  String? _activeLucky;
  String? countryCode;
  final LinkedHashMap<String, DateTime> _seen = LinkedHashMap();
  final LinkedHashMap<String, RoomScreenGiftMsg> _combos = LinkedHashMap();
  final LinkedHashMap<String, DateTime> _ended = LinkedHashMap();
  final LinkedHashMap<String, DateTime> _cancelledFlights = LinkedHashMap();
  StreamSubscription<RoomSocketMessage>? _subscription;
  Timer? _timer;
  Timer? _slotTimer;
  DateTime? _acceptAfter;
  bool _sessionActive = true;
  bool _hostVisible = true, _routeVisible = true;
  int _visualGeneration = 0;
  RoomEffectPreferences _effects = const RoomEffectPreferences();

  void setEffects(RoomEffectPreferences value) {
    _effects = value;
    if (!value.car) _entrances.clear();
    _fullscreenQueue.cancelWhere(
      (task) => task.kind == RoomGiftEffectKind.entrance
          ? !value.car
          : !value.bigGift,
    );
    if (!value.gift) {
      _slotQueue.clear();
      _flightQueue.clear();
      _micEffects.clear();
      _slotTimer?.cancel();
    }
    _emit();
  }

  int? get currentUid => _slotQueue.currentUid;
  set currentUid(int? uid) {
    final changed = uid != currentUid;
    _slotQueue.currentUid = uid;
    _fullscreenQueue.currentUid = uid;
    _flightQueue.currentUid = uid;
    _entrances.currentUid = uid;
    if (changed && mounted) _emit();
  }

  void receive(RoomSocketMessage message) => _dispatch(message);

  /// External visual sources share the same native-player lease as gifts.
  void enqueueFullscreen(RoomGiftEffectTask task) {
    if (!mounted || !_sessionActive || !state.isVisible) return;
    if (_acceptAfter != null && task.createdAt.isBefore(_acceptAfter!)) return;
    if (task.kind == RoomGiftEffectKind.entrance
        ? !_effects.car
        : !_effects.bigGift) {
      return;
    }
    final prepare = task.kind == RoomGiftEffectKind.prize ? preparePrize : null;
    final accepted = _fullscreenQueue.add(task, _now(), ready: prepare == null);
    _emit();
    if (accepted && prepare != null) {
      unawaited(_preparePrize(task, prepare, _visualGeneration));
    }
  }

  Future<void> _preparePrize(
    RoomGiftEffectTask task,
    Future<void> Function(RoomGiftEffectTask) prepare,
    int generation,
  ) async {
    var success = false;
    try {
      await prepare(task);
      success = true;
    } catch (error) {
      _log('Prize resource unavailable: $error');
    }
    if (!mounted || generation != _visualGeneration || !state.isVisible) return;
    _fullscreenQueue.prepared(task.key, _now(), success: success);
    _emit();
  }

  void completeEffect(String key) {
    _fullscreenQueue.complete(key, _now());
    final entrance = _entrances.active;
    if (entrance != null && key == '${entrance.key}:vehicle') {
      _entrances.complete(
        entrance.key,
        _now(),
        vehicle: true,
        track: _entrances.startedAt == null,
      );
    }
    _emit();
  }

  void cancelFullscreen(String key) {
    if (!mounted) return;
    _fullscreenQueue.cancelWhere((task) => task.key == key);
    _emit();
  }

  void completeFlight(String key) {
    _flightQueue.complete(key);
    _emit();
  }

  void cancelComboFlights(String comboId, {int? uid}) {
    if (comboId.isEmpty) return;
    _cancelledFlights['${uid ?? 'any'}:$comboId'] = _now();
    while (_cancelledFlights.length > 300) {
      _cancelledFlights.remove(_cancelledFlights.keys.first);
    }
    _flightQueue.cancelCombo(comboId, uid: uid);
    _emit();
  }

  void completeBanner(String key) =>
      _emit(banners: state.banners.where((item) => item.key != key).toList());
  void completeLucky(String key) {
    if (_activeLucky != key) return;
    _activeLucky = null;
    _emit(lucky: state.lucky.where((item) => item.key != key).toList());
  }

  /// Clear chat history without ending paid combos or stopping their effects.
  void clearPublicMessages() {
    if (!mounted || state.publicMessages.isEmpty) return;
    _emit(publicMessages: const []);
  }

  void setVisible(bool visible) {
    _hostVisible = visible;
    _syncVisible();
  }

  void setRouteVisible(bool visible) {
    _routeVisible = visible;
    _syncVisible();
  }

  void _syncVisible() {
    final visible = _sessionActive && _hostVisible && _routeVisible;
    if (visible == state.isVisible) return;
    reset(visible: visible, resetCombo: false);
  }

  void setSessionActive(bool active) {
    _sessionActive = active;
    if (!active) reset(visible: false, clearHistory: true);
  }

  void reset({
    bool? visible,
    bool clearHistory = false,
    bool resetCombo = true,
  }) {
    _visualGeneration++;
    _slotQueue.clear();
    _fullscreenQueue.clear();
    _flightQueue.clear();
    _micEffects.clear();
    _entrances.clear();
    _enqueuedEntrance = null;
    _activeLucky = null;
    _slotTimer?.cancel();
    if (clearHistory) {
      _seen.clear();
      _combos.clear();
      _ended.clear();
      _cancelledFlights.clear();
      _numberPolicy.clear();
    }
    // Socket timestamps can be second-resolution; accept fresh same-second events.
    final time = _now().millisecondsSinceEpoch;
    _acceptAfter = DateTime.fromMillisecondsSinceEpoch(time ~/ 1000 * 1000);
    if (resetCombo) onComboEnd?.call('');
    state = RoomGiftEventState(
      isVisible: visible ?? state.isVisible,
      roomWeekVal: clearHistory ? 0 : state.roomWeekVal,
      publicMessages: clearHistory ? const [] : state.publicMessages,
      jackpots: clearHistory ? const {} : state.jackpots,
    );
  }

  void expire() {
    if (!mounted) return;
    final now = _now();
    _slotQueue.expire(now);
    _micEffects.removeWhere((_, effect) => !now.isBefore(effect.expiresAt));
    _seen.removeWhere(
      (_, time) => now.difference(time) > const Duration(minutes: 2),
    );
    _ended.removeWhere(
      (_, time) => now.difference(time) > const Duration(seconds: 60),
    );
    _cancelledFlights.removeWhere(
      (_, time) => now.difference(time) > const Duration(minutes: 2),
    );
    _emit(slots: _slotQueue.slots);
  }

  void _emit({
    List<RoomGiftSlot?>? slots,
    List<RoomGiftPublicMessage>? publicMessages,
    List<RoomGiftBanner>? banners,
    List<RoomLuckyGiftResult>? lucky,
    int? roomWeekVal,
    Map<int, RoomJackpotInfo>? jackpots,
  }) {
    if (!mounted) return;
    _syncEntrance();
    final effects = _fullscreenQueue.tasks;
    final hasActiveEffect = _fullscreenQueue.active != null;
    final nextLucky = _effects.gift
        ? List<RoomLuckyGiftResult>.of(lucky ?? state.lucky)
        : <RoomLuckyGiftResult>[];
    if (_activeLucky != null &&
        !nextLucky.any((item) => item.key == _activeLucky)) {
      _activeLucky = null;
    }
    if (_activeLucky == null && !hasActiveEffect && nextLucky.isNotEmpty) {
      final arrival = {
        for (var i = 0; i < nextLucky.length; i++) nextLucky[i].key: i,
      };
      nextLucky.sort((a, b) {
        final bubble = (b.amount > 0 ? 1 : 0).compareTo(a.amount > 0 ? 1 : 0);
        if (bubble != 0) return bubble;
        final multiple = b.multiplier.compareTo(a.multiplier);
        return multiple != 0
            ? multiple
            : arrival[a.key]!.compareTo(arrival[b.key]!);
      });
      _activeLucky = nextLucky.first.key;
    }
    final entrance = _entrances.active;
    if (entrance != null &&
        _entrances.startedAt == null &&
        entrance.vehicle == null) {
      _entrances.start(_now());
    }
    state = RoomGiftEventState(
      slots: _effects.gift ? slots ?? state.slots : const [null, null],
      publicMessages: publicMessages ?? state.publicMessages,
      flights: _effects.gift ? _flightQueue.tasks : const [],
      effects: effects,
      banners: _effects.screen ? banners ?? state.banners : const [],
      lucky: nextLucky,
      roomWeekVal: roomWeekVal ?? state.roomWeekVal,
      isVisible: state.isVisible,
      stopEffectKey: _fullscreenQueue.stopRequestedKey,
      stopLuckyKey: hasActiveEffect ? _activeLucky : null,
      canPlayFullscreen: hasActiveEffect && _activeLucky == null,
      canPlayLucky: _activeLucky != null,
      jackpots: jackpots ?? state.jackpots,
      micEffects: Map.unmodifiable(_micEffects),
      entrance: _entrances.startedAt == null ? null : _entrances.active,
    );
    if (slots != null) _scheduleSlotExpiry();
  }

  void _scheduleSlotExpiry() {
    _slotTimer?.cancel();
    if (!_timersEnabled) return;
    final deadlines =
        _slotQueue.slots
            .whereType<RoomGiftSlot>()
            .map((slot) => slot.expiresAt)
            .toList()
          ..sort();
    if (deadlines.isEmpty) return;
    final delay = deadlines.first.difference(_now());
    _slotTimer = Timer(delay.isNegative ? Duration.zero : delay, expire);
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
    _slotTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
