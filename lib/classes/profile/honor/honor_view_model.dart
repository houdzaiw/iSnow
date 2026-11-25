import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../tools/profile_feature_repository.dart';
import 'honor_models.dart';
import 'honor_repository.dart';

class HonorState {
  const HonorState({
    this.catalog = const {},
    this.equipment,
    this.draft = const [],
    this.editing = false,
    this.busy = false,
    this.loading = false,
    this.error,
  });
  final Map<int, List<HonorBadge>> catalog;
  final HonorEquipment? equipment;
  final List<String> draft;
  final bool editing, busy, loading;
  final Object? error;
  HonorState copy({
    Map<int, List<HonorBadge>>? catalog,
    HonorEquipment? equipment,
    List<String>? draft,
    bool? editing,
    bool? busy,
    bool? loading,
    Object? error,
  }) => HonorState(
    catalog: catalog ?? this.catalog,
    equipment: equipment ?? this.equipment,
    draft: draft ?? this.draft,
    editing: editing ?? this.editing,
    busy: busy ?? this.busy,
    loading: loading ?? this.loading,
    error: error,
  );
}

final honorProvider =
    StateNotifierProvider.autoDispose<HonorViewModel, HonorState>(
      (ref) => HonorViewModel(ref.watch(honorRepositoryProvider)),
    );

class HonorViewModel extends StateNotifier<HonorState> {
  HonorViewModel(this.repo) : super(const HonorState()) {
    Future.microtask(load);
  }
  final HonorRepository repo;
  bool _alive = true;
  MembershipIdentity? _account;
  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  Future<void> load() async {
    if (!_alive || state.loading || state.busy || state.editing) return;
    state = state.copy(loading: true);
    try {
      final account = await repo.features.identity();
      final equipment = await repo.equipment(account: account);
      final catalog = <int, List<HonorBadge>>{};
      for (final type in [1, 2, 3]) {
        catalog[type] = await repo.badges(type, account: account);
      }
      if (!_alive) return;
      _account = account;
      state = HonorState(
        catalog: catalog,
        equipment: equipment,
        draft: equipment.ids,
      );
    } catch (e) {
      if (_alive) state = state.copy(loading: false, error: e);
    }
  }

  void edit() {
    if (state.equipment != null &&
        !state.busy &&
        !state.loading &&
        state.error == null) {
      state = state.copy(editing: true);
    }
  }

  void cancel() {
    if (!state.busy) {
      state = state.copy(editing: false, draft: state.equipment?.ids ?? []);
    }
  }

  void toggle(HonorBadge badge) {
    if (!state.editing || state.busy) return;
    final ids = [...state.draft];
    if (!ids.remove(badge.id)) {
      if (!badge.wearable(DateTime.now()) ||
          ids.length >= state.equipment!.limit) {
        return;
      }
      ids.add(badge.id);
    }
    state = state.copy(draft: ids);
  }

  void remove(String id) {
    if (state.editing && !state.busy) {
      state = state.copy(draft: state.draft.where((i) => i != id).toList());
    }
  }

  void move(int oldIndex, int newIndex) {
    if (!state.editing || state.busy) return;
    final ids = [...state.draft];
    if (newIndex > oldIndex) newIndex--;
    ids.insert(newIndex, ids.removeAt(oldIndex));
    state = state.copy(draft: ids);
  }

  Future<bool?> save() async {
    if (!_alive || !state.editing || state.busy || _account == null) {
      return null;
    }
    state = state.copy(busy: true);
    try {
      final result = await repo.save([...state.draft], _account!, () => _alive);
      if (!_alive) return null;
      // Commit before refreshing: a refresh failure must not offer a duplicate submission.
      state = state.copy(editing: false, busy: false);
      await load();
      return _alive ? result && state.error == null : null;
    } catch (e) {
      if (_alive) state = state.copy(busy: false, error: e);
      return null;
    }
  }
}
