import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'daily_reward_models.dart';
import 'daily_reward_repository.dart';
import '../../room/room_repository.dart';

class DailyRewardState {
  const DailyRewardState({
    this.sign,
    this.groups = const [],
    this.loadingSign = true,
    this.loadingTasks = true,
    this.signError,
    this.taskError,
    this.busy = false,
    this.signedHere = false,
    this.locallyClaimed = const {},
  });
  final DailySignInfo? sign;
  final List<DailyTaskGroup> groups;
  final bool loadingSign, loadingTasks, busy;
  final bool signedHere;
  final Set<int> locallyClaimed;
  bool get canSign => !signedHere && sign?.canSign == true;
  bool canClaim(DailyTask task) =>
      task.status == 2 && !locallyClaimed.contains(task.id);
  final Object? signError, taskError;
  DailyRewardState copy({
    DailySignInfo? sign,
    List<DailyTaskGroup>? groups,
    bool? loadingSign,
    bool? loadingTasks,
    bool? busy,
    Object? signError,
    Object? taskError,
    bool? signedHere,
    Set<int>? locallyClaimed,
  }) => DailyRewardState(
    sign: sign ?? this.sign,
    groups: groups ?? this.groups,
    loadingSign: loadingSign ?? this.loadingSign,
    loadingTasks: loadingTasks ?? this.loadingTasks,
    busy: busy ?? this.busy,
    signError: signError,
    taskError: taskError,
    signedHere: signedHere ?? this.signedHere,
    locallyClaimed: locallyClaimed ?? this.locallyClaimed,
  );
}

final dailyRewardProvider =
    StateNotifierProvider.autoDispose<DailyRewardViewModel, DailyRewardState>((
      ref,
    ) {
      final room = ref.watch(roomRepositoryProvider);
      return DailyRewardViewModel(
        ref.watch(dailyRewardRepositoryProvider),
        currentRoom: () =>
            room.roomState.isInRoom ? room.roomState.currentRoomId ?? '' : '',
      );
    });

class DailyRewardViewModel extends StateNotifier<DailyRewardState> {
  DailyRewardViewModel(this.repo, {this.currentRoom})
    : super(const DailyRewardState()) {
    Future.microtask(() {
      if (_alive) refresh();
    });
  }
  final DailyRewardRepository repo;
  final String Function()? currentRoom;
  bool _alive = true;
  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  Future<DailyDestination?> destination(DailyTask task) async {
    if (!_alive || state.busy || task.status != 1) return null;
    if (task.id == 8) {
      return const DailyDestination(DailyDestinationKind.binding);
    }
    final account = await repo.features.identity();
    final lobby = task.id == 6
        ? 1
        : task.id == 7
        ? 2
        : 0;
    DailyRoomTarget? room;
    if (lobby > 0) {
      room = await repo.ownRoom();
    } else {
      final current = currentRoom?.call() ?? '';
      room = current.isEmpty
          ? await repo.recommendedRoom()
          : DailyRoomTarget(current, 0);
      room ??= await repo.ownRoom();
    }
    await repo.features.check(account);
    if (!_alive) return null;
    return DailyDestination(
      room == null
          ? (lobby > 0
                ? DailyDestinationKind.createRoom
                : DailyDestinationKind.unavailable)
          : DailyDestinationKind.room,
      room: room,
      lobbyType: lobby,
    );
  }

  Future<void> refresh() async {
    if (!_alive || state.busy) return;
    await Future.wait([loadSign(), loadTasks()]);
  }

  Future<void> loadSign() async {
    if (!_alive) return;
    state = state.copy(loadingSign: true, taskError: state.taskError);
    try {
      final data = await repo.signInfo();
      if (_alive) {
        state = state.copy(
          sign: data,
          signedHere: false,
          loadingSign: false,
          taskError: state.taskError,
        );
      }
    } catch (e) {
      if (_alive) {
        state = state.copy(
          signError: e,
          loadingSign: false,
          taskError: state.taskError,
        );
      }
    }
  }

  Future<void> loadTasks() async {
    if (!_alive) return;
    state = state.copy(loadingTasks: true, signError: state.signError);
    try {
      final data = await repo.tasks();
      if (_alive) {
        state = state.copy(
          groups: data,
          locallyClaimed: const {},
          loadingTasks: false,
          signError: state.signError,
        );
      }
    } catch (e) {
      if (_alive) {
        state = state.copy(
          taskError: e,
          loadingTasks: false,
          signError: state.signError,
        );
      }
    }
  }

  Future<DailyOutcome?> submit({int? missionId}) async {
    if (!_alive || state.busy) return null;
    if (missionId == null) {
      if (state.loadingSign || !state.canSign) return null;
    } else if (state.loadingTasks ||
        !state.groups
            .expand((g) => g.items)
            .any((t) => t.id == missionId && state.canClaim(t))) {
      return null;
    }
    final previousRewards =
        state.sign?.items.where((d) => d.today).firstOrNull?.rewards ??
        const <DailyRewardItem>[];
    state = state.copy(
      busy: true,
      signError: state.signError,
      taskError: state.taskError,
    );
    try {
      final result = missionId == null
          ? DailyOutcome(
              previousRewards,
              await repo.sign(isCurrent: () => _alive),
            )
          : await repo.claim(missionId, isCurrent: () => _alive);
      if (!_alive) return null;
      state = state.copy(
        signedHere: missionId == null ? true : state.signedHere,
        locallyClaimed: {
          ...state.locallyClaimed,
          if (missionId != null) missionId,
        },
        signError: state.signError,
        taskError: state.taskError,
      );
      await Future.wait([loadSign(), loadTasks()]);
      return _alive
          ? DailyOutcome(
              result.rewards,
              result.refreshed &&
                  state.signError == null &&
                  state.taskError == null,
            )
          : null;
    } finally {
      if (_alive) {
        state = state.copy(
          busy: false,
          signError: state.signError,
          taskError: state.taskError,
        );
      }
    }
  }
}
