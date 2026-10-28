import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/app_socket_manager.dart';
import '../../../manager/http_api.dart';
import '../../../manager/room_manager.dart';
import '../../../model/room_models.dart';
import '../../../model/room_socket_message.dart';
import '../../../model/server_response.dart';
import '../room_repository.dart';
import 'room_tools_models.dart';
import 'room_tools_repository.dart';

part 'room_tools_operations.dart';
part 'room_tools_events.dart';

final roomToolsControllerProvider = StateNotifierProvider.autoDispose
    .family<RoomToolsController, RoomToolsState, String>((ref, roomId) {
      final controller = RoomToolsController(
        roomId: roomId,
        repository: ref.watch(roomToolsRepositoryProvider),
        room: ref.watch(roomRepositoryProvider),
        retain: ref.keepAlive,
      );
      Future.microtask(controller.start);
      return controller;
    });

class RoomToolsController extends StateNotifier<RoomToolsState>
    with WidgetsBindingObserver {
  RoomToolsController({
    required this.roomId,
    required this.repository,
    required this.room,
    this.retain,
  }) : super(const RoomToolsState());
  final String roomId;
  final RoomToolsRepository repository;
  final RoomRepository room;
  final KeepAliveLink Function()? retain;
  KeepAliveLink? _keepAlive;
  StreamSubscription<RoomSocketMessage>? _messages;
  Timer? _ticker, _prizeDelay, _lobbyInsert, _awardRemoval;
  String? _countryCode, _gameId;
  String? _errorOperation;
  bool _gameOpened = false;
  int? uid;
  int _generation = -1;
  int _entryEffectsGeneration = -1;
  bool _started = false, _foreground = true;
  bool _wasVisible = true;
  DateTime? _visualAfter;
  AppSocketStatus? _socketStatus;
  final _seen = <String>{};
  final _terminalPks = <String>{};
  final _claimedBags = <String>{};
  final _snapshotVersions = <String, int>{};
  final _reloadKeys = <String>{};
  RoomToolsState get snapshot => state;
  RoomToolsState get _value => state;
  set _value(RoomToolsState next) => state = next;
  bool get active =>
      mounted &&
      room.roomGeneration == _generation &&
      room.roomState.currentRoomId == roomId &&
      room.roomState.isInRoom &&
      room.roomState.status == RoomStatus.ready;
  bool get canManage =>
      active &&
      (room.roomState.enterResponse?.identity?.isOwnerOrManager == true ||
          uid != null && room.roomState.roomInfo?.roomOwnerUid == uid);
  bool get visible => active && !room.roomState.isMinimized && _foreground;
  String? get errorOperation => _errorOperation;
  bool get charmStatusReady => _snapshotVersions.containsKey('charm');
  bool get charmStatusBusy =>
      state.busy.contains('charm') || state.busy.contains('load:charm');

  void start() {
    if (!mounted || _started) return;
    _started = true;
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    room.addListener(_sync);
    _messages = room.socketMessages.listen(receive);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (active && visible && (state.pk.active || state.bags.isNotEmpty)) {
        state = state.copy();
      }
    });
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final current = room.roomState;
    final valid =
        current.currentRoomId == roomId &&
        current.isInRoom &&
        current.status == RoomStatus.ready;
    if (!valid) {
      if (state.sessionActive) {
        _prizeDelay?.cancel();
        _lobbyInsert?.cancel();
        _awardRemoval?.cancel();
        _gameOpened = false;
        _gameId = null;
        _errorOperation = null;
        state = const RoomToolsState();
        _keepAlive?.close();
        _keepAlive = null;
      }
      return;
    }
    if (_generation != room.roomGeneration) {
      _generation = room.roomGeneration;
      _seen.clear();
      _terminalPks.clear();
      _claimedBags.clear();
      _snapshotVersions.clear();
      _reloadKeys.clear();
      _errorOperation = null;
      state = RoomToolsState(
        sessionActive: true,
        currency: current.enterResponse?.initialCharmCurrency ?? 0,
        lobbyType: current.enterResponse?.status == 1
            ? current.enterResponse?.lobbyType ?? 0
            : 0,
        lobbyVisible:
            current.enterResponse?.status == 1 &&
            [1, 2].contains(current.enterResponse?.lobbyType),
      );
      _keepAlive ??= retain?.call();
      unawaited(_initialize(_generation));
    }
    final socket = room.socketState.status;
    if (socket == AppSocketStatus.ready &&
        _socketStatus != socket &&
        uid != null) {
      unawaited(_subscribeEntryEffects(uid!, _generation));
      unawaited(refresh());
      unawaited(_restoreSpeaker());
    }
    _socketStatus = socket;
    if (_wasVisible != visible) {
      _wasVisible = visible;
      _markVisualBoundary();
    }
    if (!visible &&
        (state.vehicleEffects.isNotEmpty ||
            state.worldBanners.isNotEmpty ||
            state.prize.isNotEmpty ||
            state.lobbyAwards.isNotEmpty)) {
      state = state.copy(
        worldBanners: [],
        prize: {},
        lobbyAwards: [],
        vehicleEffects: [],
      );
    }
  }

  Future<void> _initialize(int generation) async {
    try {
      final userId = await room.currentUid();
      if (!active || generation != _generation || userId == null) return;
      uid = userId;
      _countryCode = (await room.currentUser())?.countryCode;
      if (!active || generation != _generation) return;
      final prefs = await repository.effects(userId);
      if (!active || generation != _generation) return;
      state = state.copy(effects: prefs, preferencesReady: true);
      await _restoreSpeaker();
      if (!active) return;
      unawaited(_subscribeEntryEffects(userId, generation));
      await refresh();
    } catch (error) {
      if (active) {
        _errorOperation = 'initialize';
        state = state.copy(error: userFacingErrorMessage(error));
      }
    }
  }

  Future<void> refresh() async {
    if (!active) return;
    await Future.wait([
      _load(
        'functions',
        () => repository.functions(roomId),
        (data) => state = state.copy(config: data as RoomFunctionConfig),
      ),
      refreshCharmStatus(),
      _load(
        'pk',
        () => repository.get(HttpApi.roomPkInfo, {'roomId': roomId}),
        (data) => _applyPk(toolMap(data)),
      ),
      _load(
        'luckyConfig',
        () => repository.get(HttpApi.roomLuckyConfig, {'roomId': roomId}),
        (data) => state = state.copy(luckyConfig: toolMap(data)),
      ),
      refreshBags(),
    ]);
    if (!active) return;
    if (state.lobbyType != 0) await loadLobby();
    if (state.config.enabled(8, 17)) await refreshBigWin();
  }

  Future<void> _subscribeEntryEffects(int userId, int generation) async {
    try {
      await room.subscribeTools(userId);
      if (!active ||
          generation != _generation ||
          _entryEffectsGeneration == generation) {
        return;
      }
      _entryEffectsGeneration = generation;
      await repository.get(HttpApi.roomEntryProps, {'roomId': roomId});
    } catch (error) {
      debugPrint('[RoomTools] Entry effects unavailable: $error');
    }
  }

  Future<void> _load(
    String key,
    Future<Object?> Function() load,
    void Function(Object?) apply,
  ) async {
    if (!active) return;
    if (state.busy.contains('load:$key')) {
      _reloadKeys.add(key);
      return;
    }
    final generation = _generation;
    final version = _snapshotVersions[key] ?? 0;
    state = state.copy(busy: {...state.busy, 'load:$key'});
    try {
      final data = await load();
      if (active &&
          generation == _generation &&
          version == (_snapshotVersions[key] ?? 0)) {
        apply(data);
      }
    } catch (error) {
      if (active && generation == _generation) {
        _errorOperation = 'load:$key';
        state = state.copy(error: userFacingErrorMessage(error));
      }
    } finally {
      if (active && generation == _generation) {
        state = state.copy(
          busy: {...state.busy}..remove('load:$key'),
          error: state.error,
        );
        if (_reloadKeys.remove(key)) unawaited(_load(key, load, apply));
      }
    }
  }

  Future<bool> perform(
    String key,
    Future<void> Function(bool Function() current) action, {
    bool manager = false,
  }) async {
    if (!active || state.busy.contains(key)) return false;
    if (manager && !canManage) {
      _errorOperation = key;
      state = state.copy(error: 'Room management permission required');
      return false;
    }
    final generation = _generation;
    bool current() =>
        active && generation == _generation && (!manager || canManage);
    _errorOperation = null;
    state = state.copy(busy: {...state.busy, key}, clearError: true);
    try {
      await action(current);
      return current();
    } catch (error) {
      if (active && generation == _generation) {
        _errorOperation = key;
        state = state.copy(error: userFacingErrorMessage(error));
      }
      return false;
    } finally {
      if (active && generation == _generation) {
        state = state.copy(
          busy: {...state.busy}..remove(key),
          error: state.error,
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _markVisualBoundary();
    if (!visible) {
      if (mounted) {
        this.state = this.state.copy(
          worldBanners: [],
          prize: {},
          lobbyAwards: [],
          vehicleEffects: [],
        );
      }
    } else {
      unawaited(refresh());
    }
  }

  void _markVisualBoundary() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _visualAfter = DateTime.fromMillisecondsSinceEpoch(now ~/ 1000 * 1000);
  }

  @override
  void dispose() {
    if (_started) {
      room.removeListener(_sync);
      WidgetsBinding.instance.removeObserver(this);
    }
    _ticker?.cancel();
    _prizeDelay?.cancel();
    _lobbyInsert?.cancel();
    _awardRemoval?.cancel();
    unawaited(_messages?.cancel());
    _keepAlive?.close();
    super.dispose();
  }
}
