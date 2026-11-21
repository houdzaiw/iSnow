import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/room_manager.dart';
import '../../../manager/api_error_message.dart';
import '../../../model/room_socket_message.dart';
import '../gift/models/room_gift_effect_task.dart';
import '../gift/models/room_gift_event_models.dart';
import '../more/room_tools_models.dart';
import 'room_barrage_models.dart';
import 'room_barrage_parser.dart';
import 'room_barrage_queue.dart';
import 'room_barrage_repository.dart';

part 'room_barrage_actions.dart';

abstract interface class RoomBarrageNavigator {
  Future<bool> enterRoom(String id, bool Function() valid);
  void cancelPending();
  Future<void> profile(int uid, bool Function() valid);
  Future<void> gift(String roomId, int giftId, bool Function() valid);
  Future<void> game(String roomId, Uri url, bool Function() valid);
  Future<void> prize(RoomBarragePrize prize, bool Function() valid);
  Future<void> web(Uri url, bool Function() valid);
}

class RoomBarrageState {
  const RoomBarrageState({
    this.active,
    this.uid,
    this.actionBusy = false,
    this.visible = true,
    this.revision = 0,
    this.epoch = 0,
    this.issue,
  });
  final RoomBarragePrepared? active;
  final int? uid;
  final bool actionBusy, visible;
  final int revision, epoch;
  final String? issue;
}

class RoomBarrageViewModel extends StateNotifier<RoomBarrageState> {
  RoomBarrageViewModel(
    this.repository, {
    this.onPresentedEffect,
    this.activeJackpotGift,
    DateTime Function()? now,
    bool startTimer = true,
  }) : _now = now ?? DateTime.now,
       _queue = RoomBarrageQueue(valueOf: repository.giftValue),
       super(const RoomBarrageState()) {
    if (startTimer) {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => expire());
    }
  }
  final RoomBarrageRepository repository;
  final void Function(RoomGiftEffectTask)? onPresentedEffect;
  final RoomScreenGiftMsg? Function(int)? activeJackpotGift;
  final DateTime Function() _now;
  final RoomBarrageQueue _queue;
  final _parser = RoomBarrageParser();
  final _seen = <String, DateTime>{};
  final _prepared = <String, RoomBarragePrepared>{};
  StreamSubscription<RoomSocketMessage>? _subscription;
  Timer? _timer, _retry;
  int _authRevision = 0, _epoch = 0, _actionRevision = 0;
  int? _uid, _roomAccountUid;
  String? _country, _presented;
  DateTime? _acceptAfter;
  String? _roomId, _expectedRoom;
  int _roomGeneration = -1;
  bool _visible = true, _actionBusy = false, _started = false;
  bool _nativeBlocked = false, _acceptMessages = false;
  RoomEffectPreferences _effects = const RoomEffectPreferences();
  RoomFunctionConfig? _functions;
  String? _issue;
  RoomBarrageNavigator? _activeNavigator;
  RoomBarrageState get snapshot => state;

  void start() {
    if (_started) return;
    _started = true;
    repository.addRoomListener(syncRoom);
    repository.addAuthListener(_authChanged);
    _subscription = repository.messages.listen(
      receive,
      onError: (Object error) {
        debugPrint('[RoomBarrage] Stream failed: $error');
      },
    );
    syncRoom();
    unawaited(_loadIdentity());
  }

  void _authChanged() => unawaited(_loadIdentity(reauthenticate: true));
  Future<void> _loadIdentity({bool reauthenticate = false}) async {
    _retry?.cancel();
    _retry = null;
    final revision = ++_authRevision;
    // Revoke old account actions immediately, before persistent reads complete.
    _uid = null;
    _acceptMessages = false;
    _clear(clearSeen: true);
    _emit();
    try {
      final identity = await repository.identity();
      if (!mounted || revision != _authRevision) return;
      if (_roomAccountUid != null &&
          (reauthenticate || _roomAccountUid != identity.uid)) {
        await repository.endPreviousRoom();
        if (!mounted || revision != _authRevision) return;
      }
      _roomAccountUid = identity.uid;
      _uid = identity.uid;
      _country = identity.country;
      _effects = identity.effects;
      _queue.currentUid = _uid;
      _emit();
      await repository.bindAccount(_uid, reauthenticate: reauthenticate);
      if (!mounted || revision != _authRevision) return;
      _acceptMessages = _uid != null;
      _acceptAfter = _now();
      _emit();
    } catch (error) {
      if (!mounted || revision != _authRevision) return;
      debugPrint('[RoomBarrage] Account subscription unavailable: $error');
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 30), () {
        if (mounted && _visible) unawaited(_loadIdentity());
      });
    }
  }

  /// Also used by tests with injected identity/transport, without logging in.
  void bindIdentity(
    int? uid, {
    String? country,
    RoomEffectPreferences? effects,
  }) {
    _authRevision++;
    _acceptMessages = uid != null;
    _uid = uid;
    _country = country;
    _effects = effects ?? const RoomEffectPreferences();
    _queue.currentUid = uid;
    _clear(clearSeen: true);
    _emit();
  }

  void syncRoom() {
    if (!mounted) return;
    final room = repository.roomState;
    final id = room.isInRoom ? room.currentRoomId : null;
    if (_roomId == id && _roomGeneration == repository.roomGeneration) return;
    final expected =
        _expectedRoom != null &&
        ({RoomStatus.leaving, RoomStatus.idle}.contains(room.status) ||
            room.currentRoomId == _expectedRoom &&
                {RoomStatus.entering, RoomStatus.ready}.contains(room.status));
    _roomId = id;
    _roomGeneration = repository.roomGeneration;
    _functions = null;
    _clear(revokeAction: !expected);
    _emit();
  }

  void updateSettings(
    RoomEffectPreferences effects, {
    RoomFunctionConfig? functions,
  }) {
    if (!_effects.screen && effects.screen) _acceptAfter = _now();
    _effects = effects;
    _functions = functions;
    if (!effects.screen) _clear();
    _emit();
  }

  void setVisible(bool visible) {
    if (_visible == visible || !mounted) return;
    _visible = visible;
    _acceptAfter = _now();
    if (!visible) {
      _clear();
    } else if (_started) {
      unawaited(_loadIdentity());
    }
    _emit();
  }

  void receive(RoomSocketMessage message) {
    if (!mounted ||
        _uid == null ||
        !_acceptMessages ||
        !_visible ||
        !_effects.screen ||
        _nativeBlocked) {
      return;
    }
    try {
      final task = _parser.parse(
        message,
        now: _now(),
        uid: _uid!,
        currentRoomId: _roomId,
        countryCode: _country,
        activeJackpotGift: activeJackpotGift,
      );
      if (task == null ||
          _seen.containsKey(task.key) ||
          _acceptAfter != null && task.createdAt.isBefore(_acceptAfter!)) {
        return;
      }
      if (!_eligible(task)) return;
      _seen[task.key] = _now();
      while (_seen.length > 300) {
        _seen.remove(_seen.keys.first);
      }
      if (_queue.add(task, _now())) unawaited(_prepare(task, _epoch));
      _emit();
    } catch (error) {
      debugPrint('[RoomBarrage] Discard ${message.event}: $error');
    }
  }

  bool _eligible(RoomBarrageTask task) {
    if (task.functionPosition != null &&
        _functions != null &&
        !_functions!.enabled(8, task.functionPosition!)) {
      return false;
    }
    if (task.kind != RoomBarrageKind.jackpot) return true;
    final active = activeJackpotGift?.call(task.giftId);
    return active != null &&
        active.gift.id == task.giftId &&
        (task.comboId.isEmpty || active.comboId == task.comboId);
  }

  Future<void> _prepare(RoomBarrageTask task, int epoch) async {
    try {
      final prepared = await repository.prepare(task);
      if (!mounted ||
          epoch != _epoch ||
          !_queue.tasks.any((t) => t.key == task.key)) {
        return;
      }
      if (!_eligible(task)) {
        _queue.prepared(task.key, _now(), success: false);
      } else {
        _prepared[task.key] = prepared;
        _queue.prepared(task.key, _now(), success: true);
      }
    } catch (error) {
      if (!mounted || epoch != _epoch) return;
      debugPrint('[RoomBarrage] Artwork unavailable: $error');
      _queue.prepared(task.key, _now(), success: false);
    }
    _emit();
  }

  /// Native-start (or first text/image frame) gates prize preemption. Preparing
  /// a waiter alone never stops a playing room effect.
  void presented(String key, {int? epoch}) {
    if (epoch != null && epoch != _epoch) return;
    final task = _queue.active;
    if (!mounted || task?.key != key || _presented == key || !_visible) return;
    if (!_eligible(task!)) {
      complete(key);
      return;
    }
    _presented = key;
    final room = repository.roomState;
    if (_effects.bigGift &&
        room.isInRoom &&
        !room.isMinimized &&
        room.status == RoomStatus.ready &&
        task.fullscreen != null) {
      onPresentedEffect?.call(task.fullscreen!);
    }
  }

  void blockPlayback(String key, Object error, {int? epoch}) {
    if (epoch != null && epoch != _epoch) return;
    if (!mounted || _queue.active?.key != key) return;
    _nativeBlocked = true;
    _clear();
    _emit(issue: 'room.barrage.playbackUnavailable');
  }

  void complete(String key, {int? epoch}) {
    if (epoch != null && epoch != _epoch) return;
    if (!mounted || _queue.active?.key != key) return;
    _prepared.remove(key);
    _queue.complete(key, _now());
    _presented = null;
    _emit();
  }

  void expire() {
    if (!mounted) return;
    _seen.removeWhere(
      (_, at) => _now().difference(at) > const Duration(minutes: 2),
    );
    _queue.advance(_now());
    _emit();
  }

  void _clear({bool clearSeen = false, bool revokeAction = true}) {
    _epoch++;
    _acceptAfter = _now();
    _queue.clear();
    _prepared.clear();
    _presented = null;
    if (clearSeen) {
      _seen.clear();
      _issue = null;
    }
    if (revokeAction) {
      _activeNavigator?.cancelPending();
      _activeNavigator = null;
      _actionRevision++;
      _actionBusy = false;
      _expectedRoom = null;
    }
  }

  void _emit({String? issue}) {
    if (!mounted) return;
    if (issue != null) _issue = issue;
    while (_queue.active != null && !_eligible(_queue.active!)) {
      _prepared.remove(_queue.active!.key);
      _queue.complete(_queue.active!.key, _now());
    }
    final retained = _queue.tasks.map((t) => t.key).toSet();
    _prepared.removeWhere((key, _) => !retained.contains(key));
    state = RoomBarrageState(
      active: _prepared[_queue.active?.key],
      uid: _uid,
      visible: _visible && _effects.screen,
      actionBusy: _actionBusy,
      revision: _actionRevision,
      epoch: _epoch,
      issue: _issue,
    );
  }

  @override
  void dispose() {
    _authRevision++;
    _epoch++;
    _actionRevision++;
    _timer?.cancel();
    _retry?.cancel();
    _activeNavigator?.cancelPending();
    _activeNavigator = null;
    unawaited(_subscription?.cancel());
    if (_started) {
      repository.removeAuthListener(_authChanged);
      repository.removeRoomListener(syncRoom);
    }
    super.dispose();
  }
}
