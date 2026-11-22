import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../more/room_tools_controller.dart';
import '../more/room_tools_models.dart';
import 'room_lucky_box_models.dart';

final roomLuckyBoxProvider = StateNotifierProvider.autoDispose
    .family<RoomLuckyBoxViewModel, RoomLuckyBoxState, String>((ref, id) {
      final tools = ref.watch(roomToolsControllerProvider(id).notifier);
      return RoomLuckyBoxViewModel(tools);
    });

enum RoomLuckyBoxPhase { ready, requesting, result, error }

class RoomLuckyBoxState {
  const RoomLuckyBoxState({
    this.active = false,
    this.canSend = false,
    this.loading = false,
    this.sending = false,
    this.reviewRequired = false,
    this.type = 0,
    this.gold,
    this.people,
    this.countdown,
    this.balance = 0,
    this.config,
    this.bags = const [],
    this.current,
    this.result,
    this.phase = RoomLuckyBoxPhase.ready,
    this.error,
  });
  final bool active, canSend, loading, sending, reviewRequired;
  final int type, balance;
  final int? gold, people, countdown;
  final RoomLuckyBoxConfig? config;
  final List<RoomLuckyBag> bags;
  final RoomLuckyBag? current;
  final RoomLuckyBoxResult? result;
  final RoomLuckyBoxPhase phase;
  final String? error;
  RoomLuckyBoxMode? get mode => type == 0 ? config?.room : config?.world;
  bool get canSubmit =>
      active &&
      canSend &&
      !loading &&
      !sending &&
      !reviewRequired &&
      gold != null &&
      people != null &&
      countdown != null;
}

class RoomLuckyBoxViewModel extends StateNotifier<RoomLuckyBoxState> {
  RoomLuckyBoxViewModel(this.tools)
    : generation = tools.room.roomGeneration,
      super(const RoomLuckyBoxState()) {
    _removeTools = tools.addListener((_) => _sync(), fireImmediately: false);
    _sync();
  }
  final RoomToolsController tools;
  int generation;
  late final void Function() _removeTools;
  final _skipped = <String>{}, _finished = <String>{};
  final _readyOrder = <String>[];
  bool _presentable = false;
  bool _loading = false, _sending = false, _review = false;
  bool _configReady = false;
  int _operation = 0, _type = 0;
  int? _gold, _people, _countdown;
  String? _error;
  RoomLuckyBag? _current;
  RoomLuckyBoxResult? _result;
  RoomLuckyBoxPhase _phase = RoomLuckyBoxPhase.ready;
  bool get valid =>
      mounted && tools.active && tools.room.roomGeneration == generation;
  void _sync() {
    if (!mounted) return;
    if (tools.active && generation != tools.room.roomGeneration) {
      generation = tools.room.roomGeneration;
      _operation++;
      _current = null;
      _result = null;
      _skipped.clear();
      _finished.clear();
      _readyOrder.clear();
      _loading = false;
      _sending = false;
      _review = false;
      _configReady = false;
      _type = 0;
      _gold = null;
      _people = null;
      _countdown = null;
      _error = null;
      _phase = RoomLuckyBoxPhase.ready;
    }
    if (!valid) {
      _operation++;
      _current = null;
      _result = null;
      _skipped.clear();
      _finished.clear();
      _readyOrder.clear();
    }
    final config = RoomLuckyBoxConfig.fromJson(tools.snapshot.luckyConfig);
    final mode = _type == 0 ? config.room : config.world;
    if (!mode.amounts.any((a) => a.gold == _gold)) {
      _gold = mode.amounts.firstOrNull?.gold;
    }
    final people =
        mode.amounts.where((a) => a.gold == _gold).firstOrNull?.people ?? [];
    if (!people.contains(_people)) _people = people.firstOrNull;
    if (!mode.countdowns.contains(_countdown)) {
      _countdown = mode.countdowns.firstOrNull;
    }
    if (_current != null &&
        _phase == RoomLuckyBoxPhase.ready &&
        !tools.snapshot.bags.any((b) => b.id == _current!.id)) {
      _current = null;
    }
    state = RoomLuckyBoxState(
      active: valid,
      canSend: tools.canSendLucky && _configReady,
      config: config,
      type: _type,
      gold: _gold,
      people: _people,
      countdown: _countdown,
      balance: tools.snapshot.balance,
      bags: tools.snapshot.bags,
      loading: _loading,
      sending: _sending,
      reviewRequired: _review,
      current: _current,
      result: _result,
      phase: _phase,
      error: _error,
    );
    if (valid) {
      _readyOrder.removeWhere(
        (id) =>
            !state.bags.any((b) => b.id == id) ||
            _finished.contains(id) ||
            _skipped.contains(id),
      );
      final ready =
          state.bags.where((b) => b.remaining(DateTime.now()) == 0).toList()
            ..sort((a, b) => a.readyAt.compareTo(b.readyAt));
      for (final bag in ready) {
        if (bag.id != _current?.id &&
            !_readyOrder.contains(bag.id) &&
            !_finished.contains(bag.id) &&
            !_skipped.contains(bag.id)) {
          _readyOrder.add(bag.id);
        }
      }
    }
  }

  Future<bool> load() async {
    if (!valid || _loading || _sending) return false;
    _loading = true;
    _configReady = false;
    _error = null;
    _sync();
    final operation = _operation;
    try {
      final configOk = await tools.refreshLuckyConfig();
      if (!valid || operation != _operation) return false;
      await Future.wait([tools.refreshBalance(), tools.refreshBags()]);
      if (!valid || operation != _operation) return false;
      if (!configOk ||
          ['load:balance', 'load:bags'].contains(tools.errorOperation)) {
        _error = tools.snapshot.error ?? 'Unable to refresh Lucky Box';
        return false;
      }
      _review = false;
      _configReady = true;
      return true;
    } catch (e) {
      if (valid) _error = userFacingErrorMessage(e);
      return false;
    } finally {
      if (mounted && operation == _operation) {
        _loading = false;
        _sync();
      }
    }
  }

  void chooseType(int type) {
    if (!state.sending && [0, 1].contains(type)) {
      _type = type;
      _gold = null;
      _people = null;
      _countdown = null;
      _sync();
    }
  }

  void chooseGold(int gold) {
    if (!state.sending &&
        (state.mode?.amounts.any((a) => a.gold == gold) ?? false)) {
      _gold = gold;
      _people = null;
      _sync();
    }
  }

  void choosePeople(int people) {
    if (!state.sending &&
        (state.mode?.amounts
                .where((a) => a.gold == _gold)
                .firstOrNull
                ?.people
                .contains(people) ??
            false)) {
      _people = people;
      _sync();
    }
  }

  void chooseCountdown(int seconds) {
    if (!state.sending && (state.mode?.countdowns.contains(seconds) ?? false)) {
      _countdown = seconds;
      _sync();
    }
  }

  Future<bool?> needsConfirmation() async {
    if (!valid) return null;
    try {
      final needed = await tools.needsLuckyConfirmation();
      return valid ? needed : null;
    } catch (error) {
      if (valid) {
        _error = userFacingErrorMessage(error);
        _sync();
      }
      return null;
    }
  }

  Future<void> refreshList() async {
    await tools.refreshBags();
    if (!valid) return;
    _error = tools.errorOperation == 'load:bags' ? tools.snapshot.error : null;
    _sync();
  }

  Future<bool> send({required bool confirmed}) async {
    if (!state.canSubmit) return false;
    final type = _type,
        gold = _gold!,
        people = _people!,
        countdown = _countdown!;
    _sending = true;
    _error = null;
    _sync();
    final operation = _operation;
    try {
      final configOk = await tools.refreshLuckyConfig();
      if (!valid || operation != _operation) return false;
      await tools.refreshBalance();
      if (!valid || operation != _operation) return false;
      if (!configOk || tools.errorOperation == 'load:balance') {
        _error =
            tools.snapshot.error ?? 'Unable to verify Lucky Box configuration';
        return false;
      }
      if (tools.snapshot.balance < gold) {
        _error = 'Not enough coins';
        return false;
      }
      final success = await tools.sendLucky(
        type: type,
        gold: gold,
        recipients: people,
        countdown: countdown,
        confirmed: confirmed,
      );
      if (!valid || operation != _operation) return false;
      if (!success) {
        _error = tools.snapshot.error;
        _review = tools.errorOperation == 'luckySend';
      }
      return success;
    } finally {
      if (mounted && operation == _operation) {
        _sending = false;
        _sync();
      }
    }
  }

  /// Called by the room host only after checking modal and full-screen ownership.
  void tick({required bool presentable, DateTime? now}) {
    if (!valid) return;
    _presentable = presentable;
    if (!tools.visible) {
      _operation++;
      _current = null;
      _result = null;
      _phase = RoomLuckyBoxPhase.ready;
      _sync();
      return;
    }
    if (!_presentable || _current != null) return;
    final next = _readyOrder
        .map((id) => state.bags.where((b) => b.id == id).firstOrNull)
        .whereType<RoomLuckyBag>()
        .where(
          (b) =>
              b.remaining(now ?? DateTime.now()) == 0 &&
              !_skipped.contains(b.id) &&
              !_finished.contains(b.id),
        )
        .firstOrNull;
    if (next != null) {
      _readyOrder.remove(next.id);
      _current = next;
      _result = null;
      _phase = RoomLuckyBoxPhase.ready;
      _error = null;
      _sync();
    }
  }

  void open(String id) {
    if (!valid || !tools.visible || _current != null) return;
    final bag = state.bags
        .where((b) => b.id == id && b.remaining(DateTime.now()) == 0)
        .firstOrNull;
    if (bag == null || _finished.contains(id)) return;
    _readyOrder.remove(id);
    _current = bag;
    _result = null;
    _phase = RoomLuckyBoxPhase.ready;
    _error = null;
    _sync();
  }

  Future<void> grab() async {
    final bag = _current;
    if (!valid ||
        !tools.visible ||
        bag == null ||
        _phase == RoomLuckyBoxPhase.requesting ||
        _phase == RoomLuckyBoxPhase.result) {
      return;
    }
    final operation = ++_operation;
    _phase = RoomLuckyBoxPhase.requesting;
    _error = null;
    _sync();
    final result = await tools.grabLucky(bag.id);
    if (!valid || operation != _operation || _current?.id != bag.id) return;
    if (result == null) {
      _phase = RoomLuckyBoxPhase.error;
      _error = tools.snapshot.error;
    } else {
      _finished.add(bag.id);
      _result = RoomLuckyBoxResult.fromJson(result);
      _phase = RoomLuckyBoxPhase.result;
    }
    _sync();
  }

  void close() {
    if (!mounted) return;
    if (_current != null) _skipped.add(_current!.id);
    _operation++;
    _current = null;
    _result = null;
    _phase = RoomLuckyBoxPhase.ready;
    _error = null;
    _sync();
  }

  void suspend() {
    if (!mounted) return;
    _operation++;
    _current = null;
    _result = null;
    _phase = RoomLuckyBoxPhase.ready;
    _sync();
  }

  @override
  void dispose() {
    _operation++;
    _removeTools();
    super.dispose();
  }
}
