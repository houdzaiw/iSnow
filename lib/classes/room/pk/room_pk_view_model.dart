import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../more/room_tools_controller.dart';
import '../room_repository.dart';
import 'room_pk_models.dart';

final roomPkProvider = StateNotifierProvider.autoDispose
    .family<RoomPkViewModel, RoomPkState, String>((ref, id) {
      final tools = ref.watch(roomToolsControllerProvider(id).notifier);
      return RoomPkViewModel(tools, ref.read(roomRepositoryProvider));
    });

class RoomPkState {
  const RoomPkState({
    this.data = const RoomPkData(),
    this.seats = const [],
    this.selected = const [],
    this.doubleMode = true,
    this.duration = 3,
    this.busy = false,
    this.active = false,
    this.manager = false,
    this.mini = true,
    this.result,
    this.winnerPending = false,
    this.error,
  });
  final RoomPkData data;
  final List<RoomPkUser> seats;
  final List<int> selected;
  final bool doubleMode, busy, active, manager, mini, winnerPending;
  final int duration;
  final RoomPkData? result;
  final String? error;
  bool get canStart =>
      active &&
      manager &&
      !busy &&
      !data.active &&
      (doubleMode ? selected.length == 2 : selected.length >= 2);
}

class RoomPkViewModel extends StateNotifier<RoomPkState> {
  RoomPkViewModel(this.tools, this.room)
    : generation = room.roomGeneration,
      super(const RoomPkState()) {
    _removeTools = tools.addListener((_) => _sync(), fireImmediately: false);
    room.addListener(_sync);
    _sync();
  }
  final RoomToolsController tools;
  final RoomRepository room;
  int generation;
  late final void Function() _removeTools;
  final _finished = <String>{};
  bool _visible = true;
  bool _initialized = false;
  bool get valid => mounted && state.active;
  bool get visible => tools.visible;
  Future<void> refresh() => tools.refreshPk();
  String? _queriedExpiry;
  void _sync() {
    if (!mounted) return;
    if (tools.active && generation != room.roomGeneration) {
      generation = room.roomGeneration;
      _finished.clear();
      _initialized = false;
      _queriedExpiry = null;
      state = const RoomPkState();
    }
    final valid = tools.active && generation == room.roomGeneration;
    final data = RoomPkData.fromJson(tools.snapshot.pk.raw);
    final seats = room.roomState.micList
        .where((s) => (s.uid ?? 0) > 0)
        .map((s) => RoomPkUser.fromJson({...?s.userInfo, 'uid': s.uid}))
        .toList();
    var result = state.result;
    var winner = state.winnerPending;
    if (!valid) {
      result = null;
      winner = false;
    }
    if (data.finished && data.id.isNotEmpty && _finished.add(data.id)) {
      if (_initialized &&
          _visible &&
          tools.visible &&
          valid &&
          data.event == 4) {
        result = data;
        winner = data.winner != null && tools.snapshot.effects.bigGift;
      }
    }
    _initialized = true;
    state = RoomPkState(
      data: data,
      seats: seats,
      selected: state.selected
          .where((id) => seats.any((s) => s.uid == id))
          .toList(),
      doubleMode: state.doubleMode,
      duration: state.duration,
      busy: tools.snapshot.busy.contains('pk'),
      active: valid,
      manager: tools.canManage,
      mini: tools.snapshot.pkVisible == false || state.mini,
      result: result,
      winnerPending: winner,
      error: tools.errorOperation == 'pk' || tools.errorOperation == 'load:pk'
          ? tools.snapshot.error
          : null,
    );
    if (valid &&
        tools.visible &&
        data.active &&
        data.remaining(DateTime.now()) == 0 &&
        _queriedExpiry != data.id) {
      _queriedExpiry = data.id;
      unawaited(tools.refreshPk());
    }
  }

  void _change({
    List<int>? selected,
    bool? doubleMode,
    int? duration,
    bool? mini,
    RoomPkData? result,
    bool clearResult = false,
    bool? winner,
  }) {
    state = RoomPkState(
      data: state.data,
      seats: state.seats,
      selected: selected ?? state.selected,
      doubleMode: doubleMode ?? state.doubleMode,
      duration: duration ?? state.duration,
      busy: state.busy,
      active: state.active,
      manager: state.manager,
      mini: mini ?? state.mini,
      result: clearResult ? null : result ?? state.result,
      winnerPending: winner ?? state.winnerPending,
      error: state.error,
    );
  }

  void mode(bool doubleMode) {
    if (!state.busy && state.doubleMode != doubleMode) {
      _change(doubleMode: doubleMode, selected: []);
    }
  }

  void resetSetup() {
    if (state.active && !state.busy && !state.data.active) {
      _change(doubleMode: true, selected: [], duration: 3);
    }
  }

  void duration(int minutes) {
    if (!state.busy && [3, 5, 10, 20, 30, 40, 50, 60].contains(minutes)) {
      _change(duration: minutes);
    }
  }

  void select(int uid) {
    if (state.busy || !state.seats.any((s) => s.uid == uid)) return;
    final next = [...state.selected];
    if (next.contains(uid)) {
      next.remove(uid);
    } else {
      if (state.doubleMode && next.length >= 2) return;
      next.add(uid);
    }
    _change(selected: next);
  }

  void selectAll() {
    if (!state.busy && !state.doubleMode) {
      _change(
        selected: state.selected.length == state.seats.length
            ? []
            : state.seats.map((s) => s.uid).toList(),
      );
    }
  }

  Future<bool> begin() async {
    if (!state.canStart) return false;
    final ok = await tools.beginPk(
      [...state.selected],
      state.duration,
      oneOnOne: state.doubleMode,
    );
    if (mounted && ok && tools.active) {
      tools.showPk(true);
      _change(mini: false);
    }
    return ok;
  }

  Future<bool> end() => tools.endPk();
  void fold(bool mini) {
    if (state.active) {
      tools.showPk(!mini);
      _change(mini: mini);
    }
  }

  void setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    if (!visible && mounted) {
      _change(mini: true, clearResult: true, winner: false);
    }
  }

  void winnerFinished() {
    if (mounted) _change(winner: false);
  }

  void closeResult() {
    if (mounted) _change(clearResult: true, winner: false);
  }

  @override
  void dispose() {
    _removeTools();
    room.removeListener(_sync);
    super.dispose();
  }
}
