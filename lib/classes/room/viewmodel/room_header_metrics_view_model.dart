import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/app_socket_manager.dart';
import '../../../manager/room_manager.dart';
import '../../../model/room_socket_message.dart';
import '../room_repository.dart';

typedef RoomHeaderKey = ({String roomId, int generation});

final roomHeaderMetricsProvider = StateNotifierProvider.autoDispose
    .family<RoomHeaderMetricsViewModel, RoomHeaderMetrics, RoomHeaderKey>(
      (ref, key) =>
          RoomHeaderMetricsViewModel(ref.watch(roomRepositoryProvider), key),
    );

class RoomHeaderMetrics {
  const RoomHeaderMetrics({
    this.heat,
    this.contribution,
    this.profit,
    this.active = false,
    this.loadingHeat = false,
    this.heatError,
  });
  final int? heat, contribution, profit;
  final bool active, loadingHeat;
  final String? heatError;

  RoomHeaderMetrics copy({
    Object? heat = _unchanged,
    Object? contribution = _unchanged,
    Object? profit = _unchanged,
    bool? active,
    bool? loadingHeat,
    Object? heatError = _unchanged,
  }) => RoomHeaderMetrics(
    heat: identical(heat, _unchanged) ? this.heat : heat as int?,
    contribution: identical(contribution, _unchanged)
        ? this.contribution
        : contribution as int?,
    profit: identical(profit, _unchanged) ? this.profit : profit as int?,
    active: active ?? this.active,
    loadingHeat: loadingHeat ?? this.loadingHeat,
    heatError: identical(heatError, _unchanged)
        ? this.heatError
        : heatError as String?,
  );
  static const _unchanged = Object();
}

/// Header values are separate from audience/microphone counts and rank lists.
class RoomHeaderMetricsViewModel extends StateNotifier<RoomHeaderMetrics>
    with WidgetsBindingObserver {
  RoomHeaderMetricsViewModel(this.room, this.key)
    : super(const RoomHeaderMetrics()) {
    room.addListener(_sync);
    room.addAuthListener(_onAccountChanged);
    WidgetsBinding.instance.addObserver(this);
    _events = room.socketMessages.listen(_receive);
    // Same 100-second heat refresh cadence as Nady's PartyRefreshTimer.
    _timer = Timer.periodic(const Duration(seconds: 100), (_) => refreshHeat());
    Future.microtask(_sync);
  }
  final RoomRepository room;
  final RoomHeaderKey key;
  AppSocketStatus? _socketStatus;
  StreamSubscription<RoomSocketMessage>? _events;
  Timer? _timer;
  Future<void>? _heatTask;
  int _epoch = 0;
  bool _authorized = true;
  bool _foreground =
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  bool get active =>
      mounted &&
      _authorized &&
      _foreground &&
      room.roomGeneration == key.generation &&
      room.roomState.currentRoomId == key.roomId &&
      room.roomState.status == RoomStatus.ready &&
      room.roomState.isInRoom &&
      !room.roomState.isMinimized;

  void _sync() {
    if (!mounted) return;
    if (!_authorized ||
        room.roomGeneration != key.generation ||
        room.roomState.currentRoomId != key.roomId ||
        !room.roomState.isInRoom) {
      _cancelPending();
      state = const RoomHeaderMetrics();
      return;
    }
    final wasActive = state.active;
    final info = room.roomState.roomInfo;
    final contribution = room.roomState.roomWeekVal ?? info?.roomGiftWeekVal;
    final profit = info == null ? null : info.roomGiftIncomeVal ?? 0;
    if (contribution != state.contribution || profit != state.profit) {
      state = state.copy(contribution: contribution, profit: profit);
    }
    state = state.copy(active: active);
    final socket = room.socketState.status;
    final reconnected =
        socket == AppSocketStatus.ready && socket != _socketStatus;
    _socketStatus = socket;
    if (!active) {
      _cancelPending();
      state = state.copy(loadingHeat: false);
    } else if (!wasActive || reconnected) {
      unawaited(refreshHeat());
    }
  }

  Future<void> refreshHeat() {
    if (!active) return Future.value();
    if (_heatTask case final pending?) return pending;
    late final Future<void> task;
    task = _loadHeat(++_epoch).whenComplete(() {
      if (identical(_heatTask, task)) _heatTask = null;
    });
    _heatTask = task;
    return task;
  }

  Future<void> _loadHeat(int epoch) async {
    state = state.copy(loadingHeat: true, heatError: null);
    try {
      final value = await room.fetchRoomHeat(key.roomId);
      if (active && epoch == _epoch) {
        state = state.copy(heat: value, loadingHeat: false);
      }
    } catch (error) {
      if (active && epoch == _epoch) {
        state = state.copy(
          loadingHeat: false,
          heatError: userFacingErrorMessage(error),
        );
      }
    }
  }

  void _receive(RoomSocketMessage message) {
    if (!active || !['room', 'room:${key.roomId}'].contains(message.channel)) {
      return;
    }
    if (message.event == 'RoomAudienceUpdateEvent') {
      unawaited(refreshHeat());
    }
  }

  void _cancelPending() {
    _epoch++;
    _heatTask = null;
  }

  void _onAccountChanged() {
    _authorized = false;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    _cancelPending();
    _timer?.cancel();
    unawaited(_events?.cancel());
    room.removeListener(_sync);
    room.removeAuthListener(_onAccountChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
